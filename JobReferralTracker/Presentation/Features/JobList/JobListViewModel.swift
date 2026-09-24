import Foundation

@MainActor
final class JobListViewModel: ObservableObject {
    @Published private(set) var state: LoadState<[JobSummary]> = .loading
    @Published var pendingDeletion: JobSummary?
    @Published var errorMessage: String?

    private let observeJobSummaries: ObserveJobSummariesUseCase
    private let deleteJob: DeleteJobUseCase

    init(observeJobSummaries: ObserveJobSummariesUseCase, deleteJob: DeleteJobUseCase) {
        self.observeJobSummaries = observeJobSummaries
        self.deleteJob = deleteJob
    }

    /// Runs until the view's task is cancelled.
    func observe() async {
        do {
            for try await summaries in observeJobSummaries.execute() {
                state = .loaded(summaries)
            }
        } catch {
            state = .failed(message: error.userMessage)
        }
    }

    func delete(_ summary: JobSummary) async {
        do {
            try await deleteJob.execute(id: summary.id)
        } catch {
            errorMessage = error.userMessage
        }
    }
}
