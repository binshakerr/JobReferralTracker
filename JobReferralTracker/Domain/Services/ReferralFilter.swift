import Foundation

/// Filter for the unified "All Referrals" list.
enum ReferralFilter: Hashable, Sendable {
    case all
    case status(ReferralStatus)

    /// `.all` followed by each status in pipeline order.
    static let allCases: [ReferralFilter] = [.all] + ReferralStatus.allCases.map(ReferralFilter.status)

    func apply(to items: [ReferralListItem]) -> [ReferralListItem] {
        switch self {
        case .all: return items
        case .status(let status): return items.filter { $0.referral.status == status }
        }
    }

    /// Number of items each filter would show.
    static func counts(in items: [ReferralListItem]) -> [ReferralFilter: Int] {
        let breakdown = StatusBreakdown(statuses: items.map(\.referral.status))
        var counts: [ReferralFilter: Int] = [.all: items.count]
        for status in ReferralStatus.allCases {
            counts[.status(status)] = breakdown.count(for: status)
        }
        return counts
    }
}
