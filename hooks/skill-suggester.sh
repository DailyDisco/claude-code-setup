#!/bin/bash
# Skill Suggester Hook
# Event: UserPromptSubmit
# Purpose: Suggest relevant skills based on user prompt patterns and context

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

# Get user prompt from environment
prompt="${CLAUDE_USER_PROMPT:-}"

# Skip if no prompt
[[ -z "$prompt" ]] && exit 0

# Convert to lowercase for matching
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
METRICS_FILE="${HOME}/.claude/skill-metrics.jsonl"

suggestions=()
suggestion_priorities=()

# =============================================================================
# Context-Aware Detection
# =============================================================================

# Detect project type for context-aware suggestions
has_package_json=false
has_go_mod=false
has_pyproject=false
has_prisma=false
has_openapi=false

[[ -f "$PROJECT_DIR/package.json" ]] && has_package_json=true
[[ -f "$PROJECT_DIR/go.mod" ]] && has_go_mod=true
[[ -f "$PROJECT_DIR/pyproject.toml" ]] && has_pyproject=true
[[ -f "$PROJECT_DIR/prisma/schema.prisma" ]] && has_prisma=true
[[ -f "$PROJECT_DIR/openapi.yaml" || -f "$PROJECT_DIR/openapi.json" || -f "$PROJECT_DIR/swagger.yaml" ]] && has_openapi=true

# Check recent skill usage to avoid re-suggesting
recent_skills=""
if [[ -f "$METRICS_FILE" ]]; then
    recent_skills=$(tail -20 "$METRICS_FILE" 2>/dev/null | jq -r '.skill // empty' 2>/dev/null | sort -u | tr '\n' ' ' || true)
fi

# Helper to add suggestion with priority
add_suggestion() {
    local priority="$1"
    local msg="$2"
    local skill="$3"

    # Skip if recently used
    if [[ "$recent_skills" == *"$skill"* ]]; then
        return
    fi

    suggestions+=("$msg")
    suggestion_priorities+=("$priority")
}

# =============================================================================
# Pattern-Based Suggestions (with priority: high, medium, low)
# =============================================================================

# Debug/Bug patterns
if [[ "$prompt_lower" =~ (bug|error|broken|not\ working|crash|fail|exception|issue|problem|fix) ]]; then
    add_suggestion "high" "Consider using /debug for systematic root cause analysis" "debug"
fi

# PR/Review patterns
if [[ "$prompt_lower" =~ (review|pr|pull\ request|merge|code\ review) ]]; then
    add_suggestion "high" "Use /review-pr for comprehensive code review" "review-pr"
fi

# Feature/New patterns
if [[ "$prompt_lower" =~ (feature|implement|add|create|build|new) ]] && \
   [[ ! "$prompt_lower" =~ (just\ code|skip\ prd|no\ prd) ]]; then
    add_suggestion "medium" "Use /workflow feature for end-to-end feature development" "workflow"
fi

# Test patterns
if [[ "$prompt_lower" =~ (test|coverage|spec|unit\ test|integration\ test) ]]; then
    add_suggestion "high" "Use /test-gen to generate comprehensive tests" "test-gen"
fi

# Commit patterns
if [[ "$prompt_lower" =~ (commit|staged|git\ add|commit\ message) ]]; then
    add_suggestion "high" "Use /commit for branch name and commit message generation" "commit"
fi

# Refactor patterns
if [[ "$prompt_lower" =~ (refactor|restructure|reorganize|clean\ up|improve) ]]; then
    add_suggestion "high" "Use /refactor for safe refactoring with test verification" "refactor"
fi

# Performance patterns
if [[ "$prompt_lower" =~ (slow|performance|optimize|speed|latency|profil) ]]; then
    add_suggestion "high" "Use /perf-profiler for performance analysis" "perf-profiler"
    add_suggestion "medium" "Use /full-stack-optimizer for comprehensive optimization audit" "full-stack-optimizer"
fi

# Documentation patterns
if [[ "$prompt_lower" =~ (document|readme|doc|explain|onboard) ]]; then
    add_suggestion "medium" "Use /doc-gen or /onboard for documentation generation" "doc-gen"
fi

# Release patterns
if [[ "$prompt_lower" =~ (release|version|changelog|deploy|ship) ]]; then
    add_suggestion "high" "Use /release for changelog and version management" "release"
fi

# API patterns
if [[ "$prompt_lower" =~ (api|endpoint|route|openapi|swagger|rest) ]]; then
    add_suggestion "high" "Use /api-design for OpenAPI-first API design" "api-design"
    if [[ "$has_openapi" == "true" ]]; then
        add_suggestion "medium" "Use /types-gen to generate types from your OpenAPI spec" "types-gen"
    fi
