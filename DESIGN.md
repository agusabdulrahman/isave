---
name: Lumina Finance
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c5c9ad'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8f9379'
  outline-variant: '#454933'
  surface-tint: '#b2d400'
  primary: '#ffffff'
  on-primary: '#2a3400'
  primary-container: '#ccf21e'
  on-primary-container: '#596c00'
  inverse-primary: '#546500'
  secondary: '#44e2cd'
  on-secondary: '#003731'
  secondary-container: '#03c6b2'
  on-secondary-container: '#004d44'
  tertiary: '#ffffff'
  on-tertiary: '#67001f'
  tertiary-container: '#ffdadc'
  on-tertiary-container: '#b1394f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ccf21e'
  primary-fixed-dim: '#b2d400'
  on-primary-fixed: '#181e00'
  on-primary-fixed-variant: '#3f4c00'
  secondary-fixed: '#62fae3'
  secondary-fixed-dim: '#3cddc7'
  on-secondary-fixed: '#00201c'
  on-secondary-fixed-variant: '#005047'
  tertiary-fixed: '#ffdadc'
  tertiary-fixed-dim: '#ffb2b9'
  on-tertiary-fixed: '#400010'
  on-tertiary-fixed-variant: '#891933'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-margin: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  section-gap: 32px
---

## Brand & Style

The brand personality is **Professional, Lucid, and Empowering**. This design system avoids the cluttered, stressful nature of traditional finance apps in favor of a "Soft-Modern" aesthetic that treats financial data as a calm, manageable resource.

The target audience consists of design-conscious individuals and professionals who value clarity and efficiency. The UI should evoke a sense of **financial control and quiet confidence**.

**Design Style: Soft Minimalism**

- **Refined Minimalism:** Uses generous negative space to reduce cognitive load.
- **Modern Utility:** Focuses on clean structural lines and high-quality typography over decorative elements.
- **Balanced Contrast:** Pairs a deep, premium slate background with a high-energy lime accent to create a focal point for growth and action.

## Colors

The palette is anchored in a "Soft Dark" philosophy, moving away from harsh pure blacks to a sophisticated slate and charcoal base.

- **Primary (Electric Lime):** Reserved for growth indicators, primary CTAs, and active navigation states. It represents prosperity and forward momentum.
- **Secondary (Mint):** Used for positive cash flow, income, and success states.
- **Tertiary (Rose):** Used sparingly for expenses, alerts, and negative trends to ensure they are visible but not anxiety-inducing.
- **Neutrals (Slate):** A deep range of blue-greys provides the foundation. The background is `#0F172A`, while interactive cards use `#1E293B` to create a layered, premium feel.

## Typography

**Hanken Grotesk** is the sole typeface for this design system. Its sharp, contemporary geometry provides a "fintech-forward" look that remains highly legible at small sizes.

- **Data-First Hierarchy:** Financial figures (currency) should use `SemiBold` or `Bold` weights to stand out against descriptive labels.
- **Letter Spacing:** Headlines use slight negative tracking (-0.01em to -0.02em) for a tighter, editorial look. Small labels use positive tracking (+0.05em) for better readability in dark mode.
- **Contrast:** Use high-contrast white for primary values and a muted slate-300 for secondary metadata.

## Layout & Spacing

The layout follows a **Fluid-Fixed hybrid model**. On mobile, it uses a 4-column fluid grid; on desktop, it centers to a maximum 1200px 12-column fixed width.

- **Information Density:** Medium-Low. We prioritize "breathability" over data density. Every major financial metric should have its own visual "island" (card).
- **Safe Margins:** A consistent 20px margin is maintained on all mobile edges.
- **Rhythm:** An 8px linear scale (8, 16, 24, 32, 48, 64) is used for all padding and margins to ensure a tight, mathematical harmony.

## Elevation & Depth

This design system uses **Tonal Layering** instead of heavy shadows to maintain a clean, flat aesthetic.

- **Base Layer:** `#0F172A` (The Canvas).
- **Secondary Layer (Cards):** `#1E293B`. Cards should have a 1px solid border of `#334155` to define edges without relying on shadows.
- **Interactive Layer:** Active elements or modals use a very subtle, extra-diffused shadow: `0px 10px 30px rgba(0, 0, 0, 0.5)`.
- **Gloss Effect:** For primary actions (e.g., the primary Lime button), a subtle inner-white glow (opacity 10%) can be applied to the top edge to give it a slightly tactile, premium feel.

## Shapes

The shape language is **Refined & Friendly**.

- **Cards and Containers:** Use a `1rem` (16px) radius to create a soft, modern container.
- **Buttons:** Use a `0.75rem` (12px) radius. This distinguishes them from the larger container shapes.
- **Selection Indicators:** Chips and small status badges use a "Pill" (full-round) shape to communicate a distinct interactive state from the structural cards.

## Components

### Buttons

- **Primary:** Background `primary_color_hex` (Lime), text `#0F172A`. High impact, used for "Add Transaction" or "Save."
- **Secondary:** Transparent background with a `1px` border of slate-400.
- **Ghost:** No background or border; uses the primary color for text.

### Cards

- Interactive cards must have a hover/press state that slightly lightens the background color to `#334155`.
- Data cards should use a vertical stack: Label (Slate-300), followed by Value (White), followed by Trend Indicator (Lime or Rose).

### Input Fields

- Filled style: Background `#1E293B` with a bottom-only 2px border that highlights in Lime when focused.
- Icons should be placed on the left, using a 20px size and Slate-400 color.

### Navigation

- **Bottom Bar:** Use a frosted glass effect (Backdrop Blur 20px) with 80% opacity of the background color. Icons use a 2px stroke width. The active state is indicated by a Primary Lime icon and a small 4px dot below it.

### Progress Bars & Charts

- **Budget Rings:** Use a 12px stroke width. The "track" should be `#1E293B`, and the "progress" should be the Primary Lime.
- **Line Charts:** Use a 3px stroke with a subtle vertical gradient fill below the line (Primary Lime to Transparent).
