# Execut App Design System & Color Palette

This document outlines the core design tokens, typography, and color palettes for the Execut habit tracker application.

## Overview
The design prioritizes a high-contrast, premium tech aesthetic with a pitch-black background, structured dark card layouts, and vibrant functional accents (emerald green, warm amber, violet purple). This design matches the look and feel established in `temp.html`.

---

## 🎨 Color Palette

### 🌙 Dark Mode (Primary Mode)
*A sleek, dark, premium interface with rich accent glows.*

| Token | Color (Hex) | Description |
| :--- | :--- | :--- |
| **Background (Main)** | `#080808` | Pitch black background to minimize screen glare and highlight neon elements. |
| **Surface (Cards/Tabs)** | `#111111` | Primary cards, stats boxes, and elevated surfaces. |
| **Surface Level 2** | `#181818` | Slightly lighter dark background for banners, secondary tabs, or nested list cards. |
| **Surface Level 3** | `#1E1E1E` | Used for active/hover states or input borders. |
| **Primary Text** | `#F0F0EE` | Off-white text to provide high readability without harshness. |
| **Secondary Text** | `#777777` | Medium gray for helper text, labels, and timestamps. |
| **Muted Text / Border** | `#3A3A3A` | Very dark gray for deeply secondary indicators and background text. |
| **Border / Divider** | `#1E1E1E` | Subtle separations between screens and components. |
| **Primary Accent (Green)** | `#1D9E75` | Emerald green for primary actions, success status, level completion, and active navigation. |
| **Secondary Accent (Muted Green)** | `#5A8F76` | Muted green for side quests and secondary actions. |
| **Tertiary Accent (Purple)** | `#7C6FCD` | Violet purple for Boss Challenges. |
| **Error / Destructive (Red)** | `#C94040` | Crimson red for destructive actions and warning statuses. |

#### Accompanying Dim/Mid Colors (for Dark Mode card backgrounds & borders):
- **Green Dim / Mid:** `#0A2A1E` / `#0F5A3F` (Used for completed/positive card backgrounds and glows)
- **Muted Green Dim:** `#11241C` (Used for side quest card status highlights)
- **Purple Dim:** `#1A1530` (Used for boss challenge card styling)
- **Red Dim:** `#2A0F0F` (Used for failure risk cards)

---

### 🌞 Light Mode
*A clean, high-contrast light counterpart.*

| Token | Color (Hex) | Description |
| :--- | :--- | :--- |
| **Background (Main)** | `#FAFAFA` | Off-white canvas. |
| **Surface (Cards)** | `#FFFFFF` | Pure white cards. |
| **Surface Level 2** | `#F0F0F0` | Cool gray for text fields and layout containers. |
| **Primary Text** | `#080808` | High contrast charcoal black. |
| **Secondary Text** | `#777777` | Muted cool gray. |
| **Border / Divider** | `#E5E5E5` | Clean, subtle borders. |
| **Primary Accent (Green)** | `#1D9E75` | Emerald green for active actions and main buttons. |
| **Secondary Accent (Muted Green)** | `#436B59` | Muted green for side quests and secondary actions. |
| **Tertiary Accent (Purple)** | `#7C6FCD` | Violet purple for special items. |
| **Error / Destructive** | `#C94040` | Clean red for errors. |

---

## 📐 Typography & Spacing

To create a premium tech-oriented interface:

- **Typefaces:**
  - *Display / Titles / Logo / Key Stats:* `Syne` (vibrant, modern geometric sans-serif for striking headers).
  - *Body / Long Text / Messages:* `DM Sans` (highly legible geometric sans-serif).
  - *Status Labels / Levels / Timelines:* `DM Mono` (monospaced look for stats-driven execution elements).
- **Border Radius:**
  - Standard cards and container elements use `14px` (`--radius`).
  - Small chips, status badges, and sub-cards use `10px` (`--radius-sm`).
  - Input fields use `12px`.
  - Profile icons and circle indicators are `50%` rounded.
- **Borders & Shadows:**
  - All elements use explicit `0.5px` or `1px` borders instead of heavy drop shadows.
  - Accent colors use subtle glow glows (e.g., `rgba(29, 158, 117, 0.12)`) to convey elevation.
