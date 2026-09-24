import Foundation

/// Errors raised inside the Data layer. Repositories convert them to `DomainError`
/// with `mapToDomainErrors` before they reach other layers.
enum DataError: Error, LocalizedError {
    case storeLoadFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case corruptRecord(entity: String, id: UUID?)

    var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let underlying):
            return "The local database could not be opened. \(underlying.localizedDescription)"
        case .saveFailed(let underlying):
            return "Your changes could not be saved. \(underlying.localizedDescription)"
        case .corruptRecord(let entity, let id):
            return "A stored \(entity) record is damaged (\(id?.uuidString ?? "unknown id"))."
        }
    }
}

/// Runs a Data-layer operation, passing `DomainError`s through and wrapping anything else
/// in `DomainError.persistenceFailure`.
func mapToDomainErrors<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch let error as DomainError {
        throw error
    } catch {
        throw DomainError.persistenceFailure(message: error.localizedDescription)
    }
}
