#!/bin/bash
# =============================================================================
# Workflow Suggester Hook
# =============================================================================
# Event: UserPromptSubmit
# Purpose: Detect common multi-agent workflow patterns and suggest orchestration
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

prompt="${1:-}"

[[ -z "$prompt" ]] && exit 0

# =============================================================================
# Feature Development Workflow
# =============================================================================
if echo "$prompt" | grep -iE "(implement|build|create|add).+(feature|functionality|capability)" >/dev/null 2>&1; then
    hook_info "📋 Multi-step feature workflow detected. Recommended sequence:"
    hook_info "   1. /prd-gen → Generate PRD with requirements"
    hook_info "   2. @code-reviewer + @api-specialist → Design review (parallel)"
    hook_info "   3. Implementation → Your code changes"
    hook_info "   4. @security-auditor + @frontend-reviewer → Quality check (parallel)"
    hook_info "   5. /test-gen → Generate comprehensive tests"
    hook_info ""
    hook_info "Run with: /workflow feature-development"
fi

# =============================================================================
# Security Audit Workflow
# =============================================================================
if echo "$prompt" | grep -iE "security|audit|vulnerability|penetration|owasp|cve" >/dev/null 2>&1; then
    hook_info "🔒 Comprehensive security audit workflow:"
    hook_info "   1. @security-auditor → OWASP Top 10 assessment"
    hook_info "   2. @db-specialist → Database security review (if DB involved)"
    hook_info "   3. @infra-specialist → Infrastructure hardening review"
    hook_info ""
    hook_info "💡 All agents can run in parallel for fastest results."
fi

# =============================================================================
# Database Design/Migration Workflow
# =============================================================================
if echo "$prompt" | grep -iE "(database|schema|migration).+(design|create|modify|change|alter)" >/dev/null 2>&1; then
    hook_info "🗄️  Database workflow recommended:"
    hook_info "   1. @db-specialist → Schema design + migration strategy"
    hook_info "   2. @code-reviewer → Review migration safety"
    hook_info "   3. @security-auditor → Check for SQL injection vectors"
    hook_info "   4. /migration-planner → Generate rollback plan"
fi

# =============================================================================
# Performance Optimization Workflow
# =============================================================================
if echo "$prompt" | grep -iE "(optimize|performance|slow|speed|latency|bottleneck)" >/dev/null 2>&1; then
    hook_info "⚡ Performance optimization workflow:"
    hook_info "   1. /perf-profiler → Profile and identify bottlenecks"
    hook_info "   2. @frontend-reviewer → Frontend optimization (if UI)"
    hook_info "   3. @db-specialist → Query optimization (if DB)"
    hook_info "   4. @code-reviewer → Algorithm review"
fi

# =============================================================================
# API Design Workflow
# =============================================================================
if echo "$prompt" | grep -iE "(api|endpoint|rest|graphql).+(design|create|build)" >/dev/null 2>&1; then
    hook_info "🔌 API design workflow:"
    hook_info "   1. /api-design → OpenAPI-first design"
    hook_info "   2. @api-specialist + @security-auditor → Review contract & auth"
    hook_info "   3. /types-gen → Generate TypeScript types"
    hook_info "   4. Implementation → Your code"
fi

exit 0
