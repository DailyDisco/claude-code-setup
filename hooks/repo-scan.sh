#!/bin/bash
# =============================================================================
# TIER 1: Smart Repo Scan Hook (Context Priming)
# =============================================================================
# Event: SessionStart
# Purpose: Prevents hallucinations by scanning repo structure on session start
# Features:
#   - Detects monorepo vs single-app
#   - Identifies specific frameworks (Next.js, Remix, etc.)
#   - Finds actual test/build/lint commands
#   - Detects state management, ORMs, styling
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"
source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true
source "${HOME}/.claude/hooks/lib/context-optimizer.sh" 2>/dev/null || true

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
context=""

# Determine output mode (compact vs full)
OUTPUT_DETAIL="${CLAUDE_REPO_SCAN_DETAIL:-auto}"  # auto | compact | full
OPTIMIZATION_MODE=$(get_optimization_mode 2>/dev/null || echo "balanced")

# =============================================================================
# Caching (Phase 2.0 Optimization)
# =============================================================================
CACHE_DIR="$HOME/.claude/cache/repo-scan"
mkdir -p "$CACHE_DIR"

# Cache TTL: 5 minutes (can be overridden)
CACHE_TTL="${CLAUDE_CACHE_TTL:-300}"

# Generate cache key from project path + package.json modification time
get_cache_key() {
    local proj_hash=$(echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | cut -c1-12)
    local pkg_mtime=0
    [[ -f "$PROJECT_DIR/package.json" ]] && pkg_mtime=$(stat -c %Y "$PROJECT_DIR/package.json" 2>/dev/null || stat -f %m "$PROJECT_DIR/package.json" 2>/dev/null || echo 0)
    echo "${proj_hash}-${pkg_mtime}"
}

CACHE_KEY=$(get_cache_key)
CACHE_FILE="$CACHE_DIR/scan-$CACHE_KEY"

# Check cache validity
if [[ -f "$CACHE_FILE" ]] && [[ "$CACHE_TTL" -gt 0 ]]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $cache_age -lt $CACHE_TTL ]]; then
        # Load from cache and output
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Cache miss - perform scan (output will be captured and cached at end)
SCAN_OUTPUT=""

# =============================================================================
# Monorepo Detection
# =============================================================================
is_monorepo=false
monorepo_type=""

if [[ -f "$PROJECT_DIR/pnpm-workspace.yaml" ]]; then
    is_monorepo=true; monorepo_type="pnpm workspaces"
elif [[ -f "$PROJECT_DIR/lerna.json" ]]; then
    is_monorepo=true; monorepo_type="lerna"
elif [[ -f "$PROJECT_DIR/nx.json" ]]; then
    is_monorepo=true; monorepo_type="nx"
elif [[ -f "$PROJECT_DIR/turbo.json" ]]; then
    is_monorepo=true; monorepo_type="turborepo"
elif [[ -f "$PROJECT_DIR/package.json" ]] && jq -e '.workspaces' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    is_monorepo=true; monorepo_type="npm/yarn workspaces"
fi

if [[ "$is_monorepo" == "true" ]]; then
    context+="## Project Type: MONOREPO ($monorepo_type)\n"
    [[ -d "$PROJECT_DIR/packages" ]] && context+="Packages: $(ls "$PROJECT_DIR/packages" 2>/dev/null | tr '\n' ' ')\n"
    [[ -d "$PROJECT_DIR/apps" ]] && context+="Apps: $(ls "$PROJECT_DIR/apps" 2>/dev/null | tr '\n' ' ')\n"
    context+="\n"
fi

