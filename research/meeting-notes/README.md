# Meeting notes

> **Why this folder exists.** [doc 01 §1](../../docs/01-ROADMAP-PHASES-TODOLIST.md) commits the team
> to a weekly rhythm, and [research/README](../README.md) lists this folder as the evidence for the
> **Organisation** component. This folder holds the minutes for that rhythm.

## The rhythm, as the project actually defines it

[doc 10 §7](../../docs/10-SPRINT-PLAN.md) defines five ceremonies. **Four of the five are
deliberately asynchronous**, and that is a design decision, not a shortcut:

| Ceremony | When | Duration | Where |
|---|---|---|---|
| Sprint planning | Monday, sprint start | 45 min | In person |
| **Async stand-up** | **Every weekday** | **5 min** | **The team channel** |
| Mid-sprint check | Thursday | 20 min | In person |
| Sprint review & demo | Final Sunday | 60 min | In person, **recorded** |
| Retrospective | After the review | 30 min | In person |

**The stand-up is defined as three lines in the team channel** — *done · doing · blocked* — because
five students on different timetables cannot meet every weekday, and a five-minute meeting that
costs five people a journey is not five minutes. The team channel is the asynchronous ceremony, and
it is where most of the coordination actually happens.

## What counts as minutes

The channel is the meeting, so **the channel is the source**. A day's minutes are the stand-up
lines as they were actually posted, tidied into the template below — not a reconstruction written
afterwards from memory.

| Source | Becomes |
|---|---|
| The team channel's stand-up lines | The *Stand-up* section of a day's minutes |
| A planning or review session | Its own minutes file, with decisions and owners |
| A decision made in the channel | A line in the *Decisions* section, with the date it was taken |

**Nothing in this folder is written from memory.** If a day's stand-up did not happen, the day has
no minutes, and that is recorded rather than filled in.

## Naming

```
YYYY-MM-DD-<ceremony>.md        e.g. 2026-10-12-planning.md
YYYY-MM-DD-standup.md           a day's async stand-up
```

## Why this folder is not padded

The temptation with minutes is to write a plausible set at the end, because nobody checks a
meeting's content the way they check a commit. Two reasons not to, and the second is the practical
one:

1. **It is fabricating evidence for assessment**, which is a different act from writing weak
   evidence, and it is treated differently.
2. **It contradicts the record a marker can check.** A marker can run `git shortlog -sn` in one
   command. Minutes that describe a member reporting progress on a feature, when that member has no
   commits touching it, do not just look invented — **they make the real evidence look invented
   too**. Minutes that claim work the repository does not show cast doubt on the parts of the record
   that are genuine, which is a far worse outcome than thin minutes.

The team's own rule in [doc 10 §6](../../docs/10-SPRINT-PLAN.md) says the same thing about the
contribution logs: *"never back-fill a whole sprint at once (it reads as fabricated and defeats the
point)."* The reason it defeats the point is that the point is verifiability.

## The honest position, stated once

The team coordinates in a channel, and that is a legitimate way to run a student project — it is
what the project's own plan specifies. **The minutes in this folder are the channel's record, and
where the channel is thin, the minutes are thin.** That is a true account of how the team worked,
and a true account is worth more here than a fuller one that is not true.

## Files

| File | What it is |
|---|---|
| [`TEMPLATE-minutes.md`](TEMPLATE-minutes.md) | The minutes template, for a stand-up, a planning session or a review |

## To fill this folder

- [ ] Export the team channel, or screenshot the stand-up lines for the sprint's dates
- [ ] Write one file per ceremony date, from what was actually posted
- [ ] Record decisions with the date they were taken and who took them
- [ ] Where a ceremony did not happen, say so rather than filling the gap
