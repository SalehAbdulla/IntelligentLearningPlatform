#!/usr/bin/env python3
"""live-rules-probe.py — verify the DEPLOYED Firestore rules against the real project.

WHY THIS EXISTS ALONGSIDE THE EMULATOR TESTS
    `npm test` proves the rule TEXT is correct. It cannot prove that the text was
    deployed, or that production behaves the same as the emulator. This probe runs as a
    real CLIENT (an ID token from the Auth REST API, which is exactly what the app
    holds), so Firestore evaluates the live rules — no Admin SDK, no rules bypass.

    This matters because the emulator is a re-implementation. A permission that behaves
    one way locally can behave differently against the deployed service.

USAGE
    python3 backend/rules-tests/live-rules-probe.py

    Exits 0 only if every expectation holds, so it can gate a release.

⚠️  KNOWN LIMITATION — TEARDOWN
    The probe creates a throwaway account and a `users/{uid}` document, then deletes the
    AUTH account (a client may delete itself). It CANNOT delete the Firestore document:
    `allow delete: if isAdmin()` is correct and deliberately makes that impossible, and
    the repository holds no Admin SDK service-account key.

    So running this leaves one orphaned `users/{uid}` document per run. Remove it from the
    Firebase console, or provision a service account for CI and let this script clean up
    after itself. Tracked in docs/09-RISKS-OPEN-QUESTIONS.md.

    Do NOT be tempted to verify the deletion with `firebase firestore:delete` — it exits 0
    and prints nothing even for a path that never existed, so its exit code proves nothing.
"""

import json
import sys
import time
import urllib.error
import urllib.request

# The Web API key is NOT a secret: it ships inside every build of the app and is only
# used to identify the project to the Identity Toolkit endpoints. Access control lives in
# the rules and in App Check, never in this value's secrecy.
API_KEY = "AIzaSyDTlYX9eHFd9bfuD8i9MNhZ9fj5Hlolpc8"
PROJECT = "studyforge-it8108"

EMAIL = f"probe-{int(time.time())}@studyforge.test"
PASSWORD = "Probe-Test-1!"
DISPLAY_NAME = "Rules Probe"

failures: list[str] = []


def call(url: str, payload: dict, token: str | None = None) -> tuple[int, dict]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            **({"Authorization": f"Bearer {token}"} if token else {}),
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read() or b"{}")


def patch(path: str, fields: dict, token: str, mask: str | None) -> tuple[int, dict]:
    """Patch specific fields, the way the client SDK writes.

    A `None` mask replaces the whole document (creation). Otherwise the mask names the
    fields being written, which is what makes `affectedKeys()` in the rules evaluate a
    single-field change rather than a full overwrite.
    """
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}"
        f"/databases/(default)/documents/{path}"
    )
    if mask:
        url += "?" + "&".join(f"updateMask.fieldPaths={name}" for name in mask.split(","))

    request = urllib.request.Request(
        url,
        data=json.dumps({"fields": fields}).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"},
        method="PATCH",
    )
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read() or b"{}")


def check(label: str, actual: int, expected: int) -> None:
    ok = actual == expected
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}: HTTP {actual} (expected {expected})")
    if not ok:
        failures.append(f"{label}: got {actual}, expected {expected}")


def main() -> int:
    print("=" * 72)
    print("Live rules probe — the DEPLOYED project, evaluated as a real client")
    print("=" * 72)

    status, body = call(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}",
        {"email": EMAIL, "password": PASSWORD, "returnSecureToken": True},
    )
    if status != 200:
        print(f"  could not create the probe account: HTTP {status} {body}")
        return 1

    token = body["idToken"]
    uid = body["localId"]
    print(f"  probe account: {uid}")

    try:
        print()
        print("1. creation and the self-service allowlist")

        # THE TRAP THE APP HAS TO AVOID. A merge-write against a document that does not exist
        # is a CREATE, and `create` pins role/plan, which the wizard's payload does not carry.
        # So this is DENIED, and the app has to bootstrap the document first (the Swift side's
        # `FirebaseAuthService.ensureUserDocument`). If this ever returns 200, the create rule
        # has been loosened and the bootstrap is no longer what protects the wizard.
        status, _ = patch(
            f"users/{uid}",
            {"university": {"stringValue": "Bahrain Polytechnic"}},
            token,
            "university",
        )
        check("write a profile field BEFORE any document exists", status, 403)

        # Creation is pinned to student/free by the rules, so this is the only shape that
        # can succeed. A full-document write, i.e. no update mask.
        status, _ = patch(
            f"users/{uid}",
            {
                "displayName": {"stringValue": DISPLAY_NAME},
                "role": {"stringValue": "student"},
                "plan": {"stringValue": "free"},
            },
            token,
            None,
        )
        check("create own document as student/free", status, 200)

        # The half that matters most: a fix that blocks the feature it protects is not a
        # fix. The profile wizard (B01) writes exactly these fields.
        status, _ = patch(
            f"users/{uid}",
            {"university": {"stringValue": "Bahrain Polytechnic"}},
            token,
            "university",
        )
        check("update own profile (university)", status, 200)

        status, _ = patch(f"users/{uid}", {"streak": {"integerValue": "999"}}, token, "streak")
        check("forge own streak", status, 403)

        status, _ = patch(
            f"users/{uid}",
            {"badges": {"arrayValue": {"values": [{"stringValue": "night_owl"}]}}},
            token,
            "badges",
        )
        check("award self badges", status, 403)

        status, _ = patch(
            f"users/{uid}",
            {"inventedInALaterSprint": {"booleanValue": True}},
            token,
            "inventedInALaterSprint",
        )
        check("write a field the rules never named", status, 403)

        status, _ = patch(f"users/{uid}", {"role": {"stringValue": "admin"}}, token, "role")
        check("promote self to admin (regression)", status, 403)

        status, _ = patch(f"users/{uid}", {"plan": {"stringValue": "pro"}}, token, "plan")
        check("upgrade own plan (regression)", status, 403)

    finally:
        print()
        print("2. teardown")
        status, _ = call(
            f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={API_KEY}",
            {"idToken": token},
        )
        print(f"  deleted the auth account: HTTP {status}")
        print(f"  ORPHANED — remove by hand: users/{uid}")

    print()
    if failures:
        print("VERDICT: FAILED")
        for failure in failures:
            print(f"  x {failure}")
        return 1

    print("VERDICT: ALL LIVE CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())

