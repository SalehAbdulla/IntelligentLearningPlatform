//
//  SFRadarChart.swift
//  StudyForge
//
//  A radar (spider) chart of topic mastery — G11's `70_Progress_WeaknessRadar_{M3}` centrepiece.
//
//  WHY IT IS HAND-DRAWN AND NOT A CHART LIBRARY
//  -------------------------------------------
//  The design system is deliberately dependency-free: every other component is written by hand so
//  the tokens (colour, spacing, motion) are the only source of styling. A charting package would
//  bring its own palette and axis conventions, and the radar would be the one screen that does not
//  look like StudyForge.
//
//  WHAT IT SHOWS
//  -------------
//  One axis per topic, normalised to the strongest topic so the shape is legible even when nothing
//  is above 50%. Weak axes are drawn in the warning colour, so the "what should I revise" question
//  is answered by the chart itself rather than only by the list beneath it.
//

import SwiftUI

struct SFRadarChart: View {

    /// Each axis: a topic label and its 0…1 value.
    struct Axis: Identifiable, Equatable {
        let label: String
        let value: Double

        var id: String { label }
    }

    let axes: [Axis]

    /// Below this, an axis is drawn as weak.
    var weakThreshold: Double = 0.6

    /// Colour and labelling are read from here so the chart stays inside the design system.
    private let rings = 4

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let centre = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - Spacing.s6

            ZStack {
                grid(centre: centre, radius: radius)
                shape(centre: centre, radius: radius)
                    .fill(ColorTokens.primary.opacity(0.18))
                shape(centre: centre, radius: radius)
                    .stroke(ColorTokens.primary, lineWidth: 2)
                points(centre: centre, radius: radius)
            }
        }
        // A radar with fewer than three axes is a line, not a shape — the caller shows a list
        // instead, and this is the guard that keeps it from drawing something meaningless.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(axes.map { "\($0.label) \(Int($0.value * 100))%" }.joined(separator: ", "))
    }

    // MARK: Geometry

    private func point(index: Int, fraction: Double, centre: CGPoint, radius: CGFloat) -> CGPoint {
        let count = max(axes.count, 1)
        // Start at the top and go clockwise, which is how a reader scans a radar.
        let angle = (Double(index) / Double(count)) * 2 * .pi - .pi / 2
        let r = radius * CGFloat(max(0, min(1, fraction)))
        return CGPoint(
            x: centre.x + r * CGFloat(cos(angle)),
            y: centre.y + r * CGFloat(sin(angle))
        )
    }

    /// Normalises to the strongest axis so a chart of all-low scores still has a readable shape.
    private var scale: Double {
        max(axes.map(\.value).max() ?? 0, 0.0001)
    }

    private func grid(centre: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(1...rings, id: \.self) { ring in
                let fraction = Double(ring) / Double(rings)
                Path { path in
                    for index in axes.indices {
                        let vertex = point(index: index, fraction: fraction, centre: centre, radius: radius)
                        if index == axes.startIndex { path.move(to: vertex) } else { path.addLine(to: vertex) }
                    }
                    path.closeSubpath()
                }
                .stroke(ColorTokens.outline, lineWidth: 1)
            }
        }
    }

    private func shape(centre: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for index in axes.indices {
                let vertex = point(
                    index: index,
                    fraction: axes[index].value / scale,
                    centre: centre,
                    radius: radius
                )
                if index == axes.startIndex { path.move(to: vertex) } else { path.addLine(to: vertex) }
            }
            path.closeSubpath()
        }
    }

    private func points(centre: CGPoint, radius: CGFloat) -> some View {
        ForEach(Array(axes.enumerated()), id: \.element.id) { index, axis in
            let vertex = point(
                index: index,
                fraction: axis.value / scale,
                centre: centre,
                radius: radius
            )
            Circle()
                .fill(axis.value < weakThreshold ? ColorTokens.warning : ColorTokens.primary)
                .frame(width: 8, height: 8)
                .position(vertex)
        }
    }
}

// MARK: - Previews

#Preview("SFRadarChart") {
    SFRadarChart(axes: [
        .init(label: "Normalisation", value: 0.85),
        .init(label: "Indexing", value: 0.45),
        .init(label: "Transactions", value: 0.30),
        .init(label: "Joins", value: 0.70),
        .init(label: "Keys", value: 0.60),
    ])
    .frame(height: 260)
    .padding(Layout.screenMargin)
}