import Foundation

/// Editable, unvalidated input for creating or updating a `Referral`.
struct ReferralDraft: Hashable, Sendable {
    var contactName = ""
    var email = ""
    /// Raw text as typed; normalized to a URL when saved.
    var linkedInProfile = ""
    var note = ""
    var status: ReferralStatus = .pending

    init() {}

    init(referral: Referral) {
        contactName = referral.contactName
        email = referral.email
        linkedInProfile = referral.linkedInURL.absoluteString
        note = referral.note ?? ""
        status = referral.status
    }
}
