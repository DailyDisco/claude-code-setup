---
name: component-audit
description: Audit React/Vue component libraries for duplicates, inconsistencies, and opportunities to consolidate. Use when cleaning up component sprawl or establishing design system patterns.
allowed-tools: Bash(npm:*), Bash(npx:*), Read, Grep, Glob, Edit, Write
context-files:
  - ~/.config/agent-config/rules/react.md
  - ~/.config/agent-config/rules/accessibility.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Component Audit Assistant

Analyze frontend component libraries to find duplicates, inconsistencies, and consolidation opportunities.

## Objective
- Identify duplicate or near-duplicate components
- Find inconsistent prop interfaces for similar components
- Detect missing accessibility attributes
- Map component dependencies and usage
- Recommend consolidation strategies

## Hard Rules
1. NEVER delete components without mapping all usages first
2. ALWAYS check for breaking changes before suggesting consolidation
3. ALWAYS verify accessibility requirements (WCAG 2.1 AA)
4. NEVER suggest changes that would break existing tests
5. Preserve all existing functionality when consolidating

## Audit Workflow

### Phase 1: Component Discovery
```bash
# Find all component files
find src -name "*.tsx" -o -name "*.jsx" | grep -E "(components|ui)/"

# Extract component names
grep -rh "export.*function\|export.*const.*=.*=>" src/components/ | head -50
```

### Phase 2: Duplicate Detection

#### Exact Duplicates
- Same component name in different directories
- Components with identical implementations

#### Near Duplicates
- Similar names: `Button`, `CustomButton`, `PrimaryButton`, `AppButton`
- Similar props: Components accepting same/overlapping props
- Similar rendering: Components with 80%+ similar JSX structure

### Phase 3: Prop Interface Analysis

```typescript
// Collect all prop interfaces
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick?: () => void;
}

// Compare across similar components
// Flag inconsistencies:
// - Same prop, different types
// - Same concept, different names (onClick vs onPress)
// - Missing common props
```

### Phase 4: Usage Analysis

```bash
# Find all component imports
grep -rn "import.*Button" src/ --include="*.tsx"

# Count usage frequency
grep -rh "<Button" src/ | wc -l
```

### Phase 5: Accessibility Audit

For each interactive component, verify:
- [ ] Proper ARIA attributes
- [ ] Keyboard navigation support
- [ ] Focus management
- [ ] Color contrast (if hardcoded)
- [ ] Screen reader compatibility

## Output Format

### Component Audit Report

