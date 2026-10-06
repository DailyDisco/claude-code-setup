#!/usr/bin/env bash
# =============================================================================
# Auto-Optimizer Library - Phase 3.5
# =============================================================================
# Purpose: AI-assisted optimization recommendations and self-tuning
# Features:
#   - Analyze hook metrics and suggest configuration changes
#   - Auto-tune cache TTLs based on usage patterns
#   - Detect and recommend agent spawn threshold adjustments
#   - Generate performance reports with actionable recommendations
# =============================================================================

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true
source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

METRICS_FILE="${HOME}/.claude/hook-metrics.jsonl"
OPTIMIZER_CACHE="${HOME}/.claude/cache/auto-optimizer"
mkdir -p "$OPTIMIZER_CACHE"

# =============================================================================
# Analyze and Recommend Configuration Changes
# =============================================================================
auto_optimize_analyze() {
    local report=""

    report+="╔══════════════════════════════════════════════════════╗\n"
    report+="║      Auto-Optimizer Analysis Report                 ║\n"
    report+="╚══════════════════════════════════════════════════════╝\n\n"

    # 1. Cache TTL Analysis
    report+="$(analyze_cache_ttl)\n\n"

    # 2. Agent Spawn Analysis
    report+="$(analyze_agent_spawns)\n\n"

    # 3. Hook Performance Analysis
    report+="$(analyze_hook_performance)\n\n"

    # 4. Context Optimization Analysis
    report+="$(analyze_context_usage)\n\n"

    # 5. Generate Recommendations
    report+="$(generate_recommendations)\n"

    echo -e "$report"
}

# =============================================================================
# Cache TTL Analysis
# =============================================================================
analyze_cache_ttl() {
    local cache_dir="${HOME}/.claude/cache"
    echo "📦 Cache TTL Analysis"
    echo "─────────────────────────────────────────────"

    # Check repo-scan cache hit rate
    local repo_scan_cache="${cache_dir}/repo-scan"
    if [[ -d "$repo_scan_cache" ]]; then
        local cached_files=$(find "$repo_scan_cache" -type f 2>/dev/null | wc -l)
        local stale_files=$(find "$repo_scan_cache" -type f -mmin +5 2>/dev/null | wc -l)
        local fresh_files=$((cached_files - stale_files))

        echo "  repo-scan: $cached_files cached entries, $fresh_files fresh, $stale_files stale"

        if [[ $stale_files -gt $((cached_files / 2)) ]]; then
            echo "  ⚡ Recommendation: Increase CLAUDE_CACHE_TTL (many stale entries)"
        fi
    fi

    # Check context-injector cache
    local ctx_cache="${cache_dir}/context-injector"
    if [[ -d "$ctx_cache" ]]; then
        local ctx_files=$(find "$ctx_cache" -type f 2>/dev/null | wc -l)
        echo "  context-injector: $ctx_files cached entries"

        if [[ $ctx_files -gt 30 ]]; then
            echo "  🧹 Recommendation: Clean old entries (>30 cached)"
        fi
    fi
}

# =============================================================================
# Agent Spawn Analysis
# =============================================================================
analyze_agent_spawns() {
    echo "🤖 Agent Spawn Analysis"
    echo "─────────────────────────────────────────────"

    local agent_memory="${HOME}/.claude/cache/agent-memory"
    if [[ -d "$agent_memory" ]]; then
        local total_invocations=$(find "$agent_memory" -name "*.json" -type f 2>/dev/null | wc -l)
        echo "  Total agent invocations: $total_invocations"

        # Count by agent type
        find "$agent_memory" -name "*.json" -type f 2>/dev/null | \
            while read -r f; do basename "$f" | cut -d: -f2; done | \
            sort | uniq -c | sort -rn | head -5 | \
            while read -r count agent; do
                echo "  - $agent: $count invocations"
            done

        if [[ $total_invocations -eq 0 ]]; then
            echo "  💡 No agents have been auto-spawned yet."
            echo "     Consider: export CLAUDE_SPAWN_MEDIUM_CONFIDENCE=true"
        fi
    else
        echo "  No agent memory data found"
    fi
}

