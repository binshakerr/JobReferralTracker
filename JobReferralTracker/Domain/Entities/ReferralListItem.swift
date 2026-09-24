import Foundation

/// A referral together with the display info of the job it belongs to.
struct ReferralListItem: Identifiable, Hashable, Sendable {
    let referral: Referral
    let jobTitle: String
    let company: String

    var id: UUID { referral.id }
}
