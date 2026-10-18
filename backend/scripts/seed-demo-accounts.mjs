#!/usr/bin/env node
//
// seed-demo-accounts.mjs — create the four demo accounts, each with its role.
//
// WHY THIS EXISTS
// ---------------
// docs/01 P7-19 and P10-02 ask for four demo accounts (student, tutor, group
// member, admin) and docs/08 demo3 makes seeding them M1's evidence. The APP
// cannot create them: `firestore.rules` accepts only `role == 'student'` on
// create, pins it with `keeps('role')` on update, and the role model reads the
// role off the ID token as a CUSTOM CLAIM (docs/05 §2.1, docs/09 Q13). So the
// role has to be granted out of band, by something holding Admin credentials.
//
// `onUserCreate` (backend/functions/src/index.ts) would do it automatically, but
// the functions are NOT deployed — there is no Blaze plan — so this script is the
// "out of band" path docs/09 Q13 records, made repeatable.
//
// WHY THE ROLE MATTERS MORE THAN THE ACCOUNT
// ------------------------------------------
// `CustomClaims.swift` resolves `AppRole(rawValue: claims["role"]) ?? .student`.
// An account created in the Firebase console gets NO claims, so it is always a
// student — which means the tutor studio (F11) and the admin area (F12) are
// unreachable without this script. That is the whole reason it exists.
//
// WHAT IT NEEDS
// -------------
// A service-account key. Only the project owner can generate one:
//
//   Firebase console -> Project settings -> Service accounts
//     -> Generate new private key
//
// Save it OUTSIDE the repository, or as `backend/serviceAccountKey.json`. Both
// that name and `*firebase-adminsdk*.json` are in .gitignore deliberately: the
// file grants full admin access to the project.
//
//   export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/key.json
//   npm run seed:accounts
//
// The demo password defaults to "changeme" and can be overridden with SF_DEMO_PASSWORD.
// The default is published on purpose — see the note beside it — so a demo needs no
// lookup. The SERVICE-ACCOUNT KEY is the real credential here, and it is never committed:
// it is read from the path above, and nothing writes it anywhere.
//
// IDEMPOTENT: re-running updates the claims of accounts that already exist and
// leaves their password alone, so it is safe to run again after a claim change.

import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// ── the four accounts docs/08 demo3 asks for ───────────────────────────────────
//
// `groupIds` is on the STUDENT, not a separate role: `UserSession.swift` is
// explicit that "Study Group Member" is deliberately not a role, it is a
// capability layered on top of `student` and expressed through `groupIds` — one
// human, one account, many contexts. `g_1042` is the group the seeded preview
// session uses, so the demo's group space is the one this account lands in.
const ACCOUNTS = [
  {
    label: 'Student',
    email: 'student@studyforge.test',
    displayName: 'Sara Ali',
    claims: { role: 'student', plan: 'free', groupIds: [] },
    why: 'the golden path — sign in, upload, summarise, generate cards, review',
  },
  {
    label: 'Tutor',
    email: 'tutor@studyforge.test',
    displayName: 'Dr Ali Hassan',
    claims: { role: 'tutor', plan: 'pro', groupIds: [] },
    why: 'the tutor studio (F11) — course list, roster, review queue, gradebook',
  },
  {
    label: 'Group member',
    email: 'group@studyforge.test',
    displayName: 'Omar Noor',
    claims: { role: 'student', plan: 'pro', groupIds: ['g_1042'] },
    why: 'a student who is also in a study group — the collaboration surfaces',
  },
  {
    label: 'Admin',
    email: 'admin@studyforge.test',
    displayName: 'StudyForge Admin',
    claims: { role: 'admin', plan: 'pro', groupIds: [] },
    why: 'the admin area (F12) — moderation, taxonomy, users, broadcasts',
  },
];

const die = (message) => {
  console.error(`\n✗ ${message}\n`);
  process.exit(1);
};
const ok = (message) => console.log(`✓ ${message}`);

