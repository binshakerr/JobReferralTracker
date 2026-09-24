import CoreData

/// Emits an event whenever any context of this stack saves to the store.
final class CoreDataChangeObserver: DataChangeObserving, @unchecked Sendable {
    private let coordinator: NSPersistentStoreCoordinator
    private let notificationCenter: NotificationCenter

    init(stack: CoreDataStack, notificationCenter: NotificationCenter = .default) {
        coordinator = stack.container.persistentStoreCoordinator
        self.notificationCenter = notificationCenter
    }

    func changes() -> AsyncStream<Void> {
        // Keep only the newest event: a burst of saves triggers a single re-fetch.
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let token = notificationCenter.addObserver(
                forName: .NSManagedObjectContextDidSave, object: nil, queue: nil
            ) { [coordinator] notification in
                // Ignore saves from other stacks (e.g. parallel in-memory stacks in tests).
                guard let context = notification.object as? NSManagedObjectContext,
                      context.persistentStoreCoordinator === coordinator else { return }
                continuation.yield()
            }
            let observation = ObservationToken(token: token, center: notificationCenter)
            continuation.onTermination = { _ in observation.cancel() }
        }
    }
}

/// Removes a NotificationCenter observer when the stream ends.
private final class ObservationToken: @unchecked Sendable {
    private let token: NSObjectProtocol
    private let center: NotificationCenter

    init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }

    func cancel() {
        center.removeObserver(token)
    }
}
