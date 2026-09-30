/**
 * StudyForge — Cloud Firestore security-rules tests
 *
 * Run against the Firestore emulator via:  npm test   (from backend/)
 *
 * These tests are deliberately NEGATIVE-first. Proving the rules DENY the wrong
 * people is stronger evidence of professional practice (LO3) than proving they
 * allow the right ones — and it is the failure mode that actually leaks data.
 *
 * Uses Node's built-in test runner: no mocha, no jest, no extra dependency.
 */

import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc, getDocs,
} from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const RULES = readFileSync(join(here, '..', 'firestore.rules'), 'utf8');

let env;

// ───────────────────────────── setup ─────────────────────────────

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-studyforge',
    firestore: { rules: RULES },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

/** Write fixture data with rules bypassed (Admin-SDK-equivalent). */
async function seed(write) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await write(ctx.firestore());
  });
}

/** Auth contexts, with custom claims exactly as the Cloud Function sets them. */
const as = {
  student:      () => env.authenticatedContext('student_1', { role: 'student', plan: 'free' }),
  otherStudent: () => env.authenticatedContext('student_2', { role: 'student', plan: 'free' }),
  tutor:        () => env.authenticatedContext('tutor_1',   { role: 'tutor',   plan: 'plus' }),
  admin:        () => env.authenticatedContext('admin_1',   { role: 'admin',   plan: 'pro' }),
  anonymous:    () => env.unauthenticatedContext(),
};

// ═══════════════════════ 1. users — no self-promotion ═══════════════════════

test('users: a user may read their own document', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertSucceeds(getDoc(doc(db, 'users/student_1')));
});

test('users: DENY reading another user document', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_2'), { displayName: 'Omar', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(getDoc(doc(db, 'users/student_2')));
});

test('users: a new user may create their own document as a student on the free plan', async () => {
  const db = as.student().firestore();
  await assertSucceeds(
    setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' }),
  );
});

test('users: DENY self-registering as an admin (privilege escalation)', async () => {
  const db = as.student().firestore();
  await assertFails(
    setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'admin', plan: 'free' }),
  );
});

test('users: DENY granting yourself the pro plan', async () => {
  const db = as.student().firestore();
  await assertFails(
    setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'pro' }),
  );
});

test('users: DENY promoting your existing account to admin', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'users/student_1'), { role: 'admin' }));
});

test('users: DENY upgrading your own plan after the fact', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'users/student_1'), { plan: 'pro' }));
});

test('users: a user may update their own display name', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/student_1'), { displayName: 'Sara A.' }));
});

// ── The allowlist on `users/{uid}` updates ──────────────────────────────
//
// Before this guard existed, the rule pinned only `role` and `plan`, which left every
// OTHER field implicitly writable. These tests exist because that is the failure mode
// that appears when the schema grows: a new field is client-writable by default unless
// something says otherwise.

test('users: a user may complete their academic profile (the profile wizard)', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'users/student_1'), {
      university: 'Bahrain Polytechnic',
      major: 'Software Engineering',
      year: 2,
      courseIds: ['c_101', 'c_104'],
    }),
  );
});

test('users: DENY forging your own streak', async () => {
  // `streak` does not exist on the document yet, and that is precisely the point: an
  // allowlist denies fields the rules have never heard of. The profile screen (B06)
  // SHOWS the streak, so a client-writable value is a falsified achievement.
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'users/student_1'), { streak: 999 }));
});

test('users: DENY awarding yourself a badge', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(
    updateDoc(doc(db, 'users/student_1'), { badges: ['night_owl', 'first_steps'] }),
  );
});

test('users: DENY writing a field the rules do not name (the general case)', async () => {
  // The catch-all that the old rule allowed. Any field not in the allowlist is denied,
  // so a future sprint cannot accidentally open a client-writable hole.
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'users/student_1'), { somethingInventedLater: true }));
});

test('users: DENY tampering with a server-owned field', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), {
      displayName: 'Sara', role: 'student', plan: 'free', createdAt: '2026-01-01T00:00:00Z',
    });
  });
  const db = as.student().firestore();
  await assertFails(
    updateDoc(doc(db, 'users/student_1'), { createdAt: '2030-01-01T00:00:00Z' }),
  );
});

test('users: DENY smuggling a forbidden field alongside a permitted one', async () => {
  // A partial allowlist must not be defeatable by bundling: mixing an allowed field with
  // a forbidden one has to fail, or the guard is worthless.
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(
    updateDoc(doc(db, 'users/student_1'), { displayName: 'Sara A.', streak: 999 }),
  );
});

test('users: an admin may update any user field', async () => {
  // The allowlist constrains SELF-service edits only. Server-side admin tooling is
  // unaffected, otherwise the escape hatch for correcting bad data would be gone.
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_2'), { displayName: 'Omar', role: 'student', plan: 'free' });
  });
  const db = as.admin().firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'users/student_2'), { displayName: 'Omar K.', plan: 'plus' }),
  );
});

