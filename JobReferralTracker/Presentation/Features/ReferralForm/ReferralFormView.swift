import SwiftUI

/// Sheet for adding or editing a referral.
struct ReferralFormView: View {
    @StateObject private var viewModel: ReferralFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    init(factory: ViewModelFactory, mode: ReferralFormViewModel.Mode) {
        _viewModel = StateObject(wrappedValue: factory.makeReferralFormViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    FormTextField(title: "Name", text: viewModel.binding(\.contactName, field: .contactName),
                                  prompt: "Full name (required)", error: viewModel.errorMessage(for: .contactName))
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)

                    FormTextField(title: "Email", text: viewModel.binding(\.email, field: .email),
                                  prompt: "name@example.com (required)", error: viewModel.errorMessage(for: .email))
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    FormTextField(title: "LinkedIn profile",
                                  text: viewModel.binding(\.linkedInProfile, field: .linkedInProfile),
                                  prompt: "linkedin.com/in/name (required)",
                                  error: viewModel.errorMessage(for: .linkedInProfile))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Picker("Status", selection: viewModel.status) {
                        ForEach(ReferralStatus.allCases) { status in
                            status.coloredLabel.tag(status)
                        }
                    }
                }

                Section("Note") {
                    FormTextField(title: "Note", text: viewModel.binding(\.note, field: .note),
                                  prompt: "Optional — how you know them, what you asked…",
                                  error: viewModel.errorMessage(for: .note), axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasChanges { isConfirmingDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { if await viewModel.save() { dismiss() } }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .interactiveDismissDisabled(viewModel.hasChanges)
            .confirmationDialog("Discard your changes?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .errorAlert("Couldn't Save Referral", message: $viewModel.errorMessage)
        }
    }
}

struct ReferralFormView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralFormView(factory: AppContainer.preview(), mode: .create(jobID: UUID()))
    }
}
