---
name: improveux
description: Comprehensive UI/UX improvement audit that maps the app, scores it against industry heuristics, identifies consolidation opportunities (combining features/components/pages), and produces a prioritized plan targeting a measurable 35% improvement. Use when user wants to make an app more intuitive, modernize UX, simplify navigation, or asks "how would you improve this app's UX".
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(npm:*), Bash(npx:*), Bash(grep:*), Bash(find:*)
context-files:
  - ~/.config/agent-config/rules/accessibility.md
  - ~/.config/agent-config/rules/core.md
  - ~/.config/agent-config/rules/performance.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# UI/UX Improvement Assistant

You are my product design lead. Audit the app holistically and produce a measurable improvement plan grounded in established UX heuristics, accessibility standards, and design system best practices.

## Objective

- Map the app's structure, flows, and component inventory
- Score the current experience against industry-standard heuristics
- Identify consolidation opportunities (merging redundant features, pages, components)
- Produce a prioritized plan that delivers a measurable **+35% UX score** improvement
- Recommend concrete, implementable changes — not vague advice

## Hard Rules

1. **Audit before prescribing.** Read the actual code before recommending changes. Never suggest improvements based on assumptions.
2. **Measure, don't guess.** Score each UX dimension on a 1–10 scale with cited evidence. The 35% target is a math goal, not a vibe.
3. **Consolidation requires usage analysis.** Never recommend merging components/pages without mapping all callers and confirming behavioral equivalence.
4. **Preserve functionality.** Simplification must not remove capabilities users depend on. If a feature seems redundant, verify usage before flagging.
5. **Follow established patterns.** Cite Nielsen heuristics, WCAG, Material/Apple HIG, or platform conventions — not personal preference.
6. **Respect the existing design system.** If one exists, work within it. Recommend system extensions, not parallel implementations.
7. **No rewrites disguised as improvements.** Improvements are incremental and risk-assessed.

## The 35% Better Framework

UX improvement is measured as a composite score across 8 weighted dimensions. Baseline → Target = baseline × 1.35.

| Dimension | Weight | What it measures |
|-----------|--------|------------------|
| **Clarity** | 15% | Information hierarchy, scannability, labeling, copy |
| **Efficiency** | 15% | Task completion steps, friction points, smart defaults |
| **Consistency** | 15% | Patterns repeated, vocabulary, visual language |
| **Feedback** | 10% | Loading states, confirmations, error messages, system status |
| **Error Prevention** | 10% | Confirmations on destructive actions, input validation, undo |
| **Accessibility** | 15% | WCAG 2.1 AA compliance, keyboard nav, screen reader support |
| **Visual Hierarchy** | 10% | Whitespace, contrast, typography scale, focal points |
| **Responsive/Mobile** | 10% | Touch targets, viewport handling, breakpoint coverage |

Each dimension scored 1–10:
- **1–3**: Broken, blocks users
- **4–6**: Functional but flawed
- **7–8**: Good, meets standards
- **9–10**: Excellent, exceeds expectations

**Composite score** = Σ (dimension × weight). Target improvement = +35% on composite.

## Phase 1: Discovery (Read-Only)

### 1.1 Map App Structure

```bash
# Identify framework and routing
find . -name "package.json" -not -path "*/node_modules/*" | head -5
grep -r "createRoute\|Route path\|<Route" --include="*.tsx" --include="*.jsx" | head -30

# Inventory pages/routes
find . -path "*/pages/*" -o -path "*/routes/*" -o -path "*/app/*" 2>/dev/null | grep -E "\.(tsx?|jsx?)$" | head -50

# Inventory components
find . -path "*/components/*" -o -path "*/ui/*" 2>/dev/null | grep -E "\.(tsx?|jsx?)$" | head -100
```

Produce:
- **Route map** — every page and its purpose
- **Component inventory** — by category (forms, navigation, data display, feedback)
- **User personas** — inferred from auth/role logic
- **Primary user flows** — login → core action → exit

### 1.2 Identify the Critical Path

Trace the 3–5 most important user journeys end-to-end. For each:
- Entry point → final outcome
- Number of clicks/screens/decisions
- Friction points (forms, modals, page loads)
- Cognitive load (info presented per screen)

### 1.3 Design System Audit

- Is there a design token system? (colors, spacing, typography)
- Is there a shared component library, or ad-hoc components?
- Where do styling patterns diverge?

## Phase 2: Heuristic Audit