# =============================================================================
# Hook Performance Analysis
# =============================================================================
analyze_hook_performance() {
    echo "⚡ Hook Performance Analysis"
    echo "─────────────────────────────────────────────"

    [[ ! -f "$METRICS_FILE" ]] && echo "  No metrics available" && return

    # Get average duration per hook (last 500 entries)
    tail -500 "$METRICS_FILE" | jq -r '.hook' 2>/dev/null | sort -u | while read -r hook; do
        [[ -z "$hook" ]] && continue

        local avg=$(tail -500 "$METRICS_FILE" | \
            jq -r --arg h "$hook" 'select(.hook == $h) | .duration_ms' 2>/dev/null | \
            awk '{sum+=$1; n++} END {if(n>0) printf "%.0f", sum/n}')

        local count=$(tail -500 "$METRICS_FILE" | \
            jq -r --arg h "$hook" 'select(.hook == $h)' 2>/dev/null | wc -l)

        [[ -z "$avg" ]] && continue

        local status="✅"
        [[ ${avg:-0} -gt 100 ]] && status="⚠️"
        [[ ${avg:-0} -gt 500 ]] && status="🔴"

        printf "  %s %-35s avg: %4sms  (n=%d)\n" "$status" "$hook" "$avg" "$count"
    done

    # Check failure rate
    local total=$(tail -500 "$METRICS_FILE" | wc -l)
    local failures=$(tail -500 "$METRICS_FILE" | jq -r 'select(.result == "failure")' 2>/dev/null | wc -l)

    if [[ $total -gt 0 ]]; then
        local fail_rate=$(( (failures * 100) / total ))
        echo ""
        echo "  Overall failure rate: ${fail_rate}% ($failures/$total)"
    fi
}

# =============================================================================
# Context Usage Analysis
# =============================================================================
analyze_context_usage() {
    echo "📊 Context Optimization Status"
    echo "─────────────────────────────────────────────"

    local output_mode="${CLAUDE_OUTPUT_MODE:-minimal}"
    local optimization="${CLAUDE_CONTEXT_OPTIMIZATION:-balanced}"
    local repo_detail="${CLAUDE_REPO_SCAN_DETAIL:-auto}"

    echo "  Output Mode:     $output_mode"
    echo "  Optimization:    $optimization"
    echo "  Repo Scan Detail: $repo_detail"

    # Calculate estimated context savings
    local savings=0
    case "$output_mode" in
        minimal) savings=$((savings + 30)) ;;
        silent)  savings=$((savings + 50)) ;;
    esac
    case "$optimization" in
        aggressive)   savings=$((savings + 30)) ;;
        balanced)     savings=$((savings + 15)) ;;
    esac

    echo ""
    echo "  Estimated context savings: ~${savings}%"

    if [[ $savings -lt 30 ]]; then
        echo "  💡 Tip: Set CLAUDE_OUTPUT_MODE=minimal for more savings"
    fi
}

