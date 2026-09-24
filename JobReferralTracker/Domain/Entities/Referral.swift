import Foundation

/// A contact who may refer the user for a specific job.
struct Referral: Identifiable, Hashable, Sendable {
    let id: UUID
    let jobID: UUID
    var contactName: String
    /// Trimmed and lower-cased.
    var email: String
    /// Always an `https` linkedin.com URL.
    var linkedInURL: URL
    /// `nil` when blank.
    var note: String?
    var status: ReferralStatus
    let createdAt: Date
    var updatedAt: Date
    var statusUpdatedAt: Date
}
