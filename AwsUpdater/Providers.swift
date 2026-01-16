//
//  Providers.swift
//  AwsUpdater
//

import Foundation
import AppKit

// MARK: - Protocols

/// Protocol for clipboard access - allows mocking in tests
protocol ClipboardProvider {
    func getString() -> String?
}

/// Protocol for file system access - allows mocking in tests
protocol FileProvider {
    func read(from url: URL) throws -> String
    func write(_ content: String, to url: URL) throws
}

// MARK: - Production Implementations

/// Production implementation using the system clipboard
struct SystemClipboardProvider: ClipboardProvider {
    func getString() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
}

/// Production implementation using the real file system
struct SystemFileProvider: FileProvider {
    func read(from url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }

    func write(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

// MARK: - Manager

/// Orchestrates the credentials update process with injected dependencies
struct AWSCredentialsManager {
    let clipboard: ClipboardProvider
    let fileProvider: FileProvider
    let updater: CredentialsUpdater

    init(
        clipboard: ClipboardProvider = SystemClipboardProvider(),
        fileProvider: FileProvider = SystemFileProvider(),
        updater: CredentialsUpdater = CredentialsUpdater()
    ) {
        self.clipboard = clipboard
        self.fileProvider = fileProvider
        self.updater = updater
    }

    /// Updates the AWS credentials file with content from clipboard
    /// - Parameters:
    ///   - credentialsPath: Path to the credentials file
    ///   - profileName: The profile to update (defaults to "default")
    func updateCredentials(at credentialsPath: URL, profileName: String = "default") throws {
        // Get clipboard contents
        guard let clipboardContent = clipboard.getString() else {
            throw AWSCredentialsError.noClipboardContent
        }

        // Read current credentials file
        let content = try fileProvider.read(from: credentialsPath)

        // Parse and update
        let sections = updater.parseSections(content)
        let newContent = updater.updateSection(sections: sections, profileName: profileName, newCredentials: clipboardContent)

        // Write back
        try fileProvider.write(newContent, to: credentialsPath)
    }
}

// MARK: - Errors

enum AWSCredentialsError: LocalizedError {
    case noClipboardContent

    var errorDescription: String? {
        switch self {
        case .noClipboardContent:
            return "No text found in clipboard"
        }
    }
}
