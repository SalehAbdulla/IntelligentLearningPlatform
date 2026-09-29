/**
 * StudyForge — Cloud Storage security-rules tests
 *
 * Run with:  npm run test:storage   (from backend/)
 *
 * This suite needs BOTH emulators: storage.rules calls firestore.get() to resolve
 * shared-folder permission, so Firestore must be running and seeded. That is a
 * deliberate design choice — folder permission lives in exactly one place — and
 * these tests prove the cross-service lookup actually enforces.
 */

import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes, getMetadata, deleteObject } from 'firebase/storage';

const here = dirname(fileURLToPath(import.meta.url));
const STORAGE_RULES = readFileSync(join(here, '..', 'storage.rules'), 'utf8');
const FIRESTORE_RULES = readFileSync(join(here, '..', 'firestore.rules'), 'utf8');

const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46]);     // %PDF
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);     // \x89PNG

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-studyforge',
    firestore: { rules: FIRESTORE_RULES },
    storage: { rules: STORAGE_RULES },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
});

const as = {
  owner:        () => env.authenticatedContext('student_1', { role: 'student', plan: 'free' }),
  otherStudent: () => env.authenticatedContext('student_2', { role: 'student', plan: 'free' }),
  tutor:        () => env.authenticatedContext('tutor_1',   { role: 'tutor',   plan: 'plus' }),
  admin:        () => env.authenticatedContext('admin_1',   { role: 'admin',   plan: 'pro' }),
  anonymous:    () => env.unauthenticatedContext(),
};

/** Seed Firestore folder membership and upload a file with rules bypassed. */
async function seedFolder(folderId, memberPermission) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `folders/${folderId}`), { ownerUid: 'student_1', name: 'CS201 revision' });
    await setDoc(doc(db, `folders/${folderId}/members/student_1`), { permission: 'edit' });
    if (memberPermission) {
      await setDoc(doc(db, `folders/${folderId}/members/student_2`),
                    { permission: memberPermission });
    }
    await uploadBytes(ref(ctx.storage(), `folders/${folderId}/shared/notes.pdf`),
                      PDF, { contentType: 'application/pdf' });
  });
}

// ══════════════════ personal material — owner only ══════════════════

test('users/materials: the owner may upload a PDF', async () => {
  await assertSucceeds(
    uploadBytes(ref(as.owner().storage(), 'users/student_1/materials/lecture4.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

test('users/materials: the owner may upload a scanned image', async () => {
  await assertSucceeds(
    uploadBytes(ref(as.owner().storage(), 'users/student_1/materials/scan.png'),
                PNG, { contentType: 'image/png' }),
  );
});

test('users/materials: DENY uploading an executable', async () => {
  await assertFails(
    uploadBytes(ref(as.owner().storage(), 'users/student_1/materials/payload.sh'),
                PDF, { contentType: 'application/x-sh' }),
  );
});

test('users/materials: DENY uploading into another user directory', async () => {
  await assertFails(
    uploadBytes(ref(as.otherStudent().storage(), 'users/student_1/materials/injected.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

test('users/materials: DENY reading another student material file', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), 'users/student_1/materials/private.pdf'),
                      PDF, { contentType: 'application/pdf' });
  });
  await assertFails(getMetadata(ref(as.otherStudent().storage(),
                                    'users/student_1/materials/private.pdf')));
});

test('users/materials: DENY an unauthenticated client reading or writing', async () => {
  const storage = as.anonymous().storage();
  await assertFails(
    uploadBytes(ref(storage, 'users/student_1/materials/anon.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
  await assertFails(getMetadata(ref(storage, 'users/student_1/materials/private.pdf')));
});

test('users/materials: DENY deleting from another user directory', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), 'users/student_2/materials/theirs.pdf'),
                      PDF, { contentType: 'application/pdf' });
  });
  await assertFails(deleteObject(ref(as.owner().storage(),
                                     'users/student_2/materials/theirs.pdf')));
});

// ═══════════ avatars — readable by any signed-in user ═══════════

test('users/avatars: any signed-in user may read an avatar', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), 'users/student_1/avatars/me.png'),
                      PNG, { contentType: 'image/png' });
  });
  await assertSucceeds(getMetadata(ref(as.otherStudent().storage(),
                                       'users/student_1/avatars/me.png')));
});

test('users/avatars: DENY uploading a non-image as an avatar', async () => {
  await assertFails(
    uploadBytes(ref(as.owner().storage(), 'users/student_1/avatars/notanimage.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

// ═════════════ published course material ═════════════════

test('courses/published: a tutor may publish and a student may read', async () => {
  await assertSucceeds(
    uploadBytes(ref(as.tutor().storage(), 'courses/cs201/published/week4.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
  await assertSucceeds(getMetadata(ref(as.owner().storage(),
                                       'courses/cs201/published/week4.pdf')));
});

test('courses/published: DENY a student publishing material', async () => {
  await assertFails(
    uploadBytes(ref(as.owner().storage(), 'courses/cs201/published/fake.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

// ═══════ shared folders — permission resolved from Firestore ═══════

test('folders/shared: a member may read a shared file', async () => {
  await seedFolder('f1', 'view');
  await assertSucceeds(getMetadata(ref(as.otherStudent().storage(),
                                       'folders/f1/shared/notes.pdf')));
});

test('folders/shared: DENY a non-member reading a shared file', async () => {
  await seedFolder('f1', null);              // student_2 is NOT a member
  await assertFails(getMetadata(ref(as.otherStudent().storage(),
                                    'folders/f1/shared/notes.pdf')));
});

test('folders/shared: DENY a viewer uploading to the folder', async () => {
  await seedFolder('f1', 'view');
  await assertFails(
    uploadBytes(ref(as.otherStudent().storage(), 'folders/f1/shared/mine.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

test('folders/shared: an editor MAY upload to the folder', async () => {
  await seedFolder('f1', 'edit');
  await assertSucceeds(
    uploadBytes(ref(as.otherStudent().storage(), 'folders/f1/shared/mine.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
});

test('folders/shared: DENY an unauthenticated client reading a shared file', async () => {
  await seedFolder('f1', 'view');
  await assertFails(getMetadata(ref(as.anonymous().storage(),
                                    'folders/f1/shared/notes.pdf')));
});

// ═════════════ moderation evidence — admins only ═════════════

test('reports/evidence: DENY a student, ALLOW an admin', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), 'reports/r1/evidence.jpg'),
                      PNG, { contentType: 'image/jpeg' });
  });
  await assertFails(getMetadata(ref(as.owner().storage(), 'reports/r1/evidence.jpg')));
  await assertSucceeds(getMetadata(ref(as.admin().storage(), 'reports/r1/evidence.jpg')));
});

// ══════════════════ deny-by-default ══════════════════

test('deny-by-default: DENY an unmatched storage path', async () => {
  const storage = as.owner().storage();
  await assertFails(
    uploadBytes(ref(storage, 'somewhere/never/matched.pdf'),
                PDF, { contentType: 'application/pdf' }),
  );
  await assertFails(getMetadata(ref(storage, 'somewhere/never/matched.pdf')));
});
