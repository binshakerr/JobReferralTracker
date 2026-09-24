import Foundation
@testable import JobReferralTracker

/// Fake storage that honors the same contracts as the Core Data repositories:
/// sort orders, not-found errors, cascade delete and per-job email lookup.
actor InMemoryRepository: JobRepository, ReferralRepository {
    private(set) var jobs: [UUID: Job] = [:]
    private(set) var referrals: [UUID: Referral] = [:]
    private let onChange: @Sendable () -> Void

    init(jobs: [Job] = [], referrals: [Referral] = [], onChange: @escaping @Sendable () -> Void = {}) {
        self.jobs = Dictionary(uniqueKeysWithValues: jobs.map { ($0.id, $0) })
        self.referrals = Dictionary(uniqueKeysWithValues: referrals.map { ($0.id, $0) })
        self.onChange = onChange
    }

    // MARK: JobRepository

    func fetchJobs() async throws -> [Job] {
        jobs.values.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchJobSummaries() async throws -> [JobSummary] {
        try await fetchJobs().map { job in
            JobSummary(job: job, referralCount: referrals.values.filter { $0.jobID == job.id }.count)
        }
    }

    func fetchJob(id: UUID) async throws -> Job? { jobs[id] }

    func create(_ job: Job) async throws {
        jobs[job.id] = job
        onChange()
    }

    func update(_ job: Job) async throws {
        guard jobs[job.id] != nil else { throw DomainError.jobNotFound(id: job.id) }
        jobs[job.id] = job
        onChange()
    }

    func deleteJob(id: UUID) async throws {
        jobs[id] = nil
        referrals = referrals.filter { $0.value.jobID != id }
        onChange()
    }

    // MARK: ReferralRepository

    func fetchReferrals(jobID: UUID) async throws -> [Referral] {
        referrals.values.filter { $0.jobID == jobID }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchAllReferrals() async throws -> [Referral] {
        referrals.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchAllReferralItems() async throws -> [ReferralListItem] {
        try await fetchAllReferrals().compactMap(item(for:))
    }

    func fetchReferral(id: UUID) async throws -> Referral? { referrals[id] }

    func fetchReferralItem(id: UUID) async throws -> ReferralListItem? {
        referrals[id].flatMap(item(for:))
    }

    func emailExists(_ email: String, jobID: UUID, excludingReferralID: UUID?) async throws -> Bool {
        referrals.values.contains {
            $0.jobID == jobID && $0.email.lowercased() == email.lowercased() && $0.id != excludingReferralID
        }
    }

    func create(_ referral: Referral) async throws {
        guard jobs[referral.jobID] != nil else { throw DomainError.jobNotFound(id: referral.jobID) }
        referrals[referral.id] = referral
        onChange()
    }

    func update(_ referral: Referral) async throws {
        guard referrals[referral.id] != nil else { throw DomainError.referralNotFound(id: referral.id) }
        referrals[referral.id] = referral
        onChange()
    }

    func deleteReferral(id: UUID) async throws {
        referrals[id] = nil
        onChange()
    }

    private func item(for referral: Referral) -> ReferralListItem? {
        guard let job = jobs[referral.jobID] else { return nil }
        return ReferralListItem(referral: referral, jobTitle: job.title, company: job.company)
    }
}
