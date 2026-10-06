---
name: reskin
description: Apply a brand/design direction from reference images to a Tailwind + shadcn/ui (Next.js/React/Vite) app's design tokens. Extract palette, type, and mood from the images, map them onto one tokenized brand layer (light + dark), refresh the identity and sparse screens, verify, and optionally PR. Use when the user hands over screenshots/mockups/brand references (or a look to match) and wants the UI restyled, reskinned, rebranded, unified across apps, made more professional, or given its own personality — without looking AI-generated.
allowed-tools: Read, Grep, Glob, Edit, Write, TodoWrite, AskUserQuestion, Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx:*), Bash(make:*), Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(find:*), Bash(ls:*)
context-files:
  - ~/.config/agent-config/rules/accessibility.md
  - ~/.config/agent-config/rules/core.md
  - ~/.config/agent-config/rules/git.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Reskin — Brand a UI from reference images

You are my design engineer. I hand you reference images and point you at an app; you derive one coherent brand direction and apply it to the project's design tokens — professional, uniform, and unmistakably intentional, never a stock template.

## Objective

- Read a design direction (color, type, shape, mood) out of the reference images
- Map it onto the target project's token system (Tailwind v4 `@theme` / v3 config, shadcn/ui)
- Apply it as a **single tokenized brand layer** so every component follows automatically
- Refresh the identity (brand mark) and the sparse screens (sign-in, landing, empty, error) that carry the most personality for the least code
- Verify (typecheck, lint, build) and, only if asked, open a PR in plain human voice

## Inputs

- **Images** — one or more: mockups, screenshots of a look to match, a brand board, a competitor, or loose "vibes." Open each with Read (it renders images).
- **Target** — a directory / app, "these two apps," or a specific `globals.css`. Multiple apps stay **uniform**: same tokens and type, each keeping its own glyph/wordmark.
- **Optional constraints** — "keep our blue," "dark mode too," "don't touch the data screens," "just do it / don't ask."

If no images or no target were given, ask once, then proceed. Everything else, decide.

## Hard Rules

This is where "professional, not too crazy, not AI-generated" actually lives. Do not skip.

1. **Tokens are the single source of truth.** Reskin at ONE place (the `--brand*` block). Never hand-color components. If you're editing a Button's color, stop and fix the token.
2. **Kill the default-template tells.** Tint neutrals toward the brand hue (no pure `oklch(x 0 0)` greys). Choose real fonts (never ship the stock Geist-only + neutral-shadcn look). One confident accent, used deliberately, not sprinkled.
3. **Restraint beats flash.** No gradient soup, glassmorphism, neon, emoji headers, or shadows on everything. If a senior designer would say "that's a lot," cut it. The personality comes from a considered palette + type + one or two quiet signature details, not decoration.
4. **Surgical.** Components inherit from tokens; only touch bespoke markup where it carries identity (brand mark; sign-in / landing / empty / error screens). Every changed line traces to the direction. Leave data-dense screens to inherit.
5. **Match the house style.** Read the existing tokens and components first; extend the system, don't fork it. Keep sibling apps consistent.
6. **Accessibility is non-negotiable.** Text tokens meet WCAG AA contrast (4.5:1 body, 3:1 large/UI) in **both** light and dark. Respect `prefers-reduced-motion`. Icon-only controls keep their labels.
7. **Verify before "done."** typecheck + lint + a production build (the build compiles the Tailwind CSS and fonts — it catches token, `color-mix`, and font-wiring errors a dev server hides).
8. **Git stays human.** Conventional scoped commits and PR bodies, no AI attribution, no em dashes, no "generated with" tells, no cross-PR/stacking language. Mirror [[ship]] / [[commit]] and `~/.config/agent-config/rules/git.md`.

## Phase 1: Read the references

Open every image. For each, jot: dominant/brand color(s) and rough OKLCH (lightness / chroma / hue); neutral temperature (cool, warm, or true grey); type character (grotesk / geometric / humanist / serif / mono; display vs body; weight; tracking); shape language (corner radius, borders vs shadows, density); and mood in a word or two (institutional, editorial, playful, techy, minimal, warm).

Then **synthesize one direction, not a scrapbook.** If the images disagree, name the conflict and pick the through-line. See `references/method.md` for how to translate a sampled color to tokens and pick fonts.

## Phase 2: Map the target