fi

# Database/Migration patterns
if [[ "$prompt_lower" =~ (migration|schema|database|table|column) ]]; then
    add_suggestion "high" "Use /migration-planner for safe database migrations" "migration-planner"
    if [[ "$has_prisma" == "true" ]] || [[ "$prompt_lower" =~ (schema|validate|audit) ]]; then
        add_suggestion "medium" "Use /schema-audit to audit database schema health" "schema-audit"
    fi
fi

# Jira patterns
if [[ "$prompt_lower" =~ (jira|ticket|issue|sprint|story|task) ]]; then
    add_suggestion "high" "Use /jira-sync to sync with Jira" "jira-sync"
fi

# GitHub patterns
if [[ "$prompt_lower" =~ (github|pr|pull\ request|merge) ]]; then
    add_suggestion "high" "Use /github-pr for GitHub PR workflow" "github-pr"
fi

# =============================================================================
# NEW: Additional Context-Aware Suggestions
# =============================================================================

# Type generation patterns
if [[ "$prompt_lower" =~ (types|typescript|interface|generate.*types|type.*safe) ]]; then
    add_suggestion "high" "Use /types-gen to generate types from schemas" "types-gen"
fi

# Component patterns (React projects)
if [[ "$has_package_json" == "true" ]] && [[ "$prompt_lower" =~ (component|duplicate|consolidate|design.*system|ui.*library) ]]; then
    add_suggestion "medium" "Use /component-audit to find duplicate and inconsistent components" "component-audit"
fi

# Dependency patterns
if [[ "$prompt_lower" =~ (upgrade|update|outdated|dependenc|vulnerabilit|npm.*audit|security.*patch) ]]; then
    add_suggestion "high" "Use /deps-upgrade for safe dependency updates with migration guides" "deps-upgrade"
fi

# Log analysis patterns
if [[ "$prompt_lower" =~ (log|error.*rate|debug.*production|incident|outage|investigate) ]]; then
    add_suggestion "high" "Use /log-analyze to analyze logs for patterns and issues" "log-analyze"
    if [[ "$prompt_lower" =~ (incident|outage|down) ]]; then
        add_suggestion "high" "Use /incident for incident response workflow" "incident"
    fi
fi

# Accessibility patterns
if [[ "$prompt_lower" =~ (accessibility|a11y|wcag|screen.*reader|keyboard.*nav) ]]; then
    add_suggestion "high" "Use /a11y-audit for accessibility compliance checking" "a11y-audit"
fi

# Bundle/Performance patterns (frontend)
if [[ "$has_package_json" == "true" ]] && [[ "$prompt_lower" =~ (bundle|chunk|tree.*shak|lazy.*load|code.*split) ]]; then
    add_suggestion "high" "Use /bundle-analyze for bundle size optimization" "bundle-analyze"
fi

# Diagram patterns
if [[ "$prompt_lower" =~ (diagram|architecture|visualize|flowchart|mermaid) ]]; then
    add_suggestion "medium" "Use /diagram to generate architecture diagrams" "diagram"
fi

# Estimation patterns
if [[ "$prompt_lower" =~ (estimate|how.*long|effort|complexity|sprint.*plan) ]]; then
    add_suggestion "medium" "Use /estimate for complexity-based effort estimation" "estimate"
fi

# i18n patterns
if [[ "$prompt_lower" =~ (i18n|internationalization|translation|localization|multi.*language) ]]; then
    add_suggestion "high" "Use /i18n for internationalization support" "i18n"
fi

# PRD patterns
if [[ "$prompt_lower" =~ (prd|product.*requirement|spec|feature.*spec) ]]; then
    add_suggestion "high" "Use /prd-gen for implementation-ready PRDs" "prd-gen"
fi

# Health/Cleanup patterns
if [[ "$prompt_lower" =~ (cleanup|clean.*up|disk.*space|storage|health.*check|audit.*config) ]]; then
    add_suggestion "high" "Use /health to audit and clean ~/.claude configuration" "health"
fi

# =============================================================================
# Project-Specific Skills (React + Go Starter Kit patterns)
# =============================================================================

# Check if project has custom skills
has_project_skills=false
[[ -d "$PROJECT_DIR/.claude/skills" ]] && has_project_skills=true

