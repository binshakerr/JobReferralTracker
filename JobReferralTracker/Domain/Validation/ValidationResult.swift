import Foundation

enum ValidationIssue: Hashable, Sendable {
    case required
    case tooLong(max: Int)
    case invalidEmail
    case invalidLinkedInURL
    case duplicateEmail
}

/// Validation issues keyed by form field. Empty means valid.
struct ValidationResult<Field: Hashable & Sendable>: Hashable, Sendable {
    var issues: [Field: ValidationIssue] = [:]

    var isValid: Bool { issues.isEmpty }

    subscript(field: Field) -> ValidationIssue? { issues[field] }
}

enum JobField: Hashable, Sendable {
    case title, company, location, jobDescription
}

enum ReferralField: Hashable, Sendable {
    case contactName, email, linkedInProfile, note
}
