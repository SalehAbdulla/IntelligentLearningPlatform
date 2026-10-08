# Dark-mode proof screenshots

Rendered evidence for **P9-12 dark-mode frame variants** (`docs/TODOLIST.md` section 5). The
variants themselves live in Figma on page `6 · Dark Mode Variants (P9-12)`; these two PNGs
exist so the work can be checked without opening Figma.

| File | Frame | What it proves |
|---|---|---|
| `dark-15-home-dashboard.png` | `DARK_15_Home_Dashboard_Student_Saleh_202300540` | The student home in dark mode: dark canvas, light text, dark glass cards, the orange due-cards call to action, the dark tab bar with the blue active item |
| `dark-124-payment-processing.png` | `DARK_124_Payment_Processing_Tasbeeh_202300549` | The payment processing screen in dark mode: dark canvas, white body copy, dark glass note card |

**How they were produced.** Each dark variant was cloned from its light screen, given the
`Dark` mode of the `Color` variable collection explicitly, and rendered with the Figma MCP
screenshot tool at 900 px on the long edge. Captured 8 October 2026 while the file was at
the same revision as the exported `StudyForge.fig`.

**Full set.** All 106 variants were created and verified programmatically; the counts are
recorded in `../figma-audit.md` (106 variants, 106 with the dark mode set). Re-capture these
two screenshots if the screens change, so the proof matches the file.
