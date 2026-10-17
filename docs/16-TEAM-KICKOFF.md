# 16, Team Kickoff

> **One page. Read it, then do the one thing it asks.** The full guides are
> [`CONTRIBUTING.md`](../CONTRIBUTING.md) and your own handover file; this is the short version of
> what to do **this week**.

---

## What changed since you last looked

- **Fatema Ghareeb joined as M5.** We are **5 members** — the brief's own default, so the group-size deviation is closed.
- Features went **15 → 17**. Screens **141 → 154** inventoried, **119 built**.
- **New features:** F16 Admin-Moderated Group Chat and F17 Active Recall Space (both M5).
- **Your file lane is enforced.** Run `bash tools/check-lane.sh M2` (or your own handle) before every commit. If it says **OUT OF LANE**, stop and ask — do not force it.
- **New: every pull request needs one approval.** Any of us can approve anyone's PR, so **approve each other's**. Do not leave a PR sitting.

## Your one job this week

**One real, tested, committed change under your own name.** Not a plan, not a meeting — a commit.

The Sprints component (10%) is assessed **per person** and read from **your** commits and PRs. Nothing else counts, and it cannot be created at the end.

## Setup, once

```bash
git config --local user.name  "Your Full Name"
git config --local user.email "<your studentID>@student.polytechnic.bh"
```

That identity is what the marker reads. Committing under anyone else's name is treated as fabrication.

## Your lane and your file

| Member | Your features | Your handover file | Can you push? |
|---|---|---|---|
| **M2** Mohammed | F03 F04 F05 F11 F15 | `docs/TODO-M2-mohammed.md` | ✅ **accepted 15 Oct** |
| **M3** Tasbeeh | F06 F07 F13 F15 | `docs/TODO-M3-tasbeeh.md` | ✅ |
| **M4** Shahad | F08 F09 F10 F12 | `docs/TODO-M4-shahad.md` | ✅ |
| **M5** Fatema | F16 F17 | `docs/TODO-M5-fatema.md` | ✅ |

Hand your handover file to your AI agent whole — it is self-contained: identity, lane, features, open TODOs, git protocol, definition of done.

## The five commands

```bash
bash tools/todos.sh M3                            # what is open for you
bash tools/new-branch.sh feat/F06-exam-dates      # one branch per feature, from develop
bash tools/check-lane.sh M3                       # must exit 0 before you commit
bash tools/commit.sh --push <file> "feat(F06): capture per-course exam dates"
gh pr create --base develop --fill                # the PR is your evidence
```

**Then read the CI result before you move on:**

```bash
gh pr checks                                      # the build and the 808 tests, on macOS
```

**Xcode is macOS-only.** If you are on **Windows** you cannot build or test locally at all —
**CI is your build machine**, and it is free. Do not report that something works unless
`gh pr checks` says so. Full guide: [`docs/18-WINDOWS-CONTRIBUTING.md`](18-WINDOWS-CONTRIBUTING.md).

Then push **every day you work**. A single dump of commits on the last day reads as fabricated.

## Two rules that cost the team marks

1. **Never commit to `main` or `develop`.** Both need a pull request. `main` is the demo-safe branch and is only ever updated by releasing `develop`.
2. **Never edit a file outside your lane.** `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/` and the `.xcodeproj` belong to M1; other members' feature files belong to them.

## Deadlines

| | |
|---|---|
| **Design Document** | **Thu 22 Oct 2026, 23:55** |
| **Prototype (Figma + `.fig` + link)** | **Thu 12 Nov 2026, 23:55** |
| **Feature freeze** | 30 Nov 2026 |

## Everyone can push now

**All five members hold write access as of 16 October 2026**, verified against the API — `mohdalmadhon`, `Tasbeeh37`, `shaahaadhani43-debug` and `FatemaGhareeb` all show `write`, and the pending-invitation list is **empty**. The blocker recorded as risk **R23** is closed.

**So nothing external is stopping anyone any more.** The remaining problem is not access, it is that the commit history is still almost entirely M1's, and that **cannot be fixed at the end** — a sprint's evidence has to exist throughout the sprint. The commit timestamps are the proof, and they are read.

Every member's next step is the same one, and it is in their handover file: clone, set your own git identity, claim a file in your lane, make a real change, and commit it **under your own name**. Then do it again tomorrow.

## The one sentence worth repeating

> **A strong teammate does not raise your Sprints mark. Your own attributable, timestamped evidence is the only thing that counts, and it has to exist before the review — not be assembled after it.**
