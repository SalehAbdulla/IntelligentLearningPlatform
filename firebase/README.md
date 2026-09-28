# Firebase

Created in Phase 7:

- firestore.rules        role-based, deny-by-default
- firestore.indexes.json composite indexes
- storage.rules          owner + folder-grant access
- functions/             Tap webhook + nightly aggregation ONLY

See docs/05-DATA-MODEL-SECURITY.md

WARNING: set a Google Cloud budget alert and spend cap before the first
Cloud Functions deploy. See docs/04-TECH-ARCHITECTURE-COST.md section 5.
