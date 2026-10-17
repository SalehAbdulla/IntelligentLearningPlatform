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
    6. Plural rules in every .stringsdict: key parity across languages, and that Arabic
       declares all six CLDR categories. A rule defining only `one`/`other` renders the
       wrong grammar for 2, for 3-10 and for 11-99 — and nothing in the build says so.

USAGE
    python3 tools/check-strings.py            # verify
    python3 tools/check-strings.py --list     # also dump the key set
"""

from __future__ import annotations

import plistlib
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


def parse_stringsdict(path: Path) -> tuple[dict[str, list[str]], list[str]]:
    """Read a .stringsdict and return {key: [plural categories]} plus any problems.

    A .stringsdict is a plist, so `plistlib` reads it — but only the *categories* matter
    here. A key whose Arabic side defines `one`/`other` while Arabic needs six forms is a
    real defect that no compiler will mention: the string simply renders with the wrong
    grammar, which is exactly the failure this project's Arabic support exists to avoid.
    """
    problems: list[str] = []
    categories: dict[str, list[str]] = {}

    try:
        with open(path, "rb") as handle:
            plist = plistlib.load(handle)
    except Exception as error:  # noqa: BLE001 - report, do not crash the gate
        return {}, [f"{path.parent.stem}: Localizable.stringsdict does not parse: {error}"]

    if not isinstance(plist, dict):
        return {}, [f"{path.parent.stem}: Localizable.stringsdict is not a dictionary"]

    for key, value in plist.items():
        if not isinstance(value, dict):
            problems.append(f"{path.parent.stem}: '{key}' is not a plural-rule dictionary")
            continue
        # The count variable is named by the format key, e.g. "%#@seconds@" -> "seconds".
        found: list[str] = []
        for spec in value.values():
            if isinstance(spec, dict) and "NSStringFormatSpecTypeKey" in spec:
                found = sorted(
                    k for k in spec
                    if k not in ("NSStringFormatSpecTypeKey", "NSStringFormatValueTypeKey")
                )
        if not found:
            problems.append(f"{path.parent.stem}: '{key}' declares no plural categories")
        categories[key] = found

    return categories, problems


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

    # ---- 6: plural rules (.stringsdict) ----------------------------------
    # A .stringsdict is consulted in preference to .strings, so a key that exists in both is
    # resolved by the plural rule. Nothing in the build validates it: a malformed plist is
    # ignored, and a language missing a category renders the wrong grammar silently.
    print()
    print("5. plural rules (.stringsdict)")
    dict_files = sorted(RESOURCES.glob("*.lproj/Localizable.stringsdict"))
    if not dict_files:
        print("   no .stringsdict files (nothing to check)")
    else:
        plural: dict[str, dict[str, list[str]]] = {}
        for path in dict_files:
            language = path.parent.stem
            categories, file_problems = parse_stringsdict(path)
            plural[language] = categories
            problems.extend(file_problems)
            print(f"   {language:<4} {len(categories):>3} plural key(s)")

        # Key parity: a language with no rule for a key falls back to the flat .strings
        # entry, which is correct English and wrong Arabic — so a missing key is a problem.
        dict_reference = "en" if "en" in plural else sorted(plural)[0]
        for language in sorted(plural):
            if language == dict_reference:
                continue
            missing = sorted(set(plural[dict_reference]) - set(plural[language]))
            if missing:
                problems.append(
                    f"{language}: no plural rule for {missing} - falls back to the flat string"
                )

        # Category coverage: Arabic needs six forms. A rule defining only one/other is the
        # mistake this file was added to prevent.
        ARABIC_MINIMUM = {"zero", "one", "two", "few", "many", "other"}
        if "ar" in plural:
            for key, cats in plural["ar"].items():
                absent = sorted(ARABIC_MINIMUM - set(cats))
                if absent:
                    problems.append(
                        f"ar: '{key}' is missing plural categor{'y' if len(absent) == 1 else 'ies'} "
                        f"{absent} - Arabic needs all six, so this renders the wrong grammar"
                    )
        print(f"   {len(dict_files)} file(s) checked")

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

