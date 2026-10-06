#!/usr/bin/env bash
# =============================================================================
# Custom Agent Loader - Phase 3.4
# =============================================================================
# Purpose: Load and manage user-defined custom agents
# Features:
#   - YAML-based agent definitions
#   - Auto-discovery from ~/.claude/agents/custom/
#   - Dynamic registration with agent-router
#   - Template-based agent creation
# =============================================================================

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

CUSTOM_AGENTS_DIR="${HOME}/.claude/agents/custom"
mkdir -p "$CUSTOM_AGENTS_DIR"

# =============================================================================
# Discover Custom Agents
# =============================================================================
discover_custom_agents() {
    local agents=()

    if [[ -d "$CUSTOM_AGENTS_DIR" ]]; then
        while IFS= read -r agent_file; do
            [[ -z "$agent_file" ]] && continue
            local agent_name=$(basename "$agent_file" .yaml)
            agents+=("$agent_name")
        done < <(find "$CUSTOM_AGENTS_DIR" -name "*.yaml" -type f 2>/dev/null)
    fi

    printf '%s\n' "${agents[@]}"
}

# =============================================================================
# Load Custom Agent Definition
# =============================================================================
load_custom_agent() {
    local agent_name="$1"
    local agent_file="$CUSTOM_AGENTS_DIR/${agent_name}.yaml"

    [[ ! -f "$agent_file" ]] && hook_error "Agent definition not found: $agent_name" && return 1

    # In production, would use yq or python to parse YAML
    # For now, simple grep-based parsing
    local model=$(grep "^model:" "$agent_file" | sed 's/model: *//')
    local expertise=$(grep "^expertise:" "$agent_file" -A 10 | grep "^  -" | sed 's/^  - *//' | tr '\n' '|')

    echo "$agent_name|$model|$expertise"
}

# =============================================================================
# Check if Agent Matches Prompt
# =============================================================================
custom_agent_matches_prompt() {
    local agent_name="$1"
    local prompt="$2"

    local agent_def=$(load_custom_agent "$agent_name" 2>/dev/null || echo "")
    [[ -z "$agent_def" ]] && return 1

    local expertise=$(echo "$agent_def" | cut -d'|' -f3)

    # Convert prompt to lowercase
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    # Check if any expertise keyword matches
    IFS='|' read -ra keywords <<< "$expertise"
    for keyword in "${keywords[@]}"; do
        [[ -z "$keyword" ]] && continue
        if echo "$prompt_lower" | grep -iq "$keyword"; then
            return 0
        fi
    done

    return 1
}

# =============================================================================
# Get Matching Custom Agents
# =============================================================================
get_matching_custom_agents() {
    local prompt="$1"

    local matching_agents=()

    while IFS= read -r agent_name; do
        [[ -z "$agent_name" ]] && continue
        if custom_agent_matches_prompt "$agent_name" "$prompt"; then
            matching_agents+=("$agent_name")
        fi
    done < <(discover_custom_agents)

    printf '%s\n' "${matching_agents[@]}"
}

# =============================================================================
# Create Custom Agent Template
# =============================================================================
create_agent_template() {
    local agent_name="$1"
    local template_file="$CUSTOM_AGENTS_DIR/${agent_name}.yaml"

    [[ -f "$template_file" ]] && hook_warning "Agent already exists: $agent_name" && return 1

    cat > "$template_file" <<'EOF'
# Custom Agent Definition
name: AGENT_NAME
model: sonnet  # sonnet | opus | haiku
description: |
  Brief description of what this agent specializes in

# Areas of expertise (used for keyword matching)
expertise:
  - keyword1
  - keyword2
  - keyword3

# High-confidence keywords (always trigger)
keywords_high:
  - specific phrase
  - exact match term

# Medium-confidence keywords
keywords_medium:
  - general term
  - related concept

# System prompt for this agent
system_prompt: |
  You are a specialized agent for [DOMAIN].
  Your expertise includes:
  - Area 1
  - Area 2
  - Area 3

  When analyzing code or providing recommendations:
  1. First principle
  2. Second principle
  3. Third principle

# Tools this agent can use (optional)
tools:
  - Read
  - Grep
  - Bash

# Maximum context length for this agent
max_context: 100000

# Examples of prompts this agent handles well
examples:
  - "Example prompt 1"
  - "Example prompt 2"
  - "Example prompt 3"
EOF

    sed -i "s/AGENT_NAME/$agent_name/" "$template_file"

    hook_success "✅ Created agent template: $template_file"
    hook_info "Edit the file to customize your agent"
}

# =============================================================================
# Validate Custom Agent
# =============================================================================
validate_custom_agent() {
    local agent_name="$1"
    local agent_file="$CUSTOM_AGENTS_DIR/${agent_name}.yaml"

    [[ ! -f "$agent_file" ]] && hook_error "Agent not found: $agent_name" && return 1

    # Check required fields
    local has_name=$(grep -q "^name:" "$agent_file" && echo "yes" || echo "no")
    local has_model=$(grep -q "^model:" "$agent_file" && echo "yes" || echo "no")
    local has_expertise=$(grep -q "^expertise:" "$agent_file" && echo "yes" || echo "no")

    if [[ "$has_name" == "yes" ]] && [[ "$has_model" == "yes" ]] && [[ "$has_expertise" == "yes" ]]; then
        hook_success "✅ Agent definition is valid: $agent_name"
        return 0
    else
        hook_error "❌ Agent definition is invalid (missing required fields)"
        [[ "$has_name" == "no" ]] && hook_error "  - Missing: name"
        [[ "$has_model" == "no" ]] && hook_error "  - Missing: model"
        [[ "$has_expertise" == "no" ]] && hook_error "  - Missing: expertise"
        return 1
    fi
}

# =============================================================================
# List All Custom Agents
# =============================================================================
list_custom_agents() {
    hook_info "Custom Agents:"

    local count=0
    while IFS= read -r agent_name; do
        [[ -z "$agent_name" ]] && continue
        ((count++))

        local agent_def=$(load_custom_agent "$agent_name" 2>/dev/null || echo "||")
        local model=$(echo "$agent_def" | cut -d'|' -f2)
        local expertise=$(echo "$agent_def" | cut -d'|' -f3 | tr '|' ',' | head -c 50)

        echo "  $count. $agent_name (model: $model)"
        echo "     Expertise: $expertise..."
    done < <(discover_custom_agents)

    [[ $count -eq 0 ]] && hook_info "  (none)"
}
