# Code review notes

> **Why this folder exists.** The Sprints component is assessed **per person**, and
> [doc 10 §6](../../docs/10-SPRINT-PLAN.md) names *review notes on AI-generated code* as a form of
> individual evidence. The reasoning is that the team discloses its use of AI coding tools, and a
> disclosure is only credible if it is accompanied by evidence that someone **read and corrected**
> what the tools produced.
>
> This folder is that evidence. Each note records a defect found in AI-assisted code, **what the
> tool got wrong**, how it was found, and what changed.

## Why a correction is worth more than a clean commit

A commit that only adds code proves the tool ran. A commit that **changes** code the tool produced
proves a human understood it well enough to know it was wrong. That is the skill the rubric is
looking for, and it is the difference between using AI and being used by it.

**The rule for this folder: every note names a real commit.** A note without a hash is an opinion.

## Files

| File | What it covers |
|---|---|
| [`ai-generated-code-review.md`](ai-generated-code-review.md) | The substantive review: security, logic, accessibility and tooling defects found in AI-assisted code, with the commits that fixed each one |

## The pattern worth stating

Across the corrections below, the failures cluster in a way that is worth recording plainly, because
it shaped how the team worked:

| Failure class | What the tool tended to get wrong | How it was caught |
|---|---|---|
| **Security** | Wrote the **happy path** of a rule, and left the permissive case open | Reading `firestore.rules` line by line against the intended rule |
| **Accessibility** | Produced a screen that looks right and is **unusable** with VoiceOver, or does not scale with Dynamic Type | Running it with VoiceOver on and at AX5 |
| **Correctness** | Wrote plausible logic that is **backwards** in the domain — a strength meter rewarding complexity over length | Domain knowledge, not a test |
| **Integration** | Wrote each file correctly and **the seam between them** wrong — a dropped error, a duplicated definition, a value not carried forward | Reading the diff, not the file |

**The common thread: the tools are strong inside a file and weak across a boundary** — a boundary
between two files, or between the code and the person using it. That is why every correction below
was found by a human reading or running the product, and none was found by the test suite.

## A note on what these notes are not

These are **not** claims that the code was written by a tool and then trusted. Every entry names a
defect that was **found and fixed**, which means it was read. The notes are the audit trail of that
reading, and their value is that they are specific enough to be checked.