# =============================================================================
# Node.js Framework Detection
# =============================================================================
if [[ -f "$PROJECT_DIR/package.json" ]]; then
    pkg="$PROJECT_DIR/package.json"
    all_deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$pkg" 2>/dev/null || true)

    frameworks=""
    state_mgmt=""
    db_layer=""
    styling=""
    testing=""

    # Frontend Frameworks
    if echo "$all_deps" | grep -q "^next$"; then
        frameworks+="Next.js"
        [[ -d "$PROJECT_DIR/app" ]] && frameworks+=" (App Router)"
        [[ -d "$PROJECT_DIR/pages" && ! -d "$PROJECT_DIR/app" ]] && frameworks+=" (Pages Router)"
        frameworks+=" "
    fi
    echo "$all_deps" | grep -q "^@remix-run/" && frameworks+="Remix "
    echo "$all_deps" | grep -q "^nuxt$" && frameworks+="Nuxt "
    echo "$all_deps" | grep -q "^astro$" && frameworks+="Astro "
    echo "$all_deps" | grep -q "^svelte$\|^@sveltejs/kit$" && frameworks+="SvelteKit "
    echo "$all_deps" | grep -q "^vue$" && frameworks+="Vue "

    # Plain React detection
    if echo "$all_deps" | grep -q "^react$" && [[ -z "$frameworks" ]]; then
        echo "$all_deps" | grep -q "^vite$" && frameworks+="React+Vite "
        echo "$all_deps" | grep -q "^react-scripts$" && frameworks+="CRA "
        [[ -z "$frameworks" ]] && frameworks+="React "
    fi

    # Backend
    echo "$all_deps" | grep -q "^express$" && frameworks+="Express "
    echo "$all_deps" | grep -q "^fastify$" && frameworks+="Fastify "
    echo "$all_deps" | grep -q "^hono$" && frameworks+="Hono "
    echo "$all_deps" | grep -q "^@nestjs/core$" && frameworks+="NestJS "
    echo "$all_deps" | grep -q "^elysia$" && frameworks+="Elysia "

    # State Management
    echo "$all_deps" | grep -q "^zustand$" && state_mgmt+="Zustand "
    echo "$all_deps" | grep -q "^@reduxjs/toolkit$\|^redux$" && state_mgmt+="Redux "
    echo "$all_deps" | grep -q "^jotai$" && state_mgmt+="Jotai "
    echo "$all_deps" | grep -q "^@tanstack/react-query$" && state_mgmt+="TanStack Query "
    echo "$all_deps" | grep -q "^swr$" && state_mgmt+="SWR "

    # Database/ORM
    echo "$all_deps" | grep -q "^prisma$\|^@prisma/client$" && db_layer+="Prisma "
    echo "$all_deps" | grep -q "^drizzle-orm$" && db_layer+="Drizzle "
    echo "$all_deps" | grep -q "^typeorm$" && db_layer+="TypeORM "
    echo "$all_deps" | grep -q "^kysely$" && db_layer+="Kysely "
    echo "$all_deps" | grep -q "^mongoose$" && db_layer+="Mongoose "
    echo "$all_deps" | grep -q "^@supabase/supabase-js$" && db_layer+="Supabase "

    # Styling
    echo "$all_deps" | grep -q "^tailwindcss$" && styling+="Tailwind "
    echo "$all_deps" | grep -q "^styled-components$" && styling+="styled-components "
    echo "$all_deps" | grep -q "^@emotion/react$" && styling+="Emotion "
    echo "$all_deps" | grep -q "^sass$" && styling+="Sass "

    # Testing
    echo "$all_deps" | grep -q "^vitest$" && testing+="Vitest "
    echo "$all_deps" | grep -q "^jest$" && testing+="Jest "
    echo "$all_deps" | grep -q "^@testing-library/react$" && testing+="RTL "
    echo "$all_deps" | grep -q "^playwright$\|^@playwright/test$" && testing+="Playwright "
    echo "$all_deps" | grep -q "^cypress$" && testing+="Cypress "

    # Output detected stack (with optimization-aware detail level)
    if [[ "$OPTIMIZATION_MODE" == "aggressive" ]]; then
        # Compact mode: Only show primary framework
        [[ -n "$frameworks" ]] && context+="## Stack: $frameworks\n"
    else
        # Full mode: Show all categories
        [[ -n "$frameworks" ]] && context+="## Frameworks: $frameworks\n"
        [[ -n "$state_mgmt" ]] && context+="## State: $state_mgmt\n"
        [[ -n "$db_layer" ]] && context+="## Database: $db_layer\n"
        [[ -n "$styling" ]] && context+="## Styling: $styling\n"
        [[ -n "$testing" ]] && context+="## Testing: $testing\n"
    fi

    # Package manager
    pkg_mgr="npm"
    [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]] && pkg_mgr="pnpm"
    [[ -f "$PROJECT_DIR/yarn.lock" ]] && pkg_mgr="yarn"
    [[ -f "$PROJECT_DIR/bun.lockb" ]] && pkg_mgr="bun"
    context+="## Package Manager: $pkg_mgr\n"

    # Extract actual scripts (limit based on optimization mode)
    if [[ "$OPTIMIZATION_MODE" != "aggressive" ]]; then
        context+="\n## Scripts:\n"
        jq -r '.scripts | to_entries[] | "  \(.key): \(.value)"' "$pkg" 2>/dev/null | head -12
        context+="$(jq -r '.scripts | to_entries[] | "  \(.key): \(.value)"' "$pkg" 2>/dev/null | head -12)\n"
    fi

    # Recommended commands
    context+="\n## Commands:\n"
    jq -e '.scripts.dev' "$pkg" >/dev/null 2>&1 && context+="  Dev: $pkg_mgr run dev\n"
    jq -e '.scripts.build' "$pkg" >/dev/null 2>&1 && context+="  Build: $pkg_mgr run build\n"
    jq -e '.scripts.test' "$pkg" >/dev/null 2>&1 && context+="  Test: $pkg_mgr run test\n"
    jq -e '.scripts.lint' "$pkg" >/dev/null 2>&1 && context+="  Lint: $pkg_mgr run lint\n"
    jq -e '.scripts.typecheck // .scripts["type-check"]' "$pkg" >/dev/null 2>&1 && context+="  Types: $pkg_mgr run typecheck\n"
    context+="\n"
fi

