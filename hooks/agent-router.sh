#!/bin/bash
# Agent Router Hook
# Event: UserPromptSubmit
# Purpose: Route to specialized agents based on prompt content and file patterns
# Emits structured JSON hints for automatic agent spawning

set -euo pipefail

# Get user prompt from environment
prompt="${CLAUDE_USER_PROMPT:-}"

# Skip if no prompt
[[ -z "$prompt" ]] && exit 0

# Convert to lowercase for matching
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# Track agents and their confidence (high/medium/low)
declare -A agent_confidence
suggestions=()

# ============================================
# Database Specialist Patterns
# ============================================
if [[ "$prompt_lower" =~ (migration|schema|database|table|column|index|query|sql|postgres|mysql|sqlite|orm|prisma|drizzle|gorm|sequelize) ]]; then
    # High confidence if explicit DB keywords
    if [[ "$prompt_lower" =~ (migration|schema\ design|query\ optimiz|database\ architect) ]]; then
        agent_confidence["db-specialist"]="high"
    else
        agent_confidence["db-specialist"]="medium"
    fi
    suggestions+=("db-specialist: Schema design, migrations, query optimization")
fi

# ============================================
# Security Auditor Patterns
# ============================================
if [[ "$prompt_lower" =~ (security|vulnerab|auth|authentication|authorization|owasp|injection|xss|csrf|penetration|audit|credentials|secrets|encrypt|token|jwt|oauth|permission|access\ control|sanitiz) ]]; then
    if [[ "$prompt_lower" =~ (security.*audit|vulnerabilit|owasp|penetration) ]]; then
        agent_confidence["security-auditor"]="high"
    else
        agent_confidence["security-auditor"]="medium"
    fi
    suggestions+=("security-auditor: Vulnerability assessment, auth review, OWASP checks")
fi

# ============================================
# Infrastructure Specialist Patterns
# ============================================
if [[ "$prompt_lower" =~ (terraform|docker|kubernetes|k8s|helm|aws|gcp|azure|cloud|infrastructure|deploy|ci/cd|pipeline|nginx|load\ balanc|container|pod|service\ mesh|istio|ecs|eks|fargate) ]]; then
    if [[ "$prompt_lower" =~ (terraform|kubernetes|k8s|infrastructure.*as.*code|deploy.*pipeline) ]]; then
        agent_confidence["infra-specialist"]="high"
    else
        agent_confidence["infra-specialist"]="medium"
    fi
    suggestions+=("infra-specialist: IaC, cloud architecture, CI/CD pipelines")
fi

# ============================================
# Frontend Reviewer Patterns
# ============================================
if [[ "$prompt_lower" =~ (react|component|accessibility|a11y|aria|wcag|ui|ux|css|tailwind|styled|bundle|webpack|vite|performance|lighthouse|core\ web\ vitals|responsive|animation|hooks|state\ management|redux|zustand|context) ]]; then
    if [[ "$prompt_lower" =~ (accessibility|a11y|wcag|component.*architect|react.*pattern) ]]; then
        agent_confidence["frontend-reviewer"]="high"
    else
        agent_confidence["frontend-reviewer"]="medium"
    fi
    suggestions+=("frontend-reviewer: React patterns, accessibility, performance")
fi

# ============================================
# Code Reviewer Patterns
# ============================================
if [[ "$prompt_lower" =~ (review|code.*review|pr.*review|pull.*request|best.*practice|clean.*code|refactor.*review) ]]; then
    if [[ "$prompt_lower" =~ (review.*pr|review.*code|code.*review) ]]; then
        agent_confidence["code-reviewer"]="high"
    else
        agent_confidence["code-reviewer"]="medium"
    fi
    suggestions+=("code-reviewer: Comprehensive code review, best practices")
fi

# ============================================
# API Specialist Patterns
# ============================================
if [[ "$prompt_lower" =~ (api.*design|rest.*api|graphql|grpc|openapi|swagger|endpoint.*design|api.*contract|api.*version) ]]; then
    if [[ "$prompt_lower" =~ (api.*design|openapi|graphql.*schema) ]]; then
        agent_confidence["api-specialist"]="high"
    else
        agent_confidence["api-specialist"]="medium"
    fi
    suggestions+=("api-specialist: API design, OpenAPI, integration patterns")
fi

# ============================================
# File-based routing (boost confidence based on files)
# ============================================
check_file_patterns() {
    # Check for file patterns in the prompt and boost confidence
    if [[ "$prompt_lower" =~ (\.sql|migration|schema\.prisma|schema\.ts) ]]; then
        [[ -z "${agent_confidence[db-specialist]:-}" ]] && agent_confidence["db-specialist"]="low"
    fi

    if [[ "$prompt_lower" =~ (dockerfile|\.tf|kubernetes|\.ya?ml.*deploy|helm) ]]; then
        [[ -z "${agent_confidence[infra-specialist]:-}" ]] && agent_confidence["infra-specialist"]="low"
    fi

    if [[ "$prompt_lower" =~ (auth\.|security\.|\.env|credentials) ]]; then
        [[ -z "${agent_confidence[security-auditor]:-}" ]] && agent_confidence["security-auditor"]="low"
    fi

    if [[ "$prompt_lower" =~ (\.tsx|\.jsx|component|\.css|\.scss) ]]; then
        [[ -z "${agent_confidence[frontend-reviewer]:-}" ]] && agent_confidence["frontend-reviewer"]="low"
    fi
}