test('users: an admin may read any user', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_2'), { displayName: 'Omar', role: 'student', plan: 'free' });
  });
  const db = as.admin().firestore();
  await assertSucceeds(getDoc(doc(db, 'users/student_2')));
});

test('users: DENY a user deleting their own account document', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1'), { displayName: 'Sara', role: 'student', plan: 'free' });
  });
  const db = as.student().firestore();
  await assertFails(deleteDoc(doc(db, 'users/student_1')));
});

test('users/private: DENY another user reading your notification preferences', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/student_1/private/prefs'), { quietHours: '22:00-07:00' });
  });
  const db = as.otherStudent().firestore();
  await assertFails(getDoc(doc(db, 'users/student_1/private/prefs')));
});

// ══════════════════ 2. materials — ownership and visibility ══════════════════

test('materials: the owner may read their own material', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'materials/m1'), {
      ownerUid: 'student_1', title: 'Lecture 4', visibility: 'private', textHash: 'sha256:abc',
    });
  });
  const db = as.student().firestore();
  await assertSucceeds(getDoc(doc(db, 'materials/m1')));
});

test('materials: DENY reading another student private material', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'materials/m1'), {
      ownerUid: 'student_1', title: 'Lecture 4', visibility: 'private', textHash: 'sha256:abc',
    });
  });
  const db = as.otherStudent().firestore();
  await assertFails(getDoc(doc(db, 'materials/m1')));
});

test('materials: a cohort member may read material published to the course', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'materials/m1'), {
      ownerUid: 'tutor_1', title: 'Week 4 slides', visibility: 'course', textHash: 'sha256:def',
    });
  });
  const db = as.student().firestore();
  await assertSucceeds(getDoc(doc(db, 'materials/m1')));
});

test('materials: DENY creating material owned by somebody else', async () => {
  const db = as.student().firestore();
  await assertFails(
    setDoc(doc(db, 'materials/m9'), {
      ownerUid: 'student_2', title: 'Impersonated', visibility: 'private', textHash: 'sha256:x',
    }),
  );
});

test('materials: DENY creating material without a textHash (the AI cache key)', async () => {
  const db = as.student().firestore();
  await assertFails(
    setDoc(doc(db, 'materials/m9'), {
      ownerUid: 'student_1', title: 'No hash', visibility: 'private',
    }),
  );
});

test('materials: a tutor may read for review, but an anonymous client may not', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'materials/m1'), {
      ownerUid: 'student_1', title: 'Lecture 4', visibility: 'private', textHash: 'sha256:abc',
    });
  });
  await assertSucceeds(getDoc(doc(as.tutor().firestore(), 'materials/m1')));
  await assertFails(getDoc(doc(as.anonymous().firestore(), 'materials/m1')));
});

// ═════════ 3. server-owned collections — clients read, never write ═════════

test('subscriptions: a user may read their own entitlement', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'subscriptions/student_1'), { plan: 'plus', status: 'active' });
  });
  const db = as.student().firestore();
  await assertSucceeds(getDoc(doc(db, 'subscriptions/student_1')));
});

test('subscriptions: DENY a client writing its own entitlement (the whole point)', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'subscriptions/student_1'), { plan: 'free', status: 'active' });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'subscriptions/student_1'), { plan: 'pro' }));
});

test('subscriptions: DENY creating an entitlement document from the client', async () => {
  const db = as.student().firestore();
  await assertFails(setDoc(doc(db, 'subscriptions/student_1'), { plan: 'pro', status: 'active' }));
});

test('topicMastery: DENY a client writing its own mastery score', async () => {
  const db = as.student().firestore();
  await assertFails(
    setDoc(doc(db, 'topicMastery/student_1/topics/normalisation'), { score: 1.0 }),
  );
});

test('topicMastery: DENY a student reading another student mastery', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'topicMastery/student_1/topics/normalisation'), { score: 0.4 });
  });
  const db = as.otherStudent().firestore();
  await assertFails(getDoc(doc(db, 'topicMastery/student_1/topics/normalisation')));
});

test('progress: DENY a client writing its own progress roll-up', async () => {
  const db = as.student().firestore();
  await assertFails(setDoc(doc(db, 'progress/student_1'), { streak: 999, masteryPercent: 100 }));
});

test('aiCache: DENY every client read and write of the generation cache', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'aiCache/sha256abc'), { summary: 'cached' });
  });
  const db = as.student().firestore();
  await assertFails(getDoc(doc(db, 'aiCache/sha256abc')));
  await assertFails(setDoc(doc(db, 'aiCache/sha256zzz'), { summary: 'injected' }));
});

