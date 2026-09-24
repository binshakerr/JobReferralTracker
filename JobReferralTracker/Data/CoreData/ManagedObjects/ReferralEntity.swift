import CoreData

@objc(ReferralEntity)
final class ReferralEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var contactName: String
    @NSManaged var email: String
    @NSManaged var linkedInURL: String
    @NSManaged var note: String?
    @NSManaged var statusRaw: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var statusUpdatedAt: Date
    /// Required in the model; optional here so a damaged record surfaces as an error instead of a crash.
    @NSManaged var job: JobEntity?
}

extension ReferralEntity {
    static let entityName = "ReferralEntity"

    static func request() -> NSFetchRequest<ReferralEntity> {
        NSFetchRequest<ReferralEntity>(entityName: entityName)
    }

    static func predicate(id: UUID) -> NSPredicate {
        NSPredicate(format: "id == %@", id as CVarArg)
    }

    static func predicate(jobID: UUID) -> NSPredicate {
        NSPredicate(format: "job.id == %@", jobID as CVarArg)
    }

    static func fetch(id: UUID, in context: NSManagedObjectContext) throws -> ReferralEntity? {
        let request = request()
        request.predicate = predicate(id: id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
