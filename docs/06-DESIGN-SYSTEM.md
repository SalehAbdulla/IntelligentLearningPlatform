# 06, Design System

> **One source of truth for Figma and SwiftUI.** The Figma variables and `DesignSystem.swift` are generated from the same token list, which is how we guarantee the prototype and the app can never visually drift. This parity is itself an Innovation talking point.

---

## 1. Foundations

### 1.1 Colour

Contrast ratios below are computed against the WCAG 2.2 relative-luminance formula. **Ratios are stated deliberately**, a marker checking UI/UX practice can verify them.

**Light mode**

| Token | Hex | Usage | Contrast on `surface` | WCAG |
|---|---|---|---|---|
| `primary` | `#0062CC` | Primary buttons, active tabs, links | 5.8:1 | ✅ AA |
| `primaryContainer` | `#E1F0FF` | Selected chips, highlight backgrounds | - | fill only |
| `onPrimaryContainer` | `#00427A` | Text on `primaryContainer` | 8.8:1 | ✅ AAA |
| `accent` (Ember) | `#F97316` | Streak flame, AI actions, "generate" affordances | 2.8:1 | ⚠️ **fill/graphic only** |
| `onAccent` | `#0F172A` | Text placed on Ember fills | 6.4:1 | ✅ AA |
| `accentGold` | `#FACC15` | Achievement badges, highlights | - | decor only |
| `secondary` (Teal) | `#14B8A6` | Collaboration surfaces, group spaces | 2.3:1 | ⚠️ fill only |
| `success` | `#10B981` | Correct-answer fill, success states | 2.5:1 | ⚠️ fill only |
| `successText` | `#047857` | Success **text** | 5.5:1 | ✅ AA |
| `secondaryText` | `#0F766E` | Teal **text** (group, "active" stats) | 5.5:1 | ✅ AA |
| `accentText` | `#C2410C` | Ember **text** (mastery, "generate" stats) | 5.2:1 | ✅ AA |
| `warningText` | `#B45309` | Amber **text** (quota, at-risk stats) | 5.0:1 | ✅ AA |
| `warning` | `#F59E0B` | Quota warnings, low-confidence flags | 2.2:1 | ⚠️ fill only |
| `error` | `#DC2626` | Destructive actions, incorrect answers | 4.8:1 | ✅ AA |
| `surface` | `#FFFFFF` | Base background | - | - |
| `surfaceVariant` | `#F8FAFC` | Cards, grouped sections | - | - |
| `outline` | `#E2E8F0` | Dividers, input borders | - | - |
| `textPrimary` | `#0F172A` | Headings, body | **17.9:1** | ✅ AAA |
| `textSecondary` | `#475569` | Supporting copy | 7.6:1 | ✅ AAA |
| `textTertiary` | `#94A3B8` | Disabled / decorative only, **never body text** | 2.6:1 | ❌ not for text |

**The single most important colour rule, and the one most teams get wrong:**

> **Ember `#F97316` and the semantic fills are *fill* colours, not *text* colours.** White text on Ember fails AA (2.8:1). Any label sitting on an Ember or success fill must use `onAccent` `#0F172A`. This is documented so the rule is followed consistently rather than re-litigated per screen.
>
> **When the hue itself is the text, use its text-safe variant, never the fill.** As text, `secondary`, `accent` and `warning` measure 2.1:1 to 2.8:1, below even the 3:1 large-text bar. `secondaryText` `#0F766E`, `accentText` `#C2410C` and `warningText` `#B45309` are the same hues darkened to clear AA: 5.5:1, 5.2:1 and 5.0:1 on `surface`, and 5.2:1, 4.9:1 and 4.8:1 on the worst case (a `glass/surface` layout card over the most tinted point of the canvas). This mirrors the existing `success`/`successText` pair, and the fix was applied to the five dashboard statistics that used a fill hue as text and to the ten text labels across the app that did the same.

**Why blue, and why no purple (Apple system palette)**

The brief asks for an iOS-native feel, so the palette is built on the Apple system-blue family rather than a bespoke gradient palette. The previous revision used an indigo/violet brand palette, and a violet-to-pink ramp is the visual signature of generic AI-generated UI, which is exactly how it read on the light canvas.

Brand blue is `#0062CC`. Apple's showcase blues were measured and rejected on contrast rather than on taste: `#007AFF` is 4.0:1 on white, and `#0071E3` is 4.7:1 on white but only **4.02:1 on the tinted canvas**. That matters because `primary` is used as *text* in 26 places (links such as "Forgot password?", active tab labels), not only as a button fill. `#0062CC` measures 5.80:1 on white, 5.55:1 on `surfaceVariant`, 5.00:1 on `primaryContainer` and 4.97:1 on the most tinted point of the canvas, so `primary` clears AA as text everywhere it appears, including over the glass and the ambient wash. White text on a `primary` button improves to 5.80:1 as a side effect.

