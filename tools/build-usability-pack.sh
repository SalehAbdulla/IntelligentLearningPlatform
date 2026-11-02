#!/usr/bin/env bash
# build-usability-pack.sh — assemble the printable pack for the §17.3 usability session.
#
# WHY THIS EXISTS
#   The usability test is run by a human, in a room, with paper. research/usability/ holds the
#   method as separate Markdown files (protocol, consent, questionnaire, log, results), which is
#   the right shape for editing and the wrong shape for handing out: five participants need five
#   consent sheets, five questionnaires and five log sheets, and the facilitator needs the script
#   and the scoring rule. This script turns those files into one printable document, so the pack
#   cannot be printed half-complete.
#
# WHAT IT DOES
#   1. facilitator part: the method, the script, the tasks, the do-not-help rule and the SUS
#      scoring rule (split out of the questionnaire, which participants must not see)
#   2. participant part, one copy each: the consent sheet, the ten SUS items, the facilitator's
#      log sheet, and the session results form
#   3. page breaks between the parts, so each sheet prints on its own pages
#   4. renders through pandoc to research/usability/StudyForge-Usability-Packet.docx
#
# USAGE
#   bash tools/build-usability-pack.sh
#
# REQUIREMENTS  pandoc (brew install pandoc).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

U="research/usability"
OUT="$U/StudyForge-Usability-Packet.docx"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v pandoc >/dev/null 2>&1 || { echo "pandoc not found. Install it with: brew install pandoc" >&2; exit 1; }
for f in protocol.md consent-form.md sus-questionnaire.md participant-log.md results.md; do
  [ -f "$U/$f" ] || { echo "$U/$f is missing" >&2; exit 1; }
done

python3 - "$U" "$TMP/pack.md" <<'PY'
import os, sys

src, out = sys.argv[1], sys.argv[2]
BREAK = '\n```{=openxml}\n<w:p><w:r><w:br w:type="page"/></w:r></w:p>\n```\n\n'


def read(name):
    return open(os.path.join(src, name), encoding='utf-8').read().rstrip() + '\n'


sus = read('sus-questionnaire.md')
marker = '## Facilitator: how to score it'
if marker in sus:
    participant_sus, facilitator_scoring = sus.split(marker, 1)
    facilitator_scoring = marker + facilitator_scoring
else:
    participant_sus, facilitator_scoring = sus, ''

parts = [
    '# StudyForge usability session pack',
    '',
    '**IT8108, Project Brief 2, Intelligent Learning Platform. Session pack for Design Document '
    '§17.3, the usability test with five participants.**',
    '',
    '| Print | How many copies |',
    '|---|---|',
    '| Part 1, the facilitator guide (method, script, tasks, scoring rule) | one |',
    '| Part 2, participant information and consent | one per participant, five |',
    '| Part 3, the System Usability Scale questionnaire | one per participant, five |',
    '| Part 4, the facilitator log sheet | one per participant, five |',
    '| Part 5, the session results form | one, completed after the session |',
    '',
    'Everything needed to run the session is in this document. The method is in '
    '`research/usability/protocol.md`, the scoring rule is Brooke (1996) exactly as published, and '
    'the results go in `research/usability/results.md` only after the session has happened.',
    '',
    BREAK,
    '# Part 1. Facilitator guide',
    '',
    '## Method, script and tasks',
    '',
    read('protocol.md'),
    '',
    BREAK,
    '# Part 1, continued. Scoring the System Usability Scale',
    '',
    facilitator_scoring or '(the scoring rule is in research/usability/sus-questionnaire.md)',
    '',
    BREAK,
    '# Part 2. Participant information and consent',
    '',
    '**One copy per participant. Read the information aloud, answer any question, and only then '
    'ask for a signature. A participant who does not consent is thanked and the session ends; a '
    'partial test is not run.**',
    '',
    read('consent-form.md'),
    '',
    BREAK,
    '# Part 3. System Usability Scale',
    '',
    '**One copy per participant, handed over after the six tasks. Do not explain any item.**',
    '',
    participant_sus,
    '',
    BREAK,
    '# Part 4. Facilitator log sheet',
    '',
    '**One copy per participant. Record task success, time on task and confusions in the '
    "participant's own words.**",
    '',
    read('participant-log.md'),
    '',
    BREAK,
    '# Part 5. Session results',
    '',
    '**One copy, completed within 24 hours of the session. The SUS score is the mean of the five '
    "participants' scores, to one decimal place.**",
    '',
    read('results.md'),
    '',
]

open(out, 'w', encoding='utf-8').write('\n'.join(parts))
print('   pack assembled from 5 files in %s' % src)
PY

pandoc "$TMP/pack.md" -o "$OUT" --wrap=none
printf '  ok   written: %s (%s)\n' "$OUT" "$(du -h "$OUT" | cut -f1)"