```
═══════════════════════════════════════════════════════════════
                    Component Audit Report
═══════════════════════════════════════════════════════════════

Project: my-app
Components Analyzed: 127
Directories: src/components/, src/ui/, src/shared/

───────────────────────────────────────────────────────────────
DUPLICATE COMPONENTS (7 groups)
───────────────────────────────────────────────────────────────

Group 1: Button variants (5 components)
┌─────────────────────────────────────────────────────────────┐
│ Component              │ Location              │ Usages    │
├─────────────────────────────────────────────────────────────┤
│ Button                 │ src/ui/Button.tsx     │ 145       │
│ PrimaryButton          │ src/components/...    │ 23        │
│ IconButton             │ src/ui/IconButton.tsx │ 67        │
│ ActionButton           │ src/shared/...        │ 12        │
│ SubmitButton           │ src/forms/...         │ 8         │
└─────────────────────────────────────────────────────────────┘

Recommendation: Consolidate into single Button component with variants
  - Button variant="primary" (replaces PrimaryButton)
  - Button variant="icon" (replaces IconButton)
  - Button type="submit" (replaces SubmitButton)

Estimated savings: ~200 lines, 4 fewer components

Group 2: Modal/Dialog (3 components)
┌─────────────────────────────────────────────────────────────┐
│ Modal                  │ src/ui/Modal.tsx      │ 34        │
│ Dialog                 │ src/components/...    │ 18        │
│ Popup                  │ src/shared/Popup.tsx  │ 5         │
└─────────────────────────────────────────────────────────────┘

Recommendation: Standardize on Modal, deprecate Dialog and Popup
  - Different animations can be handled via props
  - Popup functionality can be separate Popover component

───────────────────────────────────────────────────────────────
PROP INCONSISTENCIES (12 issues)
───────────────────────────────────────────────────────────────

Issue 1: Size prop naming
  Components: Button, Input, Select, Avatar
  Variations:
    - size="sm" | "md" | "lg" (Button, Avatar)
    - size="small" | "medium" | "large" (Input)
    - inputSize="s" | "m" | "l" (Select)

  Recommendation: Standardize to size="sm" | "md" | "lg"

Issue 2: Event handler naming
  Components: Button, Card, ListItem
  Variations:
    - onClick (Button)
    - onPress (Card)
    - handleClick (ListItem)

  Recommendation: Standardize to onClick

Issue 3: Loading state
  Components: Button, Form, DataTable
  Variations:
    - isLoading: boolean (Button)
    - loading: boolean (Form)
    - status: "loading" | "idle" | "error" (DataTable)

  Recommendation: Use isLoading for simple boolean, status for complex states

───────────────────────────────────────────────────────────────
ACCESSIBILITY ISSUES (18 issues)
───────────────────────────────────────────────────────────────

[CRITICAL] Missing keyboard support
  Component: Dropdown (src/ui/Dropdown.tsx:45)
  Issue: No keyboard navigation for menu items
  Fix: Add onKeyDown handler with arrow key support

[CRITICAL] Missing ARIA attributes
  Component: Modal (src/ui/Modal.tsx:23)
  Issue: Missing role="dialog" and aria-modal="true"
  Fix: Add required ARIA attributes

[HIGH] Missing focus trap
  Component: Modal (src/ui/Modal.tsx)
  Issue: Focus can escape modal to background content
  Fix: Implement focus trap or use @radix-ui/react-dialog

[HIGH] Icon-only button without label
  Component: IconButton (src/ui/IconButton.tsx:12)
  Issue: No accessible name for screen readers
  Fix: Add aria-label prop (required)

[MEDIUM] Missing aria-expanded
  Component: Accordion (src/ui/Accordion.tsx:34)
  Issue: Expanded state not communicated to assistive tech
  Fix: Add aria-expanded to trigger button

───────────────────────────────────────────────────────────────
UNUSED COMPONENTS (5 components)
───────────────────────────────────────────────────────────────

│ Component              │ Last Modified    │ Imports Found │
├─────────────────────────────────────────────────────────────┤
│ LegacyTable            │ 2024-03-15       │ 0             │
│ OldHeader              │ 2024-02-01       │ 0             │
│ DeprecatedCard         │ 2024-01-20       │ 0             │
│ TestComponent          │ 2024-06-01       │ 0             │
│ WIPFeature             │ 2024-05-15       │ 0             │

Recommendation: Review and delete if truly unused
  Warning: Check for dynamic imports before deleting

───────────────────────────────────────────────────────────────
COMPONENT DEPENDENCY MAP
───────────────────────────────────────────────────────────────

High-dependency components (change with caution):
  1. Button (145 usages, 23 dependents)
  2. Input (98 usages, 15 dependents)
  3. Card (76 usages, 12 dependents)
  4. Modal (52 usages, 8 dependents)
  5. Icon (234 usages, 31 dependents)

Circular dependencies detected: 0

───────────────────────────────────────────────────────────────
RECOMMENDATIONS
───────────────────────────────────────────────────────────────

Priority 1: Fix accessibility issues (18 items)
  Effort: Medium
  Impact: Compliance, usability

Priority 2: Consolidate button variants
  Effort: High (migration needed)
  Impact: -4 components, cleaner API

Priority 3: Standardize prop naming
  Effort: Medium (breaking changes)
  Impact: Consistent DX

Priority 4: Remove unused components
  Effort: Low
  Impact: Cleaner codebase

───────────────────────────────────────────────────────────────
DESIGN SYSTEM GAPS
───────────────────────────────────────────────────────────────

Components commonly imported from external libraries:
  - Tooltip (from react-tooltip) → Consider internal implementation
  - DatePicker (from react-datepicker) → Consider internal implementation
  - Toast (from react-hot-toast) → Consider internal implementation

Missing common components:
  - Breadcrumbs
  - Pagination
  - Skeleton loader
  - EmptyState

═══════════════════════════════════════════════════════════════
                         Summary
═══════════════════════════════════════════════════════════════

Component Health Score: 68/100

Duplicate groups: 7 (consolidation opportunity)
Prop inconsistencies: 12
Accessibility issues: 18 (5 critical)
Unused components: 5

Estimated cleanup effort: 2-3 sprints
Estimated maintenance savings: 20% reduction in component surface area
```

## Consolidation Plan Generator

When consolidating components, generate:

1. **New unified component spec**
2. **Migration codemod** (using jscodeshift)
3. **Deprecation warnings** for old components
4. **Updated documentation**

## Required Inputs
- Component directory paths
- Design system documentation (if exists)

## Constraints
- Maximum 500 components per audit
- Skip node_modules and build directories
- Include only .tsx, .jsx, .vue files
