# Injected-failure rehearsal

> **Required by risk [R19](../../docs/09-RISKS-OPEN-QUESTIONS.md):** *"the live demo fails on the day
> — device, network, projector or payment gateway"*, mitigated by *"golden-path rehearsals
> **including an injected failure**"*.
>
> [doc 11 §4](../../docs/11-APP-IMPLEMENTATION-VIVA.md) says the same thing in one line: *"Rehearsing
> the **failure** path matters as much as the happy path."*

## Why injecting a failure is different from practising a fallback

Reading a fallback line is not rehearsal. **Rehearsing a fallback means the step actually fails,
unexpectedly, while you are mid-sentence** — and that is the only way to find out whether the line
comes out calmly or whether you apologise and start tapping.

**The thing being rehearsed is not the app. It is the presenter.** Under pressure, the instinct is
to fix it, and fixing it in front of a marker is how a five-minute demo becomes a nine-minute one
with no core loop in it.

## The rule for the rehearsal

**The person running the demo must not know which failure is coming, or when.** If they know, they
rehearse the script rather than the recovery. One member injects; the presenter runs the golden path
cold.

## The injections

One per rehearsal. Each is a real failure mode from R19's own list.

| # | Inject | How | What it tests |
|---|---|---|---|
| **F1** | **The device fails** | Presenter's device is taken away mid-run and swapped for the Simulator | Whether the fallback is a *switch* rather than a rebuild — [doc 11 §6](../../docs/11-APP-IMPLEMENTATION-VIVA.md) requires the Simulator fallback installed and current for exactly this |
| **F2** | **The network drops** | Airplane mode on, mid-run, without warning | Whether the local-first steps carry, and whether the presenter reaches for the hotspot rather than retrying |
| **F3** | **The projector fails** | Display cable pulled at the money shot | Whether the demo survives on the device screen alone, and whether the presenter narrates instead of going silent |
| **F4** | **Generation fails** | The pre-generated deck and summary are hidden; the presenter must find them | Whether the presenter reaches the fallback content **without hunting** — the most common live failure |
| **F5** | **The payment gateway fails** | Sandbox is unreachable | Whether the presenter walks the order summary and the rules instead, which is the engineering point anyway |
| **F6** | **The on-device model is unavailable** | Airplane mode plus the fallback screen forced | Whether the presenter presents **the fallback as a feature**, because it is one |
| **F7** | **A step simply hangs** | A screen is left in a loading state | Whether the presenter waits, narrates, or panics. **Waiting silently is the worst outcome** |

## The three sentences to have ready

Every fallback in [`run-sheet.md`](run-sheet.md) is one of these three shapes. If the specific line
is forgotten, one of these will do, and that is the point of having them:

| Situation | Say |
|---|---|
| **The step cannot run** | *"This step needs [X]; here is the recorded run of it."* |
| **The step ran earlier** | *"Here is the state from this morning's run."* |
| **The step failed** | *"That's a defect — here's the fallback, and here's what it means."* |

**The one thing never to say is *"sorry, let me just try that again."*** It costs the marker's
attention, it costs time out of the five minutes, and it signals that the presenter is not in control
of their own demo. One line, then move.

## Rehearsal log

One row per rehearsal. **A rehearsal without an injection is a run-through, not a rehearsal** —
record which injection was used, so the set is covered before the demo.

| # | Date | Presenter | Injected | Which step it landed on | Did the line come out? | Did the timing hold? | What to change |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |
| 4 | | | | | | | |

**"Did the line come out?"** is the question this table exists to answer. *No* is a useful answer and
belongs here.

## Coverage check

- [ ] **F4 and F7 have both been injected** — the two most likely live failures
- [ ] At least one injection landed on the **money shot** (0:25–2:55)
- [ ] At least one rehearsal ran with the **marker-facing conditions** (standing, presenting aloud)
- [ ] Every fallback line in [`run-sheet.md`](run-sheet.md) has been **said out loud at least once**
- [ ] The timing held **with** an injection, not only without one
- [ ] Anything that failed and has **no working fallback** is written into
      [`regression-log.md`](regression-log.md) as the highest-priority gap

## The honest note this file should carry

An injected failure is uncomfortable to rehearse, and it is tempting to skip once the happy path is
clean. **The rehearsals that matter are the ones that go badly**, because they are the only ones that
teach the presenter what to do when the marker is watching and the screen is blank. A team that has
never watched its own demo fail is a team that will discover how it behaves on the day, in front of
the person marking it.
