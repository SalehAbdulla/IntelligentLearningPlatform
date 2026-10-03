#!/usr/bin/env python3
"""check-strings.py — verify localisation files before they can ship broken.

WHY THIS EXISTS
    A `.strings` file fails SILENTLY. A missing key falls back to the key itself
    (`auth.login.title` shown to a user), and a malformed file is ignored with no
    build error — neither appears in `xcodebuild` output. This project ships
    English + Arabic, so the failure mode is an Arabic screen with English keys
    on it: exactly the kind of thing discovered during a VIVA.

WHAT IT CHECKS
    1. Every .strings file parses (one stray quote breaks the whole file).
    2. Every language defines the SAME key set — no missing, no extra.
    3. No duplicate keys within a file (later wins; the first is dead).
    4. Format placeholders match across languages. The dangerous one: `%d` in
       English and `%@` in Arabic is a runtime crash, not a visible typo.
    5. No empty values (an empty string renders as blank UI).

USAGE
    python3 tools/check-strings.py            # verify
    python3 tools/check-strings.py --list     # also dump the key set
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESOURCES = ROOT / "ios" / "StudyForge" / "StudyForge" / "Resources"

# Old-style plist entry:  "key" = "value";
ENTRY = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
# printf / NSString placeholders: %d %i %u %f %@ %s  (with optional flags/width)
PLACEHOLDER = re.compile(
    r"%(?:\d+\$)?[-+ #0]*[\d*]*(?:\.\d+)?(?:hh|h|ll|l|L|z|j|t)?([diuoxXfFeEgGaAcsp@])"
)


def parse(path: Path) -> tuple[dict[str, str], list[str]]:
    """Returns (key -> value, syntax problems)."""
    entries: dict[str, str] = {}
    problems: list[str] = []
    duplicates: list[str] = []

    in_block_comment = False
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()

        # Track /* ... */ so commented-out keys are not counted as live entries.
        if in_block_comment:
            if "*/" in line:
                in_block_comment = False
                line = line.split("*/", 1)[1].strip()
            else:
                continue
        if line.startswith("/*"):
            if "*/" not in line:
                in_block_comment = True
            continue
        if not line or line.startswith("//"):
            continue

        match = ENTRY.match(line)
        if not match:
            problems.append(
                f"{path.parent.stem}:{lineno}: not a valid `\"key\" = \"value\";` "
                f"entry -> {line[:70]}"
            )
            continue

        key, value = match.group(1), match.group(2)
        if key in entries:
            duplicates.append(key)
        entries[key] = value

    if duplicates:
        problems.append(
            f"{path.parent.stem}: duplicate keys (the later value silently wins): "
            f"{sorted(set(duplicates))}"
        )

    return entries, problems


def main() -> int:
    show_list = "--list" in sys.argv

    files = sorted(RESOURCES.glob("*.lproj/Localizable.strings"))
    if not files:
        print(f"x no Localizable.strings found under {RESOURCES}")
        return 1

    problems: list[str] = []
    catalogues: dict[str, dict[str, str]] = {}

    print("check-strings.py - localisation gate")
    print(f"  resources : {RESOURCES.relative_to(ROOT)}")
    print(f"  languages : {', '.join(sorted(f.parent.stem for f in files))}")
    print()

    # ---- 1 + 3: parse and de-duplicate -----------------------------------
    print("1. syntax and duplicates")
    for path in files:
        language = path.parent.stem
        entries, file_problems = parse(path)
        catalogues[language] = entries
        print(f"   {language:<4} {len(entries):>3} keys   {'OK' if not file_problems else 'FAIL'}")
        problems.extend(file_problems)

    # ---- 2: key parity ---------------------------------------------------
    print()
    print("2. key parity across languages")
    reference = "en" if "en" in catalogues else sorted(catalogues)[0]
    reference_keys = set(catalogues[reference])
    for language in sorted(catalogues):
        keys = set(catalogues[language])
        missing = sorted(reference_keys - keys)
        extra = sorted(keys - reference_keys)
        if missing:
            problems.append(
                f"{language}: missing {len(missing)} key(s) present in {reference}: {missing[:6]}"
            )
        if extra:
            problems.append(
                f"{language}: {len(extra)} key(s) absent from {reference}: {extra[:6]}"
            )
        note = "(reference)" if language == reference else ("OK" if not missing and not extra else "FAIL")
        print(f"   {language:<4} missing={len(missing):<3} extra={len(extra):<3} {note}")

    # ---- 4: placeholder agreement ----------------------------------------
    print()
    print("3. placeholder agreement")
    mismatches = 0
    for key, english in catalogues.get(reference, {}).items():
        expected = sorted(PLACEHOLDER.findall(english))
        for language in sorted(catalogues):
            if language == reference:
                continue
            translated = catalogues[language].get(key)
            if translated is None:
                continue
            actual = sorted(PLACEHOLDER.findall(translated))
            if actual != expected:
                mismatches += 1
                problems.append(
                    f"placeholder mismatch for '{key}': {reference} has {expected}, "
                    f"{language} has {actual} - crashes or renders garbage at runtime"
                )
    print(f"   {mismatches} mismatch(es)")

    # ---- 5: empty values -------------------------------------------------
    print()
    print("4. non-empty values")
    empty = 0
    for language, entries in catalogues.items():
        for key, value in entries.items():
            if not value.strip():
                empty += 1
                problems.append(f"{language}: '{key}' has an empty value (renders blank UI)")
    print(f"   {empty} empty value(s)")

    if show_list:
        print()
        print("key set:")
        for key in sorted(reference_keys):
            print(f"   {key}")

    print()
    if problems:
        print("PROBLEMS:")
        for problem in problems:
            print(f"  x {problem}")
        print()
        print("VERDICT: CHECKS FAILED")
        return 1

    print(f"VERDICT: ALL CHECKS PASSED ({len(reference_keys)} keys x {len(catalogues)} languages)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

