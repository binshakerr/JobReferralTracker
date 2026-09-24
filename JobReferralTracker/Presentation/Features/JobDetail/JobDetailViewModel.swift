import Foundation

@MainActor
final class JobDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadState<Job> = .loading
    @Published private(set) var referrals: [Referral] = []
    @Published private(set) var breakdown: StatusBreakdown = .empty
    /// Set once the job no longer exists, so the view can pop.
    @Published private(set) var isDeleted = false
    @Published var isConfirmingJobDeletion = false
    @Published var referralPendingDeletion: Referral?
    @Published var errorMessage: String?

    let jobID: UUID
    private let observeJob: ObserveJobUseCase
    private let observeReferrals: ObserveReferralsUseCase
    private let deleteJobUseCase: DeleteJobUseCase
    private let deleteReferralUseCase: DeleteReferralUseCase

    init(
        jobID: UUID,
        observeJob: ObserveJobUseCase,
        observeReferrals: ObserveReferralsUseCase,
        deleteJob: DeleteJobUseCase,
        deleteReferral: DeleteReferralUseCase
    ) {
        self.jobID = jobID
        self.observeJob = observeJob
        self.observeReferrals = observeReferrals
        deleteJobUseCase = deleteJob
        deleteReferralUseCase = deleteReferral
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeJobUpdates() }
            group.addTask { await self.observeReferralUpdates() }
        }
    }

    func deleteJob() async {
        do {
            try await deleteJobUseCase.execute(id: jobID)
            isDeleted = true
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ referral: Referral) async {
        do {
            try await deleteReferralUseCase.execute(id: referral.id)
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func observeJobUpdates() async {
        do {
            for try await job in observeJob.execute(id: jobID) {
                if let job {
                    state = .loaded(job)
                } else {
                    isDeleted = true
                }
            }
        } catch {
            state = .failed(message: error.userMessage)
        }
    }

    private func observeReferralUpdates() async {
        do {
            for try await referrals in observeReferrals.execute(jobID: jobID) {
                self.referrals = referrals
                breakdown = StatusBreakdown(statuses: referrals.map(\.status))
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