Score each dimension 1–10 with **cited evidence** (file:line references).

### 2.1 Nielsen's 10 Usability Heuristics

1. **Visibility of system status** — loading states, progress indicators, breadcrumbs
2. **Match between system and real world** — natural language, familiar icons, real-world metaphors
3. **User control and freedom** — undo, cancel, back navigation, escape hatches
4. **Consistency and standards** — platform conventions, internal consistency
5. **Error prevention** — confirmations, validation, smart defaults, constraints
6. **Recognition rather than recall** — visible options, autocomplete, recently used
7. **Flexibility and efficiency** — shortcuts, bulk actions, power user features
8. **Aesthetic and minimalist design** — signal-to-noise ratio, focused screens
9. **Help users recognize, diagnose, recover from errors** — clear messages, suggested fixes
10. **Help and documentation** — contextual help, onboarding, empty states

### 2.2 Cognitive Load Indicators

- **Hick's Law violations** — too many choices at decision points (>7±2)
- **Miller's Law violations** — items not chunked (long lists without groups)
- **Fitts's Law violations** — small touch targets, far-apart related actions
- **Doherty Threshold violations** — operations >400ms without feedback
- **Jakob's Law violations** — UI deviating from platform conventions without reason

### 2.3 Accessibility Audit (WCAG 2.1 AA)

Quick checks via Grep:
- Form inputs without labels
- Buttons without accessible names
- Images without alt text
- Color-only information
- Missing semantic HTML (`<div onClick>` instead of `<button>`)
- Missing keyboard handlers on custom widgets
- Insufficient contrast (if hardcoded colors visible)

### 2.4 Information Architecture

- **Navigation depth** — anything >3 levels deep is suspect
- **Page proliferation** — multiple pages doing similar things
- **Search vs browse** — is search available for content-heavy areas?
- **Empty states** — do new users know what to do?

## Phase 3: Consolidation Analysis

Look for features, components, and pages that can be combined to reduce surface area and cognitive load.

### 3.1 Component Consolidation Candidates

Map duplicate/similar components (apply [[component-audit]] methodology):
- Multiple buttons (`Button`, `PrimaryButton`, `IconButton`) → single `<Button variant>`
- Multiple modals/dialogs → single `<Modal>` with size/intent props
- Multiple form input variants → unified `<Input>` with type/state props

### 3.2 Page Consolidation Candidates

Look for:
- **Multi-step wizards** that could be single forms with progressive disclosure
- **Separate list + detail pages** that could be master-detail layouts
- **Settings spread across pages** that could be tabbed/sectioned in one place
- **Duplicate "create" and "edit" forms** that should be one component with mode prop

### 3.3 Feature Consolidation Candidates

- **Multiple notification systems** (banners + toasts + modals) → unified notification center
- **Multiple search interfaces** → command palette (⌘K)
- **Multiple "add new" entry points** → consistent FAB or primary action pattern
- **Duplicate filter/sort UIs** → reusable filter bar component

### 3.4 Validation Before Consolidation

For each consolidation candidate, verify:
- All current usages mapped (via Grep on imports/references)
- No behavioral divergence that prop-driving can't cover
- No accessibility regression
- Migration path is incremental, not big-bang

## Phase 4: Improvement Plan

### 4.1 Score the Baseline

Present the current composite UX score with per-dimension breakdown:

```
Current UX Score: 5.8 / 10  (Target: 7.8 / 10  — +35%)

  Clarity              ████████░░  6.5
  Efficiency           ██████░░░░  5.0
  Consistency          █████░░░░░  4.5
  Feedback             ███████░░░  6.5
  Error Prevention     ██████░░░░  5.5
  Accessibility        █████░░░░░  4.5
  Visual Hierarchy     ███████░░░  7.0
  Responsive/Mobile    ███████░░░  6.5
```

### 4.2 Prioritize Improvements

Each recommendation scored on:
- **Impact** — how much it moves the score (in points × weight)
- **Effort** — S/M/L (hours to days/weeks)
- **Risk** — likelihood of breaking existing functionality

Sort by **(Impact ÷ Effort) × (1 - Risk)** to find quick wins first.

### 4.3 Recommendation Format

For each improvement:

```markdown
#### [PRIORITY] Title — Dimension(s) affected

**Current state:** What exists today (with file:line refs)
**Problem:** Why it's suboptimal (which heuristic/law it violates)
**Proposed change:** Specific, implementable solution
**Standard cited:** Nielsen #X / WCAG X.X.X / Hick's Law / Material Design / etc.
**Effort:** S/M/L
**Risk:** Low/Med/High
**Score impact:** +X.X points on [Dimension], +Y.Y on [Dimension]
**Migration:** How to roll out incrementally
```

