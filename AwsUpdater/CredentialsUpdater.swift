//
//  CredentialsUpdater.swift
//  AwsUpdater
//

import Foundation

/// Represents a section in an AWS credentials file
struct CredentialsSection {
    let header: String
    let lines: [String]
}

/// Pure logic for parsing and updating AWS credentials files
struct CredentialsUpdater {

    /// Parses credentials file content into sections
    /// - Parameter content: The raw content of the credentials file
    /// - Returns: Array of sections, each with a header and associated lines
    func parseSections(_ content: String) -> [CredentialsSection] {
        let lines = content.components(separatedBy: .newlines)
        var sections: [CredentialsSection] = []
        var currentHeader: String? = nil
        var currentLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                // Save previous section if exists
                if let header = currentHeader {
                    sections.append(CredentialsSection(header: header, lines: currentLines))
                }
                currentHeader = trimmed
                currentLines = []
            } else if currentHeader != nil {
                currentLines.append(line)
            }
        }
        // Don't forget the last section
        if let header = currentHeader {
            sections.append(CredentialsSection(header: header, lines: currentLines))
        }

        return sections
    }

    /// Filters section headers from clipboard content
    /// - Parameter content: Raw clipboard content
    /// - Returns: Lines without section headers, with leading empty lines removed
    func filterClipboardContent(_ content: String) -> [String] {
        let clipLines = content.components(separatedBy: .newlines)
        var result: [String] = []

        for clipLine in clipLines {
            let trimmed = clipLine.trimmingCharacters(in: .whitespaces)
            // Skip any section header in clipboard content
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                continue
            }
            // Skip empty lines at start
            if result.isEmpty && trimmed.isEmpty {
                continue
            }
            result.append(clipLine)
        }

        return result
    }

    /// Updates or creates a section with new credentials
    /// - Parameters:
    ///   - sections: Parsed sections from the credentials file
    ///   - profileName: The profile name (e.g., "default", "production")
    ///   - newCredentials: New credentials content to put in the section
    /// - Returns: The complete updated credentials file content
    func updateSection(sections: [CredentialsSection], profileName: String, newCredentials: String) -> String {
        var outputLines: [String] = []
        var foundSection = false
        let filteredCredentials = filterClipboardContent(newCredentials)
        let targetHeader = "[\(profileName)]"

        for section in sections {
            if section.header.lowercased() == targetHeader.lowercased() {
                foundSection = true
                outputLines.append(section.header)
                outputLines.append(contentsOf: filteredCredentials)
            } else {
                // Keep other sections intact
                outputLines.append(section.header)
                outputLines.append(contentsOf: section.lines)
            }
        }

        // If section didn't exist, add it
        if !foundSection {
            if !outputLines.isEmpty {
                outputLines.append("")
            }
            outputLines.append(targetHeader)
            outputLines.append(contentsOf: filteredCredentials)
        }

        return outputLines.joined(separator: "\n")
    }
}
