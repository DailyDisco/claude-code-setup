---
paths: "**/*.{jsx,tsx,html,vue,svelte,astro}"
---

# Accessibility Rules

Apply these rules when building user interfaces. Target WCAG 2.1 AA compliance minimum.

---

## Core Principles (POUR)

- **Perceivable** - Information must be presentable in ways users can perceive
- **Operable** - Interface must be operable by all users
- **Understandable** - Information and operation must be understandable
- **Robust** - Content must be robust enough for assistive technologies

---

## Semantic HTML

- Use correct HTML elements for their purpose
- `<button>` for actions, `<a>` for navigation
- `<nav>`, `<main>`, `<article>`, `<aside>` for landmarks
- `<h1>` - `<h6>` in logical order (no skipping levels)
- `<ul>`, `<ol>` for lists
- `<table>` only for tabular data (with `<th>` headers)

### Anti-Patterns

```html
<!-- Bad -->
<div onclick="submit()">Submit</div>
<span class="link">Click here</span>

<!-- Good -->
<button type="submit">Submit</button>
<a href="/page">View details</a>
```

---

## Keyboard Navigation

- All interactive elements must be keyboard accessible
- Visible focus indicators (never `outline: none` without replacement)
- Logical tab order (use DOM order, avoid `tabindex` > 0)
- Skip links for main content
- Escape closes modals/dropdowns
- Arrow keys for menu navigation

### Focus Management

```jsx
// After opening modal, focus first interactive element
// After closing, return focus to trigger element
useEffect(() => {
  if (isOpen) {
    firstInput.current?.focus();
  } else {
    triggerButton.current?.focus();
  }
}, [isOpen]);
```

---

## ARIA Patterns

### When to Use ARIA

1. First: Use native HTML elements
2. Then: Add ARIA only when HTML is insufficient
3. Never: Use ARIA that conflicts with native semantics

### Common Patterns

```html
<!-- Buttons with icons only -->
<button aria-label="Close dialog">
  <Icon name="x" aria-hidden="true" />
</button>

<!-- Loading states -->
<div aria-live="polite" aria-busy="true">
  Loading...
</div>

<!-- Form errors -->
<input aria-invalid="true" aria-describedby="email-error" />
<span id="email-error" role="alert">Invalid email format</span>

<!-- Expandable sections -->
<button aria-expanded="false" aria-controls="panel-1">
  Show details
</button>
<div id="panel-1" hidden>...</div>
```

### Required ARIA for Custom Widgets

| Widget | Required ARIA |
|--------|--------------|
| Modal | `role="dialog"`, `aria-modal="true"`, `aria-labelledby` |
| Tabs | `role="tablist/tab/tabpanel"`, `aria-selected`, `aria-controls` |
| Menu | `role="menu/menuitem"`, `aria-haspopup`, `aria-expanded` |
| Combobox | `role="combobox"`, `aria-autocomplete`, `aria-expanded` |
| Alert | `role="alert"` or `aria-live="assertive"` |

---

## Color & Contrast

- Minimum contrast ratio: **4.5:1** for normal text
- Minimum contrast ratio: **3:1** for large text (18px+ or 14px+ bold)
- Never convey information by color alone
- Provide patterns, icons, or text alongside color

---

## Images & Media

### Images

```html
<!-- Informative images -->
<img src="chart.png" alt="Sales increased 25% in Q4 2024" />

<!-- Decorative images -->
<img src="decoration.png" alt="" role="presentation" />

<!-- Complex images -->
<figure>
  <img src="diagram.png" alt="System architecture diagram" />
  <figcaption>Detailed description of architecture...</figcaption>
</figure>
```

### Video/Audio

- Provide captions for video
- Provide transcripts for audio
- No auto-playing media with sound
- Pause/stop controls for moving content

---

## Forms

```html
<form>
  <!-- Always associate labels -->
  <label for="email">Email address</label>
  <input id="email" type="email" required aria-describedby="email-hint" />
  <span id="email-hint">We'll never share your email</span>

  <!-- Group related fields -->
  <fieldset>
    <legend>Shipping Address</legend>
    <!-- fields -->
  </fieldset>

  <!-- Clear error messages -->
  <span id="error" role="alert">Please enter a valid email</span>
</form>
```

---

## Motion & Animation

- Respect `prefers-reduced-motion`
- No content that flashes more than 3 times per second
- Provide pause controls for auto-updating content

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Testing Checklist

### Automated
- Run axe-core on every page
- Include in CI/CD pipeline

### Manual
- [ ] Tab through entire page
- [ ] Use screen reader (NVDA, VoiceOver)
- [ ] Test at 200% zoom
- [ ] Test without mouse
- [ ] Verify focus visibility