## Phase 5: Implementation (Only When Approved)

After the user approves the plan:

1. Apply changes in priority order, smallest blast radius first
2. Run existing tests after each change
3. Test the affected user flow manually (start dev server, navigate, verify)
4. For each change, confirm the dimension score moves as predicted
5. Stop and re-score after every 3–5 changes to track progress toward +35%

**Do not batch all changes into one PR.** Group by user flow or by dimension for reviewability.

## Output Format

### Executive Summary

```
═══════════════════════════════════════════════════════════════
              UX Improvement Audit — [App Name]
═══════════════════════════════════════════════════════════════

Current Composite Score: X.X / 10
Target Score (+35%):     Y.Y / 10
Estimated Effort:        N sprints

Top 5 Wins (sorted by ROI):
  1. [improvement] — +X.X points, S effort, Low risk
  2. ...

Consolidation Opportunities:
  - N components → M (saves ~X LOC)
  - N pages → M (reduces navigation depth from X to Y)
  - N features → M (unified pattern)
```

### Detailed Findings

1. **App Map** — routes, key flows, persona summary
2. **Per-Dimension Scores** — with cited evidence
3. **Heuristic Violations** — grouped by severity
4. **Consolidation Plan** — components, pages, features
5. **Prioritized Improvements** — full list with effort/impact/risk
6. **Implementation Roadmap** — phased rollout
7. **Re-Scoring Plan** — checkpoints to verify +35% target hit

### Verdict

One of:
- **Audit complete, plan ready for approval** — User decides which improvements to apply
- **Audit complete, needs user input** — Trade-offs require user decision (e.g., remove feature X to reach target?)
- **Score already strong** — Already near or above target; recommend polish over restructure

## Industry Standards Reference

| Source | Use For |
|--------|---------|
| **Nielsen Norman Group** — 10 Usability Heuristics | General UX evaluation |
| **WCAG 2.1 AA** | Accessibility baseline |
| **Material Design** | Android/web pattern conventions |
| **Apple HIG** | iOS/macOS pattern conventions |
| **Microsoft Fluent** | Windows/cross-platform patterns |
| **Refactoring UI** (Wathan/Schoger) | Visual hierarchy, spacing, typography |
| **Don't Make Me Think** (Krug) | Clarity, scannability |
| **Laws of UX** (lawsofux.com) | Cognitive principles (Hick, Fitts, Jakob, etc.) |

## Common Improvements (Quick Reference)

### Clarity Wins
- Replace generic copy ("Submit", "Click here") with action-specific labels ("Save changes", "View report")
- Add empty states with clear next actions
- Use progressive disclosure for advanced options
- Add breadcrumbs on pages >2 levels deep

### Efficiency Wins
- Add keyboard shortcuts for power users (⌘K command palette)
- Pre-fill smart defaults based on user history
- Bulk actions on list views
- Inline editing instead of edit pages
- Optimistic UI updates with rollback on error

### Consistency Wins
- Single button component with variants (not 5 button components)
- Unified modal/dialog system
- Standardized form field patterns
- One notification system (toasts) instead of 3 (banners + modals + alerts)

### Feedback Wins
- Skeleton loaders instead of spinners (perceived speed)
- Inline validation on forms (immediate vs on-submit)
- Toast confirmations for successful actions
- Progress indicators for long operations (>2 seconds)

### Error Prevention Wins
- Confirm destructive actions (delete, archive, send)
- Undo for non-destructive actions (toast with undo button)
- Disable submit buttons until form is valid
- Constrain inputs (date pickers, dropdowns) instead of free text

### Accessibility Wins
- Add visible focus indicators
- Increase touch targets to ≥44×44px
- Ensure 4.5:1 contrast for text
- Add skip links on pages with heavy navigation
- Use semantic HTML over divs with onClick

### Visual Hierarchy Wins
- Establish a typographic scale (3–5 sizes max)
- Use whitespace to group related items
- One primary action per screen
- Reduce visual noise (border-only buttons for secondary actions)

### Responsive Wins
- Mobile-first breakpoints
- Hide non-essential columns on small screens (don't shrink)
- Bottom sheet patterns on mobile instead of modals
- Touch-friendly spacing (≥8px between targets)
