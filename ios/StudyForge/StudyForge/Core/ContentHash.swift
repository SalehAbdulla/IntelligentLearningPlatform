//
//  ContentHash.swift
//  StudyForge
//
//  A stable hash of text, shared by everything that keys on content.
//
//  WHY THIS SITS AT THE TOP OF `Core` RATHER THAN INSIDE A FEATURE
//  --------------------------------------------------------------
//  Two unrelated layers need the SAME digest: the AI response cache
//  (`AICostGovernor`, so a document is not paid for twice) and a material's `textHash` (which
//  `firestore.rules` requires on create). A copy in each place would eventually disagree, and a
//  disagreement shows up as a cache that misses or a write the server rejects — neither of which
//  points at the hash. It belongs to no feature, which is exactly why it is not inside one.
//

import CryptoKit
import Foundation

enum ContentHash {

    /// The lowercase hex SHA-256 digest of `text`.
    ///
    /// SHA-256 rather than `Hashable`'s `hashValue`, because Swift seeds that randomly per
    /// process: the same document would hash differently on every launch, so nothing keyed on it
    /// would ever match across launches.
    static func sha256Hex(of text: String) -> String {
        SHA256.hash(data: Data(text.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
