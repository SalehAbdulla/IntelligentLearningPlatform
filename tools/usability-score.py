#!/usr/bin/env python3
"""usability-score.py — score the §17.3 usability test and print the block to paste into it.

WHY THIS EXISTS
  The System Usability Scale is only comparable to published values if it is scored exactly as
  Brooke (1996) defined it, and the two mistakes that ruin it are both easy to make: calling the
  result a percentage, and averaging the item responses across participants before scoring. This
  script does the arithmetic the one correct way and prints the section, so the write-up is a
  paste rather than a calculation done under time pressure.

THE RULE, IMPLEMENTED EXACTLY
  1. odd items (1, 3, 5, 7, 9): the contribution is response - 1
  2. even items (2, 4, 6, 8, 10): the contribution is 5 - response
  3. the ten contributions sum to 0-40
  4. the sum is multiplied by 2.5, giving that participant's score out of 100
  5. the reported figure is the MEAN of the participants' scores, to one decimal place

INPUT  a plain-text file, one line per participant, either form:
    P1: 4 2 5 1 4 2 5 1 5 2
    | P1 | 4 2 5 1 4 2 5 1 5 2 |
  and optionally one line per task, five marks of P (pass) or F (fail), in participant order:
    T1: P P P F P

USAGE
    python3 tools/usability-score.py research/usability/responses.md

The output is Markdown: a participant table, the score with its Bangor (2009) band, an optional
task-success table, and a paragraph written in the document's voice. Nothing is written to any
file, so a draft can be checked before it is pasted.
"""
import re
import sys

BANDS = [
    (85.0, 'Excellent', 'A'),
    (72.0, 'Good', 'B'),
    (68.0, 'OK, at the average', 'C'),
    (51.0, 'Poor', 'D'),
    (0.0, 'Awful', 'F'),
]


def band(score):
    for low, adjective, grade in BANDS:
        if score > low or (low == 0.0 and score >= 0.0):
            return adjective, grade
    return 'Awful', 'F'


def parse(path):
    responses, tasks = [], []
    for lineno, raw in enumerate(open(path, encoding='utf-8'), start=1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        m = re.match(r'^\|?\s*(P\d+)\s*[:|]\s*([1-5](?:\s*[,\s]\s*[1-5]){9})\s*\|?\s*$', line)
        if m:
            values = [int(v) for v in re.findall(r'[1-5]', m.group(2))]
            responses.append((m.group(1).upper(), values))
            continue
        m = re.match(r'^\|?\s*(T\d+)\s*[:|]\s*([PF](?:\s*[,\s]\s*[PF]){4})\s*\|?\s*$', line, re.I)
        if m:
            marks = re.findall(r'[PF]', m.group(2).upper())
            tasks.append((m.group(1).upper(), marks))
            continue
        sys.exit('line %d is not a participant row or a task row: %s' % (lineno, line))
    if not responses:
        sys.exit('no participant rows found in %s' % path)
    return responses, tasks


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__.strip().split('USAGE')[1].strip().splitlines()[0].strip())
    responses, tasks = parse(sys.argv[1])

    rows, scores = [], []
    for pid, values in responses:
        contributions = [v - 1 if i % 2 == 0 else 5 - v for i, v in enumerate(values)]
        total = sum(contributions)
        score = total * 2.5
        scores.append(score)
        rows.append((pid, values, contributions, total, score))

    mean = sum(scores) / len(scores)
    adjective, grade = band(mean)
    n = len(scores)

    print('## 17.3 Usability test\n')
    print('**%d participants**, none a squad member, each session moderated and think-aloud, '
          'recorded in `research/usability/`.\n' % n)
    print('| Participant | SUS responses, items 1 to 10 | Sum (0 to 40) | SUS score (0 to 100) |')
    print('|---|---|---|---|')
    for pid, values, _c, total, score in rows:
        print('| %s | %s | %d | %.1f |' % (pid, ' '.join(str(v) for v in values), total, score))
    print('| **Mean** | | | **%.1f** |' % mean)
    print()
    print('The test produced **a SUS score of %.1f**, which sits in the **%s** band (**grade %s**) '
          'on the Bangor, Kortum and Miller (2009) scale, against the published average of 68. It '
          'is a 0 to 100 scale, not a percentage.' % (mean, adjective, grade))
    print()

    if tasks:
        labels = {
            'T1': 'T1 create an account',
            'T2': 'T2 add the PDF on the device',
            'T3': 'T3 get a summary',
            'T4': 'T4 turn it into flashcards',
            'T5': 'T5 study the cards',
            'T6': 'T6 quiz on the material',
        }
        print('| Task | %s | Passed |' % ' | '.join(pid for pid, _v, _c, _t, _s in rows))
        print('|---|%s---|' % ('---|' * n))
        for tid, marks in tasks:
            cells = [marks[i] if i < len(marks) else '?' for i in range(n)]
            print('| %s | %s | %d of %d |' % (labels.get(tid, tid), ' | '.join(cells),
                                              cells.count('P'), n))
        print()

    print('| Item | %s |' % ' | '.join(pid for pid, _v, _c, _t, _s in rows))
    print('|---|%s' % ('---|' * n))
    for i in range(10):
        cells = ' | '.join(str(values[i]) for _pid, values, _c, _t, _s in rows)
        print('| %d | %s |' % (i + 1, cells))
    print()
    print('Scored by Brooke (1996): odd items contribute the response minus 1, even items 5 minus '
          'the response, the ten contributions sum to 0 to 40, and the sum is multiplied by 2.5. '
          'The mean is taken of the %d final scores, not of the item responses.' % n)


if __name__ == '__main__':
    main()