check_file_patterns

# ============================================
# Output - structured JSON for high confidence, suggestions for others
# ============================================
high_confidence_agents=()
other_agents=()

for agent in "${!agent_confidence[@]}"; do
    if [[ "${agent_confidence[$agent]}" == "high" ]]; then
        high_confidence_agents+=("$agent")
    else
        other_agents+=("$agent")
    fi
done

# Emit structured hint for high-confidence agents (Claude can auto-spawn these)
if [[ ${#high_confidence_agents[@]} -gt 0 ]]; then
    echo ""
    echo "Recommended agents (high confidence):"
    for agent in "${high_confidence_agents[@]}"; do
        echo "  → **$agent** - spawn with Task tool for parallel analysis"
    done
fi

# Show suggestions for medium/low confidence
if [[ ${#other_agents[@]} -gt 0 ]]; then
    echo ""
    echo "Available specialists:"
    for suggestion in "${suggestions[@]}"; do
        # Only show if not high confidence
        agent_name=$(echo "$suggestion" | cut -d: -f1)
        if [[ ! " ${high_confidence_agents[*]} " =~ " $agent_name " ]]; then
            echo "  - $suggestion"
        fi
    done
fi

# Hint for parallel spawning when multiple high-confidence agents
if [[ ${#high_confidence_agents[@]} -gt 1 ]]; then
    echo ""
    echo "Multiple specialists relevant - consider spawning in parallel."
fi

# ============================================
# Phase 2.0: Enhanced Auto-Spawn Logic
# ============================================
# Auto-spawn agents if enabled
AUTO_SPAWN="${CLAUDE_AUTO_SPAWN_AGENTS:-true}"
MAX_AGENTS="${CLAUDE_MAX_AUTO_AGENTS:-2}"
SPAWN_MEDIUM_CONFIDENCE="${CLAUDE_SPAWN_MEDIUM_CONFIDENCE:-false}"  # Phase 2.0: opt-in

# Determine which agents to spawn
agents_to_spawn=()

# Always include high-confidence
for agent in "${high_confidence_agents[@]}"; do
    agents_to_spawn+=("$agent")
done

# Phase 2.0: Optionally include medium-confidence
if [[ "$SPAWN_MEDIUM_CONFIDENCE" == "true" ]]; then
    for agent in "${other_agents[@]}"; do
        # Only add if confidence is medium (not low)
        if [[ "${agent_confidence[$agent]}" == "medium" ]]; then
            agents_to_spawn+=("$agent")
        fi
    done
fi

if [[ "$AUTO_SPAWN" == "true" ]] && [[ ${#agents_to_spawn[@]} -gt 0 ]]; then
    # Limit to MAX_AGENTS for safety (prevent token explosions)
    num_to_spawn=${#agents_to_spawn[@]}
    if [[ $num_to_spawn -gt $MAX_AGENTS ]]; then
        num_to_spawn=$MAX_AGENTS
    fi

    # Determine message based on confidence level
    if [[ ${#high_confidence_agents[@]} -gt 0 ]]; then
        confidence_msg="High-confidence match detected"
    else
        confidence_msg="Medium-confidence match detected"
    fi

    echo ""
    echo "🤖 AUTO-SPAWN DIRECTIVE:"
    echo "   $confidence_msg. Spawning ${num_to_spawn} agent(s) in parallel..."
    echo ""

    # Emit Task tool invocation directives
    count=0
    for agent in "${agents_to_spawn[@]}"; do
        [[ $count -ge $MAX_AGENTS ]] && break

        case "$agent" in
            "db-specialist")
                echo "SPAWN: Task(subagent_type='db-specialist', model='opus', prompt='Analyze database design, schema safety, migration strategy, and query optimization for: $prompt')"
                ;;
            "security-auditor")
                echo "SPAWN: Task(subagent_type='security-auditor', model='opus', prompt='Perform security assessment covering OWASP Top 10, authentication, authorization, input validation, and data protection for: $prompt')"
                ;;
            "frontend-reviewer")
                echo "SPAWN: Task(subagent_type='frontend-reviewer', model='opus', prompt='Review React architecture, component patterns, accessibility (WCAG 2.1), and Core Web Vitals optimization for: $prompt')"
                ;;
            "infra-specialist")
                echo "SPAWN: Task(subagent_type='infra-specialist', model='opus', prompt='Analyze infrastructure as code, containerization, cloud architecture, and deployment strategy for: $prompt')"
                ;;
            "code-reviewer")
                echo "SPAWN: Task(subagent_type='code-reviewer', prompt='Comprehensive code quality review covering architecture, design patterns, test coverage, and maintainability for: $prompt')"
                ;;
            "api-specialist")
                echo "SPAWN: Task(subagent_type='api-specialist', prompt='Review API design, contracts, REST/GraphQL patterns, versioning, and integration documentation for: $prompt')"
                ;;
        esac

        ((count++))
    done

    echo ""
    echo "DIRECTIVE: Please spawn these agents IN PARALLEL using a single message with multiple Task tool calls."
    echo "After agents complete, synthesize findings into a unified recommendation."
    echo ""
    echo "To disable auto-spawn: export CLAUDE_AUTO_SPAWN_AGENTS=false"
    echo ""
fi

exit 0
