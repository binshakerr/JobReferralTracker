import SwiftUI

extension ReferralStatus {
    var title: String {
        switch self {
        case .pending: return "Pending"
        case .contacted: return "Contacted"
        case .interview: return "Interview"
        case .hired: return "Hired"
        case .rejected: return "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .contacted: return .blue
        case .interview: return .orange
        case .hired: return .green
        case .rejected: return .red
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .contacted: return "paperplane"
        case .interview: return "person.2"
        case .hired: return "checkmark.seal"
        case .rejected: return "xmark.octagon"
        }
    }
}

extension ReferralFilter {
    var title: String {
        switch self {
        case .all: return "All"
        case .status(let status): return status.title
        }
    }

    var color: Color {
        switch self {
        case .all: return .accentColor
        case .status(let status): return status.color
        }
    }
}

extension StatusBreakdown {
    /// e.g. "Hired 1 · Interview 2", or "No referrals yet".
    var summaryText: String {
        let parts = ReferralStatus.allCases
            .filter { count(for: $0) > 0 }
            .map { "\($0.title) \(count(for: $0))" }
        return parts.isEmpty ? "No referrals yet" : parts.joined(separator: " · ")
    }
}

func referralCountText(_ count: Int) -> String {
    count == 1 ? "1 referral" : "\(count) referrals"
}