The decorative backdrop glows are restricted to one cool family (blue `#0062CC` / sky `#32ADE6` / teal `#30B0C7`) at **24% alpha**, so the canvas reads as neutral glass rather than a tinted wash. No hue anywhere in the product sits between 215° and 350°, which is the band that makes an interface read as "AI purple".

**Dark mode**

| Token | Hex | Contrast on `#0B1220` | WCAG |
|---|---|---|---|
| `surface` | `#0B1220` | - | - |
| `surfaceVariant` | `#131C2E` | - | - |
| `outline` | `#263149` | - | - |
| `primary` | `#0A84FF` | 5.1:1 | ✅ AA |
| `accent` | `#FB923C` | fill only | - |
| `textPrimary` | `#F1F5F9` | 16.9:1 | ✅ AAA |
| `textSecondary` | `#CBD5E1` | 11.2:1 | ✅ AAA |
| `success` | `#34D399` | 8.6:1 | ✅ AA |
| `secondaryText` | `#5EEAD4` | 12.7:1 | ✅ AAA |
| `accentText` | `#FDBA74` | 11.1:1 | ✅ AAA |
| `warningText` | `#FCD34D` | 13.0:1 | ✅ AAA |
| `error` | `#F87171` | 6.7:1 | ✅ AA |

**Subject colour coding** (used by course tags, calendar blocks, radar axes, 8 hues, all AA against both surfaces when used as fills with `onAccent` labels): blue, teal, rose, amber, mint, cyan, lime, slate. Deliberately excludes violet and pink, so a stack of course tags still cannot assemble itself into an AI-looking gradient.

### 1.2 Typography

System font (SF Pro) so Dynamic Type and Arabic glyph shaping come free. **No custom font for Latin text**, a deliberate accessibility decision.

| Style | Size / Line | Weight | Tracking | Usage |
|---|---|---|---|---|
| `displayL` | 34 / 41 | Bold | −0.4 | Splash, big numbers, score rings |
| `titleL` | 28 / 34 | Bold | −0.3 | Screen titles |
| `titleM` | 22 / 28 | Semibold | −0.2 | Section headers, card titles |
| `titleS` | 17 / 22 | Semibold | −0.1 | List row titles, tab labels |
| `body` | 17 / 24 | Regular | 0 | Default body |
| `bodyEmph` | 17 / 24 | Semibold | 0 | Emphasis |
| `callout` | 16 / 21 | Regular | 0 | Secondary body |
| `subhead` | 15 / 20 | Semibold | 0 | Overlines, group headers |
| `footnote` | 13 / 18 | Regular | 0 | Metadata, timestamps |
| `caption` | 12 / 16 | Regular | +0.1 | Chips, badges |
| `mono` | 15 / 20 | Regular (SF Mono) | 0 | OTP codes, invite codes, charge refs |

**Rules:** minimum body size **17 pt** · minimum tappable label **13 pt** · never below 11 pt anywhere · all text scales with Dynamic Type up to **AX5** · the dyslexia-friendly option increases line-height by 40% and letter-spacing by 5% while keeping the same size ladder · for Arabic, line-height increases by 15% and tracking is set to 0 (Arabic must never be negatively tracked).

### 1.3 Spacing, radius, elevation

**Spacing, a strict 4 pt grid.** Only these values are permitted.

| Token | px | Typical use |
|---|---|---|
| `space1` | 4 | Icon ↔ label |
| `space2` | 8 | Inside chips and badges |
| `space3` | 12 | Tight card padding, list-row vertical |
| `space4` | 16 | **Default** screen margin, card padding |
| `space5` | 20 | Between related groups |
| `space6` | 24 | Between sections |
| `space8` | 32 | Before major headings |
| `space10` | 40 | Empty-state spacing |
| `space12` | 48 | Above primary CTAs |

**Layout rules:** screen horizontal margin **16 pt** · content max width **640 pt** on iPad · bottom safe-area + 16 pt for tab bars · primary CTA sits in the thumb zone (bottom third) · lists use 16 pt leading/trailing with a 12 pt gap between the icon and text.

**Radius**

