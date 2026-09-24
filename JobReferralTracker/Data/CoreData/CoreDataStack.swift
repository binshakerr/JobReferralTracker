import CoreData

/// Owns the persistent container. Created once by the app's composition root and injected
/// into repositories; tests create their own in-memory instances.
final class CoreDataStack: @unchecked Sendable {
    enum StoreType: Sendable {
        case persistent
        case inMemory
    }

    static let modelName = "JobReferralTracker"

    /// Loaded once per process. Loading the same model twice makes Core Data unable to tell
    /// which entity a managed object subclass belongs to (this matters for tests with many stacks).
    /// This is an immutable model description, not a service singleton.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle(for: CoreDataStack.self).url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url)
        else { preconditionFailure("Missing Core Data model \(modelName).momd") }
        return model
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(storeType: StoreType = .persistent) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)

        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        if storeType == .inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
    }

    /// Opens the store. Throws `DataError.storeLoadFailed`.
    func load() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: DataError.storeLoadFailed(underlying: error))
                } else {
                    continuation.resume()
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Runs `block` on a new private-queue context and saves it if anything changed.
    /// Only `Sendable` values (domain types) may leave the block.
    func performBackgroundTask<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    context.rollback()
                    throw DataError.saveFailed(underlying: error)
                }
            }
            return result
        }
    }
}
