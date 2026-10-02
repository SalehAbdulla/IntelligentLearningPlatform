//
//  ProgressDashboardView.swift
//  StudyForge
//
//  G10 + G11 — `69_Progress_Dashboard_{M3}` and `70_Progress_WeaknessRadar_{M3}` (docs/03 §G, P0).
//  The stat row, weekly bars, subject list, goal bar, topic radar and weakness cards.
//

import SwiftUI

struct ProgressDashboardView: View {

    @State private var viewModel: ProgressDashboardViewModel

    init(
        materials: any MaterialStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        studyPlans: any StudyPlanStore,
        profile: any ProfileService
    ) {
        _viewModel = State(initialValue: ProgressDashboardViewModel(
            materials: materials,
            decks: decks,
            quizzes: quizzes,
            studyPlans: studyPlans,
            profile: profile
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if let snapshot = viewModel.snapshot, snapshot.hasData {
                dashboard(snapshot)
            } else {
                emptyState
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: Dashboard

    private func dashboard(_ snapshot: ProgressSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                statRow(snapshot)
                weeklyActivity(snapshot)

                if snapshot.goalFraction != nil {
                    goalBar(snapshot)
                }

                topics(snapshot)
                weakTopics(snapshot)
                subjects(snapshot)
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Stat row

    private func statRow(_ snapshot: ProgressSnapshot) -> some View {
        HStack(spacing: Spacing.s3) {
            stat(
                value: viewModel.masteryValue(snapshot.masteryPercent),
                label: viewModel.masteryLabel,
                caption: viewModel.cardsValue(snapshot.cardsMastered, snapshot.cardsTotal)
            )
            stat(
                value: viewModel.streakValue(snapshot.streakDays),
                label: viewModel.streakLabel,
                caption: nil
            )
            stat(
                value: viewModel.hoursValue(viewModel.hours(fromMinutes: snapshot.minutesThisWeek)),
                label: viewModel.hoursLabel,
                caption: nil
            )
        }
    }

    private func stat(value: String, label: String, caption: String?) -> some View {
        VStack(spacing: Spacing.s1) {
            Text(value)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.primary)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
            if let caption {
                Text(caption)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: Weekly activity

    private func weeklyActivity(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.weeklyHeading)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            HStack(alignment: .bottom, spacing: Spacing.s2) {
                ForEach(snapshot.weeklyActivity) { day in
                    bar(day, peak: snapshot.peakDayMinutes)
                }
            }
            .frame(height: Spacing.s12 * 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    private func bar(_ day: DailyActivity, peak: Int) -> some View {
        // A day with activity but under an hour would round to a zero-height bar, which reads as
        // "you did nothing" — so any activity at all gets a visible minimum.
        let fraction = min(1, Double(day.minutes) / Double(peak))
        let hasActivity = day.items > 0

        return VStack(spacing: Spacing.s1) {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: Radius.s)
                .fill(hasActivity ? ColorTokens.primary : ColorTokens.outline)
                .frame(height: hasActivity ? max(Spacing.s2, (Spacing.s12 * 2) * fraction) : Spacing.s1)

            Text(day.day.formatted(.dateTime.weekday(.narrow)))
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide))), \(day.minutes) minutes")
    }

    // MARK: Goal

    private func goalBar(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack {
                Text(viewModel.goalHeading)
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer(minLength: Spacing.s2)
                Text(viewModel.goalCaption(snapshot))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            ProgressView(value: snapshot.goalFraction ?? 0)
                .tint(ColorTokens.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Topics (the radar)

    private func topics(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.radarTitle)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            if snapshot.topics.count < 3 {
                // A radar needs at least three axes to be a shape, so below that the list alone is
                // the honest presentation rather than a degenerate triangle.
                Text(viewModel.radarEmptyTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                SFRadarChart(axes: snapshot.topics.map {
                    SFRadarChart.Axis(label: $0.topic, value: $0.mastery)
                })
                .frame(height: Spacing.s12 * 5)

                VStack(alignment: .leading, spacing: Spacing.s2) {
                    ForEach(snapshot.topics) { topic in
                        HStack {
                            Text(topic.topic)
                                .font(.sfCallout)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Spacer(minLength: Spacing.s2)
                            Text(viewModel.masteryValue(topic.percent))
                                .font(.sfBodyEmph)
                                .foregroundStyle(topic.isWeak ? ColorTokens.warning : ColorTokens.successText)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Weak topics

    private func weakTopics(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.weakTopicsHeading)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            if snapshot.weakTopics.isEmpty {
                Text(viewModel.noWeakTopicsTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(snapshot.weakTopics) { topic in
                    weakTopicRow(topic)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weakTopicRow(_ topic: TopicMastery) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.warning)
                .accessibilityHidden(true)

            Text(topic.topic)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer(minLength: Spacing.s2)

            Text(viewModel.masteryValue(topic.percent))
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.warning)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.warning.opacity(0.10), in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }

    // MARK: Subjects

    private func subjects(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.subjectsHeading)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            if snapshot.subjects.isEmpty {
                Text(viewModel.noSubjectsTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(snapshot.subjects) { subject in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        HStack {
                            Text(subject.subject)
                                .font(.sfCallout)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Spacer(minLength: Spacing.s2)
                            Text(viewModel.masteryValue(subject.percent))
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        ProgressView(value: subject.fraction)
                            .tint(ColorTokens.Subject.color(for: subject.subject))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("G10 Progress — empty") {
    NavigationStack {
        ProgressDashboardView(
            materials: InMemoryMaterialStore(),
            decks: InMemoryDeckStore(),
            quizzes: InMemoryQuizStore(),
            studyPlans: InMemoryStudyPlanStore(),
            profile: MockProfileService(latency: .zero)
        )
    }
}