| Token | px | Use |
|---|---|---|
| `radiusS` | 8 | Chips, tags, small inputs |
| `radiusM` | 12 | Buttons, text fields, list groups |
| `radiusL` | 16 | Cards, sheets |
| `radiusXL` | 24 | Hero cards, modals |
| `radiusFull` | 999 | Avatars, pills, progress rings |

**Elevation** (iOS-style: subtle, shadow + a 1 pt outline in dark mode)

| Level | Shadow | Use |
|---|---|---|
| `e0` | none, 1 pt `outline` | Flat lists, grouped rows |
| `e1` | y1 blur3 `rgba(15,23,42,.06)` | Cards |
| `e2` | y4 blur12 `rgba(15,23,42,.10)` | FAB, sticky headers, popovers |
| `e3` | y12 blur32 `rgba(15,23,42,.16)` | Modals, sheets, the flashcard in review |

In **dark mode** shadows are replaced by a 1 pt `outline` stroke plus a lifted `surfaceVariant`, shadows are invisible on dark backgrounds, a detail most designs miss.

### 1.4 Motion

| Token | Duration | Curve | Used for |
|---|---|---|---|
| `motionInstant` | 100 ms | ease-out | Press feedback, checkboxes |
| `motionQuick` | 180 ms | ease-out | Tab switch, chip select |
| `motionStandard` | 280 ms | spring(0.35, 0.8) | Card expand, list insert |
| `motionEmphasis` | 420 ms | spring(0.45, 0.7) | Flashcard flip, streak increment, score ring |
| `motionSheet` | 320 ms | spring(0.4, 1.0) | Sheet present / dismiss |

**Rules:** every animation respects **Reduce Motion** (cross-fade instead of motion, no spring bounce) · no animation longer than 500 ms · the flashcard flip is a 3D Y-axis rotation (the single most important "feels real" moment in the app) · **haptics**: light impact on card flip, success notification on quiz completion, warning on destructive confirm.

---

## 2. Component inventory

Built once in Figma with variables, mirrored once in SwiftUI. Every component defines **default / hover-or-focus / pressed / disabled / loading** states.

| Group | Components |
|---|---|
| **Actions** | Primary button · Secondary button · Ghost/tertiary · Destructive · Icon button · FAB · Inline text link · Segmented control |
| **Input** | Text field (with helper + error) · Secure field · Search bar · OTP field · Text area · Number stepper · Slider · Date/time picker · Multi-select chips · Toggle · Checkbox · Radio card |
| **Containment** | Card (e1) · Hero card (e2) · List row (3 variants: navigation, toggle, value) · Grouped section · Sheet · Full-screen modal · Popover · Banner / inline alert · Toast |
| **Data display** | Stat tile · Progress ring · Progress bar · Bar chart · Radar chart · Heatmap · Badge · Chip / tag · Avatar · Avatar stack · Table row · Key-value row |
| **Learning-specific** | **Flashcard** (front/back/rated) · **Quiz option row** (default/correct/incorrect/flagged) · **Due-count badge** · **Mastery dot** · **Provenance citation chip** · **Confidence band** · **Streak flame** · **Subject colour tag** · **Calendar session block** · **AI engine badge** ("On-device · private") · **Timer ring** |
| **Feedback** | Loading skeleton (list/card/chart/reader) · Progress overlay · Empty state · Error state (retry) · Offline banner · Success confirmation · Confirmation dialog · Quota-exceeded state |
| **Navigation** | Tab bar · Nav bar (large + inline title) · Back button · Breadcrumb-free (mobile) · Page dots · Stepper indicator (wizard) |

**Why the learning-specific group matters:** these are the components that make StudyForge feel like a study app rather than a generic CRUD app, and they are the ones markers will look at when judging *"meaningful enhancement of the selected brief"*.

---

## 3. Iconography and imagery

- **SF Symbols** exclusively, weight matched to text weight, size matched to the adjacent text line height. No mixing of icon families, consistency is a stated rubric criterion.
- **Illustrations** only in onboarding, empty states and error states, all from one consistent style (flat, 2-tone, blue + ember) drawn or commissioned once.
- **Photography:** none. Avoids licensing issues and keeps the visual language coherent.
- **Charts:** Swift Charts in the app, matching redrawn vectors in Figma. Radar and heatmap hand-built (Swift Charts has no native radar).

---

## 4. Mapping to the brief's stated design principles

The brief lists specific **Visual Design Principles** and **Interaction & UX Design Practices**. Rather than restate them, here is the concrete decision that satisfies each, this table goes straight into the Design Document as a section, because it lets a marker tick each listed criterion directly.

### 4.1 Visual design principles

