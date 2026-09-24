import CoreData

struct CoreDataJobRepository: JobRepository {
    let stack: CoreDataStack

    func fetchJobs() async throws -> [Job] {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                try context.fetch(Self.newestFirstRequest()).map { $0.toDomain() }
            }
        }
    }

    func fetchJobSummaries() async throws -> [JobSummary] {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                let request = Self.newestFirstRequest()
                request.relationshipKeyPathsForPrefetching = ["referrals"]
                return try context.fetch(request).map { $0.toSummary() }
            }
        }
    }

    func fetchJob(id: UUID) async throws -> Job? {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                try JobEntity.fetch(id: id, in: context)?.toDomain()
            }
        }
    }

    func create(_ job: Job) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                JobEntity(context: context).apply(job)
            }
        }
    }

    func update(_ job: Job) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                guard let entity = try JobEntity.fetch(id: job.id, in: context) else {
                    throw DomainError.jobNotFound(id: job.id)
                }
                entity.apply(job)
            }
        }
    }

    func deleteJob(id: UUID) async throws {
        try await mapToDomainErrors {
            try await stack.performBackgroundTask { context in
                // Referrals are removed by the relationship's Cascade delete rule.
                if let entity = try JobEntity.fetch(id: id, in: context) {
                    context.delete(entity)
                }
            }
        }
    }

    private static func newestFirstRequest() -> NSFetchRequest<JobEntity> {
        let request = JobEntity.request()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JobEntity.createdAt, ascending: false)]
        return request
    }
}
