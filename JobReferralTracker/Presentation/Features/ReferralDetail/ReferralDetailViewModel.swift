import Foundation

@MainActor
final class ReferralDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadState<ReferralListItem> = .loading
    /// Set once the referral no longer exists, so the view can pop.
    @Published private(set) var isDeleted = false
    @Published var isConfirmingDeletion = false
    @Published var errorMessage: String?

    let referralID: UUID
    private let observeReferral: ObserveReferralUseCase
    private let updateStatus: UpdateReferralStatusUseCase
    private let deleteReferralUseCase: DeleteReferralUseCase

    init(
        referralID: UUID,
        observeReferral: ObserveReferralUseCase,
        updateStatus: UpdateReferralStatusUseCase,
        deleteReferral: DeleteReferralUseCase
    ) {
        self.referralID = referralID
        self.observeReferral = observeReferral
        self.updateStatus = updateStatus
        deleteReferralUseCase = deleteReferral
    }

    func observe() async {
        do {
            for try await item in observeReferral.execute(id: referralID) {
                if let item {
                    state = .loaded(item)
                } else {
                    isDeleted = true
                }
            }
        } catch {
            state = .failed(message: error.userMessage)
        }
    }

    /// Saves immediately. The picker updates optimistically and reverts if saving fails.
    func setStatus(_ status: ReferralStatus) async {
        guard case .loaded(let item) = state, item.referral.status != status else { return }
        var optimistic = item.referral
        optimistic.status = status
        state = .loaded(ReferralListItem(referral: optimistic, jobTitle: item.jobTitle, company: item.company))

        do {
            _ = try await updateStatus.execute(id: referralID, status: status)
        } catch {
            state = .loaded(item)
            errorMessage = error.userMessage
        }
    }

    func delete() async {
        do {
            try await deleteReferralUseCase.execute(id: referralID)
            isDeleted = true
        } catch {
            errorMessage = error.userMessage
        }
    }
}
