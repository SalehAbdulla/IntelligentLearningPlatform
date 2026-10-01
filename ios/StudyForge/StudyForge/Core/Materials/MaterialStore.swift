//
//  MaterialStore.swift
//  StudyForge
//
//  Where the student's materials are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, ON PURPOSE
//  ----------------------
//  Cloud Storage is bypassed (D24, docs/09 R21), so a material's text lives on the device: no
//  server needs the bytes, because the model that reads them runs here too. The consequence for
//  this protocol is that it is the ONLY place that knows that. A screen asks for materials and
//  never learns whether they came from a file, a database or a server — which is what keeps the
//  decision reversible, and what makes every screen testable with `InMemoryMaterialStore`.
//
//  WHY `async` EVEN THOUGH THE DEFAULT IMPLEMENTATION IS A FILE
//  -----------------------------------------------------------
//  Reading and writing a file is IO and must not run on the main actor, and the moment materials
//  gain a remote half — syncing derived text, say — the call becomes a network round trip. An
//  interface that is already `async` absorbs that change without touching a caller.
//

import Foundation

/// Reads and writes the student's local materials.
protocol MaterialStore: Sendable {

    /// Every material, newest first.
    func all() async throws -> [Material]

    /// Stores a material, replacing any existing one with the same id.
    func add(_ material: Material) async throws

    /// Removes a material. Removing one that is already gone is not an error.
    func delete(id: String) async throws

    /// One material, or `nil` when nothing is stored under that id.
    func material(id: String) async throws -> Material?
}

/// Failures from the material store, in the app's own vocabulary.
enum MaterialError: Error, Equatable {

    /// The local store could not be read or written.
    ///
    /// One case rather than a code per `FileManager` error: nothing a student can do differs
    /// between them, and the screen shows a retry either way.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            // `.server` carries a reference and a retry, which is the honest description of
            // "the app could not reach its own storage" — a defect on our side, not the
            // student's mistake.
            .server(reference: "material-store-failed")
        }
    }
}
