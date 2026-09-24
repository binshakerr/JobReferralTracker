import Foundation
@testable import JobReferralTracker

enum Fixtures {
    static let date1 = Date(timeIntervalSince1970: 1_700_000_000)
    static let date2 = Date(timeIntervalSince1970: 1_700_086_400)
    static let date3 = Date(timeIntervalSince1970: 1_700_172_800)

    static func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
    }

    static func job(
        id: Int = 1,
        title: String = "iOS Engineer",
        company: String = "Acme",
        createdAt: Date = date1
    ) -> Job {
        Job(id: uuid(id), title: title, company: company, location: "Remote",
            jobDescription: "Build apps.", createdAt: createdAt, updatedAt: createdAt)
    }

    static func referral(
        id: Int = 100,
        jobID: Int = 1,
        email: String = "jane@example.com",
        status: ReferralStatus = .pending,
        updatedAt: Date = date1
    ) -> Referral {
        Referral(id: uuid(id), jobID: uuid(jobID), contactName: "Jane Doe", email: email,
                 linkedInURL: URL(string: "https://www.linkedin.com/in/janedoe")!, note: nil,
                 status: status, createdAt: date1, updatedAt: updatedAt, statusUpdatedAt: date1)
    }
}

/// Returns UUIDs 1, 2, 3… in order.
final class SequentialIDs: @unchecked Sendable {
    private var next: Int
    private let lock = NSLock()

    init(startingAt start: Int = 1) { next = start }

    func make() -> UUID {
        lock.lock(); defer { lock.unlock() }
        defer { next += 1 }
        return Fixtures.uuid(next)
    }
}