// ═════════════════════════ 4. quiz attempts ════════════════════════════

test('quizAttempts: a student may record their own attempt', async () => {
  const db = as.student().firestore();
  await assertSucceeds(addDoc(collection(db, 'quizAttempts'), { uid: 'student_1', score: 8 }));
});

test('quizAttempts: DENY recording an attempt for another student', async () => {
  const db = as.student().firestore();
  await assertFails(addDoc(collection(db, 'quizAttempts'), { uid: 'student_2', score: 10 }));
});

test('quizAttempts: DENY editing an attempt after the fact', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'quizAttempts/a1'), { uid: 'student_1', score: 3 });
  });
  const db = as.student().firestore();
  await assertFails(updateDoc(doc(db, 'quizAttempts/a1'), { score: 10 }));
});


// ══════════════════ 5. folders — membership governs access ══════════════════

async function seedFolder(permission) {
  await seed(async (db) => {
    await setDoc(doc(db, 'folders/f1'), { ownerUid: 'student_1', name: 'CS201 revision' });
    await setDoc(doc(db, 'folders/f1/members/student_1'), { permission: 'edit' });
    await setDoc(doc(db, 'folders/f1/members/student_2'), { permission });
    await setDoc(doc(db, 'folders/f1/items/i1'), { title: 'Shared notes' });
  });
}

test('folders: a member may read the folder', async () => {
  await seedFolder('view');
  const db = as.otherStudent().firestore();
  await assertSucceeds(getDoc(doc(db, 'folders/f1')));
});

test('folders: DENY a non-member reading the folder', async () => {
  await seedFolder('view');
  // Even a tutor is denied: folder access is membership-based, not role-based.
  await assertFails(getDoc(doc(as.tutor().firestore(), 'folders/f1')));
});

test('folders: a viewer may NOT write a folder item', async () => {
  await seedFolder('view');
  const db = as.otherStudent().firestore();
  await assertFails(setDoc(doc(db, 'folders/f1/items/i2'), { title: 'sneaky' }));
});

test('folders: a commenter MAY write a folder item', async () => {
  await seedFolder('comment');
  const db = as.otherStudent().firestore();
  await assertSucceeds(setDoc(doc(db, 'folders/f1/items/i2'), { title: 'my note' }));
});

test('folders: DENY a member promoting their own permission to edit', async () => {
  await seedFolder('view');
  const db = as.otherStudent().firestore();
  await assertFails(updateDoc(doc(db, 'folders/f1/members/student_2'), { permission: 'edit' }));
});

test('folders: DENY a member removing the owner from the folder', async () => {
  await seedFolder('edit');
  const db = as.otherStudent().firestore();
  await assertFails(deleteDoc(doc(db, 'folders/f1/members/student_1')));
});

// ═════════════ 6. tutor review queue — the human-in-the-loop gate ═════════

test('reviewQueue: a tutor may read the queue', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'reviewQueue/q1'), { courseId: 'cs201', status: 'pending' });
  });
  await assertSucceeds(getDoc(doc(as.tutor().firestore(), 'reviewQueue/q1')));
});

test('reviewQueue: DENY a student reading AI content awaiting review', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'reviewQueue/q1'), { courseId: 'cs201', status: 'pending' });
  });
  await assertFails(getDoc(doc(as.student().firestore(), 'reviewQueue/q1')));
});

test('reviewQueue: DENY a student writing the queue', async () => {
  const db = as.student().firestore();
  await assertFails(setDoc(doc(db, 'reviewQueue/q2'), { courseId: 'cs201', status: 'approved' }));
});

// ══════════════ 7. deny-by-default, across the board ══════════════════

test('auditLog: DENY every client write, even by an admin (append-only via Cloud Functions)', async () => {
  const admin = as.admin().firestore();
  await assertFails(setDoc(doc(admin, 'auditLog/e1'), { action: 'tamper' }));
});

test('auditLog: DENY rewriting an existing entry, even as an admin', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'auditLog/e1'), { action: 'role-change', actor: 'admin_1' });
  });
  const admin = as.admin().firestore();
  await assertFails(updateDoc(doc(admin, 'auditLog/e1'), { action: 'nothing-happened' }));
});

test('deny-by-default: DENY reading an unmatched collection', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'somethingNeverMatched/x1'), { secret: true });
  });
  await assertFails(getDoc(doc(as.student().firestore(), 'somethingNeverMatched/x1')));
});

test('deny-by-default: DENY an unauthenticated client reading anything', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'materials/m1'), {
      ownerUid: 'student_1', title: 'Lecture 4', visibility: 'course', textHash: 'sha256:abc',
    });
  });
  const db = as.anonymous().firestore();
  await assertFails(getDoc(doc(db, 'materials/m1')));
  await assertFails(getDoc(doc(db, 'users/student_1')));
});

