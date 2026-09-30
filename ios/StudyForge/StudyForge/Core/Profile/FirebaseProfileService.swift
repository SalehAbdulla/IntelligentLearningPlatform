//
//  FirebaseProfileService.swift
//  StudyForge
//
//  The Firestore implementation of the profile write. The ONLY file in the profile stack
//  that imports Firebase.
//
//  It writes four fields plus a server timestamp — no more. The rule it answers to is an
//  allowlist (`onlyChanges(editableProfileFields())`, backend/firestore.rules), so an
//  extra key here does not persist quietly: it fails the whole write. `merge: true` is
//  the other half of that care — an update must not become a replace, or the `plan`,
//  `streak` and `badges` a Cloud Function owns would disappear the moment a student
//  corrects their major.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseProfileService: ProfileService, @unchecked Sendable {

    /// - Note: `@unchecked Sendable` for the SDK reference only. `Firestore` is documented
    ///   as safe for concurrent use but is not annotated `Sendable`, which the compiler
    ///   cannot verify. This type owns no other state.
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func saveAcademicProfile(_ profile: AcademicProfile) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ProfileError.notSignedIn
        }

        // Field names come from `AcademicProfile.Field` so this write and the rules
        // allowlist cannot drift apart. `updatedAt` is a SERVER timestamp: the field is
        // writable but must not be forgeable, and a client clock is trivially backdated.
        let fields: [String: Any] = [
            AcademicProfile.Field.university: profile.university,
            AcademicProfile.Field.major: profile.major,
            AcademicProfile.Field.year: profile.year,
            AcademicProfile.Field.courseIds: profile.courseIds,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        do {
            try await firestore
                .collection(FirebaseAuthService.usersCollection)
                .document(uid)
                .setData(fields, merge: true)
        } catch {
            throw Self.map(error)
        }
    }

    /// Translates a Firestore failure into the app's vocabulary, so no screen has to know
    /// about `FirestoreErrorCode`.
    static func map(_ error: any Error) -> ProfileError {
        let nsError = error as NSError

        // Connectivity surfaces as `URLError`, not as a Firestore error, so it is checked
        // first — the same ordering bug that makes "no internet" show up as "wrong
        // password" in so many apps.
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return .offline
        }

        guard nsError.domain == FirestoreErrorDomain,
              // Note the nested `.Code`: the ObjC `NS_ERROR_ENUM` imports as a namespace
              // type, unlike FirebaseAuth's flat `AuthErrorCode`. The SDK's own Swift
              // compile tests use this spelling.
              let code = FirestoreErrorCode.Code(rawValue: nsError.code) else {
            return .unknown(underlying: nsError.localizedDescription)
        }

        switch code {
        case .permissionDenied:
            // The interesting one. It means the client asked to write a field the
            // allowlist does not name — our bug, not the student's mistake — so it is
            // reported with a traceable reference rather than as an access problem.
            return .writeRejected(reference: "profile-write-denied")
        case .unavailable, .deadlineExceeded:
            return .offline
        case .unauthenticated:
            return .notSignedIn
        default:
            return .unknown(underlying: nsError.localizedDescription)
        }
    }
}
