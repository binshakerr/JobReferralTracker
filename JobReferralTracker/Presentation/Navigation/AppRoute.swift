import Foundation

/// Push destinations. Routes carry IDs, not models, so destinations always show live data.
enum AppRoute: Hashable {
    case jobDetail(jobID: UUID)
    case referralDetail(referralID: UUID)
}
