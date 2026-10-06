# Reskin method

The how-to behind the phases. Read the direction out of images, turn it into tokens, and avoid the traps.

## Reading a direction out of images

Open each image with Read. Per image, capture:

| Axis | What to look for |
|------|------------------|
| **Brand color** | The one color a viewer would name. Note its lightness (dark/mid/light), how saturated (muted vs vivid), and hue family. |
| **Neutrals** | Are the greys cool (blue-tinted), warm (beige/taupe), or dead neutral? Backgrounds off-white or true white? |
| **Accent(s)** | A secondary color for data/highlights? Keep to one. More than two accents reads busy. |
| **Type** | Serif or sans? Geometric (Poppins-ish), grotesk (Helvetica-ish), or humanist (open, friendly)? Big tracked-out display type, or quiet uniform text? Heavy or light weights? |
| **Shape** | Corner radius (sharp, soft, pill). Depth via borders or shadows. Dense or airy spacing. |
| **Mood** | One or two words: institutional, editorial, playful, techy, minimal, warm, brutalist, premium. |

Then **synthesize one direction.** Pick a single brand hue, a neutral temperature, one accent, a type pairing, a radius, and a mood sentence. If images conflict, say which one you're following and why. A scrapbook of everything is the failure mode.

## OKLCH cheatsheet

`oklch(L C H)` — perceptual, so equal L reads as equal brightness across hues (unlike HSL).

- **L** (0..1): text ink ~0.20–0.25; muted text ~0.50–0.55; borders ~0.90–0.92; backgrounds ~0.98–1.0. Dark mode: bg ~0.15–0.20, cards ~0.21–0.24, text ~0.96.
- **C** (0..~0.37): neutrals 0.003–0.02 (the tint); UI brand 0.14–0.20; vivid data up to ~0.25.
- **H** (0..360): red 27 · orange 55 · amber 80 · yellow 100 · green 150 · teal 190 · cyan 210 · blue 250 · indigo 264 · violet 300 · magenta 330 · pink 350.

**Sampled hex → token:** paste the hex into oklch.com (or convert) to get L C H. For a UI primary, keep L ~0.50–0.58 (light mode) so white text passes on it; nudge C down if it vibrates. Round to 2–3 decimals.

## Neutral tinting (the anti-"stock" move)

Don't use `oklch(x 0 0)`. Give every neutral a whisper of the brand hue:

- backgrounds/cards: C ≈ 0.001–0.008 at `--brand-hue`
- muted/secondary/borders: C ≈ 0.005–0.012
- foreground ink: C ≈ 0.015–0.02

It's invisible as "color" but the surface stops looking like a default install. The template's `var(--brand-hue)` does this for you.

## Dark mode math

- Background L ≈ 0.15–0.20 (tinted), cards +0.03–0.05 L above bg, popovers = cards.
- Brand: raise L by ~0.08–0.12 vs light so it glows on dark; keep white foreground.
- Borders/inputs: `oklch(1 0 0 / 8–14%)` (translucent white) reads cleaner than a flat grey.
- Muted text ≈ 0.70–0.72 L. Semantic colors: raise L, drop foreground to near-black.

## Contrast — check these pairs (WCAG AA)

Body text 4.5:1, large/UI 3:1, in **both** themes:

- `foreground` on `background` and on `card`
- `muted-foreground` on `background` and on `card` (the one that fails most)
- `primary-foreground` on `primary` (button label)
- `sidebar-foreground` / `sidebar-accent-foreground` on `sidebar`
- `destructive`/`success`/`warning` foreground on their backgrounds

If `muted-foreground` is borderline, drop its L (light) or raise it (dark) by ~0.03.

## Font pairings that read designed

Load via `next/font/google` (or `@font-face`). One display face for wordmarks/headings + a clean workhorse for body is the reliable formula.

| Feel | Display | Body |
|------|---------|------|
| Techy / product | Space Grotesk | Geist / Inter |
| Editorial / premium | Fraunces or Instrument Serif | Inter / Geist |
| Geometric / modern | Sora or Outfit | Geist / Inter |
| Neutral / institutional | Schibsted Grotesk | Inter |
| Friendly | Bricolage Grotesque | Hanken Grotesk |

Avoid: shipping **only** Geist or Inter (the generated-app default), and pairing two display faces. When unsure, keep the project's body font and add one display face — lower risk, still a clear identity.

## Stack detection

```bash
# Token source + Tailwind version
find . -name globals.css -o -name index.css 2>/dev/null | grep -v node_modules
grep -rl "@custom-variant\|@theme" --include=*.css .        # v4
find . -name "tailwind.config.*" 2>/dev/null | grep -v node_modules   # v3
cat components.json 2>/dev/null                              # shadcn: style, baseColor
# Font loading
grep -rn "next/font\|@font-face\|fonts.googleapis" --include=*.tsx --include=*.ts --include=*.css . | grep -v node_modules | head
```

## Gotchas

- **Self-referential font var.** `--font-sans: var(--font-sans)` in `@theme` means the font loads but never applies (text falls back to system). Wire it to the real variable (`var(--font-geist-sans)`). Check this every time.
- **Hardcoded colors bypass tokens.** Grep for `#`, `rgb(`, `bg-\[`, `text-\[` in components. Those won't follow a reskin — either tokenize them or leave them and flag them.
- **shadcn `data-slot` hooks.** Signature utilities target `[data-slot="card"]`, `[data-slot="button"]`, `[data-slot="tabs-content"]` — stable across shadcn components, so you style behavior globally without editing each primitive.
- **`@theme` vs `@theme inline`.** `inline` substitutes the value at build; use it for the `--color-*` → `var(--token)` mapping so light/dark `:root`/`.dark` overrides resolve at the element.
- **base color.** `components.json` `baseColor: "neutral"` just seeds the greys; the token blocks override it. No need to re-run the shadcn CLI.
- **`color-mix` + `mask-image`** need a modern browser target (fine for Next 14+/Vite). If the project supports old browsers, drop the dot-grid layer.
- **Two apps, separate repos.** Same token file in each (they can't share a file); keep them byte-identical except the glyph/wordmark. Reskin both or they drift.
