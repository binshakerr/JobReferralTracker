import XCTest
@testable import JobReferralTracker

final class JobValidatorTests: XCTestCase {
    private let validator = JobValidator()

    private func draft(
        title: String = "iOS Engineer",
        company: String = "Acme",
        location: String = "",
        jobDescription: String = ""
    ) -> JobDraft {
        var draft = JobDraft()
        draft.title = title
        draft.company = company
        draft.location = location
        draft.jobDescription = jobDescription
        return draft
    }

    func testDraftWithOnlyTitleAndCompanyIsValid() {
        let result = validator.validate(draft())

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.issues, [:])
    }

    func testWhitespaceOnlyTitleAndCompanyAreRequired() {
        let result = validator.validate(draft(title: "   ", company: "\n\t"))

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result[.title], .required)
        XCTAssertEqual(result[.company], .required)
    }

    func testTitleAtLimitIsValidAndOneOverIsTooLong() {
        XCTAssertNil(validator.validate(draft(title: String(repeating: "a", count: 120)))[.title])
        XCTAssertEqual(validator.validate(draft(title: String(repeating: "a", count: 121)))[.title], .tooLong(max: 120))
    }

    func testLengthIsMeasuredAfterTrimming() {
        let padded = "  " + String(repeating: "a", count: 120) + "  "

        XCTAssertNil(validator.validate(draft(company: padded))[.company])
    }

    func testCompanyLocationAndDescriptionLimits() {
        let result = validator.validate(draft(
            company: String(repeating: "c", count: 121),
            location: String(repeating: "l", count: 121),
            jobDescription: String(repeating: "d", count: 5001)
        ))

        XCTAssertEqual(result[.company], .tooLong(max: 120))
        XCTAssertEqual(result[.location], .tooLong(max: 120))
        XCTAssertEqual(result[.jobDescription], .tooLong(max: 5000))
    }

    func testDescriptionAtLimitIsValid() {
        XCTAssertNil(validator.validate(draft(jobDescription: String(repeating: "d", count: 5000)))[.jobDescription])
    }

    func testNormalizedTrimsEveryField() {
        let normalized = validator.normalized(draft(
            title: "  iOS Engineer ",
            company: "\tAcme\n",
            location: " Remote ",
            jobDescription: "\n Build apps. \n"
        ))

        XCTAssertEqual(normalized.title, "iOS Engineer")
        XCTAssertEqual(normalized.company, "Acme")
        XCTAssertEqual(normalized.location, "Remote")
        XCTAssertEqual(normalized.jobDescription, "Build apps.")
    }
}
