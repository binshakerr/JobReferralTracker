import XCTest
@testable import JobReferralTracker

final class ReferralValidatorTests: XCTestCase {
    private let validator = ReferralValidator()

    private func draft(
        contactName: String = "Jane Doe",
        email: String = "jane@example.com",
        linkedInProfile: String = "https://www.linkedin.com/in/janedoe",
        note: String = ""
    ) -> ReferralDraft {
        var draft = ReferralDraft()
        draft.contactName = contactName
        draft.email = email
        draft.linkedInProfile = linkedInProfile
        draft.note = note
        return draft
    }

    // MARK: - Whole draft

    func testCompleteDraftIsValid() {
        XCTAssertEqual(validator.validate(draft()).issues, [:])
    }

    func testNewDraftDefaultsToPending() {
        XCTAssertEqual(ReferralDraft().status, .pending)
    }

    func testBlankRequiredFieldsAreReported() {
        let result = validator.validate(draft(contactName: " ", email: "", linkedInProfile: "  "))

        XCTAssertEqual(result[.contactName], .required)
        XCTAssertEqual(result[.email], .required)
        XCTAssertEqual(result[.linkedInProfile], .required)
    }

    func testContactNameLimit() {
        XCTAssertNil(validator.validate(draft(contactName: String(repeating: "n", count: 120)))[.contactName])
        XCTAssertEqual(validator.validate(draft(contactName: String(repeating: "n", count: 121)))[.contactName], .tooLong(max: 120))
    }

    func testNoteIsOptionalWithLimit() {
        XCTAssertNil(validator.validate(draft(note: String(repeating: "x", count: 2000)))[.note])
        XCTAssertEqual(validator.validate(draft(note: String(repeating: "x", count: 2001)))[.note], .tooLong(max: 2000))
    }

    // MARK: - Email

    func testValidEmailsAreAccepted() {
        for email in ["jane@example.com", " Jane.Doe+jobs@Example.co.uk ", "a_b-c%d@sub.domain.io"] {
            XCTAssertNil(validator.validate(draft(email: email))[.email], email)
        }
    }

    func testMalformedEmailsAreRejected() {
        for email in ["jane", "jane@", "@example.com", "jane@example", "jane doe@example.com", "jane@example.c"] {
            XCTAssertEqual(validator.validate(draft(email: email))[.email], .invalidEmail, email)
        }
    }

    func testNormalizedEmailIsTrimmedAndLowercased() {
        XCTAssertEqual(validator.normalizedEmail("  Jane.Doe@Example.COM \n"), "jane.doe@example.com")
    }

    // MARK: - LinkedIn

    func testLinkedInURLWithoutSchemeIsNormalizedToHTTPS() {
        XCTAssertEqual(validator.normalizedLinkedInURL(" linkedin.com/in/janedoe "),
                       URL(string: "https://linkedin.com/in/janedoe"))
    }

    func testHTTPLinkedInURLIsUpgradedToHTTPS() {
        XCTAssertEqual(validator.normalizedLinkedInURL("http://www.linkedin.com/in/janedoe"),
                       URL(string: "https://www.linkedin.com/in/janedoe"))
    }

    func testCountrySubdomainIsAccepted() {
        XCTAssertEqual(validator.normalizedLinkedInURL("https://uk.linkedin.com/in/janedoe"),
                       URL(string: "https://uk.linkedin.com/in/janedoe"))
    }

    func testNonLinkedInURLsAreRejected() {
        let invalid = [
            "https://example.com/in/janedoe",
            "https://notlinkedin.com/in/janedoe",
            "https://linkedin.com.evil.com/in/janedoe",
            "https://linkedin.com",
            "https://linkedin.com/",
            "ftp://linkedin.com/in/janedoe",
            "janedoe",
        ]
        for raw in invalid {
            XCTAssertNil(validator.normalizedLinkedInURL(raw), raw)
            XCTAssertEqual(validator.validate(draft(linkedInProfile: raw))[.linkedInProfile], .invalidLinkedInURL, raw)
        }
    }

    // MARK: - Note

    func testBlankNoteNormalizesToNil() {
        XCTAssertNil(validator.normalizedNote("  \n "))
    }

    func testNoteIsTrimmed() {
        XCTAssertEqual(validator.normalizedNote("  Met at WWDC. \n"), "Met at WWDC.")
    }
}
