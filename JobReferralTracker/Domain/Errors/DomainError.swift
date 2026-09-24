import Foundation

enum DomainError: Error, Equatable {
    case invalidJob(ValidationResult<JobField>)
    case invalidReferral(ValidationResult<ReferralField>)
    case jobNotFound(id: UUID)
    case referralNotFound(id: UUID)
    /// Wraps storage errors so callers never see Data-layer types.
    case persistenceFailure(message: String)
}
