//
//  ProfileError.swift
//  StudyForge
//
//  Failures from the profile write, in the app's own vocabulary — the same shape as
//  `AuthError`, so no screen ever sees a Firestore error code or a server string
//  (docs/04 §8).
//

import Foundation

enum ProfileError: Error, Equatable {

    /// The server refused the write.
    ///
    /// On `users/{uid}` this is almost always the field allowlist rejecting a key nobody
    /// has named — which means the APP asked for something it is not allowed to write.
    /// That is a defect on our side, not a permission problem the student has, and the
    /// distinction decides both the copy and who is expected to act on it.
    case writeRejected(reference: String)

    /// The server refused to let the app READ the document.
    ///
    /// Separate from `writeRejected` because it is a different defect with a different fix:
    /// a read is not gated by the field allowlist but by the document-level `read` rule, so
    /// this means the app asked for a document it is not entitled to see. On `users/{uid}`
    /// that should be unreachable — the rule permits `isSelf` — which is exactly why it is
    /// worth naming rather than folding into `unknown` if it ever appears.
    case readRejected(reference: String)

    /// No signed-in user, so there is no `users/{uid}` document to write to.
    ///
    /// Unreachable from the wizard, which sits behind authentication — but it is the
    /// difference between failing and silently writing to the wrong document, so it is
    /// checked rather than assumed.
    case notSignedIn

    case offline
    case unknown(underlying: String)

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .writeRejected(let reference), .readRejected(let reference):
            // NOT `.notPermitted`: telling a student "you don't have access to this"
            // about their own profile would be both wrong and unactionable. A server
            // error carries a reference and a retry, which is the honest description.
            .server(reference: reference)
        case .notSignedIn:
            .authFailed(reason: "Your session ended before we could save. Please sign in again.")
        case .offline:
            .offline
        case .unknown:
            .unknown
        }
    }
}
