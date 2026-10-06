---
name: deps-upgrade
description: Safely upgrade project dependencies with breaking change detection and migration assistance. Use when updating packages, addressing security vulnerabilities, or modernizing dependencies.
allowed-tools: Bash(npm:*), Bash(npx:*), Bash(yarn:*), Bash(pnpm:*), Bash(go:*), Bash(pip:*), Read, Grep, Glob, Edit, Write, WebSearch
context-files:
  - ~/.config/agent-config/rules/security.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Dependency Upgrade Assistant

Safely upgrade dependencies with breaking change detection, migration guides, and automated fixes.

## Objective
- Identify outdated dependencies and security vulnerabilities
- Assess breaking changes before upgrading
- Generate migration code for major version upgrades
- Validate upgrades don't break existing functionality
- Provide rollback strategies

## Hard Rules
1. NEVER upgrade without checking for breaking changes first
2. ALWAYS run tests after each upgrade batch
3. ALWAYS preserve lock file integrity
4. NEVER upgrade multiple major versions at once
5. ALWAYS document significant upgrades in changelog

## Upgrade Workflow

### Phase 1: Dependency Analysis

```bash
# Node.js
npm outdated
npm audit

# Go
go list -u -m all
govulncheck ./...

# Python
pip list --outdated
pip-audit
```

### Phase 2: Risk Assessment

Categorize each update:

| Category | Risk Level | Strategy |
|----------|------------|----------|
| Patch (1.0.0 → 1.0.1) | Low | Batch upgrade |
| Minor (1.0.0 → 1.1.0) | Medium | Test after upgrade |
| Major (1.0.0 → 2.0.0) | High | Individual upgrade + migration |
| Security fix | Critical | Immediate upgrade |

### Phase 3: Breaking Change Detection

For major upgrades:
1. Fetch release notes and changelogs
2. Identify breaking changes
3. Search codebase for affected patterns
4. Generate migration checklist

### Phase 4: Staged Upgrade

```bash
# Upgrade in stages
# 1. Security patches (immediate)
# 2. Patch versions (batch)
# 3. Minor versions (batch with testing)
# 4. Major versions (one at a time)
```

### Phase 5: Validation

After each upgrade batch:
- Run full test suite
- Check TypeScript compilation
- Run linting
- Verify build succeeds
- Test critical paths manually

## Output Format

### Dependency Upgrade Report

