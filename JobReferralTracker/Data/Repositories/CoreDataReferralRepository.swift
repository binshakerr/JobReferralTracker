import CoreData

struct CoreDataReferralRepository: ReferralRepository {
    let stack: CoreDataStack

    func fetchReferrals(jobID: UUID) async throws -> [Referral] {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                let request = Self.recentFirstRequest()
                request.predicate = ReferralEntity.predicate(jobID: jobID)
                return try context.fetch(request).map { try $0.toDomain() }
            }
        }
    }

    func fetchAllReferrals() async throws -> [Referral] {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                try context.fetch(Self.recentFirstRequest()).map { try $0.toDomain() }
            }
        }
    }

    func fetchAllReferralItems() async throws -> [ReferralListItem] {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                let request = Self.recentFirstRequest()
                request.relationshipKeyPathsForPrefetching = ["job"]
                return try context.fetch(request).map { try $0.toListItem() }
            }
        }
    }

    func fetchReferral(id: UUID) async throws -> Referral? {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                try ReferralEntity.fetch(id: id, in: context)?.toDomain()
            }
        }
    }

    func fetchReferralItem(id: UUID) async throws -> ReferralListItem? {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                try ReferralEntity.fetch(id: id, in: context)?.toListItem()
            }
        }
    }

    func emailExists(_ email: String, jobID: UUID, excludingReferralID: UUID?) async throws -> Bool {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                var predicates = [
                    ReferralEntity.predicate(jobID: jobID),
                    NSPredicate(format: "email ==[c] %@", email),
                ]
                if let excludingReferralID {
                    predicates.append(NSPredicate(format: "id != %@", excludingReferralID as CVarArg))
                }
                let request = ReferralEntity.request()
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                return try context.count(for: request) > 0
            }
        }
    }

    func create(_ referral: Referral) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                guard let job = try JobEntity.fetch(id: referral.jobID, in: context) else {
                    throw DomainError.jobNotFound(id: referral.jobID)
                }
                let entity = ReferralEntity(context: context)
                entity.apply(referral)
                entity.job = job
            }
        }
    }

    func update(_ referral: Referral) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                guard let entity = try ReferralEntity.fetch(id: referral.id, in: context) else {
                    throw DomainError.referralNotFound(id: referral.id)
                }
                entity.apply(referral)
            }
        }
    }

    func deleteReferral(id: UUID) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                if let entity = try ReferralEntity.fetch(id: id, in: context) {
                    context.delete(entity)
                }
            }
        }
    }

    private static func recentFirstRequest() -> NSFetchRequest<ReferralEntity> {
        let request = ReferralEntity.request()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReferralEntity.updatedAt, ascending: false)]
        return request
    }
}