| Rubric principle | Our concrete decision |
|---|---|
| **Balance** | Every screen uses a single primary focal element (the hero card) with supporting content weighted below it. Two-column layouts are used only for symmetric pairs: stat tiles (2×2), quiz options (1×4 stacked), and the checkout summary. Numbers and icons are optically centred, not geometrically centred. |
| **Contrast** | Exactly one primary action per screen, rendered in `primary` blue at full saturation. SEMANTIC FILLS (ember/success/error) are used only as fills with `onAccent` text, the AA contrast rule from §1.1. Text hierarchy is carried by weight + size, never by colour alone. |
| **Alignment** | One 16 pt screen margin, one 4 pt spacing grid, one left edge for all text in a group. Icons align to the first text baseline. Cards inside a list share a single left edge across every screen in the app. |
| **Simplicity** | Maximum **5 tab-bar items**. Maximum **7 items** in any settings group. Maximum **2 levels** of navigation depth before a modal is used instead. Every screen must answer "what is the one thing to do here?", if two answers exist, it is split into two screens. |
| **Proximity** | Related controls are grouped in cards with 16 pt internal padding; unrelated groups are separated by 24 pt or a divider. The Generate action sheet groups all four AI outputs together, with the AI engine badge attached directly to the action it describes. |
| **Repetition** | One component library, one icon family (SF Symbols), one radius ladder, one motion ladder. The flashcard, quiz option and progress ring are identical wherever they appear. Nothing is redesigned per screen. |
| **White space** | 16 pt base margin, 24 pt between sections, 40 pt around empty states, and the primary CTA is never crowded, 48 pt of breathing room above it. Deliberately generous: study content is dense, so the chrome must not be. |

### 4.2 Interaction and UX design practices

| Rubric practice | Our concrete decision |
|---|---|
| **Clear Navigation** | A persistent 5-tab spine (Home · Library · Coach · Practise · Plan) with role-specific variants. Every modal has a visible dismiss affordance. No dead ends: every error state offers a next action. Screen depth is capped; the current location is always visible in the nav bar. |
| **Interactive Elements** | Every control has a ≥44×44 pt hit area even when visually smaller. Buttons have pressed states. Destructive actions require confirmation. Long-press reveals contextual actions on artefacts (bookmark, share, generate). |
| **Error & Feedback States** | A complete state set is designed for every screen, see the dedicated state screens `133`–`137` plus `30`, `41`, `50`, `56`, `87`, `98`, `126`. Includes: loading, empty, offline, server error with retry, quota exceeded, invalid input (inline), permission denied, payment declined, and success confirmations with undo where destructive. |
| **Mobile Optimization** | Thumb-zone CTAs, one-handed reachability (no primary action in the top 20% of the screen), large type, no hover dependency, sheets instead of dropdowns, native keyboard types per field (`.emailAddress`, `.numberPad`, `.oneTimeCode`), and predictive back gestures. |
| **Consistency** | Same terminology everywhere ("deck" not "set"; "material" not "document"; "Coach" not "Assistant"). Same component behaviour across roles. The tutor and admin apps use the identical design system, only the information architecture differs. |

### 4.3 Nielsen's heuristics and WCAG, an explicit cross-check

Because the module assesses *"UI and UX best practice"* (LO1), the document includes a table mapping our screens against **Nielsen's 10 usability heuristics** and **WCAG 2.2 AA**. Highlights:

- *Visibility of system status* → streaming generation progress, sync indicators, `137_Loading_Skeleton_Kit`
- *Match between system and real world* → "exam-ready summary", "missed session", "due today", no internal jargon
- *User control and freedom* → every generation is cancellable; every destructive action is undoable or confirmed
- *Consistency and standards* → iOS conventions throughout; no invented gestures
- *Error prevention* → inline validation, confirmation dialogs, disabled states with explanations rather than silent failures
- *Recognition rather than recall* → recent searches, recent folders, prompt suggestions in the Coach
- *Aesthetic and minimalist design* → one primary action per screen
- *Help users recognise, diagnose and recover from errors* → plain-language errors with a reference id and a recovery action
- *Help and documentation* → contextual empty states and inline explainers rather than a separate help section

---

## 5. Accessibility standard (SDG 10 in practice)