```
═══════════════════════════════════════════════════════════════
                  Dependency Upgrade Report
═══════════════════════════════════════════════════════════════

Project: my-app
Package Manager: npm
Total Dependencies: 147 (89 direct, 58 dev)
Last Updated: 45 days ago

───────────────────────────────────────────────────────────────
🚨 SECURITY VULNERABILITIES (3)
───────────────────────────────────────────────────────────────

[CRITICAL] lodash < 4.17.21
  CVE: CVE-2021-23337
  Severity: Critical (CVSS 9.8)
  Current: 4.17.15
  Fixed: 4.17.21
  Breaking: No
  Action: npm update lodash

[HIGH] axios < 1.6.0
  CVE: CVE-2023-45857
  Severity: High (CVSS 7.5)
  Current: 0.27.2
  Fixed: 1.6.0
  Breaking: Yes (major version)
  Action: See migration guide below

[MODERATE] semver < 7.5.2
  CVE: CVE-2022-25883
  Severity: Moderate (CVSS 5.3)
  Current: 7.3.8
  Fixed: 7.5.2
  Breaking: No
  Action: npm update semver

───────────────────────────────────────────────────────────────
📦 OUTDATED DEPENDENCIES
───────────────────────────────────────────────────────────────

MAJOR UPDATES (5) - Require migration
┌─────────────────────────────────────────────────────────────┐
│ Package          │ Current  │ Latest   │ Breaking Changes  │
├─────────────────────────────────────────────────────────────┤
│ react            │ 17.0.2   │ 19.0.0   │ Yes (see below)   │
│ @tanstack/query  │ 4.36.1   │ 5.17.0   │ Yes (see below)   │
│ axios            │ 0.27.2   │ 1.6.5    │ Yes (see below)   │
│ typescript       │ 4.9.5    │ 5.3.3    │ Minor             │
│ eslint           │ 8.56.0   │ 9.0.0    │ Yes (config)      │
└─────────────────────────────────────────────────────────────┘

MINOR UPDATES (12) - Generally safe
┌─────────────────────────────────────────────────────────────┐
│ Package          │ Current  │ Latest   │ Notes             │
├─────────────────────────────────────────────────────────────┤
│ @types/node      │ 20.10.0  │ 20.11.5  │ Type improvements │
│ tailwindcss      │ 3.3.0    │ 3.4.1    │ New utilities     │
│ zod              │ 3.22.0   │ 3.22.4   │ Bug fixes         │
│ ... (9 more)     │          │          │                   │
└─────────────────────────────────────────────────────────────┘

PATCH UPDATES (23) - Safe to batch
  Run: npm update

───────────────────────────────────────────────────────────────
📋 MIGRATION GUIDES
───────────────────────────────────────────────────────────────

### React 17 → 19 Migration

Breaking Changes:
1. New JSX Transform (already supported in 17)
2. Strict Mode behaviors
3. Removed legacy context API
4. New hooks API changes

Affected Files (scan results):
  - src/contexts/AuthContext.tsx (legacy context)
  - src/components/ClassComponent.tsx (class component)

Migration Steps:
1. ✓ Already using new JSX transform
2. □ Update legacy context to new Context API
3. □ Convert class components to functions
4. □ Update to new use() hook patterns

Estimated Effort: 2-4 hours

### TanStack Query 4 → 5 Migration

Breaking Changes:
1. useQuery signature changed
2. Removed callbacks from useQuery
3. New suspense support

Affected Files (23 matches):
  - src/hooks/useUsers.ts
  - src/hooks/useProducts.ts
  - ... (21 more)

Auto-fixable: 18/23 files

Codemod available:
  npx @tanstack/query-codemods v5/remove-callbacks ./src

Manual fixes needed:
  - src/hooks/useAuth.ts (complex onSuccess logic)
  - src/hooks/useUpload.ts (onError with retry logic)

Estimated Effort: 1-2 hours

### Axios 0.x → 1.x Migration

Breaking Changes:
1. TypeScript types restructured
2. Response type inference changed
3. Error handling modified

Affected Files (15 matches):
  - src/api/client.ts
  - src/api/auth.ts
  - ... (13 more)

Migration Steps:
1. □ Update import types
2. □ Fix response type access (.data vs direct)
3. □ Update error type guards

Estimated Effort: 1 hour

───────────────────────────────────────────────────────────────
🎯 RECOMMENDED UPGRADE PATH
───────────────────────────────────────────────────────────────

Step 1: Security patches (immediate)
  npm update lodash semver
  npm install axios@1.6.5
  Time: 30 minutes

Step 2: Patch updates (batch)
  npm update
  Time: 10 minutes + test run

Step 3: Minor updates
  npm install tailwindcss@3.4.1 zod@3.22.4 ...
  Time: 20 minutes + test run

Step 4: TypeScript 5
  npm install typescript@5.3.3
  npx tsc --noEmit  # Verify compilation
  Time: 30 minutes

Step 5: TanStack Query 5
  npm install @tanstack/react-query@5
  npx @tanstack/query-codemods v5/remove-callbacks ./src
  # Manual fixes for 5 files
  Time: 2 hours

Step 6: React 19 (optional - significant effort)
  # Plan for dedicated sprint
  Time: 4-8 hours

───────────────────────────────────────────────────────────────
⚙️ GENERATED COMMANDS
───────────────────────────────────────────────────────────────

# Security fixes (run now)
npm update lodash semver && npm install axios@1.6.5

# Safe batch update
npm update

# Individual major updates (run separately)
npm install typescript@5.3.3
npm install @tanstack/react-query@5.17.0

# Verify after each
npm run typecheck && npm test && npm run build

═══════════════════════════════════════════════════════════════
                         Summary
═══════════════════════════════════════════════════════════════

Security Issues: 3 (1 critical, 1 high, 1 moderate)
Major Updates Available: 5
Minor Updates Available: 12
Patch Updates Available: 23

Recommended Action: Address security vulnerabilities immediately
Total Upgrade Effort: ~8 hours (excluding React 19)
```

## Rollback Strategy

For each upgrade, document rollback:

```bash
# Before upgrade
cp package-lock.json package-lock.json.backup

# If upgrade fails
git checkout package.json package-lock.json
npm ci
```

## Automated Fixes

Generate codemods for common migrations:

```javascript
// Example: axios 0.x → 1.x response access
// Before: response.data.users
// After: response.data.users (unchanged, but types fixed)

export default function transformer(file, api) {
  const j = api.jscodeshift;
  return j(file.source)
    .find(j.ImportDeclaration, { source: { value: 'axios' } })
    .forEach(path => {
      // Transform logic
    })
    .toSource();
}
```

## Required Inputs
- Project root directory
- Target packages (optional, defaults to all)

## Constraints
- Maximum 50 dependencies analyzed in detail per run
- Fetch changelogs only for major updates
- Cache dependency metadata for 24 hours
