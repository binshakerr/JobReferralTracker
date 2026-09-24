import SwiftUI

/// Referral tracking detail: contact info and one-tap status updates.
struct ReferralDetailView: View {
    private let factory: ViewModelFactory
    @StateObject private var viewModel: ReferralDetailViewModel
    @EnvironmentObject private var router: Router
    @State private var editingReferral: Referral?

    init(referralID: UUID, factory: ViewModelFactory) {
        self.factory = factory
        _viewModel = StateObject(wrappedValue: factory.makeReferralDetailViewModel(referralID: referralID))
    }

    var body: some View {
        content
            .navigationTitle("Referral")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingReferral) { referral in
                ReferralFormView(factory: factory, mode: .edit(referral))
            }
            .confirmationDialog("Delete this referral?", isPresented: $viewModel.isConfirmingDeletion,
                                titleVisibility: .visible) {
                Button("Delete Referral", role: .destructive) {
                    Task { await viewModel.delete() }
                }
            } message: {
                Text("This can't be undone.")
            }
            .errorAlert(message: $viewModel.errorMessage)
            .onChange(of: viewModel.isDeleted) { isDeleted in
                if isDeleted { router.dismiss(.referralDetail(referralID: viewModel.referralID)) }
            }
            .task { await viewModel.observe() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Couldn't Load Referral", message: message)
        case .loaded(let item):
            loadedContent(item)
                .toolbar { toolbar(for: item.referral) }
        }
    }

    private func loadedContent(_ item: ReferralListItem) -> some View {
        let referral = item.referral
        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(referral.contactName)
                        .font(.title2.bold())
                    Text("For \(item.jobTitle) at \(item.company)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    StatusBadge(status: referral.status)
                }
                .padding(.vertical, 4)
            }

            Section {
                Picker("Status", selection: statusBinding(for: referral)) {
                    ForEach(ReferralStatus.allCases) { status in
                        status.coloredLabel.tag(status)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Update Status")
            } footer: {
                Text("Status last changed \(referral.statusUpdatedAt.formatted(.relative(presentation: .named))).")
            }

            Section("Contact") {
                if let mailURL = URL(string: "mailto:\(referral.email)") {
                    Link(destination: mailURL) {
                        Label(referral.email, systemImage: "envelope")
                    }
                }
                Link(destination: referral.linkedInURL) {
                    Label(linkedInDisplayText(referral.linkedInURL), systemImage: "link")
                }
            }

            if let note = referral.note {
                Section("Note") {
                    Text(note)
                }
            }

            Section("Details") {
                if !router.contains(.jobDetail(jobID: referral.jobID)) {
                    NavigationLink(value: AppRoute.jobDetail(jobID: referral.jobID)) {
                        LabeledContent("Job", value: item.jobTitle)
                    }
                }
                LabeledContent("Added", value: referral.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last updated", value: referral.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .listStyle(.insetGrouped)
    }

    private func statusBinding(for referral: Referral) -> Binding<ReferralStatus> {
        Binding(
            get: { referral.status },
            set: { newStatus in Task { await viewModel.setStatus(newStatus) } }
        )
    }

    private func linkedInDisplayText(_ url: URL) -> String {
        let host = url.host ?? "linkedin.com"
        return host.replacingOccurrences(of: "www.", with: "") + url.path
    }

    @ToolbarContentBuilder
    private func toolbar(for referral: Referral) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { editingReferral = referral } label: {
                    Label("Edit Referral", systemImage: "pencil")
                }
                Button(role: .destructive) { viewModel.isConfirmingDeletion = true } label: {
                    Label("Delete Referral", systemImage: "trash")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
}
