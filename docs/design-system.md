# TOMMY LC — Design System v1

> Bu hujjat ilovada (`index.html`) **haqiqatan ishlatilayotgan** tizimni aks ettiradi (skill-qoralama emas).
> Tamoyil: **aniqlik > o'qilishlik > soddalik > kengayuvchanlik > bezak.** Bitta accent, neytral-og'ir palitra, 8px grid, vazmin soyalar. Hech narsa faqat "bezak uchun" qo'shilmaydi.
> Maqsad: Linear / Stripe / Notion / Vercel darajasidagi sayqal — toza va minimal.

---

## 1. TYPOGRAPHY

**Font pairing (o'zgarmaydi):**
- **Plus Jakarta Sans** (`--sans`) — barcha UI matni
- **DM Mono** (`--mono`) — faqat raqamli/texnik qiymatlar (ball, %, ID, sana, vaqt, metrika)

> **Rule:** Mono hech qachon paragraf yoki tugma matni emas — faqat raqam/kod.

**Type scale (kanonik):**

| Rol | Size / Line-height / Weight | Qayerda |
|-----|------|---------|
| `display` | 40–64px / 1.0–1.1 / **800** | Bitta sahifadagi asosiy raqam (dash-pct) |
| `h1` | 24px / 1.25 / 700–800 | Sahifa/bo'lim sarlavhasi (sd-greet, sd-vtitle) |
| `h2` | 19px / 1.3 / 700 | Page-title, karta-guruh sarlavhasi |
| `h3` | 16px / 1.4 / 600–700 | Karta sarlavhasi (card-title) |
| `body` | 15px / 1.55 / 400 | Asosiy matn (base) |
| `body-sm` | 13px / 1.5 / 400–500 | Ikkilamchi matn, tugma |
| `caption` | 12px / 1.4 / 500 | Label, meta, tag |

> **Rule 1 — Min size:** Eng kichik matn **12px**. (Istisno: faqat brend-mark mikro-kaptioni "LEARNING CENTRE" 10px.)
> **Rule 2 — Weights:** Faqat **400 / 500 / 700 / 800**. 800 ataylab ikki kontekstda farqlanadi: **admin = 700** (jiddiy), **viewer/o'quvchi = 800** (energik). Bu nomuvofiqlik emas — kontekst tanlovi.
> **Rule 3 — Tracking:** Display/h1 sarlavhalarga `letter-spacing:-.022em`. Body neytral.
> **Rule 4 — Line-height:** sarlavha 1.0–1.4, body **1.55**.

---

## 2. SPACING — 4 / 8 grid

```css
--s1:4px  --s2:8px  --s3:12px  --s4:16px  --s5:20px  --s6:24px  --s8:32px
```

| Maqsad | Token |
|--------|-------|
| Ikon↔matn, mayda ichki gap | `--s2` (8) |
| Grid gap (kartalar orasi) | `--s3` (12) |
| Karta padding (kichik / ro'yxat-qator) | `--s4` (16) |
| Karta padding (kontent) | `--s5` (20) |
| Konteyner / modal / sahifa padding | `--s6` (24) |
| Katta bo'lim oralig'i | `--s8` (32) |

> **Rule 1:** Yangi `padding/margin/gap` **faqat tokendan** (`var(--s4)`). Qo'lda `17px` taqiqlanadi.
> **Rule 2:** Kartalar orasi vertikal masofa — kontent `--s4`, ro'yxat-qator `--s3`.
> **Rule 3:** Mobil'da konteyner padding `--s6` → `--s3`.

---

## 3. COLORS

**Falsafa:** neytral ~90%, accent (qizil) ~10%. Qizil = **brend va asosiy harakat**. Status ranglari faqat fikr-mulohaza.

### Light (source of truth)
```css
--bg:#f7f8fa; --surface:#ffffff; --surface-2:#f9fafb;
--border:#e2e3e7; --border-strong:#d2d3d9;
--text:#101114; --text-2:#5b5d66; --text-3:#6e707a;
--brand:#e5242b; --brand-dark:#c41a23; --brand-light:#fdecec;   /* Primary */
--good:#15803d; --good-light:#e7f6ec;   /* Success */
--warn:#b45309; --warn-light:#fef3e2;   /* Warning */
--bad:#dc2626;  --bad-light:#fdecec;    /* Error */
```
### Dark
```css
--bg:#0c0d10; --surface:#16181d; --surface-2:#1c1f26;
--border:#262932; --border-strong:#3a3e49;
--text:#f2f3f5; --text-2:#a6aab5; --text-3:#969aa6;
--brand:#ff4d54; --brand-dark:#ff6b71; --brand-light:#2a1416;
--good:#34d058; --warn:#e3a93c; --bad:#ff5a5f;
```

| Rol | Token | Qoida |
|-----|-------|-------|
| **Primary** | `--brand` | Asosiy CTA, faol nav/tab, link — **to'ldirilgan** tugma |
| **Secondary** | `--surface` + `--border-strong` | Ikkilamchi tugma (outline/ghost) |
| **Accent** | `--brand` (yagona) | Ikkinchi accent **yo'q** |
| **Success** | `--good` | "O'tdi", bajarildi, o'sish ▲ |
| **Warning** | `--warn` | Kutilmoqda, yarim |
| **Error** | `--bad` | Xato, "o'tmadi", o'chirish, tushish ▼ |
| **Neutral** | `--text/-2/-3`, `--border/-strong`, `--surface/-2`, `--bg` | Matn, fon, chiziq |

> **⚠️ Critical — brand va bad bir xil qizil:** Brend qizil saqlanadi. Shuning uchun **destructive (o'chirish) hech qachon to'ldirilgan qizil tugma emas** — har doim *qizil matn* yoki *qizil outline*. Faqat **Primary** to'ldirilgan qizil bo'ladi. Shu farq ikkalasini ajratadi.
> **Rule — Contrast floor:** har matn ≥ **4.5:1** (light + dark).
> **Rule — Status fon:** status ranglari fon sifatida faqat `-light` variant bilan; matn quyuq variant bilan.

---

## 4. COMPONENTS

### Buttons
```
Radius: 9px · Font: 13px/600 · Padding: 7px 16px (sm: 5px 12px)
Mobil tap-target: ≥44px
Primary:     bg --brand, color #fff · hover --brand-dark + translateY(-1px)
Secondary:   bg --surface, border --border-strong · hover --bg
Destructive: color --bad, ghost/outline — TO'LDIRILMAYDI
Press:       :active translateY(1px) scale(.985)
Disabled:    opacity .55 + not-allowed
```
> **Rule:** Bir ekranda **bitta** Primary. Qolgani Secondary/ghost.

### Inputs
```
Radius: 9–11px · Padding: 9px 12px · bg --surface-2 · border 1px --border-strong
Focus: border --brand + ring 0 0 0 3px var(--brand-light)
Mobil: min-height 44px, font 16px (iOS zoom yo'q)
Error: border --bad + ring --bad-light (+ shake — kelgusi)
```

### Cards
```
bg --surface · border 1px --border · radius --radius (14) · shadow --shadow-sm
Padding: kontent --s5, ro'yxat-qator --s4 · Margin-bottom: --s4 / --s3
Bosiladigan: hover translateY(-2px)+shadow-md; active scale(.995)
```
> **Rule:** Bosilmaydigan kartada hover-lift YO'Q.

### Modals
```
overlay: rgba(0,0,0,.35) fade .18s · modal: radius 16px, padding --s6, max-width 400px
Ochilish: modal scale(.97)→1 + translateY(10→0) .24s ease-out
Fon bosilsa / Esc → yopiladi
```

### Navigation
```
nav-item: padding 9–11px 13–18px · radius 9–11px · 13–14px/500
Hover: bg --bg + color --text · Active: bg --brand-light + color --brand + weight 600
```
> **Rule:** Faol element har doim brand-light fon + brand matn. Bir vaqtda bitta faol.

### Tables
```
Header: 12px/600 caption · qator: 13–14px · qator hover: bg --surface-2
Raqamli ustun: center + mono · status: rang-pill
Mobil: keng jadval gorizontal scroll (kelgusida kartochka)
```

---

## 5. VISUAL LANGUAGE

**Border radius — kanonik scale (rolga bog'liq tier):**
| Tier | Radius | Element |
|------|--------|---------|
| Tiny control | 8px | Mayda ikon-tugma, menyu elementi |
| Small | 10px (`--radius-sm`) | Input, tugma, pill, mayda box (metric, toast) |
| Icon tile | 12px | 42px kvadrat ikon-plitka (dash-card-ic, sd-iconbtn) |
| Card | 14px (`--radius`) | Karta, jadval |
| Modal | 16px | Modal oynalar |
| Panel | 18px | sd-card, auth-box |
| Pill / avatar | 50% | Dumaloq elementlar |

> **Rule:** Yangi element shu tierlardan birini oladi — oraliq qiymat (11/13/15) ishlatilmaydi.

**Shadows — 3 daraja (balandlik signali, bezak emas):**
```css
--shadow-sm: 0 1px 2px /.04, 0 1px 3px /.06   /* statik karta (default) */
--shadow-md: 0 2px 4px /.04, 0 8px 20px /.08  /* hover / ko'tarilgan */
--shadow-lg: 0 12px 40px /.14                 /* modal / popover / suzuvchi qatlam */
```

**Borders / Dividers:** `1px solid var(--border)` (butun ilovada 1px — `.5px` ishlatilmaydi). Faqat zarur joyda; ko'p chiziq o'rniga **whitespace** afzal.

**Icon style:**
```
SVG outline (stroke) · stroke-width 2 · linecap/linejoin round
O'lcham 16–19px (UI), 24px (hero) · color: currentColor
```
> **Rule:** Faqat outline ikon — solid/duotone aralashmaydi. Emoji faqat motivatsion aksent (🔥/🎯), strukturaviy ikon sifatida emas.

**Illustrations:** YO'Q. Bo'sh holatlarda — bitta outline ikon + matn + "keyingi qadam" jumlasi. Stock/3D rasm, parallax, dekorativ grafik ishlatilmaydi.

**Motion:**
```
Davomiylik ≤300ms · faqat opacity + transform · easing cubic-bezier(.2,.8,.2,1)
prefers-reduced-motion → barcha animatsiya o'chadi
```
Mavjud: `viewIn` (sahifa), `fadeUp` (stagger, sahifa ochilishi), `tickPop` (uy ishi), `modalIn`/`overlayIn` (modal), `popIn` (dropdown), `floaty` (logo), toast slide.

---

## 6. STRICT GLOBAL RULES (izchillik kafolati)

1. **Token-only** — rang/masofa/radius/soya faqat CSS o'zgaruvchidan. Qo'lda hex/px taqiqlanadi.
2. **One accent** — qizildan boshqa brend rangi yo'q.
3. **Primary uniqueness** — ekranda bitta to'ldirilgan-qizil tugma; destructive hech qachon to'ldirilmaydi.
4. **Type scale lock** — 7 rol, 4 weight, min 12px.
5. **8px rhythm** — barcha masofa 4/8 ga bo'linadi.
6. **Radius tier** — 8/10/12/14/16/18/50% rolga ko'ra; oraliq qiymat yo'q.
7. **Contrast floor** — har matn ≥4.5:1.
8. **Touch floor** — interaktiv element mobil'da ≥44px.
9. **Motion budget** — ≤300ms, faqat opacity+transform, reduced-motion hurmat.
10. **Elevation logic** — soya = balandlik (sm→md→lg), ixtiyoriy emas.
11. **Decoration ban** — har element vazifaga ega; "chiroyli ko'rinsin" uchun hech narsa qo'shilmaydi.

---

## 7. Kelgusi konvergensiya (ixtiyoriy)
- Weight'ni admin+viewer bo'ylab birlashtirish (hozir 700/800 ataylab ikki kontekst).
- `sd-logo .brand-sub` 8.5px → 10px (min-size qoidasiga to'liq moslik).
- Test jadvalini mobil'da kartochka ko'rinishiga (gorizontal scroll o'rniga).
- Input xato holati: shake + qizarish (Medium).

---
*Oxirgi yangilanish: 2026-06-14 — index.html bilan mos (border 1px, radius tier, spacing token, micro-interactions).*
