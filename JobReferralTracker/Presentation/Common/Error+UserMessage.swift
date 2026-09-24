import Foundation

extension Error {
    /// Readable English text for alerts and error screens.
    var userMessage: String {
        guard let error = self as? DomainError else { return localizedDescription }
        switch error {
        case .invalidJob, .invalidReferral:
            return "Please fix the highlighted fields."
        case .jobNotFound:
            return "This job no longer exists."
        case .referralNotFound:
            return "This referral no longer exists."
        case .persistenceFailure(let message):
            return message
        }
    }
}
