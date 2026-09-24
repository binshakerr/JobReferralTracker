import Foundation

/// Referral counts per status. Every status is present, with 0 when there are none.
struct StatusBreakdown: Hashable, Sendable {
    let counts: [ReferralStatus: Int]

    init<S: Sequence>(statuses: S) where S.Element == ReferralStatus {
        var counts = Dictionary(uniqueKeysWithValues: ReferralStatus.allCases.map { ($0, 0) })
        for status in statuses { counts[status, default: 0] += 1 }
        self.counts = counts
    }

    static let empty = StatusBreakdown(statuses: [])

    var total: Int { counts.values.reduce(0, +) }

    func count(for status: ReferralStatus) -> Int { counts[status, default: 0] }
}

struct JobReferralBreakdown: Identifiable, Hashable, Sendable {
    let job: Job
    let breakdown: StatusBreakdown

    var id: UUID { job.id }
}

struct ReferralAnalytics: Hashable, Sendable {
    let overall: StatusBreakdown
    /// Jobs with referrals first (by total, descending), then jobs without referrals.
    let perJob: [JobReferralBreakdown]

    static let empty = ReferralAnalytics(overall: .empty, perJob: [])
}
