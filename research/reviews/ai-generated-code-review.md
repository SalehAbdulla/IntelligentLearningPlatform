# AI-generated code review notes

| Field | Value |
|---|---|
| **Reviewer** | **M1, Saleh Abdulla** (`202300540`) |
| **Scope** | The AI-assisted code in `ios/`, `backend/` and `tools/` |
| **Disclosure** | The team's use of AI coding tools is disclosed in the Design Document's appendix, per §16.3 |
| **What this file is** | Corrections made to code produced with AI assistance, each naming the commit that fixed it |

> **How to read this.** Every entry below is a defect that was **found by reading or running the
> product**, not by the test suite. That is the point: the suite was green in every case, because
> none of these were caught by a test. Each entry names the commit, so the claim can be checked.

---

## 1. Security

### 1.1 A permissive write rule on `users/{uid}` — the most serious defect found

**Commit:** `8cc542c` — *fix(F01): close a self-write hole on users/{uid} with an explicit field allowlist*
**Also documented at:** `backend/firestore.rules` lines 54–80, and risk **D25** in [doc 09](../../docs/09-RISKS-OPEN-QUESTIONS.md)

**What was wrong.** The rule let a user write their own document. The generated version was
structurally correct and passed every test — because a test signs in as the user and writes the
user's own fields. What it did **not** restrict was *which* fields. So a signed-in student could
write `role: 'admin'` or `plan: 'pro'` straight into their own document from the client.

**Why it mattered.** `role` is what `isAdmin()` and `isTutor()` read. A client-writable `role` is a
privilege-escalation path: the student does not need to defeat the admin rules, only to relabel
themselves. `plan` is the same class of problem for F13.

**How it was found.** Reading `firestore.rules` against the intended rule rather than against the
tests. The tests asked *"can the user write their profile?"* — yes. Nobody had asked *"can the user
write anything else?"*

**The fix.** Three deliberately overlapping guards on the self-write path:

- `keeps('role') && keeps('plan')` — explicit, so the failure is loud if the guard is ever removed
- `onlyChanges(editableProfileFields())` — **the real protection**: a field nobody has named is
  denied, so the rule fails **closed**
- `create` is separately constrained to `role == 'student'` and `plan == 'free'`

**The follow-on finding, which is the more interesting one.** The obvious place to have put the
profile wizard's preferences was the `private` subcollection, which was already self-read/self-write
and looked like the natural home. Reading it showed it had **no field guard at all** — so a field
added there would become client-writable the moment it existed. Routing the wizard's output into it
would have **reopened the same hole under a different path**. The fix therefore names the writable
fields explicitly in the guarded rule instead, and the rules file records why.

**The lesson.** A rule that says *yes* needs an answer to *yes to what*. The generated code answered
the first question and not the second, and no test was ever going to ask it.

### 1.2 A service-account key nearly committed

**Commit:** `cd4963d` — *fix(security): ignore Firebase Admin SDK private keys*

**What was wrong.** A Firebase Admin SDK private key — a credential that bypasses every Firestore
rule in §1.1 — sat in a path the ignore rules did not cover.

**Why it mattered.** A committed private key is not a bug that can be patched; it has to be rotated,
and if it reaches a public remote it must be treated as compromised from the moment it is pushed.

**How it was found.** Reviewing what `git status` would have added, rather than trusting the
existing `.gitignore`. The generated ignore file covered the common cases and not this one.

**The lesson.** `.gitignore` is a security control, and a generated one covers the cases the tool
happened to know about. It gets read, not assumed.

---

## 2. Correctness — logic that was plausible and backwards

### 2.1 A password strength meter that rewarded the wrong thing

**Commit:** `6d945f5` — *fix(F01): make password strength length-dominant so a passphrase outranks a short composed password*

**What was wrong.** The generated meter scored a password mainly on **character-class variety** —
lowercase, uppercase, digit, symbol. So `P@ssw0rd!` scored highly and a long passphrase of ordinary
words scored poorly.

