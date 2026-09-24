import Foundation

struct DeleteReferralUseCase: Sendable {
    let repository: ReferralRepository

    func execute(id: UUID) async throws {
        try await repository.deleteReferral(id: id)
    }
}
