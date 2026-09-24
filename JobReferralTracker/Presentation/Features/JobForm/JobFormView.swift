import SwiftUI

/// Sheet for creating or editing a job.
struct JobFormView: View {
    @StateObject private var viewModel: JobFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    init(factory: ViewModelFactory, mode: JobFormViewModel.Mode) {
        _viewModel = StateObject(wrappedValue: factory.makeJobFormViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    FormTextField(title: "Title", text: viewModel.binding(\.title, field: .title),
                                  prompt: "Job title (required)", error: viewModel.errorMessage(for: .title))
                        .textInputAutocapitalization(.words)
                    FormTextField(title: "Company", text: viewModel.binding(\.company, field: .company),
                                  prompt: "Company (required)", error: viewModel.errorMessage(for: .company))
                        .textInputAutocapitalization(.words)
                        .textContentType(.organizationName)
                }

                Section("Location") {
                    FormTextField(title: "Location", text: viewModel.binding(\.location, field: .location),
                                  prompt: "e.g. Remote or Berlin, DE", error: viewModel.errorMessage(for: .location))
                }

                Section("Description") {
                    FormTextField(title: "Description",
                                  text: viewModel.binding(\.jobDescription, field: .jobDescription),
                                  prompt: "Responsibilities, requirements, links…",
                                  error: viewModel.errorMessage(for: .jobDescription), axis: .vertical)
                        .lineLimit(4...12)
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
            .errorAlert("Couldn't Save Job", message: $viewModel.errorMessage)
        }
    }
}

struct JobFormView_Previews: PreviewProvider {
    static var previews: some View {
        JobFormView(factory: AppContainer.preview(), mode: .create)
    }
}
