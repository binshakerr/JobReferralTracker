import Foundation

/// The pipeline stage of a referral. Declaration order is pipeline order.
enum ReferralStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case pending
    case contacted
    case interview
    case hired
    case rejected

    var id: String { rawValue }
}

extension ReferralStatus {
    /// Hired and Rejected end the pipeline; the other statuses are still open.
    var isClosed: Bool { self == .hired || self == .rejected }
}