- Detect the stack: find `globals.css` / `index.css` (Tailwind v4 `@theme` + `@custom-variant dark`) or `tailwind.config.*` (v3 HSL vars); `components.json` (shadcn `baseColor`); font loading (`next/font` vs `<link>` vs `@font-face`).
- Locate the **single token source** and its dark-mode block. This is what you rewrite.
- Inventory the **identity surfaces**: brand mark / logo lockup, sidebar + header chrome, and the sparse screens (sign-in, landing, empty states, error / unauthorized). These carry the most personality per line changed.
- Run the gotcha check from `references/method.md` (self-referential `--font-sans`, hardcoded colors that bypass tokens, shadcn `data-slot` hooks).

## Phase 3: Confirm the direction (once)

Present the derived direction in a few lines (accent color, neutral temperature, font pairing, mood). Then confirm only the **two subjective forks that are expensive to redo** — the accent/color and the typographic personality — via AskUserQuestion with a recommended default. Everything smaller, just decide. If the user said "match these exactly" or "just do it," skip the question and go.

## Phase 4: Apply (token-first, then identity, then surfaces)

1. **Brand layer.** Rewrite the token blocks from `references/brand-layer.css`: `--brand*` vars up top, then the full set (primary, brand-tinted neutrals, semantic success/warning, chart ramp, border/input/ring, sidebar) for light **and** dark. Keep the "single reskin point" comment. The template is hue-parameterized (`--brand-hue`) so the neutrals re-tint from one value.
2. **Type.** Load the chosen fonts in the framework layer (`next/font/google`, etc.), then wire `--font-sans` / `--font-display` / `--font-mono` in `@theme`. Set the display face on headings + wordmarks. **Fix the self-reference bug** if `--font-sans: var(--font-sans)` is present.
3. **Identity.** Refine or create the brand mark: a solid brand-colored tile (subtle inset ring/shadow, no gradient logo) + a display wordmark. Extract it into one component and reuse it everywhere (sidebar, sign-in, notices) so it stays uniform. Give sibling apps the same lockup with a different glyph.
4. **Surfaces.** Elevate the sparse screens with the mark + a restrained brand backdrop (`.auth-backdrop` in the template). Add the quiet signature utilities (card hover, button press, tab fade, brand text-selection) via `data-slot` selectors.
5. **Leave the rest.** Tables, forms, dialogs inherit the tokens. Don't restyle them by hand.

## Phase 5: Verify

- Run the project's `typecheck`, `lint`, and `build` (via its make/pnpm/npm scripts). All green before you report.
- Eyeball contrast on the new text tokens in light and dark (`references/method.md` has the pairs to check).
- Report: what changed, the direction in one sentence, and how to re-hue later (one block). Note that a live screenshot may need the app running behind its auth.

## Phase 6: Ship (only when asked)

- Separate repos → separate PRs. Branch off the default branch; never commit to it directly.
- Stage only intended source files — no `.env`, build artifacts (`.next/`, `*.tsbuildinfo`), or assistant/config files.
- Conventional scoped commit + PR body in the repo's own template, plain voice. Follow [[ship]].

## Anti-patterns (the "AI-generated" look — avoid on sight)

- Stock shadcn neutral palette (pure grey tokens) + Geist as the only font. This combo *is* the generated-starter tell.
- A rainbow of accent colors, or a hero gradient / glassmorphic cards / glowing borders everywhere.
- Emoji in headings, exclamation-heavy microcopy, "Welcome to your dashboard 🎉".
- Purple-to-pink gradient logos and gradient text.
- Perfectly uniform shadows on every element; no hierarchy.
- Re-styling components inline instead of at the token layer (drifts immediately).

## References

- `references/brand-layer.css` — a proven Tailwind v4 + shadcn token layer to adapt: hue-parameterized brand vars, tinted neutrals, semantic + chart tokens, dark mode, font wiring, signature utilities, auth backdrop, reduced-motion. (Notes for Tailwind v3 at the bottom.)
- `references/method.md` — reading a direction out of images, the OKLCH cheatsheet, hex→token translation, neutral-tinting and dark-mode math, contrast targets, font pairings that read designed, stack detection, and the gotcha list.

Related: [[improveux]] for a structure/UX pass (this skill is visual identity, not IA), [[dataviz]] when the app has charts, [[component-audit]] before consolidating a sprawling component set.