# =============================================================================
# Go Projects
# =============================================================================
if [[ -f "$PROJECT_DIR/go.mod" ]]; then
    go_module=$(head -1 "$PROJECT_DIR/go.mod" | sed 's/module //')
    context+="## Go Module: $go_module\n"

    go_deps=$(cat "$PROJECT_DIR/go.mod" 2>/dev/null || true)
    go_fw=""
    echo "$go_deps" | grep -q "gin-gonic/gin" && go_fw+="Gin "
    echo "$go_deps" | grep -q "gofiber/fiber" && go_fw+="Fiber "
    echo "$go_deps" | grep -q "labstack/echo" && go_fw+="Echo "
    echo "$go_deps" | grep -q "go-chi/chi" && go_fw+="Chi "
    [[ -n "$go_fw" ]] && context+="Frameworks: $go_fw\n"

    context+="## Commands: go build ./... | go test ./... | go run .\n\n"
fi

# =============================================================================
# Rust Projects
# =============================================================================
if [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    crate=$(grep -m1 '^name' "$PROJECT_DIR/Cargo.toml" | sed 's/.*"\(.*\)".*/\1/' || echo "unknown")
    context+="## Rust Crate: $crate\n"

    rust_deps=$(cat "$PROJECT_DIR/Cargo.toml" 2>/dev/null || true)
    rust_fw=""
    echo "$rust_deps" | grep -q "actix-web" && rust_fw+="Actix "
    echo "$rust_deps" | grep -q "axum" && rust_fw+="Axum "
    echo "$rust_deps" | grep -q "rocket" && rust_fw+="Rocket "
    [[ -n "$rust_fw" ]] && context+="Frameworks: $rust_fw\n"

    context+="## Commands: cargo build | cargo test | cargo run\n\n"
fi

# =============================================================================
# Python Projects
# =============================================================================
if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    context+="## Python Project\n"

    py_deps=$(cat "$PROJECT_DIR/pyproject.toml" 2>/dev/null || true)
    py_fw=""
    echo "$py_deps" | grep -qi "fastapi" && py_fw+="FastAPI "
    echo "$py_deps" | grep -qi "django" && py_fw+="Django "
    echo "$py_deps" | grep -qi "flask" && py_fw+="Flask "
    [[ -n "$py_fw" ]] && context+="Frameworks: $py_fw\n"

    # Package manager
    [[ -f "$PROJECT_DIR/poetry.lock" ]] && context+="Package Manager: Poetry\n"
    [[ -f "$PROJECT_DIR/uv.lock" ]] && context+="Package Manager: uv\n"
    [[ -f "$PROJECT_DIR/Pipfile.lock" ]] && context+="Package Manager: Pipenv\n"

    context+="## Commands: pytest | ruff check . | mypy .\n\n"
fi

# =============================================================================
# Infrastructure
# =============================================================================
infra=""
[[ -f "$PROJECT_DIR/docker-compose.yml" ]] || [[ -f "$PROJECT_DIR/docker-compose.yaml" ]] && infra+="Docker "
[[ -d "$PROJECT_DIR/cdk" ]] && infra+="CDK "
[[ -d "$PROJECT_DIR/terraform" ]] || [[ -f "$PROJECT_DIR/main.tf" ]] && infra+="Terraform "
[[ -d "$PROJECT_DIR/.github/workflows" ]] && infra+="GitHub Actions "
[[ -f "$PROJECT_DIR/vercel.json" ]] && infra+="Vercel "
[[ -f "$PROJECT_DIR/fly.toml" ]] && infra+="Fly.io "
[[ -n "$infra" ]] && context+="## Infrastructure: $infra\n\n"

# =============================================================================
# Environment Variables
# =============================================================================
if [[ -f "$PROJECT_DIR/.env.example" ]]; then
    env_vars=$(grep -E "^[A-Z_]+=" "$PROJECT_DIR/.env.example" 2>/dev/null | cut -d= -f1 | head -10 | tr '\n' ' ')
    context+="## Env Vars: $env_vars\n\n"
fi

# =============================================================================
# Key Directories
# =============================================================================
context+="## Directories: "
for dir in src app pages lib components api server routes models services utils hooks tests e2e; do
    [[ -d "$PROJECT_DIR/$dir" ]] && context+="$dir "
done
context+="\n"

# =============================================================================
# README (brief)
# =============================================================================
if [[ -f "$PROJECT_DIR/README.md" ]]; then
    readme_line=$(grep -m1 "^[A-Za-z]" "$PROJECT_DIR/README.md" 2>/dev/null | head -c 200 || true)
    [[ -n "$readme_line" ]] && context+="\n## About: $readme_line\n"
fi

# Output and cache
if [[ -n "$context" ]]; then
    output="Repository Context:\n$context"

    # Cache the output
    if [[ "$CACHE_TTL" -gt 0 ]]; then
        echo -e "$output" > "$CACHE_FILE"

        # Cleanup old cache files (keep last 10)
        ls -t "$CACHE_DIR"/scan-* 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi

    # Display output
    echo -e "$output"
fi

exit 0
