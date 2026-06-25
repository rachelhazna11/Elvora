# Phase 05: AI Style Match — UI Specification

## 1. Brand Identity Alignment
- **Aesthetic**: Quiet Luxury, Minimalist, Editorial.
- **Palette**: Ivory (#FAFAF7), Beige (#F5F0E8), Charcoal (#2D2D2D), Sage (#8A9E8E).
- **Typography**: Playfair Display (Serif) for headlines, Poppins (Sans-serif) for body.

## 2. Style Match Landing Page (`style-match.html`)

### 2.1 Hero Section
- **Background**: Soft beige or a faded lifestyle image of someone styling an outfit.
- **Headline**: "Find Your Perfect Match" (Playfair Display).
- **Subheadline**: "Our AI-powered stylist analyzes your coloring and preferences to curate your ultimate active wardrobe."
- **CTA**: "Begin Style Analysis" (Smooth scroll to form).

### 2.2 Step Overview
- 3 icons/images with short labels:
  1. **Upload**: Share a photo for color analysis.
  2. **Select**: Tell us your activity and fit preferences.
  3. **Discover**: Receive 3 curated outfits from the Elvora catalog.

### 2.3 The Analysis Form
- **State management**: Alpine.js `x-data="{ step: 1, photo: null, prefs: { ... }, loading: false, result: null }"`.
- **Photo Area**:
  - Dotted border box.
  - Preview after upload.
  - "Clear Photo" button.
- **Preference Selectors**:
  - Activity Chips: Padel, Pilates, Tennis, Training, Running (Multi-select).
  - Fit Chips: Fitted, Relaxed, Longline (Single-select).
  - Aesthetic Chips: Minimal, Sporty, Editorial (Single-select).
  - Colour Chips: Neutral, Earth, Sage, Monochrome (Single-select).

### 2.4 Loading State
- Centered spinner.
- Fade-in messages: "Analysing your style preferences...", "Exploring the Elvora collection...", "Curating your outfits...".

### 2.5 Results Display
- **Layout**: Grid of 2–3 "Outfit Combinations".
- **Outfit Card**:
  - Name (e.g., "The Morning Padel Set").
  - Horizontal scroll or small grid of 2–3 product cards.
  - **Product Card**: Image, name, price, link.
- **Colour Guidance**:
  - A dedicated "Stylist's Note" section.
  - Text: "Your ivory and sage combinations complement your cool undertones beautifully."

## 3. Interaction Details
- **Mobile**: Single column for form and results.
- **Transitions**: Smooth fade-in for results using `x-transition`.
- **Toasts**: Success "Analysis complete", Error "Something went wrong".

## 4. Traceability
- **F-030**: Landing page structure.
- **F-031**: Photo upload UI.
- **F-032**: Visual selector chips.
- **F-033**: Recommendation rendering.
- **F-034**: Colour guidance display.
