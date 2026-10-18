# Contributing from Windows

> **Who this is for.** Four of the five members work on **Windows**. This document is written
> for **their AI agent** as much as for them, because the agent is what will run the commands.
> Hand this file to the agent whole, alongside your own handover file
> (`docs/TODO-M2-mohammed.md` and so on).

## The one thing to understand first

**Xcode is macOS-only.** There is no workaround, no Windows port, and no emulator that runs an
iOS Simulator. So on a Windows machine you **cannot**:

- build the project
- run the app
- run the unit tests
- see the UI

**That is not a reason you cannot contribute. It means CI is your build machine.** Every push runs
a real macOS build and the full test suite on GitHub, and reports back on the pull request. That
result is your evidence, and it is stronger than a local run because it is reproducible by anyone.

## What you can and cannot verify locally

| | Windows | Notes |
|---|---|---|
| Clone, branch, commit, push | ✅ | Git works the same everywhere |
| Edit Swift, docs, Figma | ✅ | Text is text |
| `python3 tools/verify-docs.py` | ✅ | Needs Python 3.11+ |
| `python3 tools/check-strings.py` | ✅ | Needs Python 3.11+ |
| `bash tools/check-lane.sh M2` | ⚠️ | Needs **WSL** or **Git Bash** — see the setup section |
| `bash tools/check-tokens.sh` | ⚠️ | Same |
| `bash tools/commit.sh`, `tools/new-branch.sh` | ⚠️ | Same |
| `xcodebuild` — build, test, run | ❌ | **macOS only. Use CI.** |

**The `⚠️` rows are the important ones.** `check-lane.sh` is the guard that stops you editing
another member's file. If you cannot run it, you are editing blind — so **install WSL or Git Bash
before your first commit.** It is a 10-minute install and it is not optional.

## Setup, once

**1. Git identity.** Your commits are read off `git log` by name, so this has to be yours:

```bash
git config --global user.name  "Your Full Name"
git config --global user.email "<yourID>@student.polytechnic.bh"
```

