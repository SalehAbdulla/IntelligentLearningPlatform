//
//  PromoCode.swift
//  StudyForge
//
//  F13 — the discount entered on the order summary (docs/03 §L L03).
//
//  HONEST SCOPE NOTE
//  -----------------
//  In production `promoCodes/{code}` is a Cloud-Function-ONLY collection (docs/05 §2): a
//  client that could read the table could enumerate every code, and one that could write it
//  could mint its own. So the authority is the server, and the discount that matters is
//  applied again inside `createCharge`.
//
//  This local table exists for the same reason every other store does — so the field is
//  demonstrable with no Firebase project — and it is deliberately marked as sandbox data
//  rather than presented as the real thing.
//

import Foundation

/// A promotional discount: a percentage off a list price.
struct PromoCode: Identifiable, Equatable, Sendable, Codable {

    /// The stored code, already upper-cased (see `normalise`).
    let code: String

    /// Whole percent off. Clamped at construction so no code can discount more than 100 %.
    let percentOff: Int

    var id: String { code }

    init(code: String, percentOff: Int) {
        self.code = PromoCode.normalise(code)
        self.percentOff = max(0, min(100, percentOff))
    }

    /// The discount, in fils, on a VAT-INCLUSIVE list amount.
    ///
    /// Rounded DOWN: a promo may never discount more than its stated percentage once
    /// rounding is applied, so the charged total can only ever be the same or higher than
    /// the student was shown — never a surprise. (A discount that rounds UP is a receipt
    /// that does not match the order summary.)
    func discountFils(on listFils: Int) -> Int {
        Int((Double(listFils) * Double(percentOff) / 100).rounded(.down))
    }

    /// Trims and upper-cases raw input so `" study20 "` matches `STUDY20`.
    ///
    /// Codes are case-insensitive to the user and case-sensitive in storage — a single
    /// normalisation point keeps the two from disagreeing.
    static func normalise(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

/// The stand-in promo table used until the Cloud Function owns codes (see the note above).
enum PromoSandbox {

    /// Codes that work in the demo build.
    static let codes: [PromoCode] = [
        PromoCode(code: "STUDY20", percentOff: 20),
        PromoCode(code: "WELCOME10", percentOff: 10),
    ]

    /// Validates raw input, returning the matching code or `nil`.
    ///
    /// An unknown code returns `nil` rather than throwing: L03 treats a bad code as inline
    /// field feedback, not as a screen-level failure, so the checkout is not interrupted by
    /// a typo.
    static func validate(_ raw: String) -> PromoCode? {
        let normalised = PromoCode.normalise(raw)
        guard !normalised.isEmpty else { return nil }
        return codes.first { $0.code == normalised }
    }
}
