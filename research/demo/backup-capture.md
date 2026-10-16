# Backup capture inventory

> **Control 4 of the four in [doc 11 §3](../../docs/11-APP-IMPLEMENTATION-VIVA.md):** a full screen
> capture of the working golden path, **re-recorded after any change to those screens**, used if the
> live hardware or network fails.
>
> **The dangerous property of a backup recording is that it silently goes stale.** A recording from
> three weeks ago that shows a screen the app no longer has is worse than no recording: it is
> evidence of a product that does not exist, shown to a marker who may know the current build. So
> every recording here carries **the commit it was made from**, and the trigger table below says
> exactly what invalidates it.

| Field | Value |
|---|---|
| **Recorded on** | |
| **Device** | |
| **Method** | iOS Control Centre screen recording |
| **Stored on** | ⬜ the presenting device · ⬜ a USB stick · ⬜ a second device |

## Inventory

| # | Recording | Covers | Commit | Date | Stored on | Still valid? |
|---|---|---|---|---|---|---|
| **R1** | Golden path, full | Steps 1–8, unbroken | | | | ⬜ |
| **R2** | Core loop only | Steps 2–5, the money shot | | | | ⬜ |
| **R3** | AI Coach | The advanced feature, with its citation | | | | ⬜ |
| **R4** | Payments, sandbox | Authorisation through unlock | | | | ⬜ |
| **R5** | Collaboration | Second device, live leaderboard | | | | ⬜ |
| **R6** | Tutor & admin | Review queue, KPI dashboard | | | | ⬜ |

**R2 exists for a reason.** If the live demo is running late, the money shot is what must survive.
A four-minute clip that covers the core loop is more valuable than a twenty-minute one nobody
watches.

## What invalidates a recording

**A recording is stale the moment a screen it shows changes.** Check this before every demo:

| If this changes | These recordings are stale |
|---|---|
| Any screen in the core loop (upload, summary, cards, review) | **R1, R2** |
| The AI Coach screens, or the tiering/fallback copy | **R1, R3** |
| The paywall, plan or order-summary screens | **R1, R4** |
| The group space or live quiz | **R1, R5** |
| The tutor or admin dashboards | **R1, R6** |
| **Anything at all** | **R1**, because it shows the whole flow |

**R1 is invalidated by everything**, which is why it is the one to re-record last and the one most
likely to be stale. If only one recording is refreshed before the demo, refresh R1.

## Re-record procedure

```bash
git switch develop && git pull
bash tools/run-device.sh          # prints the commit it built — record that commit above
# Control Centre → Screen Recording → run the golden path from run-sheet.md
# stop, then note the commit and the date in the table
```

- [ ] The recording starts **after** the app is already signed in (no login fumbling on camera)
- [ ] Notifications are silenced, and **quiet hours disabled** only for the reminder step if it is
      being recorded
- [ ] Battery above 50% so the recording is not cut short
- [ ] The commit printed by `run-device.sh` is written into the inventory row
- [ ] **Play it back once, on the device it will be shown from** — a recording that will not open is
      the one failure this whole file exists to prevent

## The rule for this file

**A backup that has not been played back is not a backup.** The specific failure this guards against
is a recording that exists, is recent, and cannot be opened on the presenting device because it was
made on someone else's phone or in the wrong format. Play it back from the machine it will be shown
from, before the day.

## Duplication

[doc 11 §6](../../docs/11-APP-IMPLEMENTATION-VIVA.md) requires the backup on the **device and a USB
stick**. The reason is that these two fail independently: a lost or flat phone is recovered by the
stick, and a missing stick is recovered by the phone. Neither covers the other.

- [ ] On the presenting device, **downloaded**, not just in the cloud
- [ ] On a USB stick, with the right adapter for the presenting machine
- [ ] Both verified by playing back, not by seeing the file listed
