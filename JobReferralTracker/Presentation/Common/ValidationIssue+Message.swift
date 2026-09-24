import Foundation

extension ValidationIssue {
    func message(fieldName: String) -> String {
        switch self {
        case .required:
            return "\(fieldName) is required."
        case .tooLong(let max):
            return "\(fieldName) must be \(max) characters or fewer."
        case .invalidEmail:
            return "Enter a valid email address."
        case .invalidLinkedInURL:
            return "Enter a LinkedIn profile URL, like linkedin.com/in/name."
        case .duplicateEmail:
            return "Another referral for this job already uses this email."
        }
    }
}

extension JobField {
    var label: String {
        switch self {
        case .title: return "Title"
        case .company: return "Company"
        case .location: return "Location"
        case .jobDescription: return "Description"
        }
    }
}

extension ReferralField {
    var label: String {
        switch self {
        case .contactName: return "Name"
        case .email: return "Email"
        case .linkedInProfile: return "LinkedIn profile"
        case .note: return "Note"
        }
    }
}
