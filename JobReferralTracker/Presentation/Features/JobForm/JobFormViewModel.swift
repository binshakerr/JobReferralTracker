import SwiftUI

@MainActor
final class JobFormViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Job)
    }

    @Published private(set) var draft: JobDraft
    @Published private(set) var touchedFields: Set<JobField> = []
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    let mode: Mode
    private let initialDraft: JobDraft
    private let createJob: CreateJobUseCase
    private let updateJob: UpdateJobUseCase
    private let validator: JobValidator

    init(mode: Mode, createJob: CreateJobUseCase, updateJob: UpdateJobUseCase, validator: JobValidator) {
        self.mode = mode
        self.createJob = createJob
        self.updateJob = updateJob
        self.validator = validator
        switch mode {
        case .create: initialDraft = JobDraft()
        case .edit(let job): initialDraft = JobDraft(job: job)
        }
        draft = initialDraft
    }

    var title: String {
        if case .edit = mode { return "Edit Job" }
        return "New Job"
    }

    var validation: ValidationResult<JobField> { validator.validate(draft) }

    var hasChanges: Bool { draft != initialDraft }

    var canSave: Bool {
        guard validation.isValid, !isSaving else { return false }
        if case .edit = mode { return hasChanges }
        return true
    }

    /// Binding that also marks the field as edited, so its error starts showing.
    func binding(_ keyPath: WritableKeyPath<JobDraft, String>, field: JobField) -> Binding<String> {
        Binding(
            get: { self.draft[keyPath: keyPath] },
            set: { newValue in
                self.draft[keyPath: keyPath] = newValue
                self.touchedFields.insert(field)
            }
        )
    }

    /// Validation message for fields the user has edited.
    func errorMessage(for field: JobField) -> String? {
        guard touchedFields.contains(field), let issue = validation[field] else { return nil }
        return issue.message(fieldName: field.label)
    }

    /// Returns `true` when saved, so the view can dismiss.
    func save() async -> Bool {
        guard canSave else {
            touchedFields.formUnion([.title, .company, .location, .jobDescription])
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .create:
                _ = try await createJob.execute(draft)
            case .edit(let job):
                _ = try await updateJob.execute(id: job.id, draft: draft)
            }
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
