import Foundation

protocol ReferralRepository: Sendable {
    /// Most recently updated first.
    func fetchReferrals(jobID: UUID) async throws -> [Referral]
    func fetchAllReferrals() async throws -> [Referral]
    /// Most recently updated first, with job title and company.
    func fetchAllReferralItems() async throws -> [ReferralListItem]
    func fetchReferral(id: UUID) async throws -> Referral?
    func fetchReferralItem(id: UUID) async throws -> ReferralListItem?
    /// Case-insensitive match within one job, optionally ignoring one referral (the one being edited).
    func emailExists(_ email: String, jobID: UUID, excludingReferralID: UUID?) async throws -> Bool
    /// Throws `DomainError.jobNotFound` when the referral's job does not exist.
    func create(_ referral: Referral) async throws
    /// Throws `DomainError.referralNotFound` when the referral does not exist.
    func update(_ referral: Referral) async throws
    func deleteReferral(id: UUID) async throws
}
