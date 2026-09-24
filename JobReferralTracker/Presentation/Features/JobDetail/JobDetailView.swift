import SwiftUI

/// A job and its referrals (the "Referral Screen").
struct JobDetailView: View {
    private let factory: ViewModelFactory
    @StateObject private var viewModel: JobDetailViewModel
    @EnvironmentObject private var router: Router
    @State private var sheet: Sheet?
    @State private var isDescriptionExpanded = false

    private enum Sheet: Identifiable {
        case editJob(Job)
        case addReferral

        var id: String {
            switch self {
            case .editJob: return "editJob"
            case .addReferral: return "addReferral"
            }
        }
    }

    init(jobID: UUID, factory: ViewModelFactory) {
        self.factory = factory
        _viewModel = StateObject(wrappedValue: factory.makeJobDetailViewModel(jobID: jobID))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .editJob(let job):
                    JobFormView(factory: factory, mode: .edit(job))
                case .addReferral:
                    ReferralFormView(factory: factory, mode: .create(jobID: viewModel.jobID))
                }
            }
            .confirmationDialog(
                "Delete this job?",
                isPresented: $viewModel.isConfirmingJobDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete Job", role: .destructive) {
                    Task { await viewModel.deleteJob() }
                }
            } message: {
                Text(viewModel.referrals.isEmpty
                     ? "This can't be undone."
                     : "This also deletes its \(referralCountText(viewModel.referrals.count)). This can't be undone.")
            }
            .confirmationDialog(
                "Delete referral for \(viewModel.referralPendingDeletion?.contactName ?? "")?",
                isPresented: Binding(isPresent: $viewModel.referralPendingDeletion),
                titleVisibility: .visible,
                presenting: viewModel.referralPendingDeletion
            ) { referral in
                Button("Delete Referral", role: .destructive) {
                    Task { await viewModel.delete(referral) }
                }
            }
            .errorAlert(message: $viewModel.errorMessage)
            .onChange(of: viewModel.isDeleted) { isDeleted in
                if isDeleted { router.dismiss(.jobDetail(jobID: viewModel.jobID)) }
            }
            .task { await viewModel.observe() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Couldn't Load Job", message: message)
        case .loaded(let job):
            loadedContent(job)
                .navigationTitle(job.title)
                .toolbar { toolbar(for: job) }
        }
    }

    private func loadedContent(_ job: Job) -> some View {
        List {
            Section {
                header(for: job)
            }

            if !viewModel.referrals.isEmpty {
                Section("Referral Status") {
                    StatusCountGrid(breakdown: viewModel.breakdown)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }

            Section {
                if viewModel.referrals.isEmpty {
                    EmptyStateView(
                        systemImage: "person.2",
                        title: "No Referrals Yet",
                        message: "Add the people who could refer you for this job.",
                        actionTitle: "Add Referral",
                        action: { sheet = .addReferral }
                    )
                    .frame(minHeight: 240)
                } else {
                    ForEach(viewModel.referrals) { referral in
                        NavigationLink(value: AppRoute.referralDetail(referralID: referral.id)) {
                            ReferralRow(name: referral.contactName, subtitle: referral.email, status: referral.status)
                        }
                        .swipeActions {
                            Button { viewModel.referralPendingDeletion = referral } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            } header: {
                Text("Referrals (\(viewModel.referrals.count))")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func header(for job: Job) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.title)
                .font(.title2.bold())
            Label(job.company, systemImage: "building.2")
                .labelStyle(.compact)
                .font(.headline)
                .foregroundStyle(.secondary)
            if !job.location.isEmpty {
                Label(job.location, systemImage: "mappin.and.ellipse")
                    .labelStyle(.compact)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !job.jobDescription.isEmpty {
                Text(job.jobDescription)
                    .font(.body)
                    .lineLimit(isDescriptionExpanded ? nil : 4)
                    .padding(.top, 4)
                if job.jobDescription.count > 200 || job.jobDescription.filter(\.isNewline).count > 3 {
                    Button(isDescriptionExpanded ? "Less" : "More") {
                        withAnimation { isDescriptionExpanded.toggle() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ToolbarContentBuilder
    private func toolbar(for job: Job) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button { sheet = .addReferral } label: {
                Label("Add Referral", systemImage: "person.badge.plus")
            }
            Menu {
                Button { sheet = .editJob(job) } label: {
                    Label("Edit Job", systemImage: "pencil")
                }
                Button(role: .destructive) { viewModel.isConfirmingJobDeletion = true } label: {
                    Label("Delete Job", systemImage: "trash")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
}