**Why it mattered.** It is backwards in the domain. Length is the dominant factor in resisting
offline cracking, and complexity rules mostly produce predictable substitutions (`a`→`@`, `o`→`0`)
that attackers' rule sets already cover. **The screen was teaching students to pick weaker
passwords**, which is worse than having no meter at all — it was confidently wrong.

**How it was found.** Not by a test. The tests asserted the meter returned a score in range, which
it did. It was found by typing a real passphrase into it and seeing the app call it weak.

**The fix.** Length became the dominant term, so a passphrase outranks a short composed password.

**The lesson.** A test can confirm that a function returns a number without confirming the number
means anything. This is the clearest example in the project of a green suite hiding a wrong answer,
and it is why the test logs in [`research/testing/`](../testing/README.md) record what they **did
not** verify.

### 2.2 The account document written after the profile read it

**Commit:** `8e2b32f` — *fix(F01): bootstrap the user document before the profile write*

**What was wrong.** An ordering bug on the sign-up path: the profile write ran against a document
that had not been created yet.

**Why it mattered.** The failure is **intermittent**, which is the worst kind: it depends on how
fast the network answers. On a fast connection it never appeared; on a slow one the first write
landed against nothing. A defect that hides on the developer's machine is a defect that appears in
front of the marker.

**How it was found.** Reading the sign-up sequence as a sequence, rather than reading each function
on its own. Each function was correct.

**The lesson.** This is the "correct inside a file, wrong across the seam" class named in the folder
[README](README.md). The tool wrote two correct functions and one incorrect order.

### 2.3 An error translated into silence

**Commit:** `6cda158` — *fix(state): translate AIError in AppError.from instead of dropping it*

**What was wrong.** The error-mapping function handled most error types and **fell through** on
`AIError`, so an AI-layer failure arrived at the UI as a generic error — or, worse, as nothing.

**Why it mattered.** The AI tier is the part of the product most likely to fail in a way the user
needs explained: the model is unavailable, the device cannot run it, the answer was not grounded.
Collapsing those into one generic message throws away the explanation the user needs to know what
to do next. The whole point of `AITier`'s fallback design is that failures are **legible**.

**How it was found.** Reading the `switch` for its **missing** case rather than its present ones.

**The lesson.** A `switch` with a `default` is where errors go to die. The default was doing work
that looked like safety and was actually information loss.

### 2.4 A value that existed and was never carried forward

**Commit:** `7715793` — *fix(F13): restore the admin mastery key dropped from the catalogue*

**What was wrong.** A key present in the source catalogue was not carried into the derived one, so
the admin mastery figure silently went missing.

**Why it mattered.** Nothing crashed. A number was simply **absent** on a screen that had been
specified to show it, and an absent number is easy to read as "no data" rather than "a bug".

**How it was found.** Comparing the source data against the derived data, field by field.

**The lesson.** The most dangerous defect is the one that produces a plausible-looking result.
Nothing here was broken; something was just **missing**, and missing data looks like real data.


---

## 3. Accessibility — a defect class the tool produced consistently

Accessibility is where the generated code failed most consistently, and in the same way each time:
**a screen that looks correct and cannot be used by someone who cannot see it.**

### 3.1 A type scale that did not scale

**Commit:** `863ac77` — *fix(a11y): base the type scale on system text styles so it scales to AX5*

**What was wrong.** The type scale used **fixed point sizes** rather than the system's text styles,
so it ignored the user's Dynamic Type setting entirely.

**Why it mattered.** A student who has set their phone to a large text size — for any reason, from
preference to low vision — got a UI at the size the designer chose. **The app overrode an
accessibility setting the user had deliberately turned on**, which is a worse failure than being
merely hard to read, because it is invisible unless you test at a large size.

**How it was found.** Setting the simulator to **AX5**, the largest accessibility size, and looking
at the app. It was not found by any test.

