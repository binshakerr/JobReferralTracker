import CoreData

extension JobEntity {
    func toDomain() -> Job {
        Job(id: id, title: title, company: company, location: location,
            jobDescription: jobDescription, createdAt: createdAt, updatedAt: updatedAt)
    }

    func toSummary() -> JobSummary {
        JobSummary(job: toDomain(), referralCount: referrals.count)
    }

    func apply(_ job: Job) {
        id = job.id
        title = job.title
        company = job.company
        location = job.location
        jobDescription = job.jobDescription
        createdAt = job.createdAt
        updatedAt = job.updatedAt
    }
}
