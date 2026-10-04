//
//  MoneyText.swift
//  StudyForge
//
//  F13 — money as the user reads it, in one place.
//
//  WHY ONE FORMATTER
//  -----------------
//  The order summary, the paywall cards and the receipt must all render `BHD 1.900` the
//  SAME way — including the three decimal places the Bahraini dinar uses and its position
//  relative to the number, which differs between English and Arabic. A `.currency`
//  `NumberFormatter` keyed on the ISO code gets placement and digits right per locale and
//  guarantees the three screens cannot drift.
//

import Foundation

/// Renders fils as display money.
enum MoneyText {

    /// A labelled amount — `BHD 1.900` in English, `BHD ١٫٩٠٠` in Arabic.
    ///
    /// Falls back to the plain decimal form if the formatter cannot produce a string, so a
    /// screen shows `BHD 1.900` rather than nothing at all.
    static func price(_ fils: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = MoneyCurrency.bhd
        formatter.locale = locale
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3

        let value = Double(fils) / Double(MoneyCurrency.minorUnitsPerMajor)
        return formatter.string(from: NSNumber(value: value))
            ?? "\(MoneyCurrency.bhd) \(PaymentCatalogue.amountString(fils, locale: locale))"
    }
}
