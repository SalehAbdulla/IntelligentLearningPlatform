# Pre-demo checklist — StudyForge

> One page to work through **before** the VIVA demo. It gathers the pre-flight from the
> run sheet and the readiness boxes from [`docs/11`](../../docs/11-APP-IMPLEMENTATION-VIVA.md)
> §4–5, with the two traps found on 7 Nov 2026 written in so they are not re-hit.
> Tick each one. Nothing here is optional.

## A. 30 minutes before — environment

- [ ] **Gemini key is set.** Without it, tier 1 reports "not available" and every AI screen is a fallback:
      ```bash
      export GEMINI_API_KEY="$(sed -n 's/^GEMINI_API_KEY=//p' .env.local)"
      ```
- [ ] **A fresh, SIGNED build.** Run the runner, not a stale app:
      ```bash
      # Simulator (signs ad-hoc; the key reaches the app via simctl):
      SIMCTL_CHILD_GEMINI_API_KEY="$GEMINI_API_KEY" bash tools/run-ios.sh
      # Physical device:
      bash tools/run-device.sh
      ```
      An **unsigned** build has no keychain entitlement, so **sign-in fails** — the cause of the
      `-34018` hunt (fixed in PR #162; do not run a build that predates that merge).
- [ ] **Four demo accounts sign in.** Key icon (top-right) → tap each: **student · tutor · group · admin**.
      If one fails, reset them:
      ```bash
      cd backend
      GOOGLE_APPLICATION_CREDENTIALS="$HOME/.studyforge/serviceAccountKey.json" \
        npm run seed:accounts -- --force-password
      ```
- [ ] **On a physical device:** unlocked, ≥80% battery, Apple Intelligence enabled, and provisioned
      **within 7 days** (a personal-team profile expires — rebuild, don't trust last week's copy).

## B. Demo content

- [ ] A **5–20 page PDF** on the device for the upload step.
- [ ] Demo course with **3–4 real materials pre-uploaded and pre-processed**.
- [ ] Demo **group space with 2 members** (for the collaboration beat).
- [ ] Tap **sandbox test card** details written down (never from memory).

## C. Go / no-go — walk the happy path once, properly

- [ ] Happy path completes **twice in a row**, no crash, no dead end.
- [ ] **Loading, empty and error** states all visible and correct.
- [ ] It works against the **seeded demo account** with realistic content.
- [ ] You can **explain every screen and every data write** in it.
- [ ] It survives **aeroplane mode** without hanging.

## D. Presenting

- [ ] Second device for the group quiz (two accounts, both signed in).
- [ ] Backup **screen recording** on the presenting device **and** a USB stick.
- [ ] Chargers · cables · projector dongle · slides exported to PDF.
- [ ] Notifications enabled and **quiet hours off**, so the reminder demo fires.

## E. If it breaks — say it, don't hide it

| Symptom | Cause | Fix |
|---|---|---|
| Switcher: *"couldn't find an account"* | a demo account's password drifted | `npm run seed:accounts -- --force-password` (section A) |
| AI screens: *"not available"* | `GEMINI_API_KEY` unset | set it (section A) |
| Simulator app won't sign in at all | unsigned build — no keychain | rebuild with `bash tools/run-ios.sh` (post-PR #162) |
| Account lands on a student home when it should be tutor/admin | the mock auth (`-seedDemo`), not the real one | launch **without** `-seedDemo` so the switcher uses real Firebase auth |
