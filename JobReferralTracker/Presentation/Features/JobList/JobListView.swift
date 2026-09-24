import SwiftUI

/// Home screen: every saved job as a summary card.
struct JobListView: View {
    private let factory: ViewModelFactory
    @StateObject private var viewModel: JobListViewModel
    @State private var isAddingJob = false

    init(factory: ViewModelFactory) {
        self.factory = factory
        _viewModel = StateObject(wrappedValue: factory.makeJobListViewModel())
    }

    var body: some View {
        content
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isAddingJob = true } label: {
                        Label("Add Job", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingJob) {
                JobFormView(factory: factory, mode: .create)
            }
            .confirmationDialog(
                "Delete “\(viewModel.pendingDeletion?.job.title ?? "")”?",
                isPresented: Binding(isPresent: $viewModel.pendingDeletion),
                titleVisibility: .visible,
                presenting: viewModel.pendingDeletion
            ) { summary in
                Button("Delete Job", role: .destructive) {
                    Task { await viewModel.delete(summary) }
                }
            } message: { summary in
                Text(summary.referralCount == 0
                     ? "This can't be undone."
                     : "This also deletes its \(referralCountText(summary.referralCount)). This can't be undone.")
            }
            .errorAlert(message: $viewModel.errorMessage)
            .task { await viewModel.observe() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Couldn't Load Jobs", message: message)
        case .loaded(let summaries) where summaries.isEmpty:
            EmptyStateView(
                systemImage: "briefcase",
                title: "No Jobs Yet",
                message: "Add a job you're applying for, then track the people who can refer you.",
                actionTitle: "Add Job",
                action: { isAddingJob = true }
            )
        case .loaded(let summaries):
            List(summaries) { summary in
                NavigationLink(value: AppRoute.jobDetail(jobID: summary.id)) {
                    JobSummaryCard(summary: summary)
                }
                .swipeActions {
                    Button { viewModel.pendingDeletion = summary } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct JobListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            JobListView(factory: AppContainer.preview())
        }
        .environmentObject(Router())
    }
}
