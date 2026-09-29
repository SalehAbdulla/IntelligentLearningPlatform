# iOS app — StudyForge

> **This is the 60% must-pass deliverable.** iOS App Implementation & Demonstration,
> assessed through the completed app and an in-person VIVA.
> See [docs/11-APP-IMPLEMENTATION-VIVA.md](../docs/11-APP-IMPLEMENTATION-VIVA.md).

Xcode 27 · SwiftUI · Swift 6 · **iOS 26.0** deployment target · MVVM with `@Observable`.
Coding rules, folder conventions and the Cline working agreement: [docs/04 §8](../docs/04-TECH-ARCHITECTURE-COST.md).

---

## Status — Sprint S0 scaffold ✅

The project builds clean on a first attempt and renders a design-system gallery.

| Layer | State |
|---|---|
| Xcode project (`objectVersion 77`, synchronised file groups) | ✅ builds, zero warnings |
| Shared scheme (`StudyForge`) | ✅ committed so CI and every machine behave identically |
| App entry + `RootView` routing shell | ✅ |
| `AppContainer` dependency injection | ✅ no singletons |
| `LoadState` + `AppError` (loading/empty/failed states) | ✅ |
| Design tokens — colour, type, spacing, radius, motion | ✅ mirrors the Figma variables |
| Design-system gallery | ✅ proves the tokens in light and dark |
| Auth, features, Firebase wiring | ⬜ Sprint S1 |

## Layout

```
ios/StudyForge/
├── StudyForge.xcodeproj/
│   ├── project.pbxproj                     objectVersion 77
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/StudyForge.xcscheme
└── StudyForge/
    ├── App/          StudyForgeApp · RootView · AppContainer
    ├── Core/
    │   ├── Auth/     UserSession (roles + plan from custom claims)
    │   └── State/    LoadState · AppError
    ├── DesignSystem/ ColorTokens · TypeScale · Spacing
    ├── Features/     <FeatureName>/ (one folder per feature)
    ├── Resources/    Assets.xcassets
    └── Preview Content/
```

**Feature folders arrive in S1**, one per feature ID: `Features/Auth/`, `Features/Library/`,
`Features/Flashcards/`, … Each holds its `View`, `ViewModel` and `Repository`.

## Build & test

```bash
# Build for the simulator
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj \
           -scheme StudyForge \
           -destination 'generic/platform=iOS Simulator' \
           build CODE_SIGNING_ALLOWED=NO

# Run on a specific simulator
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj \
           -scheme StudyForge \
           -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
           build
```

**Notes**

- The project uses **synchronised file groups**, so new files under `StudyForge/` are picked
  up automatically — no `.pbxproj` edits needed when adding a Swift file.
- `GoogleService-Info.plist` is **not** committed and is required before Firebase is wired (S1).
- The on-device AI tier does **not** run in the Simulator. Use a physical device with
  Apple Intelligence for tier-0 AI, or rely on tier 1 — see
  [docs/04 §4](../docs/04-TECH-ARCHITECTURE-COST.md).

