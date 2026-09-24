import Foundation

struct UpdateJobUseCase: Sendable {
    let repository: JobRepository
    let validator: JobValidator
    let now: DateProvider

    func execute(id: UUID, draft: JobDraft) async throws -> Job {
        let validation = validator.validate(draft)
        guard validation.isValid else { throw DomainError.invalidJob(validation) }
        guard var job = try await repository.fetchJob(id: id) else { throw DomainError.jobNotFound(id: id) }

        let clean = validator.normalized(draft)
        job.title = clean.title
        job.company = clean.company
        job.location = clean.location
        job.jobDescription = clean.jobDescription
        job.updatedAt = now()
        try await repository.update(job)
        return job
    }
}
