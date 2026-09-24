import Foundation

struct JobValidator: Sendable {
    static let shortTextLimit = 120
    static let descriptionLimit = 5000

    func validate(_ draft: JobDraft) -> ValidationResult<JobField> {
        var result = ValidationResult<JobField>()
        result.issues[.title] = TextRules.requiredIssue(draft.title, limit: Self.shortTextLimit)
        result.issues[.company] = TextRules.requiredIssue(draft.company, limit: Self.shortTextLimit)
        result.issues[.location] = TextRules.lengthIssue(draft.location, limit: Self.shortTextLimit)
        result.issues[.jobDescription] = TextRules.lengthIssue(draft.jobDescription, limit: Self.descriptionLimit)
        return result
    }

    func normalized(_ draft: JobDraft) -> JobDraft {
        var clean = draft
        clean.title = draft.title.trimmed
        clean.company = draft.company.trimmed
        clean.location = draft.location.trimmed
        clean.jobDescription = draft.jobDescription.trimmed
        return clean
    }
}