// ── credentials ───────────────────────────────────────────────────────────────
function loadCredential() {
  const flagIndex = process.argv.indexOf('--key');
  const path = flagIndex !== -1
    ? process.argv[flagIndex + 1]
    : process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!path) {
    die(
      'no service-account key given.\n' +
      '    Generate one: Firebase console -> Project settings -> Service accounts\n' +
      '                  -> Generate new private key\n' +
      '    Then either:\n' +
      '      export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/key.json\n' +
      '      npm run seed:accounts\n' +
      '    or:\n' +
      '      npm run seed:accounts -- --key /absolute/path/to/key.json\n' +
      '\n' +
      '    Keep the key OUTSIDE the repository. `serviceAccountKey.json` and\n' +
      '    `*firebase-adminsdk*.json` are gitignored, but the file grants full\n' +
      '    admin access to the project, so treat it as a credential.'
    );
  }

  const absolute = resolve(path);
  if (!existsSync(absolute)) die(`no file at ${absolute}`);

  const json = JSON.parse(readFileSync(absolute, 'utf8'));
  if (json.type !== 'service_account') {
    die(`${absolute} is not a service-account key (type is "${json.type}").`);
  }
  return { credential: cert(json), projectId: json.project_id };
}

// The demo password. `changeme` by default, because the whole point of these accounts is
// that a demo can be run without looking a password up.
//
// THE TRADE-OFF, STATED PLAINLY: this repository is public, so `changeme` is a PUBLISHED
// credential. That is acceptable for these four accounts and nothing else — they hold no
// real data, they use reserved `.test` addresses, and docs/09 R4 already treats the free
// tier as burnable. It would not be acceptable for an account holding anything real, which
// is why the script prints the warning below rather than staying quiet.
const DEFAULT_DEMO_PASSWORD = 'changeme';

const usingDefaultPassword = !process.env.SF_DEMO_PASSWORD;
const password = process.env.SF_DEMO_PASSWORD ?? DEFAULT_DEMO_PASSWORD;

if (password.length < 8) {
  die('the demo password must be at least 8 characters — Firebase Auth rejects shorter ones.');
}

// ── run ───────────────────────────────────────────────────────────────────────
const { credential, projectId } = loadCredential();
initializeApp({ credential, projectId });

const auth = getAuth();
const results = [];

for (const account of ACCOUNTS) {
  let user;
  let created = false;

  try {
    user = await auth.getUserByEmail(account.email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }

  if (user) {
    // The password is deliberately NOT reset on a re-run: rotating it would
    // invalidate a password already written on the demo run sheet.
    await auth.updateUser(user.uid, { displayName: account.displayName });
  } else {
    user = await auth.createUser({
      email: account.email,
      password,
      displayName: account.displayName,
      // `onUserCreate` would have done this. It is not deployed, so it is done
      // here — and doing it HERE rather than in the app is the point: the client
      // must never be able to choose its own role (docs/09 Q13).
      emailVerified: true,
    });
    created = true;
  }

  await auth.setCustomUserClaims(user.uid, account.claims);
  results.push({ ...account, uid: user.uid, created });
}

// ── report ────────────────────────────────────────────────────────────────────
console.log(`\nProject: ${projectId}\n`);
console.log('  Account        Role     Plan   Group ids        Email');
console.log('  ─────────────  ───────  ─────  ───────────────  ─────────────────────────');
for (const row of results) {
  const groups = row.claims.groupIds.length ? row.claims.groupIds.join(', ') : '—';
  console.log(
    `  ${row.label.padEnd(13)}  ${row.claims.role.padEnd(7)}  ${row.claims.plan.padEnd(5)}  ` +
    `${groups.padEnd(15)}  ${row.email}`
  );
}

console.log('');
for (const row of results) {
  ok(`${row.label}: ${row.created ? 'created' : 'already existed, claims updated'}  (${row.why})`);
}

if (usingDefaultPassword) {
  console.log(
    `  ! These accounts use the DEFAULT demo password "${DEFAULT_DEMO_PASSWORD}".\n` +
    '    It is published in this repository on purpose, so a demo needs no lookup —\n' +
    '    and that means anyone can sign in as them. Never put real data in these\n' +
    '    accounts. Set SF_DEMO_PASSWORD to use a different one.\n'
  );
}
console.log('Sign in on the device and confirm each account lands on the right home screen.\n');
console.log(
  'NOTE: a claim change only reaches the app on a fresh ID token. If a role change does\n' +
  'not show up, sign out and in again.\n'
);
