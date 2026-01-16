//
//  CredentialsUpdaterTests.swift
//  AwsUpdaterTests
//

import XCTest
@testable import AwsUpdater

final class CredentialsUpdaterTests: XCTestCase {

    var updater: CredentialsUpdater!

    override func setUp() {
        super.setUp()
        updater = CredentialsUpdater()
    }

    // MARK: - parseSections Tests

    func testParseSections_singleSection() {
        let content = """
        [default]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        """

        let sections = updater.parseSections(content)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].header, "[default]")
        XCTAssertEqual(sections[0].lines.count, 2)
    }

    func testParseSections_multipleSections() {
        let content = """
        [default]
        aws_access_key_id = DEFAULT_KEY

        [profile dev]
        aws_access_key_id = DEV_KEY

        [profile prod]
        aws_access_key_id = PROD_KEY
        """

        let sections = updater.parseSections(content)

        XCTAssertEqual(sections.count, 3)
        XCTAssertEqual(sections[0].header, "[default]")
        XCTAssertEqual(sections[1].header, "[profile dev]")
        XCTAssertEqual(sections[2].header, "[profile prod]")
    }

    func testParseSections_emptyContent() {
        let content = ""

        let sections = updater.parseSections(content)

        XCTAssertEqual(sections.count, 0)
    }

    func testParseSections_noSections() {
        let content = """
        # This is a comment
        some random text
        """

        let sections = updater.parseSections(content)

        XCTAssertEqual(sections.count, 0)
    }

    func testParseSections_preservesWhitespaceInLines() {
        let content = """
        [default]
            aws_access_key_id = KEY
        """

        let sections = updater.parseSections(content)

        XCTAssertEqual(sections.count, 1)
        // The line should preserve its original indentation
        XCTAssertTrue(sections[0].lines[0].hasPrefix("    "))
    }

    // MARK: - filterClipboardContent Tests

    func testFilterClipboardContent_removesHeaders() {
        let content = """
        [default]
        aws_access_key_id = KEY
        aws_secret_access_key = SECRET
        """

        let filtered = updater.filterClipboardContent(content)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertFalse(filtered.contains("[default]"))
        XCTAssertTrue(filtered[0].contains("aws_access_key_id"))
    }

    func testFilterClipboardContent_removesLeadingEmptyLines() {
        let content = """


        aws_access_key_id = KEY
        """

        let filtered = updater.filterClipboardContent(content)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered[0].contains("aws_access_key_id"))
    }

    func testFilterClipboardContent_preservesMiddleEmptyLines() {
        let content = """
        aws_access_key_id = KEY

        aws_secret_access_key = SECRET
        """

        let filtered = updater.filterClipboardContent(content)

        XCTAssertEqual(filtered.count, 3)
        XCTAssertTrue(filtered[1].isEmpty)
    }

    // MARK: - updateSection Tests (default profile)

    func testUpdateSection_replacesExistingDefault() {
        let sections = [
            CredentialsSection(header: "[default]", lines: ["aws_access_key_id = OLD_KEY"]),
            CredentialsSection(header: "[profile dev]", lines: ["aws_access_key_id = DEV_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_KEY\naws_secret_access_key = NEW_SECRET"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("aws_access_key_id = NEW_KEY"))
        XCTAssertTrue(result.contains("aws_secret_access_key = NEW_SECRET"))
        XCTAssertFalse(result.contains("OLD_KEY"))
        XCTAssertTrue(result.contains("[profile dev]"))
        XCTAssertTrue(result.contains("DEV_KEY"))
    }

    func testUpdateSection_addsDefaultWhenMissing() {
        let sections = [
            CredentialsSection(header: "[profile dev]", lines: ["aws_access_key_id = DEV_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("aws_access_key_id = NEW_KEY"))
        XCTAssertTrue(result.contains("[profile dev]"))
    }

    func testUpdateSection_createsDefaultInEmptyFile() {
        let sections: [CredentialsSection] = []
        let newCredentials = "aws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("aws_access_key_id = NEW_KEY"))
    }

    func testUpdateSection_caseInsensitiveDefaultMatch() {
        let sections = [
            CredentialsSection(header: "[DEFAULT]", lines: ["aws_access_key_id = OLD_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        // Should replace, not add a new [default]
        let defaultCount = result.components(separatedBy: "[").filter { $0.lowercased().hasPrefix("default]") }.count
        XCTAssertEqual(defaultCount, 1)
        XCTAssertTrue(result.contains("NEW_KEY"))
        XCTAssertFalse(result.contains("OLD_KEY"))
    }

    func testUpdateSection_stripsHeaderFromClipboard() {
        let sections = [
            CredentialsSection(header: "[default]", lines: ["aws_access_key_id = OLD_KEY"])
        ]
        let newCredentials = "[default]\naws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        // Should only have one [default] header
        let lines = result.components(separatedBy: "\n")
        let defaultHeaders = lines.filter { $0.trimmingCharacters(in: .whitespaces).lowercased() == "[default]" }
        XCTAssertEqual(defaultHeaders.count, 1)
    }

    func testUpdateSection_preservesOtherSectionsOrder() {
        let sections = [
            CredentialsSection(header: "[profile alpha]", lines: ["key = alpha"]),
            CredentialsSection(header: "[default]", lines: ["key = default"]),
            CredentialsSection(header: "[profile beta]", lines: ["key = beta"])
        ]
        let newCredentials = "key = new_default"

        let result = updater.updateSection(sections: sections, profileName: "default", newCredentials: newCredentials)

        let alphaIndex = result.range(of: "[profile alpha]")!.lowerBound
        let defaultIndex = result.range(of: "[default]")!.lowerBound
        let betaIndex = result.range(of: "[profile beta]")!.lowerBound

        XCTAssertLessThan(alphaIndex, defaultIndex)
        XCTAssertLessThan(defaultIndex, betaIndex)
    }

    // MARK: - updateSection Tests (custom profiles)

    func testUpdateSection_updatesExistingCustomProfile() {
        let sections = [
            CredentialsSection(header: "[default]", lines: ["aws_access_key_id = DEFAULT_KEY"]),
            CredentialsSection(header: "[production]", lines: ["aws_access_key_id = OLD_PROD_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_PROD_KEY"

        let result = updater.updateSection(sections: sections, profileName: "production", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("DEFAULT_KEY"))
        XCTAssertTrue(result.contains("[production]"))
        XCTAssertTrue(result.contains("NEW_PROD_KEY"))
        XCTAssertFalse(result.contains("OLD_PROD_KEY"))
    }

    func testUpdateSection_createsNewCustomProfile() {
        let sections = [
            CredentialsSection(header: "[default]", lines: ["aws_access_key_id = DEFAULT_KEY"])
        ]
        let newCredentials = "aws_access_key_id = STAGING_KEY"

        let result = updater.updateSection(sections: sections, profileName: "staging", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("DEFAULT_KEY"))
        XCTAssertTrue(result.contains("[staging]"))
        XCTAssertTrue(result.contains("STAGING_KEY"))
    }

    func testUpdateSection_createsCustomProfileInEmptyFile() {
        let sections: [CredentialsSection] = []
        let newCredentials = "aws_access_key_id = PROD_KEY"

        let result = updater.updateSection(sections: sections, profileName: "production", newCredentials: newCredentials)

        XCTAssertTrue(result.contains("[production]"))
        XCTAssertTrue(result.contains("PROD_KEY"))
        XCTAssertFalse(result.contains("[default]"))
    }

    func testUpdateSection_caseInsensitiveCustomProfileMatch() {
        let sections = [
            CredentialsSection(header: "[PRODUCTION]", lines: ["aws_access_key_id = OLD_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "production", newCredentials: newCredentials)

        // Should replace existing, not add a new section
        let prodCount = result.components(separatedBy: "[").filter { $0.lowercased().hasPrefix("production]") }.count
        XCTAssertEqual(prodCount, 1)
        XCTAssertTrue(result.contains("NEW_KEY"))
        XCTAssertFalse(result.contains("OLD_KEY"))
    }

    func testUpdateSection_preservesOriginalHeaderCase() {
        let sections = [
            CredentialsSection(header: "[PRODUCTION]", lines: ["aws_access_key_id = OLD_KEY"])
        ]
        let newCredentials = "aws_access_key_id = NEW_KEY"

        let result = updater.updateSection(sections: sections, profileName: "production", newCredentials: newCredentials)

        // Should preserve the original [PRODUCTION] header, not replace with [production]
        XCTAssertTrue(result.contains("[PRODUCTION]"))
        XCTAssertFalse(result.contains("[production]"))
    }
}

// MARK: - Mock Providers for Integration Tests

final class MockClipboardProvider: ClipboardProvider {
    var content: String?

    func getString() -> String? {
        return content
    }
}

final class MockFileProvider: FileProvider {
    var files: [URL: String] = [:]
    var writeError: Error?
    var readError: Error?

    func read(from url: URL) throws -> String {
        if let error = readError {
            throw error
        }
        guard let content = files[url] else {
            throw NSError(domain: "MockFileProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        return content
    }

    func write(_ content: String, to url: URL) throws {
        if let error = writeError {
            throw error
        }
        files[url] = content
    }
}

// MARK: - Integration Tests

final class AWSCredentialsManagerTests: XCTestCase {

    var mockClipboard: MockClipboardProvider!
    var mockFileProvider: MockFileProvider!
    var manager: AWSCredentialsManager!
    let testURL = URL(fileURLWithPath: "/tmp/test-credentials")

    override func setUp() {
        super.setUp()
        mockClipboard = MockClipboardProvider()
        mockFileProvider = MockFileProvider()
        manager = AWSCredentialsManager(
            clipboard: mockClipboard,
            fileProvider: mockFileProvider
        )
    }

    func testUpdateCredentials_fullFlow_defaultProfile() throws {
        // Setup
        mockFileProvider.files[testURL] = """
        [default]
        aws_access_key_id = OLD_KEY

        [profile dev]
        aws_access_key_id = DEV_KEY
        """
        mockClipboard.content = "aws_access_key_id = NEW_KEY\naws_secret_access_key = NEW_SECRET"

        // Execute
        try manager.updateCredentials(at: testURL)

        // Verify
        let result = mockFileProvider.files[testURL]!
        XCTAssertTrue(result.contains("NEW_KEY"))
        XCTAssertTrue(result.contains("NEW_SECRET"))
        XCTAssertFalse(result.contains("OLD_KEY"))
        XCTAssertTrue(result.contains("[profile dev]"))
        XCTAssertTrue(result.contains("DEV_KEY"))
    }

    func testUpdateCredentials_customProfile() throws {
        // Setup
        mockFileProvider.files[testURL] = """
        [default]
        aws_access_key_id = DEFAULT_KEY

        [production]
        aws_access_key_id = OLD_PROD_KEY
        """
        mockClipboard.content = "aws_access_key_id = NEW_PROD_KEY"

        // Execute
        try manager.updateCredentials(at: testURL, profileName: "production")

        // Verify
        let result = mockFileProvider.files[testURL]!
        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("DEFAULT_KEY"))
        XCTAssertTrue(result.contains("[production]"))
        XCTAssertTrue(result.contains("NEW_PROD_KEY"))
        XCTAssertFalse(result.contains("OLD_PROD_KEY"))
    }

    func testUpdateCredentials_createsNewProfile() throws {
        // Setup
        mockFileProvider.files[testURL] = """
        [default]
        aws_access_key_id = DEFAULT_KEY
        """
        mockClipboard.content = "aws_access_key_id = STAGING_KEY"

        // Execute
        try manager.updateCredentials(at: testURL, profileName: "staging")

        // Verify
        let result = mockFileProvider.files[testURL]!
        XCTAssertTrue(result.contains("[default]"))
        XCTAssertTrue(result.contains("DEFAULT_KEY"))
        XCTAssertTrue(result.contains("[staging]"))
        XCTAssertTrue(result.contains("STAGING_KEY"))
    }

    func testUpdateCredentials_noClipboardContent_throwsError() {
        mockFileProvider.files[testURL] = "[default]\nkey = value"
        mockClipboard.content = nil

        XCTAssertThrowsError(try manager.updateCredentials(at: testURL)) { error in
            XCTAssertEqual((error as? AWSCredentialsError), .noClipboardContent)
        }
    }

    func testUpdateCredentials_fileReadError_propagatesError() {
        mockClipboard.content = "aws_access_key_id = KEY"
        mockFileProvider.readError = NSError(domain: "Test", code: 1, userInfo: nil)

        XCTAssertThrowsError(try manager.updateCredentials(at: testURL))
    }

    func testUpdateCredentials_fileWriteError_propagatesError() {
        mockFileProvider.files[testURL] = "[default]\nkey = value"
        mockClipboard.content = "aws_access_key_id = KEY"
        mockFileProvider.writeError = NSError(domain: "Test", code: 1, userInfo: nil)

        XCTAssertThrowsError(try manager.updateCredentials(at: testURL))
    }
}
