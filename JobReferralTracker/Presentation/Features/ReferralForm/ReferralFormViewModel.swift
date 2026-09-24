import SwiftUI

@MainActor
final class ReferralFormViewModel: ObservableObject {
    enum Mode {
        case create(jobID: UUID)
        case edit(Referral)
    }

    @Published private(set) var draft: ReferralDraft
    @Published private(set) var touchedFields: Set<ReferralField> = []
    /// Issues only the use case can detect (duplicate email). Cleared when that field is edited.
    @Published private(set) var externalIssues: [ReferralField: ValidationIssue] = [:]
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    let mode: Mode
    private let initialDraft: ReferralDraft
    private let addReferral: AddReferralUseCase
    private let updateReferral: UpdateReferralUseCase
    private let validator: ReferralValidator

    init(mode: Mode, addReferral: AddReferralUseCase, updateReferral: UpdateReferralUseCase,
         validator: ReferralValidator) {
        self.mode = mode
        self.addReferral = addReferral
        self.updateReferral = updateReferral
        self.validator = validator
        switch mode {
        case .create: initialDraft = ReferralDraft()
        case .edit(let referral): initialDraft = ReferralDraft(referral: referral)
        }
        draft = initialDraft
    }

    var title: String {
        if case .edit = mode { return "Edit Referral" }
        return "New Referral"
    }

    var validation: ValidationResult<ReferralField> {
        var result = validator.validate(draft)
        result.issues.merge(externalIssues) { local, _ in local }
        return result
    }

    var hasChanges: Bool { draft != initialDraft }

    var canSave: Bool {
        guard validation.isValid, !isSaving else { return false }
        if case .edit = mode { return hasChanges }
        return true
    }

    var status: Binding<ReferralStatus> {
        Binding(get: { self.draft.status }, set: { self.draft.status = $0 })
    }

    /// Binding that also marks the field as edited, so its error starts showing.
    func binding(_ keyPath: WritableKeyPath<ReferralDraft, String>, field: ReferralField) -> Binding<String> {
        Binding(
            get: { self.draft[keyPath: keyPath] },
            set: { newValue in
                self.draft[keyPath: keyPath] = newValue
                self.touchedFields.insert(field)
                self.externalIssues[field] = nil
            }
        )
    }

    func errorMessage(for field: ReferralField) -> String? {
        guard touchedFields.contains(field) || externalIssues[field] != nil,
              let issue = validation[field] else { return nil }
        return issue.message(fieldName: field.label)
    }

    /// Returns `true` when saved, so the view can dismiss.
    func save() async -> Bool {
        guard canSave else {
            touchedFields.formUnion([.contactName, .email, .linkedInProfile, .note])
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .create(let jobID):
                _ = try await addReferral.execute(jobID: jobID, draft: draft)
            case .edit(let referral):
                _ = try await updateReferral.execute(id: referral.id, draft: draft)
            }
            return true
        } catch DomainError.invalidReferral(let result) {
            // Show use-case-only issues (e.g. duplicate email) inline under their fields.
            externalIssues = result.issues
            touchedFields.formUnion(result.issues.keys)
            return false
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
