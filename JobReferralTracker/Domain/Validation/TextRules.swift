import Foundation

/// Shared text-field rules used by the validators.
enum TextRules {
    static func requiredIssue(_ value: String, limit: Int) -> ValidationIssue? {
        value.trimmed.isEmpty ? .required : lengthIssue(value, limit: limit)
    }

    static func lengthIssue(_ value: String, limit: Int) -> ValidationIssue? {
        value.trimmed.count > limit ? .tooLong(max: limit) : nil
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
