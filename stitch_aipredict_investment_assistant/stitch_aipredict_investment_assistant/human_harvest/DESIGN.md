# Design System Strategy: The Human-Centric Investor

## 1. Overview & Creative North Star: "The Digital Sanctuary"
This design system rejects the frantic, high-frequency aesthetic of traditional fintech. Instead, it follows the Creative North Star of **"The Digital Sanctuary."** The goal is to transform complex financial data into a serene, editorial experience that feels like reading a premium lifestyle magazine rather than a terminal.

We break the "standard app template" by embracing **intentional asymmetry** and **tonal depth**. Instead of rigid grids, we use generous whitespace (breathing room) and overlapping elements to create a sense of organic growth. The UI should feel like a physical desk—layers of high-quality paper and frosted glass stacked purposefully. This approach replaces "high-tech complexity" with "high-end clarity."

---

## 2. Colors: Tonal Atmosphere
Our palette moves away from "Bank Blue" and "AI Neon" toward an organic, earthy spectrum.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to section off content. 
Structure must be defined exclusively through:
*   **Background Shifts:** Placing a `surface-container-lowest` card against a `surface-container-low` background.
*   **Tonal Transitions:** Using soft gradients between `primary` and `primary-container` to guide the eye.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the surface tiers to create "nested importance":
*   **Base Layer:** `surface` (#fdf9f4) for the main canvas.
*   **Sectioning:** `surface-container-low` (#f7f3ef) for secondary content areas.
*   **Interactive Focus:** `surface-container-lowest` (#ffffff) for primary cards to make them "pop" naturally.

### The "Glass & Gradient" Rule
To ensure the app feels bespoke:
*   **Glassmorphism:** Use semi-transparent `surface` colors with a 20px+ backdrop-blur for floating navigation or modal overlays.
*   **Signature Textures:** Apply subtle linear gradients (e.g., `primary` to `primary_container`) on large CTAs. This adds a "soul" to the UI that flat colors cannot replicate.

---

## 3. Typography: Editorial Authority
We utilize two distinct typefaces to balance friendliness with financial precision.

*   **Display & Headlines (Plus Jakarta Sans):** This is our "Editorial" voice. The rounded geometry feels modern and approachable. Use `display-lg` and `headline-md` with generous tracking to create a premium, spacious feel.
*   **Body & Labels (Manrope):** Chosen for its high legibility in dense data. `body-lg` is your workhorse for investment descriptions. `label-sm` should be used sparingly for metadata, always in `secondary` (#5f5e59) to maintain hierarchy.

**Hierarchy Tip:** Never center-align long-form text. Maintain a strong left-aligned axis to create an "anchor" for the user's eye amidst the asymmetrical layout.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "digital." We mimic natural light.

*   **The Layering Principle:** Achieve depth by "stacking." A `surface-container-lowest` object placed on `surface-container` creates a soft, tactile lift.
*   **Ambient Shadows:** For floating elements (like an investment FAB), use an extra-diffused shadow: `blur: 40px`, `spread: 0`, `opacity: 6%`. The shadow color must be a tinted version of `on-surface` (#1c1b19), never pure black.
*   **The "Ghost Border" Fallback:** If a boundary is vital for accessibility, use the `outline-variant` (#bdc9c8) at **15% opacity**. This creates a "suggestion" of a line rather than a hard barrier.
*   **Tactile Curvature:** Follow the **20px+ rule**. Use `lg` (2rem) for main cards and `xl` (3rem) for parent containers to reinforce the organic, human-centric feel.

---

## 5. Components: The Tactile Kit

### Buttons
*   **Primary:** High-pill shape (`rounded-full`). Background: `primary` (#036565). No shadow; use a subtle gradient to `primary-container`.
*   **Secondary:** `surface-container-highest` background with `on-surface` text.
*   **Tertiary (Coral Accent):** Use `tertiary` (#9e380d) for "Action-Required" moments. It should be used sparingly to draw the eye without creating alarm.

### Cards & Lists
*   **The "Anti-Divider" Rule:** Forbid 1px horizontal lines. Use `1.5rem` (md) vertical spacing or a subtle shift to `surface-container-low` to separate items.
*   **Investment Cards:** Should use `surface-container-lowest` with a `lg` (2rem) corner radius. Data visualizations (charts) should be "borderless," bleeding to the edges of the card.

### Input Fields
*   **Soft Inputs:** Replace harsh boxes with `surface-container-high` backgrounds and `rounded-md` (1.5rem) corners. The active state should transition to a `primary` ghost border (20% opacity) rather than a thick line.

### Additional Signature Components
*   **The "Growth Petal":** Instead of a standard progress bar, use an organic, thick-stroke path using `primary` to show investment maturity.
*   **Contextual Tooltips:** Use Glassmorphism (backdrop-blur) with `on-surface` text to provide "AI insights" that feel like a whisper, not a shout.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use asymmetrical margins (e.g., 24px left, 32px right) for editorial layouts.
*   **Do** lean into the "Warm White" (`surface`) background; it reduces eye strain and feels more prestigious than pure white.
*   **Do** use `tertiary` (Coral) for "Buy" actions to make the experience feel energetic and human.

### Don't:
*   **Don't** use pure black (#000000) for text. Always use `on-surface` (#1c1b19).
*   **Don't** use sharp corners. If it's less than 20px (unless it's a small chip), it's too aggressive for this system.
*   **Don't** use "Dashboard-itis"—avoid cramming 20 charts on one screen. Use vertical scrolling and large typography to tell a story.