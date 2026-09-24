import Foundation

/// Live job for the Job Detail screen. Yields `nil` once the job is deleted.
struct ObserveJobUseCase: Sendable {
    let repository: JobRepository
    let liveQuery: LiveQuery

    func execute(id: UUID) -> AsyncThrowingStream<Job?, Error> {
        liveQuery.stream { [repository] in try await repository.fetchJob(id: id) }
    }
}
