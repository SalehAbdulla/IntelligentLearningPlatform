# Feature Cheat Sheet, Shahad Ashoor (M4)

> One page to keep open in the VIVA. Fill it in from now to the feature freeze.

| Field | Value |
|---|---|
| **Member** | Shahad Ashoor (M4) |
| **Student ID** | `202305767` |
| **Features I develop** | F08, F09, F10, F12 |
| **Features I test** | F01, F04, F05, F11 |
| **Sprints I contributed in** | S0 [ ] · S1 [ ] · S2 [ ] · S3 [ ] · S4 [ ] · S5 [ ] |

## My features

### F08, Shared Study Folders
- **What it does, in three sentences:** 1. 2. 3.
- **Key source files:** `Features/Folders/`, `Core/Folders/`
- **The hard part and how I solved it:** per-member permissions (`view` / `comment` / `edit`)
- **A trade-off I made:** I chose ______ over ______ because ______.
- **Known limitation:**
- **Loading / empty / error / offline behaviour:**
- **Who tested it (should be M3):**

### F09, Group Revision Spaces
- **Key sources:** `Features/Groups/`, `Core/Groups/`
- **The hard part:** the live quiz state machine, real-time leaderboard, reconnect
- **A trade-off I made:**
- **Known limitation:**
- **Who tested it (should be M1):**

### F10, Resource Bookmarking & Collections
- **Key sources:** `Features/Bookmarks/`
- **The hard part:**
- **A trade-off I made:**
- **Known limitation:**
- **Who tested it (should be M3):**

### F12, Admin Content Management & Moderation
- **Key sources:** `Features/Admin/`
- **The hard part:** role change, suspend, moderation queue, append-only audit log
- **A trade-off I made:**
- **Known limitation:**
- **Who tested it (should be M2):**

## Also mine: UI/UX, accessibility and the Figma prototype

- [ ] VoiceOver pass, Dynamic Type AX5 pass, contrast check, RTL proof (evidence recorded)
- [ ] Figma frames extended and wired; `.fig` export checkpoint (`deliverables/prototype/`)

## Hard questions I should expect

| Question | My prepared answer |
|---|---|
| "How is accessibility actually handled?" | contrast tokens, AX5 proof, VoiceOver labels, colour-independence, RTL |
| "How do folder permissions work?" | |
| "What happens if the host drops mid-quiz?" | |
| "What doesn't work?" | |
| "What would you change with more time?" | |

## VIVA evidence I can point to

- [ ] Merged PR(s): links
- [ ] Hand-written commits: `git log --author="Shahad Ashoor" --grep="hand:"`
- [ ] Test logs for F01, F04, F05, F11
- [ ] Accessibility / RTL evidence
- [ ] Sprint review recording(s) where I demoed my own work
- [ ] Figma frames named `Shahad_202305767`
