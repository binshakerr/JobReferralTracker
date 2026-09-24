import CoreData

extension AppContainer {
    /// In-memory container for SwiftUI previews, optionally seeded with sample data.
    static func preview(seeded: Bool = true) -> AppContainer {
        let stack = CoreDataStack(storeType: .inMemory)
        // In-memory stores load synchronously, so the sample data can be inserted right away.
        stack.container.loadPersistentStores { _, _ in }
        if seeded {
            PreviewData.seed(into: stack.viewContext)
        }
        return AppContainer(stack: stack)
    }
}

enum PreviewData {
    static func seed(into context: NSManagedObjectContext) {
        let now = Date()
        let samples: [(title: String, company: String, location: String, referrals: [(String, ReferralStatus)])] = [
            ("Senior iOS Engineer", "Acme Corp", "Remote", [("Jane Doe", .interview), ("Sam Lee", .contacted), ("Priya Patel", .pending)]),
            ("Mobile Tech Lead", "Globex", "Berlin, DE", [("Omar Haddad", .hired), ("Lena Fischer", .rejected)]),
            ("Swift Developer", "Initech", "", []),
        ]

        for (index, sample) in samples.enumerated() {
            let job = JobEntity(context: context)
            job.apply(Job(id: UUID(), title: sample.title, company: sample.company, location: sample.location,
                          jobDescription: "Build and ship delightful iOS features with SwiftUI.",
                          createdAt: now.addingTimeInterval(Double(-index) * 86_400),
                          updatedAt: now.addingTimeInterval(Double(-index) * 86_400)))

            for (offset, (name, status)) in sample.referrals.enumerated() {
                let handle = name.lowercased().replacingOccurrences(of: " ", with: "")
                let referral = ReferralEntity(context: context)
                referral.apply(Referral(
                    id: UUID(), jobID: job.id, contactName: name, email: "\(handle)@example.com",
                    linkedInURL: URL(string: "https://www.linkedin.com/in/\(handle)")!,
                    note: offset == 0 ? "Former teammate — happy to refer." : nil, status: status,
                    createdAt: now.addingTimeInterval(Double(-offset) * 3_600),
                    updatedAt: now.addingTimeInterval(Double(-offset) * 3_600),
                    statusUpdatedAt: now.addingTimeInterval(Double(-offset) * 3_600)
                ))
                referral.job = job
            }
        }
        try? context.save()
    }
}
