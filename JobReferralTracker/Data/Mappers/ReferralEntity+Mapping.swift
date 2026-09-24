import CoreData

extension ReferralEntity {
    /// Throws `DataError.corruptRecord` when the stored status, URL or job link is invalid.
    func toDomain() throws -> Referral {
        guard let job,
              let status = ReferralStatus(rawValue: statusRaw),
              let url = URL(string: linkedInURL)
        else { throw DataError.corruptRecord(entity: Self.entityName, id: id) }

        return Referral(id: id, jobID: job.id, contactName: contactName, email: email,
                        linkedInURL: url, note: note, status: status, createdAt: createdAt,
                        updatedAt: updatedAt, statusUpdatedAt: statusUpdatedAt)
    }

    func toListItem() throws -> ReferralListItem {
        let referral = try toDomain()
        guard let job else { throw DataError.corruptRecord(entity: Self.entityName, id: id) }
        return ReferralListItem(referral: referral, jobTitle: job.title, company: job.company)
    }

    /// Copies every field except the job link.
    func apply(_ referral: Referral) {
        id = referral.id
        contactName = referral.contactName
        email = referral.email
        linkedInURL = referral.linkedInURL.absoluteString
        note = referral.note
        statusRaw = referral.status.rawValue
        createdAt = referral.createdAt
        updatedAt = referral.updatedAt
        statusUpdatedAt = referral.statusUpdatedAt
    }
}
