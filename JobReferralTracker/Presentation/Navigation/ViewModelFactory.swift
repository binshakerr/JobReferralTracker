import Foundation

/// Builds ViewModels with their dependencies. Implemented by `AppContainer`.
@MainActor
protocol ViewModelFactory {
    func makeJobListViewModel() -> JobListViewModel
    func makeJobFormViewModel(mode: JobFormViewModel.Mode) -> JobFormViewModel
    func makeJobDetailViewModel(jobID: UUID) -> JobDetailViewModel
    func makeReferralFormViewModel(mode: ReferralFormViewModel.Mode) -> ReferralFormViewModel
    func makeReferralDetailViewModel(referralID: UUID) -> ReferralDetailViewModel
    func makeAnalyticsViewModel() -> AnalyticsViewModel
}
