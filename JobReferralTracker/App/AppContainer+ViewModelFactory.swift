import Foundation

extension AppContainer: ViewModelFactory {
    func makeJobListViewModel() -> JobListViewModel {
        JobListViewModel(observeJobSummaries: observeJobSummaries, deleteJob: deleteJob)
    }

    func makeJobFormViewModel(mode: JobFormViewModel.Mode) -> JobFormViewModel {
        JobFormViewModel(mode: mode, createJob: createJob, updateJob: updateJob, validator: JobValidator())
    }

    func makeJobDetailViewModel(jobID: UUID) -> JobDetailViewModel {
        JobDetailViewModel(jobID: jobID, observeJob: observeJob, observeReferrals: observeReferrals,
                           deleteJob: deleteJob, deleteReferral: deleteReferral)
    }

    func makeReferralFormViewModel(mode: ReferralFormViewModel.Mode) -> ReferralFormViewModel {
        ReferralFormViewModel(mode: mode, addReferral: addReferral, updateReferral: updateReferral,
                              validator: ReferralValidator())
    }

    func makeReferralDetailViewModel(referralID: UUID) -> ReferralDetailViewModel {
        ReferralDetailViewModel(referralID: referralID, observeReferral: observeReferral,
                                updateStatus: updateReferralStatus, deleteReferral: deleteReferral)
    }

    func makeAnalyticsViewModel() -> AnalyticsViewModel {
        AnalyticsViewModel(observeAnalytics: observeReferralAnalytics, observeAllReferrals: observeAllReferrals)
    }
}
