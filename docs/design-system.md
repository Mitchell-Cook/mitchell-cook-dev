# Design system

The single source of design truth for [mitchellcook.dev](https://mitchellcook.dev). This
document is the **spec**; `site/styles.css` is its implementation. When the two disagree,
this doc wins — change it here first, then make the CSS match.

The goal: every page on the site looks like it belongs to the same site — same font, same
colors, same spacing, same buttons — without anyone having to think about it. One shared
CSS file, a small vocabulary of tokens and components, reused everywhere.

> **Status:** v1 — direction settled. The core decisions (color, theme, fonts, layout,
> naming, and what to build first) are locked in [Settled decisions](#settled-decisions).
> A few `_(proposed)_` items are deliberately deferred until a page needs them.

## Philosophy

- **Content first.** The site exists to publish writing, ideas, and demos. Design serves
  legibility and gets out of the way. If a choice makes the words easier to read, it wins.
- **Boring on purpose.** Prefer plain HTML/CSS and web-standard features over frameworks
  and cleverness. It should still work — and be editable — in five years.
- **One file, small vocabulary.** A handful of tokens and a short list of components,
  reused. Every new page composes existing pieces; it doesn't invent new ones.
- **Constraint over configuration.** A narrow set of colors, sizes, and spacings you pick
  _from_, not a system you tune. Fewer choices → more consistency, less bikeshedding.
- **Progressive, not fragile.** Works without JavaScript. JS enhances; it's never required
  to read a page.

## Principles

The rules that settle future arguments so we don't re-litigate them per page:

1. **System fonts, always.** The visitor's own OS default UI font for text, system monospace
   for code. No web fonts.
2. **One reading column, generous whitespace.** No multi-column text. Long-form content
   lives in a constrained measure; whitespace does the visual work.
3. **Semantic HTML carries meaning; classes carry style.** Use `<header> <main> <footer>
   <article> <nav>`. Reach for a class when style needs it, not to replace structure.
4. **Tokens, never magic numbers.** Colors, spacing, radii, and type sizes come from CSS
   custom properties. If you're typing a raw hex or px in a component, add a token instead.
5. **Mobile-first.** Base styles target small screens; larger screens are enhancements
   layered on with `min-width` media queries.
6. **Accessible by default.** Sufficient contrast, visible focus states, respects
   `prefers-reduced-motion`, works with keyboard.

## Layout & page structure

Every page follows the same skeleton:

```
<header>   — page/site title, tagline, and (later) nav
<main>     — the content, inside a constrained reading column
<footer>   — copyright + links
```

- **Reading column.** Content is capped at a comfortable measure — `--measure: 44rem`
  (~70–80 characters per line, the readable range for prose). `<header>`, `<main>`, and
  `<footer>` each center their content within this width. A wider cap, `--measure-wide`
  (~60rem), exists for opt-in wide content (see below).
- **Gutters.** A consistent horizontal padding (`1.5rem`) keeps content off the screen edge
  on mobile.
- **Vertical rhythm.** Sections are separated by a hairline top border
  (`1px solid rgba(255,255,255,0.08)`) and consistent vertical padding, rather than boxes.
- **Flat background, constrained content.** A single solid background color fills the
  viewport; text sits in the centered column on top of it. No gradient.

**Wide content:** the narrow prose column is the default everywhere. Content that genuinely
benefits from more room — a demo, a wide image, code output — opts in with a single wide
modifier (a `--wide` variant of the container, capped at `--measure-wide`). That's the whole
mechanism: one column, one opt-out. Simple, idiomatic, and nothing to decide per page.

## HTML & markup conventions

How pages are marked up — the structural counterpart to the visual system. Semantic HTML does
the heavy lifting; BEM classes are layered on only for style. Keep it valid and boring;
correct markup is what makes the [accessibility](#accessibility) guarantees actually hold.

- **Document skeleton.** Every page has `<!doctype html>`, `lang` on `<html>`,
  `<meta charset>`, the responsive `viewport` meta, a `<title>`, and a
  `<meta name="description">`.
- **Landmarks.** `<header>`, `<nav>`, `<main>` (exactly one per page), `<footer>`. Group
  content in `<section>` with a heading, or `<article>` for self-contained content (a post).
- **Headings.** Exactly one `<h1>` (the page title); don't skip levels (`h1 → h2 → h3`).
  Headings describe structure — size comes from type tokens, never from picking a bigger tag.
- **Links vs. buttons.** `<a>` navigates (it has a destination); `<button>` performs an
  action. Never fake one with the other — it breaks keyboard and screen-reader behavior.
- **Lists & prose.** Real `<ul>`/`<ol>` for lists (nav links usually live in a list); `<p>`
  for paragraphs; `<blockquote>`, `<figure>`/`<figcaption>`, `<time datetime="…">` for dates,
  `<code>`/`<pre>` for code.
- **Images.** `<img>` with `width`/`height` set (avoids layout shift); `alt` per the
  accessibility rules.
- **Progressive enhancement.** Every page is valid, readable HTML with no CSS and no JS.
  Styling and scripts enhance; they never gate content.

## Responsive approach

- **Mobile-first**, one fluid column that simply gets more breathing room as the viewport
  grows. The `--measure` cap means on large screens the column stops widening and the
  margins grow instead — no desktop-specific layout needed for prose.
- **Fluid type** for large display text via `clamp()` (the hero already does this), so
  headings scale smoothly without breakpoint jumps.
- **Breakpoints are rare and intentional.** We add one only when a component genuinely needs
  to reflow (e.g. a nav collapsing). No grid of arbitrary device widths.
- _(proposed)_ Named breakpoints when we need them: `--bp-sm: 40rem`, `--bp-md: 60rem`.
  Introduce lazily, not up front.

## Color

**Monochrome. No accent color, no gradient.** Essentially two colors — a foreground and a
background — that swap based on the visitor's OS setting: black-on-white in light mode,
white-on-black in dark mode, via `prefers-color-scheme`. No toggle, no JavaScript. This is
the whole palette, on purpose: it's calm, print-like, and ages out of fashion cycles.

Colors are defined once as role tokens and referenced by role, never by raw value, so the
light/dark swap is just a second set of token values.

| Token | Light | Dark | Role |
|---|---|---|---|
| `--bg` | `#ffffff` | `#0a0a0a` | Page background (flat, no gradient) |
| `--fg` | `#111111` | `#f2f2f2` | Primary text |
| `--muted` | `#6a6a6a` | `#9a9a9a` | Secondary text, captions, "coming soon" |
| `--border` | `rgba(0,0,0,0.12)` | `rgba(255,255,255,0.14)` | Hairline dividers |

Near-black/near-white rather than pure `#000`/`#fff` — softer on the eyes and avoids harsh
contrast, while still reading as "black and white." (If you'd rather go pure, it's a
two-value edit.)

Implementation: defaults in `:root`, dark overrides in
`@media (prefers-color-scheme: dark)`.

Rules:

- **Reference by role, not value.** Components use `--fg` / `--bg`, never a raw hex.
- **No accent color.** Emphasis comes from weight, size, underline, and whitespace — not
  hue. **Links** are the same color as body text, distinguished by underline (see
  Typography).
- **Contrast matters.** Body text must clear WCAG AA (4.5:1) in both themes. Muted text is
  for non-essential copy only.
- _(proposed)_ If a component ever truly needs a status color (e.g. form validation), add a
  single semantic token then — not before. Even then, prefer text/icons over color alone.

## Typography

- **Font stack** _(settled)_: native system UI stack only
  (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, …`) — no web fonts. Zero network
  cost, no layout shift, looks at home on every OS, ages perfectly. Each visitor sees their
  own system's default UI font, which is the point.
- **Base size** `16px` / `1rem`, `line-height: 1.65` for body prose (roomy, readable).
- **Type scale** — a small, fixed set instead of arbitrary sizes:

  | Token | Size | Use |
  |---|---|---|
  | `--text-hero` | `clamp(2.5rem, 8vw, 4rem)` | Page title (h1) |
  | `--text-h2` | `1.4rem` | Section heading |
  | `--text-lg` | `1.2rem` | Tagline, lead paragraph |
  | `--text-base` | `1rem` | Body |
  | `--text-sm` | `0.9rem` | Footer, captions, metadata |

- **Weights:** normal for body, bold for headings. Tight letter-spacing (`-0.02em`) on the
  large display heading only.
- **Links:** same color as surrounding text, underlined. On hover, the underline thickens or
  the text goes bold — no color change. Emphasis is monochrome. Visible focus outline for
  keyboard users.
- **Code**: a system monospace stack for `code`/`pre`
  (`ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace`) — same system-font
  philosophy, no web font.

## Spacing & sizing

A small spacing scale keeps rhythm consistent — pick from it, don't freehand:

| Token | Value |
|---|---|
| `--space-1` | `0.5rem` |
| `--space-2` | `1rem` |
| `--space-3` | `1.5rem` |
| `--space-4` | `2rem` |
| `--space-6` | `3rem` |
| `--space-8` | `5rem` |

Other primitives:

- **Radii:** `--radius: 0.5rem` (cards, buttons), `--radius-sm: 0.25rem` (tags, inline code).
- **Borders:** hairline `1px` in `--border` for dividers.
- **Shadows:** used sparingly, if at all — the flat monochrome look leans on hairline
  borders and whitespace for structure rather than drop shadows.

## Components

The component vocabulary — described here, coded in `styles.css`. Every page composes from
this list; adding a genuinely new component means adding it here first.

The **core set** (build now) is tokens + base + the components below marked _build now_.
Everything else is added when a page needs it.

| Component | What it is | Status |
|---|---|---|
| **Link** | Same color as text, underlined; hover thickens/bolds; visible focus ring | exists |
| **Hero** | Page title + tagline block at top of a page | exists |
| **Section** | A titled content block with a hairline top divider | exists |
| **Muted text** | `.muted` for secondary/"coming soon" copy | exists |
| **Button** | Solid (filled `--fg`) + outline variants; monochrome, no accent fill | build now |
| **Nav** | Site navigation in the header; collapses gracefully on mobile | build now |
| **Card** | A bordered container for a demo or linked item | build now |
| **Form** | Inputs, textarea, select, labels, help/error text, submit button | build now |
| **Post layout** | Article structure: title, date/meta, prose body, code blocks | build now |
| **Tag / badge** | Small pill for post tags, statuses | later |
| **Code block** | Styled `pre`/`code` for the dev blog | later |

Buttons and forms are monochrome like everything else: emphasis via fill/outline/weight,
never a color accent. Focus states are always visible for keyboard users.

### Class naming — BEM

Components use [BEM](https://getbem.com/) (`block__element--modifier`) so class names are
self-documenting and styles stay flat and predictable:

- **Block** — the component root: `.card`, `.btn`, `.nav`, `.form`.
- **Element** — a part of a block, double underscore: `.card__title`, `.form__label`,
  `.nav__link`.
- **Modifier** — a variant, double dash: `.btn--outline`, `.card--wide`, `.nav__link--active`.

Rules of thumb: keep nesting shallow (block → element, not element → element), let semantic
HTML carry structure with BEM classes layered for style, and reserve short utility classes
(`.muted`, `.container`) for one-off helpers rather than forcing everything through BEM.

## Motion

- **Subtle and functional.** Transitions on interactive states (link/button hover, focus)
  only — nothing decorative that moves on its own.
- **Fast.** ~150–200ms ease on color/opacity changes.
- **Respect `prefers-reduced-motion`.** Disable non-essential transitions and the smooth
  scroll for users who ask for it.

## Accessibility

Accessibility is part of the design system, not a later audit. The tokens and components are
defined so that using them normally *is* accessible — you shouldn't have to bolt it on.
Baseline commitments:

- **Semantic structure.** One `<h1>` per page, headings in order, real landmark elements.
  (See [HTML & markup conventions](#html--markup-conventions).) Structure is the foundation
  everything else rests on.
- **Contrast.** Body text clears WCAG AA (4.5:1) in both light and dark; large text ≥ 3:1.
  The monochrome palette makes this easy to guarantee.
- **Never color alone.** Meaning is never carried by color by itself — and there's no accent
  color to lean on anyway. Use text, weight, underline, or icons.
- **Visible focus.** Every interactive element has a clear, high-contrast focus outline.
  Never remove an outline without replacing it with something equally visible.
- **Keyboard operable.** Everything works without a mouse; logical tab order; a "skip to
  content" link before the header.
- **Reduced motion.** Honor `prefers-reduced-motion: reduce` — disable non-essential
  transitions and smooth scroll.
- **Forms.** Every input has an associated `<label>`; errors are conveyed as text (not just
  color); help and error text are linked with `aria-describedby`.
- **Images.** Meaningful images get descriptive `alt`; decorative images get `alt=""`.
- **ARIA sparingly.** Prefer native elements (`<button>`, `<nav>`, `<a>`). Add ARIA only to
  fill gaps native HTML can't — e.g. `aria-current` on the active nav link, `aria-expanded`
  on a mobile menu toggle.
- **Touch targets.** Comfortably large on touch (~44px minimum).

Rule of thumb: tab through every page, check contrast in both themes, and try a screen reader
now and then. If a component can't be built accessibly, it doesn't go in the system.

## Open decisions

None outstanding. The one remaining knob is cosmetic and easy to flip later:

- **Pure vs. near black/white?** The doc specifies near-black/near-white (`#0a0a0a` /
  `#f2f2f2`) for eye comfort. Switch to pure `#000`/`#fff` any time if you want maximum
  contrast — it's a two-value edit.

## Settled decisions

- **Color:** monochrome, no accent, no gradient. Foreground + background only. _(2026-07-08)_
- **Theme:** auto light/dark via `prefers-color-scheme` — no toggle, no JS. _(2026-07-08)_
- **Links:** monochrome, underline-based emphasis (no colored links). _(2026-07-08)_
- **Fonts:** system stack only — system UI font for text, system monospace for code, no web
  fonts. _(2026-07-08)_
- **Build scope:** tokens + base + core components — button, nav, card, form, post layout —
  built now. Tag/badge and code block come later. _(2026-07-08)_
- **Wide content:** narrow prose column by default; opt-in `--wide` variant capped at
  `--measure-wide` for demos/media. _(2026-07-08)_
- **Class naming:** BEM (`block__element--modifier`), with short utility classes for
  one-offs. _(2026-07-08)_
