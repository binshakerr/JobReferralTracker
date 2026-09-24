import CoreData

/// Owns the Core Data stack used for local storage.
struct PersistenceController {
    static let shared = PersistenceController()

    /// In-memory store for SwiftUI previews.
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "JobReferralTracker")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // TODO: Replace with user-facing error handling before shipping.
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Saves the view context if it has unsaved changes.
    func save() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }
}