# Full-stack feature scaffolding (React + Go projects)
if [[ "$has_go_mod" == "true" ]] && [[ "$has_package_json" == "true" ]]; then
    if [[ "$prompt_lower" =~ (add|create|implement|build).*(feature|functionality|capability) ]]; then
        add_suggestion "high" "Use /scaffold-feature for full-stack feature scaffolding (Go service + React hooks)" "scaffold-feature"
    fi

    # Go service scaffolding
    if [[ "$prompt_lower" =~ (add|create).*(service|backend|api.*service|handler) ]]; then
        add_suggestion "high" "Use /scaffold-service to generate Go service with handlers and tests" "scaffold-service"
    fi

    # Type sync between Go and TypeScript
    if [[ "$prompt_lower" =~ (sync|update|align|mismatch).*(types?|models?|typescript|frontend|go) ]]; then
        add_suggestion "high" "Use /sync-models to sync Go models to TypeScript types" "sync-models"
    fi
fi

# Database migration (Go projects with GORM or any project with migrations directory)
if [[ "$has_go_mod" == "true" ]] || [[ -d "$PROJECT_DIR/backend/migrations" ]] || [[ -d "$PROJECT_DIR/migrations" ]]; then
    if [[ "$prompt_lower" =~ (add|create|new).*(migration|table|column|index|constraint) ]]; then
        add_suggestion "high" "Use /add-migration to generate SQL migration files" "add-migration"
    fi
fi

# Environment validation (any project)
if [[ "$prompt_lower" =~ (check|verify|validate|setup|config).*(env|environment|docker|container|setup) ]]; then
    add_suggestion "medium" "Use /env-check to validate environment setup and Docker containers" "env-check"
fi

# API debugging/testing
if [[ "$prompt_lower" =~ (debug|test|curl|try).*(api|endpoint|request|route) ]] && \
   [[ ! "$prompt_lower" =~ (unit|integration|spec) ]]; then
    add_suggestion "medium" "Use /debug-api to generate curl commands for API testing" "debug-api"
fi

# =============================================================================
# Tag-Based Skill Discovery (for "help skills", "list skills", "what skills")
# =============================================================================

if [[ "$prompt_lower" =~ (help.*skill|list.*skill|what.*skill|show.*skill|available.*skill) ]]; then
    echo ""
    echo "📚 Available Skills by Category:"
    echo ""
    echo "**Workflow:**"
    echo "  /commit, /review-pr, /debug, /refactor, /workflow, /release"
    echo ""
    echo "**Code Quality:**"
    echo "  /test-gen, /types-gen, /schema-audit, /component-audit, /a11y-audit"
    echo ""
    echo "**Analysis:**"
    echo "  /full-stack-optimizer, /perf-profiler, /deps-upgrade, /log-analyze, /bundle-analyze"
    echo ""
    echo "**Documentation:**"
    echo "  /doc-gen, /api-design, /prd-gen, /diagram, /onboard"
    echo ""
    echo "**Project Setup:**"
    echo "  /init-project, /stack-typescript, /stack-react, /stack-nextjs, /stack-go, /stack-python"
    echo ""
    echo "**Integration:**"
    echo "  /jira-sync, /github-pr, /incident, /i18n"
    echo ""
    echo "**Maintenance:**"
    echo "  /health"
    echo ""
    if [[ "$has_go_mod" == "true" ]] && [[ "$has_package_json" == "true" ]]; then
        echo "**React + Go Project Skills:**"
        echo "  /scaffold-feature, /scaffold-service, /add-migration, /sync-models, /env-check, /debug-api"
        echo ""
    fi
    echo "Use /skill-name to invoke. Example: /commit"
    exit 0
fi

# =============================================================================
# Output suggestions (sorted by priority, max 3)
# =============================================================================

if [[ ${#suggestions[@]} -gt 0 ]]; then
    echo ""
    echo "💡 Skill suggestions:"

    # Output high priority first, then medium, limit to 3 total
    count=0
    max_suggestions=3

    # High priority
    for i in "${!suggestions[@]}"; do
        if [[ "${suggestion_priorities[$i]}" == "high" ]] && [[ $count -lt $max_suggestions ]]; then
            echo "  → ${suggestions[$i]}"
            ((++count))
        fi
    done

    # Medium priority (if room)
    for i in "${!suggestions[@]}"; do
        if [[ "${suggestion_priorities[$i]}" == "medium" ]] && [[ $count -lt $max_suggestions ]]; then
            echo "  → ${suggestions[$i]}"
            ((++count))
        fi
    done

    # Low priority (if room)
    for i in "${!suggestions[@]}"; do
        if [[ "${suggestion_priorities[$i]}" == "low" ]] && [[ $count -lt $max_suggestions ]]; then
            echo "  → ${suggestions[$i]}"
            ((++count))
        fi
    done
fi

exit 0