**The fix.** The scale was rebuilt on the system's text styles, so it scales with the setting.

**The lesson.** An accessibility defect is invisible at default settings. It is only ever found by
changing the setting, which is why the manual passes in the test logs list AX5 explicitly.

### 3.2 A warning colour that failed contrast, in seven places

**Commits:** `fix(a11y): use warningText for …` across the admin quota banner, the coach warning
labels, the low-confidence badge, the low-confidence label, the material status label, the tutor
at-risk KPI and the weak-topic mastery text.

**What was wrong.** Warning and low-confidence text used a colour that did not meet contrast
requirements against its background.

**Why it mattered.** These are the labels that carry **the most important information on their
screens** — low confidence, at-risk students, weak topics. The text most needed was the text hardest
to read.

**How it was found.** Checking the actual colour pair against the contrast requirement, rather than
assuming a token named for a warning role was legible in it. The token existed; it was the wrong
one for text.

**The lesson.** A semantic token name (`warning`) describes **intent**, not legibility. One failure
repeated in seven places is not seven findings — it is one wrong choice in the design system, which
is why the fix was a token swap rather than seven colour tweaks.

### 3.3 VoiceOver, retrofitted

**Commits:** roughly twenty, of the form *fix(F<xx>): record the <screen>'s VoiceOver coverage* and
*fix(F<xx>): announce … as one element* — e.g. `8ffa0d6` *honour Reduce Motion when scrolling to a
new message*.

**What was wrong.** VoiceOver support was **not present** in the generated screens. Individual
elements were readable, but composite rows were announced as fragments, headers were not announced
at all, and motion ignored the Reduce Motion setting.

**Why it mattered.** A screen reader user heard a stream of disconnected values with no structure.
The information was technically present and practically unusable.

**How it was found.** Turning VoiceOver on and using the app with the screen off.

**The lesson, and the honest one.** This was fixed **screen by screen, after the fact**, and that is
the wrong order. Accessibility retrofitted across 119 frames costs far more than it would have cost
to generate correctly, and the tool had no reason to produce it unprompted — **it was never asked
to.** The correction is not only in the code: the team's checklists now include a VoiceOver pass and
an AX5 pass as **gates**, not as polish.

---

## 4. Tooling — a check that could be fooled

**Commit:** `74ca60a` — *fix(tools): split the interview checks so a filled date cannot pass silently*

**What was wrong.** One submission check verified two things at once, so a **partially** completed
item passed: an interview date recorded without the interview content behind it satisfied the check.

**Why it mattered.** A gate that can be satisfied by an empty file is worse than no gate, because it
reports *"cleared"* and removes the reason to look. The team's own submission tool was telling them
they were ready when they were not.

**How it was found.** By asking what input would make the check pass **without** the work existing —
the same question as §1.1, aimed at a script instead of a rule.

**The lesson.** The security review and the tooling review turned out to be the same review. **A
rule and a gate both need to fail closed**, and both were initially written to confirm the happy
path.

---

## 5. What changed as a result

The corrections above are the individual findings. The more useful outcome is what they changed
about how the work was done:

| Change | Prompted by |
|---|---|
| Every Firestore rule that permits a write now **names the fields** it permits, and fails closed on anything unnamed | §1.1 |
| The manual pass in every test log explicitly lists **AX5** and **VoiceOver** | §3.1, §3.3 |
| `check-submission.sh` predicates were **split so a partial item cannot pass** | §4 |
| `.gitignore` is reviewed as a **security control**, not housekeeping | §1.2 |
| Test logs record **what was not verified**, because a green suite hid §2.1 | §2.1 |

**The honest summary.** Every defect in this file was found by a person reading or using the
product. **Not one was found by a test.** That is not an argument against tests — the suite is what
makes the rest of the code trustworthy. It is an argument for reading AI-assisted code as code
someone else wrote, because that is what it is.

