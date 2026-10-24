# Test fixture for tools/usability-score.py. NOT results, and not research data.
#
# It exists for one reason: P1's row is the worked example in
# research/usability/sus-questionnaire.md, which must score 87.5. If the tool ever stops
# printing 87.5 for that row, the tool is wrong.

P1: 4 2 5 1 4 2 5 1 5 2
P2: 5 1 4 2 5 2 4 1 5 1
P3: 4 2 4 2 4 2 4 2 4 2
P4: 5 1 5 1 5 1 5 1 5 1
P5: 3 2 4 2 4 2 3 2 4 2

T1: P P P P P
T2: P F P P P
T3: P P P F P
T4: P P F P P
T5: P P P P F
T6: P F P P P
