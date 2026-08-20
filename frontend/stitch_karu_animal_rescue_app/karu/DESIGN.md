---
name: Karuṇā
colors:
  surface: '#f8f9ff'
  surface-dim: '#d1dbec'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dfe9fa'
  surface-container-highest: '#d9e3f4'
  on-surface: '#121c28'
  on-surface-variant: '#3e4947'
  inverse-surface: '#27313e'
  inverse-on-surface: '#eaf1ff'
  outline: '#6e7977'
  outline-variant: '#bdc9c6'
  surface-tint: '#006a63'
  primary: '#005c55'
  on-primary: '#ffffff'
  primary-container: '#0f766e'
  on-primary-container: '#a3faef'
  inverse-primary: '#80d5cb'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dfe0e0'
  on-secondary-container: '#616363'
  tertiary: '#893a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#af4c00'
  on-tertiary-container: '#ffe6da'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9cf2e8'
  primary-fixed-dim: '#80d5cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#00504a'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb690'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#783200'
  background: '#f8f9ff'
  on-background: '#121c28'
  surface-variant: '#d9e3f4'
typography:
  display-lg:
    fontFamily: EB Garamond
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: EB Garamond
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: EB Garamond
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '700'
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
  base: 8px
  xs: 4px
  sm: 12px
  md: 20px
  lg: 32px
  xl: 48px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style
The design system is rooted in the Sanskrit concept of *Karuṇā* (compassion). It balances the urgency of animal rescue with a serene, modern Indian aesthetic that feels both professional and deeply empathetic. 

The style is **Modern Minimalist with a Humanist touch**. It avoids cluttered "NGO" tropes in favor of expansive white space, precise typography, and subtle organic patterns inspired by Indian textiles and architecture. The emotional response should be one of "Calm Reliability"—users should feel that the app is a stable, high-tech platform capable of handling emergencies, while remaining approachable and warm.

- **Minimalism:** Use generous margins and clear content hierarchies to prevent cognitive overload during stressful rescue situations.
- **Modern Indian Aesthetic:** Subtle use of geometric patterns (Jali) as background watermarks and a palette that favors deep, earth-toned teals against pristine white.
- **Compassionate Tone:** Photography should be high-quality, focusing on successful rescue stories and the bond between humans and animals.

## Colors
The palette is anchored by **Dark Teal**, representing stability and the natural world. This is contrasted against a dominant **White** base to ensure a clean, medical-grade clarity for the rescue interface.

- **Primary (Dark Teal):** Used for primary actions, headers, and brand moments.
- **Secondary (White):** The primary surface color, providing a sense of purity and space.
- **Accent (Saffron/Orange):** A tertiary color (#F97316) used sparingly for "Urgent" or "Emergency" status indicators, drawing from traditional Indian color symbolism without being overwhelming.
- **Neutral:** Cool grays are used for secondary text and borders to maintain a sophisticated, modern feel.

## Typography
This design system employs a sophisticated serif-sans pairing to reflect its dual nature: the serif for heritage and heart, and the sans-serif for utility and precision.

- **Headline Font (EB Garamond):** Used for brand identity, screen titles, and impactful storytelling. It brings a literary, authoritative, and compassionate quality.
- **Body & UI Font (Hanken Grotesk):** A clean, contemporary sans-serif used for all functional elements. Its high legibility is crucial for data-heavy rescue forms.
- **Usage Note:** Maintain high contrast between headlines (Teal) and body text (Neutral Gray/Black). Use `label-caps` for metadata like "Rescue ID" or "Location Stamp."

## Layout & Spacing
The layout follows a **fluid grid** model optimized for mobile-first interactions, using an 8px base unit.

- **Mobile:** 4-column grid with 20px side margins and 16px gutters.
- **Content Density:** Elements are given ample "breathing room" (20px-32px padding) to ensure the UI feels calm and navigable.
- **Safe Areas:** Adhere strictly to mobile safe areas for bottom navigation and top status bars, ensuring that critical "Report Emergency" buttons are always within the natural thumb zone.

## Elevation & Depth
Depth is created through **Tonal Layering** and soft, ambient shadows. 

- **Surface Levels:** The base layer is pure white (#FFFFFF). Cards and containers use a very subtle off-white or a 1px border (#E5E7EB) to distinguish themselves.
- **Shadows:** Avoid harsh, black shadows. Use soft, diffused shadows with a slight teal tint to lift primary action buttons and floating emergency triggers.
- **Interactive Depth:** When pressed, elements should appear to sink slightly (decrease elevation) to provide tactile feedback.

## Shapes
The shape language is **Softly Rounded**, reflecting the friendliness and safety of the brand.

- **Standard Elements:** Buttons and input fields use a 0.5rem (8px) radius.
- **Cards & Large Containers:** Use a 1rem (16px) radius to feel approachable and modern.
- **Icons:** Use rounded terminals and consistent stroke weights (2px) to match the Hanken Grotesk typeface. Avoid sharp corners in iconography.

## Components
- **Buttons:** Primary buttons are solid Dark Teal with White text. Secondary buttons use a Teal outline with a transparent background. 
- **Emergency Action:** The "Report Animal in Distress" button is a floating action button (FAB) using the Saffron accent color to ensure immediate visibility.
- **Cards:** Used for rescue listings. Cards feature a top-aligned image with a 16px corner radius, followed by title and status chips.
- **Chips:** Status indicators (e.g., "Safe", "Critical", "In Treatment") use low-saturation background colors with high-saturation text for readability.
- **Input Fields:** Minimalist design with a bottom-border focus state in Dark Teal. Labels always remain visible (floating label style) to assist users in high-stress situations.
- **Progress Steppers:** Used for rescue tracking. Vertical steppers with soft nodes to indicate the animal's journey from "Reported" to "Adopted."