# =============================================================================
# Generate Actionable Recommendations
# =============================================================================
generate_recommendations() {
    echo "💡 Recommendations"
    echo "─────────────────────────────────────────────"

    local rec_count=0
    local recs=()

    # Check if output filtering is enabled
    if [[ "${CLAUDE_OUTPUT_MODE:-}" != "minimal" ]] && [[ "${CLAUDE_OUTPUT_MODE:-}" != "silent" ]]; then
        recs+=("Set CLAUDE_OUTPUT_MODE=minimal for 30-50% context reduction")
    fi

    # Check if context optimization is enabled
    if [[ "${CLAUDE_CONTEXT_OPTIMIZATION:-}" == "conservative" ]] || [[ -z "${CLAUDE_CONTEXT_OPTIMIZATION:-}" ]]; then
        recs+=("Set CLAUDE_CONTEXT_OPTIMIZATION=balanced for smarter filtering")
    fi

    # Check cache settings
    if [[ "${CLAUDE_CACHE_TTL:-300}" -lt 120 ]]; then
        recs+=("Increase CLAUDE_CACHE_TTL to 300+ for better cache hit rates")
    fi

    # Check agent settings
    if [[ "${CLAUDE_AUTO_SPAWN_AGENTS:-true}" == "false" ]]; then
        recs+=("Enable CLAUDE_AUTO_SPAWN_AGENTS=true for automatic specialist routing")
    fi

    # Check health monitor
    if [[ "${CLAUDE_HEALTH_CHECK_ENABLED:-false}" == "false" ]]; then
        recs+=("Enable CLAUDE_HEALTH_CHECK_ENABLED=true for proactive monitoring")
    fi

    # Check metrics file size
    if [[ -f "$METRICS_FILE" ]]; then
        local size=$(stat -c%s "$METRICS_FILE" 2>/dev/null || echo 0)
        if [[ $size -gt $((5 * 1024 * 1024)) ]]; then
            recs+=("Metrics file is large ($(( size / 1024 / 1024 ))MB). Consider manual rotation.")
        fi
    fi

    if [[ ${#recs[@]} -eq 0 ]]; then
        echo "  ✅ Configuration is optimal! No changes recommended."
    else
        for rec in "${recs[@]}"; do
            ((rec_count++))
            echo "  $rec_count. $rec"
        done
    fi
}

# =============================================================================
# Auto-Tune (apply recommendations automatically)
# =============================================================================
auto_tune() {
    local dry_run="${1:-true}"  # Default to dry-run

    echo "🔧 Auto-Tune ${dry_run:+(DRY RUN)}"
    echo "─────────────────────────────────────────────"

    source "${HOME}/.claude/hooks/lib/agent-memory.sh" 2>/dev/null || true

    # Optimal defaults
    local optimal_output_mode="minimal"
    local optimal_optimization="balanced"
    local optimal_cache_ttl="300"
    local optimal_max_agents="2"

    if [[ "$dry_run" == "false" ]]; then
        user_pref_set "CLAUDE_OUTPUT_MODE" "$optimal_output_mode"
        user_pref_set "CLAUDE_CONTEXT_OPTIMIZATION" "$optimal_optimization"
        user_pref_set "CLAUDE_CACHE_TTL" "$optimal_cache_ttl"
        user_pref_set "CLAUDE_MAX_AUTO_AGENTS" "$optimal_max_agents"
        echo "  ✅ Applied optimal configuration to user preferences"
    else
        echo "  Would set:"
        echo "    CLAUDE_OUTPUT_MODE=$optimal_output_mode"
        echo "    CLAUDE_CONTEXT_OPTIMIZATION=$optimal_optimization"
        echo "    CLAUDE_CACHE_TTL=$optimal_cache_ttl"
        echo "    CLAUDE_MAX_AUTO_AGENTS=$optimal_max_agents"
        echo ""
        echo "  Run with dry_run=false to apply"
    fi
}

# =============================================================================
# System Health Score (0-100)
# =============================================================================
get_health_score() {
    local score=100

    # Deduct for failures
    if [[ -f "$METRICS_FILE" ]]; then
        local failures=$(tail -100 "$METRICS_FILE" | jq -r 'select(.result == "failure")' 2>/dev/null | wc -l)
        score=$((score - failures * 5))
    fi

    # Deduct for large cache
    local cache_size=$(du -sb "${HOME}/.claude/cache" 2>/dev/null | cut -f1)
    if [[ ${cache_size:-0} -gt $((100 * 1024 * 1024)) ]]; then
        score=$((score - 10))
    fi

    # Deduct for missing optimization
    [[ "${CLAUDE_OUTPUT_MODE:-}" != "minimal" ]] && [[ "${CLAUDE_OUTPUT_MODE:-}" != "silent" ]] && score=$((score - 5))
    [[ "${CLAUDE_CONTEXT_OPTIMIZATION:-}" == "conservative" ]] && score=$((score - 5))

    # Ensure score stays in range
    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100

    echo "$score"
}

# =============================================================================
# Quick Status Check
# =============================================================================
quick_status() {
    local score=$(get_health_score)

    local grade="A+"
    [[ $score -lt 95 ]] && grade="A"
    [[ $score -lt 85 ]] && grade="B"
    [[ $score -lt 70 ]] && grade="C"
    [[ $score -lt 50 ]] && grade="D"
    [[ $score -lt 30 ]] && grade="F"

    echo "System Health: $score/100 (Grade: $grade)"
}

# =============================================================================
# Main
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-analyze}" in
        analyze)     auto_optimize_analyze ;;
        tune)        auto_tune "${2:-true}" ;;
        score)       quick_status ;;
        *)
            echo "Usage: $0 [analyze|tune|score]"
            echo "  analyze - Full analysis report"
            echo "  tune    - Auto-tune configuration (dry run by default)"
            echo "  score   - Quick health score"
            ;;
    esac
fi
