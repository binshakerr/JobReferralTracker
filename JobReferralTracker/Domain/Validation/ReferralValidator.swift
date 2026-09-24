import Foundation

struct ReferralValidator: Sendable {
    static let shortTextLimit = 120
    static let noteLimit = 2000

    private static let emailPattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#

    func validate(_ draft: ReferralDraft) -> ValidationResult<ReferralField> {
        var result = ValidationResult<ReferralField>()
        result.issues[.contactName] = TextRules.requiredIssue(draft.contactName, limit: Self.shortTextLimit)
        result.issues[.email] = emailIssue(draft.email)
        result.issues[.linkedInProfile] = linkedInIssue(draft.linkedInProfile)
        result.issues[.note] = TextRules.lengthIssue(draft.note, limit: Self.noteLimit)
        return result
    }

    func normalizedEmail(_ raw: String) -> String {
        raw.trimmed.lowercased()
    }

    /// Returns the profile as an `https` URL, or `nil` if it is not a linkedin.com profile URL.
    /// A missing scheme is accepted.
    func normalizedLinkedInURL(_ raw: String) -> URL? {
        let text = raw.trimmed
        let withScheme = text.contains("://") ? text : "https://" + text
        guard var components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host?.lowercased(),
              host == "linkedin.com" || host.hasSuffix(".linkedin.com"),
              !components.path.isEmpty, components.path != "/"
        else { return nil }

        components.scheme = "https"
        return components.url
    }

    /// Trimmed note, or `nil` when blank.
    func normalizedNote(_ raw: String) -> String? {
        let note = raw.trimmed
        return note.isEmpty ? nil : note
    }

    private func emailIssue(_ raw: String) -> ValidationIssue? {
        let email = raw.trimmed
        if email.isEmpty { return .required }
        let isValid = email.range(of: Self.emailPattern, options: [.regularExpression, .caseInsensitive]) != nil
        return isValid ? nil : .invalidEmail
    }

    private func linkedInIssue(_ raw: String) -> ValidationIssue? {
        if raw.trimmed.isEmpty { return .required }
        return normalizedLinkedInURL(raw) == nil ? .invalidLinkedInURL : nil
    }
}