**2. Python** (for the doc checks) — [python.org](https://python.org), 3.11 or newer. Verify:
```bash
python3 tools/verify-docs.py     # expect: VERDICT: ALL CHECKS PASSED
```

**3. A bash shell.** Either:
- **WSL** — `wsl --install` in an admin PowerShell, then work inside Ubuntu; **or**
- **Git Bash** — comes with Git for Windows, already installed

Verify:
```bash
bash tools/check-lane.sh M2      # expect: VERDICT: lane OK
```

**4. GitHub CLI** — [cli.github.com](https://cli.github.com). This is how you read the CI result.
```bash
gh auth login
gh pr checks                     # on a branch with a PR
```

---

## The verification loop — what the agent runs

This is the part that matters. **The agent must run these and report what they actually said**,
not what it expects them to say.

### Before pushing

```bash
bash tools/check-lane.sh M2      # must exit 0. This is the guard that stops cross-lane edits
python3 tools/verify-docs.py     # must print ALL CHECKS PASSED
python3 tools/check-strings.py   # must print ALL CHECKS PASSED (only if you touched .strings)
bash tools/todos.sh              # your open count should go DOWN, not up
```

### After pushing — get the CI verdict

```bash
gh pr checks                     # the fast answer: which jobs passed or failed
```

**CI also runs on the push itself, before any pull request exists** — on every `feat/`, `fix/`,
`docs/`, `chore/`, `release/` and `hotfix/` branch. So **you do not have to open a PR to find out
whether your branch builds, and you should not wait for one:**

```bash
gh run list --branch "$(git branch --show-current)" --limit 3   # is a run going?
gh run watch                                                    # wait for the newest one
```

> **Why this matters more than it sounds.** A member pushed a branch that did not compile and
> nothing looked at it for hours: CI only ran on pull requests, and he never opened one. Three
> types his file referenced did not exist anywhere in the repository. **Push, then watch the
> run** — a red result eleven minutes later is a working session; silence is a lost afternoon.

The output looks like this, and **the agent should quote it verbatim**:

```
Repo checks        pass    12s    https://github.com/.../runs/123
iOS build and test pass    9m4s   https://github.com/.../runs/124
```

### If something failed — get the detail

```bash
# The readable summary: Xcode version, simulator, and the test result line
gh run view <run-id> --log | grep -A20 'iOS build and test'

# Only the failing steps, which is usually what you want
gh run view <run-id> --log-failed | tail -80

# The full raw xcodebuild log, as an artifact, if the above is not enough
gh run download <run-id> -n xcodebuild-log
```

**The job summary is the fastest signal.** GitHub renders it at the top of the run page, and
`gh run view <run-id>` prints it. It contains:

| Field | Why it matters |
|---|---|
| **Xcode version** | so a failure can be reproduced exactly |
| **Simulator** | the device the tests ran on |
| **Test result** | e.g. `Test run with 808 tests in 90 suites passed` |
| **Failures** | the first 25 failing lines, so the agent does not have to hunt |

### The rule that makes this worth anything

> **Do not claim something works unless CI says it does.**

The agent must never write *"the build passes"* or *"tests pass"* from reasoning. It writes either
the CI verdict it fetched, or *"CI has not run yet"*. This project's whole evidence set is built on
that distinction, and a claim without a fetched result is the one thing that undermines it.

---

## Using an AI agent to do the work — what is allowed, and what is not

**Using AI to write the code is permitted, and your tutor confirmed it in writing.** `docs/10 §9`
records the correction:

> *"the tutor has confirmed that using AI to write code is acceptable... The tutor's permission
> removes the **authorship** problem. It does **not** remove the **understanding** requirement."*

So "the agent wrote it" is not a problem. **"I cannot explain it" is.** The VIVA is **60%,
must-pass, and individual** — a marker can say *"open your feature's view model and explain this
function"*, and every member answers for their own code, alone.

### The six rules, and which two an agent-only workflow breaks

| # | Rule | Enforced by |
|---|---|---|
| 1 | **Disclose AI use on every PR** — which tool, for what | PR template |
| 2 | **Read and review every generated line before it is committed.** Record what you corrected | `research/reviews/` |
| 3 | **No PR is merged for code you cannot explain.** The PR body carries a 3-sentence plain-English explanation | PR template |
| 4 | **Change something yourself each sprint** — a label, a bug, a layout, a validation rule. *"Not because hand-writing is required, but because making a change is the fastest way to actually understand code"* | a commit tagged `hand:` |
| 5 | **Weekly "explain it" drill** — open *another* member's feature and explain it unprompted | rotation, logged |
| 6 | **Every member demonstrates something at the sprint review** | `research/sprints/` |

**Rules 2 and 4 are the ones an "all agent" workflow breaks by default.** Neither requires hand-
writing code. Both require the member to have *engaged* with it:

- **Rule 2** — after the agent produces a diff, the member reads it and records what was wrong or
  unclear in `research/reviews/`. This is the same file that already holds the nine AI-code
  corrections found in this project.
- **Rule 4** — one small change per sprint, committed with `hand:` in the message. A label, a
  colour, a validation rule. Small is fine; **the point is that it is theirs.**

### What to put in the agent's prompt

Add this to whatever prompt starts the agent, so the contract is carried into every session:

```
Before you commit anything:
  1. Show me the full diff and explain each file in plain English.
  2. Flag anything you are not confident about — do not commit it silently.
  3. Tell me which lines I should change myself, and why.
  4. Remind me to record any correction in research/reviews/.

Do not tell me the build passes. Fetch the CI result with `gh pr checks` and
quote it verbatim, or say that CI has not run yet.
```

---

## What this means day to day

| Cadence | Action |
|---|---|
| **Every session** | Branch, make the change with the agent, read the diff, run the local checks, commit |
| **Every push** | CI runs automatically. **Read the result before moving on** |
| **Every day** | Push *something*. Commit timestamps are what a marker reads, and a single end-of-sprint dump reads as fabricated |
| **Every sprint** | One `hand:` commit · one entry in `research/reviews/` · one entry in your contribution log |
| **Weekly** | The "explain it" drill — explain someone else's feature from the code |

## The honest limits of this setup

- **CI proves it builds and the tests pass. It does not prove it looks right.** Nothing on Windows
  can show you the UI. If your change is visual, say so in the PR and ask someone on a Mac to look.
- **CI takes ~10 minutes.** Start it early rather than at the deadline.
- **A green CI is not the same as a good change.** The tests check behaviour, not whether the
  behaviour is what the brief asked for.
- **`gh run view --log` output is long.** Use `--log-failed` and the job summary first.

