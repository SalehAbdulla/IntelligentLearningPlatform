# Feature Cheat Sheet — `<Your Name>`

> **Purpose:** one page you always have open in the VIVA. The marker may ask you to explain *any* part of the app; this makes "where does that live and why?" answerable in under ten seconds.
> Fill this in from **S2** and keep it current to the feature freeze.

| Field | Value |
|---|---|
| **Member** | `<Name>` (M?) |
| **Student ID** | `2023xxxxx` |
| **Features I develop** | F__, F__, … |
| **Features I test** | F__, F__, … (see [doc 02 §7](../../docs/02-FEATURE-LIST-OWNERSHIP.md)) |
| **Sprints I contributed in** | S0 ☐ · S1 ☐ · S2 ☐ · S3 ☐ · S4 ☐ · S5 ☐ |

---

## My features

Repeat this block once per feature you develop.

### `F__ — <Feature name>`

- **What it does, in three sentences** (no jargon — if you can't say it plainly you don't own it):
  1.
  2.
  3.
- **Key source files:**
  - `Features/<Name>/<Name>View.swift`
  - `Features/<Name>/<Name>ViewModel.swift`
  - `Features/<Name>/<Name>Repository.swift`
- **Firestore collections and Storage paths touched:**
- **The hard part and how I solved it:**
- **A trade-off I made:** *I chose ______ over ______ because ______.*
- **A known limitation, and what I'd do about it:**
- **Loading / empty / error / offline behaviour:**
- **Who tested it, and what they found:**

---

## Code walkthrough — rehearsed

> Practise this out loud. The marker will say: *"open it and walk me through it."*

- **Entry point** → where the screen is registered and how you navigate to it:
- **The view** → structure, what it renders from, what it delegates:
- **The view model** → state, `LoadState` handling, async calls:
- **The repository** → Firestore/Storage/on-device access, error mapping:
- **The data contract** → which collections, which rules govern them, which custom claim gates it:
- **What happens when it fails** → the specific error path you'd demo:

---

## Where things live — the 10-second drill

| Feature | Screen ID | View file | ViewModel | Repository | Collections |
|---|---|---|---|---|---|
| F0_ | | | | | |

**Drill:** pick a random row, navigate to the file, and name its collection within ten seconds. Do this weekly.

---

## Hard questions I should expect

| Question | My prepared answer |
|---|---|
| "Why did you build it this way?" | |
| "What happens with no internet?" | |
| "What if the AI returns nonsense?" | |
| "What does this specific function do?" | |
| "What doesn't work?" *(always have a real answer)* | |
| "What would you change with more time?" | |

---

## VIVA evidence I can point to

- [ ] Merged PR(s): links
- [ ] Hand-written commits: `git log --author="<me>" --grep="hand:"`
- [ ] Test log(s) for features I tested
- [ ] Sprint review recording(s) where I demoed my own work
- [ ] Figma frames named with my student ID
