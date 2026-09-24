import Foundation

struct DeleteJobUseCase: Sendable {
    let repository: JobRepository

    /// Deletes the job and all of its referrals.
    func execute(id: UUID) async throws {
        try await repository.deleteJob(id: id)
    }
}
