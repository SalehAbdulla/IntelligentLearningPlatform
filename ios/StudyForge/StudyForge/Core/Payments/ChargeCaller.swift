//
//  ChargeCaller.swift
//  StudyForge
//
//  F13: the `createCharge` Cloud Function, behind a seam.
//
//  WHY THE CALL IS ABSTRACTED
//  --------------------------
//  `TapPaymentsGateway` must be unit-testable without a deployed function or a Tap account
//  (docs/09 D22). This protocol is the seam: the real conformer calls the callable, and a test
//  conformer returns a canned ticket. The Tap SECRET never appears here; it lives only in the
//  function (backend/functions/src/index.ts), which is exactly why the client asks the server to
//  start a charge instead of calling Tap itself.
//

import Foundation
import FirebaseFunctions

/// What the server returns from `createCharge`.
struct ChargeTicket: Sendable, Equatable {
    /// Tap's charge id: the receipt's traceable reference.
    let tapChargeId: String
    /// The Tap hosted-page URL the student is sent to, when a redirect is needed.
    let redirectURL: URL?
}

/// Starts a charge on the server. Only the plan is sent; the amount is resolved server-side.
protocol ChargeCaller: Sendable {
    func createCharge(planId: String, term: String) async throws -> ChargeTicket
}

/// Failures specific to starting a charge.
enum ChargeCallerError: Error, Equatable {
    /// The callable could not be reached, or returned an unexpected shape.
    case unavailable
}

/// The real caller: invokes the `createCharge` callable function.
struct FirebaseChargeCaller: ChargeCaller {
    func createCharge(planId: String, term: String) async throws -> ChargeTicket {
        do {
            let result = try await Functions.functions()
                .httpsCallable("createCharge")
                .call(["planId": planId, "term": term])

            guard let data = result.data as? [String: Any] else {
                throw ChargeCallerError.unavailable
            }
            let chargeId = data["tapChargeId"] as? String ?? ""
            let urlString = data["redirectURL"] as? String
            return ChargeTicket(
                tapChargeId: chargeId,
                redirectURL: urlString.flatMap(URL.init(string:))
            )
        } catch {
            throw ChargeCallerError.unavailable
        }
    }
}
