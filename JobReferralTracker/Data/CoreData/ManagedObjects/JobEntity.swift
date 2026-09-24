import CoreData

@objc(JobEntity)
final class JobEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var company: String
    @NSManaged var location: String
    @NSManaged var jobDescription: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var referrals: Set<ReferralEntity>
}

extension JobEntity {
    static let entityName = "JobEntity"

    static func request() -> NSFetchRequest<JobEntity> {
        NSFetchRequest<JobEntity>(entityName: entityName)
    }

    static func predicate(id: UUID) -> NSPredicate {
        NSPredicate(format: "id == %@", id as CVarArg)
    }

    static func fetch(id: UUID, in context: NSManagedObjectContext) throws -> JobEntity? {
        let request = request()
        request.predicate = predicate(id: id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
