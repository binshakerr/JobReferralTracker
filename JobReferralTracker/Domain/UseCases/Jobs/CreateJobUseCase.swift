import Foundation

struct CreateJobUseCase: Sendable {
    let repository: JobRepository
    let validator: JobValidator
    let now: DateProvider
    let makeID: IDGenerator

    func execute(_ draft: JobDraft) async throws -> Job {
        let validation = validator.validate(draft)
        guard validation.isValid else { throw DomainError.invalidJob(validation) }

        let clean = validator.normalized(draft)
        let timestamp = now()
        let job = Job(id: makeID(), title: clean.title, company: clean.company, location: clean.location,
                      jobDescription: clean.jobDescription, createdAt: timestamp, updatedAt: timestamp)
        try await repository.create(job)
        return job
    }
}
