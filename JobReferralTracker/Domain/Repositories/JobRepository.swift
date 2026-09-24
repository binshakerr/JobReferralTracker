import Foundation

protocol JobRepository: Sendable {
    /// Newest first.
    func fetchJobs() async throws -> [Job]
    /// Newest first, with referral counts.
    func fetchJobSummaries() async throws -> [JobSummary]
    func fetchJob(id: UUID) async throws -> Job?
    func create(_ job: Job) async throws
    /// Throws `DomainError.jobNotFound` when the job does not exist.
    func update(_ job: Job) async throws
    /// Also deletes the job's referrals.
    func deleteJob(id: UUID) async throws
}
