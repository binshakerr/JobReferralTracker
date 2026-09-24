import Foundation

/// Live list of job summaries for the Home screen.
struct ObserveJobSummariesUseCase: Sendable {
    let repository: JobRepository
    let liveQuery: LiveQuery

    func execute() -> AsyncThrowingStream<[JobSummary], Error> {
        liveQuery.stream { [repository] in try await repository.fetchJobSummaries() }
    }
}
