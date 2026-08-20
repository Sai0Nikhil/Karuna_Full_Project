---
name: Karuṇā Admin
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#bdc9c6'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#889391'
  outline-variant: '#3e4947'
  surface-tint: '#80d5cb'
  primary: '#80d5cb'
  on-primary: '#003733'
  primary-container: '#0f766e'
  on-primary-container: '#a3faef'
  inverse-primary: '#006a63'
  secondary: '#6bd8cb'
  on-secondary: '#003732'
  secondary-container: '#29a195'
  on-secondary-container: '#00302b'
  tertiary: '#adc6ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#0165d8'
  on-tertiary-container: '#e4eaff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf2e8'
  primary-fixed-dim: '#80d5cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#00504a'
  secondary-fixed: '#89f5e7'
  secondary-fixed-dim: '#6bd8cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Outfit
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
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
  container-max: 1440px
  gutter: 24px
  margin-desktop: 40px
  margin-mobile: 16px
  base-unit: 8px
---

## Brand & Style

The design system is centered on a high-end, immersive "Glassmorphism" aesthetic tailored for a premium administrative experience. It targets power users who require a sophisticated, focused environment where data feels suspended in a deep, atmospheric space.

The visual language balances the "depth" of physical layers with the "light" of digital neon. It utilizes rich charcoal backgrounds, vibrant mesh gradients, and translucent glass panes to create a sense of infinite space. The emotional response is one of calm authority, precision, and technological prestige.

## Colors

The palette is anchored in a true-dark spectrum. The background is a deep charcoal (#0A0A0A) layered with subtle, low-opacity mesh gradients in Deep Emerald and Royal Blue to provide organic movement.

- **Primary & Secondary:** Deep Emerald (#0F766E) and Teal (#0D9488) are used for high-intent actions and active states, often accompanied by a soft outer glow (drop-shadow).
- **Accents:** Royal Blue (#3B82F6) is reserved for data visualization highlights and informational micro-interactions.
- **Feedback:** Amber and Crimson provide high-contrast alerts against the dark backdrop, ensuring critical information is never missed.

## Typography

This design system utilizes **Outfit** for all headings to provide a modern, geometric, and geometric-chic personality. It pairs with **Inter** for body copy and UI labels to ensure maximum legibility at small sizes within dense data tables and sidebars.

Headlines should use tight letter-spacing to maintain a "high-fashion" tech aesthetic. Labels and captions should use slightly increased tracking for clarity against the dark, translucent backgrounds.

## Layout & Spacing

The layout follows a fluid 12-column grid for the main content area, with a fixed-width sidebar (280px) that utilizes a vertical "glass rail" design. 

Spacing is governed by an 8px rhythmic scale. Extensive use of "safe margins" (40px on desktop) ensures that the glass containers have room to breathe, allowing the background mesh gradients to remain visible and maintain the sense of depth. On mobile, the sidebar collapses into a bottom-anchored tab bar or a full-screen glass overlay.

## Elevation & Depth

Hierarchy is established through cumulative blur and border luminosity rather than traditional shadows.

1.  **Level 0 (Background):** Deep charcoal with slow-moving, large-scale radial gradients (15% opacity).
2.  **Level 1 (Cards/Panes):** `backdrop-filter: blur(16px)` with a 1px solid border at `rgba(255,255,255,0.1)`.
3.  **Level 2 (Modals/Popovers):** `backdrop-filter: blur(32px)` with a more prominent 1px border and a subtle inner glow.
4.  **Interactive Elements:** Active buttons and selected states use "Neon Accents"—thin 1px gradients on the border (Teal to Royal Blue) and a `box-shadow` glow with a 20px spread.

## Shapes

The design system employs a "Rounded" (0.5rem) base radius to soften the high-tech aesthetic and make the glass panes feel like polished tablets. Larger containers (cards, main dashboard areas) should use `rounded-xl` (1.5rem) to emphasize the "floating" nature of the glass surfaces. Interactive components like chips and toggle switches use pill-shapes to contrast against the structured grid of the cards.

## Components

- **Buttons:** Primary buttons use a solid Deep Emerald background with a subtle "inner-light" top border. Secondary buttons are ghost-style with a white-translucent border that glows on hover.
- **Glass Cards:** The signature component. Must include `backdrop-filter: blur(16px)` and a top-down linear gradient border (white-translucent to transparent).
- **Inputs:** Darker than the card background (10% opacity white) with a bottom-accent border that illuminates in Teal when focused.
- **Micro-Interactions:** Use spring physics for all hover states. When a user hovers over a glass card, the border opacity should increase from 0.1 to 0.25, and the backdrop-blur should intensify.
- **Data Visuals:** Charts should use semi-transparent fills and glowing line-strokes, utilizing the Primary Teal and Royal Blue accents.
- **Sidebar:** A full-height glass pane with a sharp right-side border. Active links use a vertical "neon-indicator" on the far left.