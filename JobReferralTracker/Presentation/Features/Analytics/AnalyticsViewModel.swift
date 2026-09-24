import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    enum Segment: String, CaseIterable, Identifiable {
        case byJob = "By Job"
        case allReferrals = "All Referrals"

        var id: String { rawValue }
    }

    @Published var segment: Segment = .byJob
    @Published var filter: ReferralFilter = .all
    @Published private(set) var analytics: LoadState<ReferralAnalytics> = .loading
    @Published private(set) var allReferrals: LoadState<[ReferralListItem]> = .loading

    private let observeAnalytics: ObserveReferralAnalyticsUseCase
    private let observeAllReferrals: ObserveAllReferralsUseCase

    init(observeAnalytics: ObserveReferralAnalyticsUseCase, observeAllReferrals: ObserveAllReferralsUseCase) {
        self.observeAnalytics = observeAnalytics
        self.observeAllReferrals = observeAllReferrals
    }

    var filteredReferrals: [ReferralListItem] {
        filter.apply(to: allReferrals.value ?? [])
    }

    var filterCounts: [ReferralFilter: Int] {
        ReferralFilter.counts(in: allReferrals.value ?? [])
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeAnalyticsUpdates() }
            group.addTask { await self.observeReferralUpdates() }
        }
    }

    private func observeAnalyticsUpdates() async {
        do {
            for try await analytics in observeAnalytics.execute() {
                self.analytics = .loaded(analytics)
            }
        } catch {
            analytics = .failed(message: error.userMessage)
        }
    }

    private func observeReferralUpdates() async {
        do {
            for try await items in observeAllReferrals.execute() {
                allReferrals = .loaded(items)
            }
        } catch {
            allReferrals = .failed(message: error.userMessage)
        }
    }
}