| Requirement | Target | How we verify |
|---|---|---|
| Text contrast | **WCAG 2.2 AA** (≥4.5:1 body, ≥3:1 large) | Contrast table in §1.1 + a Figma plugin pass + SwiftUI audit |
| Dynamic Type | Full support to **AX5** | `138_Accessibility_LargeText_Example` + a simulator pass at AX5 |
| Touch targets | **≥44 × 44 pt** everywhere | Overlay grid check on every frame |
| VoiceOver | Every control has a label, value and hint; logical focus order; charts expose a summary | A recorded VoiceOver walkthrough is a Phase 8 gate item |
| Reduce Motion | All animation degrades to cross-fade | Toggle test |
| Colour independence | No information conveyed by colour alone, every status also carries an icon or text label | Review of all state components |
| RTL | Full mirroring via `layoutDirection`; icons that imply direction are flipped; numbers use Arabic-Indic digits where the locale expects it | `139_RTL_Arabic_Example` |
| Dyslexia support | Optional increased line-height (+40%) and letter-spacing (+5%) | Toggle in `20_Settings_Accessibility` |
| Plain language | No jargon in user-facing copy; 8th-grade reading level for error messages | Copy review pass |
| Language | Full EN + AR localisation, no hard-coded strings | `Localizable.strings` completeness check in CI |

**Why this is worth doing properly:** the brief ties StudyForge's brief to **SDG 10 (Reduced Inequalities)**, and LO1 assesses UI/UX best practice. Accessibility is where those two meet, and it is one of the few rubric areas where a competitor group is unlikely to have done any work at all.

---

## 6. Implementation parity (Figma ↔ SwiftUI)

The design system exists in exactly two places and they are kept mechanically in sync:

| Token group | Figma | SwiftUI |
|---|---|---|
| Colour | Variables collection `Color/…` | `enum ColorTokens { static let primary = Color(hex: 0x0062CC) }` |
| Type | Text styles `Type/body` … | `extension Font { static let sfBody = Font.system(size: 17, weight: .regular) }` |
| Spacing | Variables `Space/4` … | `enum Spacing { static let s4: CGFloat = 16 }` |
| Radius | Variables `Radius/M` … | `enum Radius { static let m: CGFloat = 12 }` |
| Motion | Smart-animate presets | `enum Motion { static let emphasis = Animation.spring(response: 0.42, dampingFraction: 0.7) }` |

**Workflow rule:** a token changes in **both** places in the same commit, or it does not change. A short script (`tools/check-tokens.sh`) greps the token names in both files and fails the build if they diverge.

```swift
// DesignSystem/ColorTokens.swift  (shape reference, full file in Phase 6)
enum ColorTokens {
    static let primary            = Color(hex: 0x0062CC)
    static let primaryContainer   = Color(hex: 0xE1F0FF)
    static let accent             = Color(hex: 0xF97316)
    static let onAccent           = Color(hex: 0x0F172A)   // never white on accent, fails AA
    static let textPrimary        = Color(hex: 0x0F172A)
    static let textSecondary      = Color(hex: 0x475569)
    static let surface            = Color(hex: 0xFFFFFF)
    static let surfaceVariant     = Color(hex: 0xF8FAFC)
    static let outline            = Color(hex: 0xE2E8F0)
    static let success            = Color(hex: 0x10B981)
    static let successText        = Color(hex: 0x047857)
    static let secondaryText      = Color(hex: 0x0F766E)
    static let accentText         = Color(hex: 0xC2410C)
    static let warningText        = Color(hex: 0xB45309)
    static let error              = Color(hex: 0xDC2626)
}
```

```swift
// DesignSystem/TypeScale.swift
extension Font {
    static let sfDisplayL = Font.system(size: 34, weight: .bold)
    static let sfTitleL   = Font.system(size: 28, weight: .bold)
    static let sfTitleM   = Font.system(size: 22, weight: .semibold)
    static let sfTitleS   = Font.system(size: 17, weight: .semibold)
    static let sfBody     = Font.system(size: 17, weight: .regular)
    static let sfCallout  = Font.system(size: 16, weight: .regular)
    static let sfFootnote = Font.system(size: 13, weight: .regular)
    static let sfCaption  = Font.system(size: 12, weight: .regular)
    static let sfMono     = Font.system(size: 15, weight: .regular, design: .monospaced)
}
```

```swift
// DesignSystem/Spacing.swift
enum Spacing { static let s1: CGFloat = 4;  static let s2: CGFloat = 8
               static let s3: CGFloat = 12; static let s4: CGFloat = 16
               static let s5: CGFloat = 20; static let s6: CGFloat = 24
               static let s8: CGFloat = 32; static let s10: CGFloat = 40
               static let s12: CGFloat = 48 }

enum Radius  { static let s: CGFloat = 8; static let m: CGFloat = 12
               static let l: CGFloat = 16; static let xl: CGFloat = 24 }
```



