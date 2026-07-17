---
name: Clinical Precision
colors:
  surface: '#f9f9ff'
  surface-dim: '#d8d9e3'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3fd'
  surface-container: '#ecedf7'
  surface-container-high: '#e6e8f2'
  surface-container-highest: '#e0e2ec'
  on-surface: '#191c23'
  on-surface-variant: '#414754'
  inverse-surface: '#2d3038'
  inverse-on-surface: '#eff0fa'
  outline: '#727785'
  outline-variant: '#c1c6d6'
  surface-tint: '#005bc0'
  primary: '#005bbf'
  on-primary: '#ffffff'
  primary-container: '#1a73e8'
  on-primary-container: '#ffffff'
  inverse-primary: '#adc7ff'
  secondary: '#585f6c'
  on-secondary: '#ffffff'
  secondary-container: '#dce2f3'
  on-secondary-container: '#5e6572'
  tertiary: '#9e4300'
  on-tertiary: '#ffffff'
  tertiary-container: '#c55500'
  on-tertiary-container: '#0e0200'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc7ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#dce2f3'
  secondary-fixed-dim: '#c0c7d6'
  on-secondary-fixed: '#151c27'
  on-secondary-fixed-variant: '#404754'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb691'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#783100'
  background: '#f9f9ff'
  on-background: '#191c23'
  surface-variant: '#e0e2ec'
  canvas-light: '#F8F9FB'
  pure-surface: '#FFFFFF'
  primary-ink: '#1F2937'
  whisper-border: '#E5E7EB'
  primary-light-blue: '#E8F0FE'
  status-success: '#059669'
  status-warning: '#D97706'
  status-error: '#DC2626'
  status-completed: '#7C3AED'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  desktop-margin: 2rem
  desktop-gutter: 1.5rem
  mobile-margin: 1rem
  touch-target-min: 44px
---

# Design System: Smart Clinic Management System

## 1. Visual Theme & Atmosphere
A clean, trustworthy, and editorial medical SaaS design system. The atmosphere is professional, clinical, and comforting — balancing soft backgrounds with crisp structure to minimize cognitive load for healthcare staff and doctors. It uses precise layouts, functional dividers, and comfortable whitespace (Daily App Balanced density) with modern, subtle depth.

## 2. Color Palette & Roles
- **Canvas Light** (#F8F9FB) — Primary background surface, airy and calm.
- *(Pure Surface** (#FFFFFF) — Card background, dialog surface, elevated areas.
- **Primary Ink** (#1F2937) — Primary text, headings, dark gray depth.
- **Secondary Muted** (#6B7280) — Subtitles, descriptive text, metadata.
- **Whisper Border** (#E5E7EB) — Standard thin dividers, 1px card borders.
- **Primary Blue** (#1A73E8) — Active states, primary action buttons, focus indicator.
- **Primary Light Blue** (#E8F0FE) — Hover states, background highlights, subtle badges.
- **Status Success** (#059669) — Muted green for confirmed appointments.
- **Status Warning** (#D97706) — Amber for pending states.
- **Status Error** (#DC2626) — Red for cancellations and error highlights.
- **Status Completed** (#7C3AED) — Muted purple for completed visits.

*No neon glows, no dark purple gradients, no warm/cool grey fluctuations.*

## 3. Typography Rules
- **Display & Headlines:** Cairo (Google Font) — Track-tight, controlled scale. Heavy weight (Bold/ExtraBold) for section anchors, primary titles. Left-aligned for tabular/grid views, right-aligned (RTL) for Arabic language blocks.
- **Body & Labels:** Cairo — Muted color, relaxed leading (1.5 to 1.6), maximum 65 characters per line to ensure optimal legibility.
- **Mono:** JetBrains Mono — Reserved exclusively for patient numbers, billing IDs, invoice prices, timestamps, and technical metrics.
- **Banned:** Inter (generic AI tell), generic serif fonts (Times New Roman, Garamond).

## 4. Component Stylings
- **Buttons:** Flat surfaces, 10px rounded corners. Primary buttons use solid Primary Blue with white text. Secondary buttons use transparent fill with 1px border. No shadows, no neon outer glows. 
- **Cards:** 12px rounded corners, flat borders (1px Whisper Border) or extremely soft diffused shadow (rgba(0,0,0,0.04)). Avoid stacking cards inside cards; use negative space or thin dividers for internal structures.
- **Inputs:** Label above the input field, light gray background fill, placeholder text in neutral gray. Focus ring outlines in Primary Blue. No floating labels.
- **Loaders:** Custom skeletal loaders matching the exact dimensions of cards/elements. Circular progress indicators are restricted to small button states.
- **Empty States:** Composed illustration or icon composition with high-contrast text and a direct call to action.

## 5. Layout Principles
- **Grid Architecture:** 12-column desktop grid collapsing to single-column on mobile. No exceptions.
- **Alignment:** RTL layout by default for Arabic clinics. The primary action area is placed on the top-left, and headers/labels align to the right.
- **Spatial Separation:** All elements occupy their own clear spatial zones. No absolute-positioned overlaps.
- **Feature Rows:** Banned 3 equal horizontal cards. Use asymmetrical layouts (e.g., 2/3 main dashboard area, 1/3 quick stats/activity list).
- **Responsive Safety:** touch target size minimum 44px on mobile devices. No horizontal page overflow.

## 6. Motion & Interaction
- **Spring Physics:** `stiffness: 100, damping: 20` for all screen transitions, list items, and modal mounts to create a weighty, premium physical feedback.
- **Cascade Orchestration:** Lists (e.g., today's appointments) waterfall reveal with a 50ms stagger delay per item.
- **Transforms Only:** Animate strictly using hardware-accelerated properties (`transform: translate/scale` and `opacity`). Never animate width, height, or absolute top/left coordinates.

## 7. Anti-Patterns (Banned)
- No emojis anywhere in professional views.
- No Inter font.
- No pure black (#000000).
- No oversaturated primary accents or gradients.
- No AI copywriting clichés ("seamlessly manage", "next-gen dashboard").
- No generic placeholder names ("John Doe", "Acme Corp").
- No broken image links — use clean SVG/Vector medical symbols or high-quality avatars.
