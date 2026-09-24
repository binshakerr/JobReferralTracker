import Foundation

/// Home-screen card data for a job.
struct JobSummary: Identifiable, Hashable, Sendable {
    let job: Job
    let referralCount: Int

    var id: UUID { job.id }
}
