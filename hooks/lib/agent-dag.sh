#!/usr/bin/env bash
# =============================================================================
# Agent DAG (Directed Acyclic Graph) Library - Phase 3.2
# =============================================================================
# Purpose: Define and execute agent workflows with dependencies
# Features:
#   - Conditional agent spawning based on previous results
#   - Dependency resolution
#   - Parallel execution where possible
#   - Result sharing between agents
# =============================================================================

source "${HOME}/.claude/hooks/lib/agent-memory.sh" 2>/dev/null || true
source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

DAG_CACHE_DIR="${HOME}/.claude/cache/agent-dag"
mkdir -p "$DAG_CACHE_DIR"

# =============================================================================
# Define Agent Node
# =============================================================================
agent_dag_define_node() {
    local node_id="$1"
    local agent_type="$2"
    local condition="${3:-always}"  # always | if_previous_found:pattern | if_previous_success
    local dependencies="${4:-}"     # comma-separated list of node_ids

    local dag_file="$DAG_CACHE_DIR/current_dag.json"

    # Initialize DAG file if doesn't exist
    [[ ! -f "$dag_file" ]] && echo '{"nodes":[]}' > "$dag_file"

    # Add node to DAG
    jq --arg id "$node_id" \
       --arg agent "$agent_type" \
       --arg condition "$condition" \
       --arg deps "$dependencies" \
       '.nodes += [{
           id: $id,
           agent: $agent,
           condition: $condition,
           dependencies: ($deps | split(",") | map(select(length > 0))),
           status: "pending"
       }]' "$dag_file" > "${dag_file}.tmp" && mv "${dag_file}.tmp" "$dag_file"
}

# =============================================================================
# Check if node condition is met
# =============================================================================
agent_dag_check_condition() {
    local condition="$1"
    local previous_results="$2"

    case "$condition" in
        always)
            return 0
            ;;
        if_previous_success)
            # Check if previous agent succeeded (not empty result)
            [[ -n "$previous_results" ]]
            ;;
        if_previous_found:*)
            # Check if previous result contains pattern
            local pattern="${condition#if_previous_found:}"
            echo "$previous_results" | grep -iq "$pattern"
            ;;
        *)
            hook_warning "Unknown condition: $condition, defaulting to 'always'"
            return 0
            ;;
    esac
}

# =============================================================================
# Get nodes ready to execute (dependencies satisfied)
# =============================================================================
agent_dag_get_ready_nodes() {
    local dag_file="$DAG_CACHE_DIR/current_dag.json"

    [[ ! -f "$dag_file" ]] && return 1

    # Find nodes that are:
    # 1. Status = pending
    # 2. All dependencies are completed
    jq -r '.nodes[] |
        select(.status == "pending") |
        select(
            (.dependencies | length) == 0 or
            all(.dependencies[]; . as $dep |
                any($ARGS.positional[]; .nodes[] | select(.id == $dep and .status == "completed"))
            )
        ) |
        .id' --args "$dag_file" "$dag_file" 2>/dev/null || true
}

# =============================================================================
# Mark node as completed
# =============================================================================
agent_dag_mark_completed() {
    local node_id="$1"
    local result="$2"
    local dag_file="$DAG_CACHE_DIR/current_dag.json"

    [[ ! -f "$dag_file" ]] && return 1

    # Update node status
    jq --arg id "$node_id" \
       --arg result "$result" \
       '(.nodes[] | select(.id == $id) | .status) = "completed" |
        (.nodes[] | select(.id == $id) | .result) = $result' \
       "$dag_file" > "${dag_file}.tmp" && mv "${dag_file}.tmp" "$dag_file"

    # Store in agent memory for sharing
    local agent_type=$(jq -r --arg id "$node_id" '.nodes[] | select(.id == $id) | .agent' "$dag_file")
    agent_memory_store "$agent_type" "$result"
}

# =============================================================================
# Execute DAG workflow
# =============================================================================
agent_dag_execute() {
    local prompt="$1"
    local dag_file="$DAG_CACHE_DIR/current_dag.json"

    [[ ! -f "$dag_file" ]] && hook_error "No DAG defined" && return 1

    hook_info "🔄 Executing agent workflow with $(jq '.nodes | length' "$dag_file") nodes..."

    local max_iterations=20
    local iteration=0

    while [[ $iteration -lt $max_iterations ]]; do
        ((iteration++))

        # Get ready nodes
        local ready_nodes=$(agent_dag_get_ready_nodes)

        # Exit if no ready nodes
        [[ -z "$ready_nodes" ]] && break

        # Execute ready nodes in parallel
        while IFS= read -r node_id; do
            [[ -z "$node_id" ]] && continue

            local agent_type=$(jq -r --arg id "$node_id" '.nodes[] | select(.id == $id) | .agent' "$dag_file")
            local condition=$(jq -r --arg id "$node_id" '.nodes[] | select(.id == $id) | .condition' "$dag_file")

            # Get previous results
            local previous_results=$(agent_memory_retrieve)

            # Check condition
            if agent_dag_check_condition "$condition" "$previous_results"; then
                hook_info "  → Spawning $agent_type (node: $node_id)"

                # In real implementation, this would spawn the agent via Task tool
                # For now, mark as completed with placeholder result
                local result="Agent $agent_type completed for: $prompt"
                agent_dag_mark_completed "$node_id" "$result"
            else
                hook_info "  ⊘ Skipping $agent_type (condition not met)"
                agent_dag_mark_completed "$node_id" "skipped"
            fi
        done <<< "$ready_nodes"

    done

    # Check if all nodes completed
    local pending_count=$(jq '[.nodes[] | select(.status == "pending")] | length' "$dag_file")

    if [[ $pending_count -eq 0 ]]; then
        hook_success "✅ Workflow completed successfully"
    else
        hook_warning "⚠️  $pending_count nodes still pending (possible circular dependency)"
    fi
}

# =============================================================================
# Clear current DAG
# =============================================================================
agent_dag_clear() {
    rm -f "$DAG_CACHE_DIR/current_dag.json" 2>/dev/null || true
}

# =============================================================================
# Predefined DAG Templates
# =============================================================================

# Security Audit Workflow
agent_dag_template_security_audit() {
    local prompt="$1"

    agent_dag_clear
    agent_dag_define_node "security-scan" "security-auditor" "always" ""
    agent_dag_define_node "db-security" "db-specialist" "if_previous_found:database" "security-scan"
    agent_dag_define_node "infra-hardening" "infra-specialist" "if_previous_found:infrastructure" "security-scan"

    agent_dag_execute "$prompt"
}

# Feature Development Workflow
agent_dag_template_feature_dev() {
    local prompt="$1"

    agent_dag_clear
    agent_dag_define_node "design-review" "code-reviewer" "always" ""
    agent_dag_define_node "api-design" "api-specialist" "if_previous_found:api" "design-review"
    agent_dag_define_node "security-check" "security-auditor" "always" "design-review,api-design"
    agent_dag_define_node "frontend-review" "frontend-reviewer" "if_previous_found:react" "security-check"

    agent_dag_execute "$prompt"
}

# Database Migration Workflow
agent_dag_template_db_migration() {
    local prompt="$1"

    agent_dag_clear
    agent_dag_define_node "schema-design" "db-specialist" "always" ""
    agent_dag_define_node "migration-review" "code-reviewer" "always" "schema-design"
    agent_dag_define_node "security-audit" "security-auditor" "always" "migration-review"

    agent_dag_execute "$prompt"
}
