//
//  SFChipFlow.swift
//  StudyForge
//
//  A wrapping row of chips.
//
//  WHY A CUSTOM LAYOUT RATHER THAN AN HSTACK OR A GRID
//  --------------------------------------------------
//  `HStack` clips a long chip row instead of wrapping it, and `LazyVGrid` forces every
//  cell to the same width, which makes a short course name as wide as a long one. A
//  wrapping flow is the only one of the three that behaves like the design, and SwiftUI
//  has none built in, so it is written once here and reused (B01's courses today, C09's
//  active filters next).
//
//  WHY IT DOES NOT TAKE A LAYOUT DIRECTION
//  ---------------------------------------
//  It looks like a custom `Layout` should need the environment's `layoutDirection`, since
//  a `Layout` is not a `View` and cannot read the environment directly. It does not:
//  SwiftUI mirrors the coordinate space it hands to `placeSubviews`, so an RTL build lays
//  the chips out from the trailing edge on its own. Mirroring by hand as well cancels the
//  framework's, and the chips come out in REVERSE order — which is what the first version
//  of this file did, and what the Arabic simulator screenshot caught: the row read
//  "Databases → Data Structures → Introduction to Programming".
//

import SwiftUI

/// - Note: `SwiftUI.Layout` is spelled out deliberately. This target also declares its own
///   `Layout` (the screen-margin/touch-target token enum in `DesignSystem/Spacing.swift`),
///   which shadows the protocol name inside the module — an unqualified `Layout` here
///   resolves to the token type and the file will not compile.
struct SFChipFlow: SwiftUI.Layout {

    /// Gap between chips on the same line.
    var spacing: CGFloat = Spacing.s2

    /// Gap between lines.
    var lineSpacing: CGFloat = Spacing.s2

    // MARK: - Layout

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let lines = lines(for: subviews, maxWidth: maxWidth)

        let height = lines.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, lines.count - 1))
        let width = lines.map(\.width).max() ?? 0

        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    ) {
        var y = bounds.minY

        for line in lines(for: subviews, maxWidth: bounds.width) {
            var offset: CGFloat = 0

            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)

                // Placed leading-to-trailing inside the bounds we were given. RTL needs no
                // special case here: SwiftUI mirrors the coordinate space it hands a
                // custom layout, so flipping x by hand as well would mirror TWICE — which
                // reverses the chip order in Arabic. Verified on the simulator, not
                // assumed: the first version of this file did that flip, and the Arabic
                // screenshot read "Databases → Data Structures → Introduction to
                // Programming" where it should read the opposite.
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + offset, y: y),
                    proposal: ProposedViewSize(size)
                )

                offset += size.width + spacing
            }

            y += line.height + lineSpacing
        }
    }

    // MARK: - Line breaking

    /// One wrapped line: which subviews it holds, and the size it occupies.
    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Greedy first-fit line breaking — the same rule a text layout engine uses, and the
    /// simplest one that never reorders the chips.
    private func lines(for subviews: LayoutSubviews, maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = []
        var current = Line()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let widthWithChip = current.indices.isEmpty
                ? size.width
                : current.width + spacing + size.width

            // A chip wider than the container still gets its own line rather than being
            // dropped — an overflowing chip is a data problem, a missing one is a bug.
            if !current.indices.isEmpty && widthWithChip > maxWidth {
                lines.append(current)
                current = Line()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
                continue
            }

            current.indices.append(index)
            current.width = widthWithChip
            current.height = max(current.height, size.height)
        }

        if !current.indices.isEmpty { lines.append(current) }
        return lines
    }
}
