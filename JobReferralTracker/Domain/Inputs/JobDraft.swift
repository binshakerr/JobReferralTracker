import Foundation

/// Editable, unvalidated input for creating or updating a `Job`.
struct JobDraft: Hashable, Sendable {
    var title = ""
    var company = ""
    var location = ""
    var jobDescription = ""

    init() {}

    init(job: Job) {
        title = job.title
        company = job.company
        location = job.location
        jobDescription = job.jobDescription
    }
}
