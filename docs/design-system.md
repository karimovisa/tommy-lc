# TOMMY Learning Center — Design System

Brand-anchored design tokens, extracted from the TOMMY logo (`tommy photo.jpg`).
Generated with the ui-ux-pro-max skill, tuned for a **language / academic** learning center.

## Brand colors (from logo)
- Logo red: `#EC1D25`
- Logo white: `#FFFFFF`

## Color tokens
| Token | Hex | Use |
|-------|-----|-----|
| `--brand`        | `#EC1D25` | Primary brand red — logo, primary buttons, links, accents |
| `--brand-dark`   | `#C2161D` | Hover / pressed state for red elements |
| `--brand-tint`   | `#FEECEC` | Soft red backgrounds, badges, highlights |
| `--ink`          | `#1A1A1A` | Primary body text (near-black) |
| `--muted`        | `#5C5C5C` | Secondary text, captions |
| `--surface`      | `#FFFFFF` | Cards, main background |
| `--bg-soft`      | `#F7F7F8` | Alternating section backgrounds |
| `--border`       | `#E5E5E5` | Dividers, card outlines |
| `--cta`          | `#1F8A4C` | Primary call-to-action (Enroll) — green for contrast |
| `--cta-dark`     | `#176B3B` | CTA hover |

## Typography — Lexend + Source Sans 3
- Headings: **Lexend** (600 / 700)
- Body: **Source Sans 3** (400 / 600)
- Designed for reading proficiency — ideal for a language/learning brand.

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Lexend:wght@400;500;600;700&family=Source+Sans+3:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### Alt pairing (friendlier): Poppins + Open Sans
```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&family=Open+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
```

## CSS variables (drop into :root)
```css
:root {
  --brand: #EC1D25;
  --brand-dark: #C2161D;
  --brand-tint: #FEECEC;
  --ink: #1A1A1A;
  --muted: #5C5C5C;
  --surface: #FFFFFF;
  --bg-soft: #F7F7F8;
  --border: #E5E5E5;
  --cta: #1F8A4C;
  --cta-dark: #176B3B;

  --font-heading: 'Lexend', system-ui, sans-serif;
  --font-body: 'Source Sans 3', system-ui, sans-serif;

  --radius: 12px;
  --shadow-sm: 0 1px 3px rgba(0,0,0,.08);
  --shadow-md: 0 4px 16px rgba(0,0,0,.10);
}
```

## Tailwind config (if using Tailwind)
```js
theme: {
  extend: {
    colors: {
      brand: { DEFAULT: '#EC1D25', dark: '#C2161D', tint: '#FEECEC' },
      ink: '#1A1A1A',
      muted: '#5C5C5C',
      cta: { DEFAULT: '#1F8A4C', dark: '#176B3B' },
    },
    fontFamily: {
      heading: ['Lexend', 'sans-serif'],
      body: ['Source Sans 3', 'sans-serif'],
    },
  },
}
```

## UX / quality checklist (from skill)
- [ ] No emojis as icons — use SVG (Heroicons / Lucide)
- [ ] `cursor: pointer` on all clickable elements
- [ ] Hover states with smooth 150–300ms transitions
- [ ] Text contrast ≥ 4.5:1 (red `#EC1D25` on white passes for large/bold; use `--ink` for body)
- [ ] Visible focus states for keyboard navigation
- [ ] Respect `prefers-reduced-motion`
- [ ] Responsive at 375px, 768px, 1024px, 1440px
- [ ] Section gaps 48px+; generous whitespace
