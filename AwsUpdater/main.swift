//
//  main.swift
//  AwsUpdater
//
//  Created by John Brosnan on 4/19/25.
//

import Foundation
import AppKit

// Get the home directory path
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let credentialsPath = homeDirectory.appendingPathComponent(".aws/credentials")

// Get clipboard contents first
let pasteboard = NSPasteboard.general
guard let clipboardContent = pasteboard.string(forType: .string) else {
    print("Error: No text found in clipboard")
    exit(1)
}

// Read and update the credentials file
do {
    let content = try String(contentsOf: credentialsPath, encoding: .utf8)
    let lines = content.components(separatedBy: .newlines)

    // Parse file into sections: each section is (header, [lines])
    var sections: [(header: String, lines: [String])] = []
    var currentHeader: String? = nil
    var currentLines: [String] = []

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            // Save previous section if exists
            if let header = currentHeader {
                sections.append((header: header, lines: currentLines))
            }
            currentHeader = trimmed
            currentLines = []
        } else if currentHeader != nil {
            currentLines.append(line)
        }
    }
    // Don't forget the last section
    if let header = currentHeader {
        sections.append((header: header, lines: currentLines))
    }

    // Build new file content, replacing only [default] section
    var outputLines: [String] = []
    var foundDefault = false

    for section in sections {
        if section.header.lowercased() == "[default]" {
            foundDefault = true
            outputLines.append(section.header)
            // Add the new credentials from clipboard (without any header if present)
            let clipLines = clipboardContent.components(separatedBy: .newlines)
            for clipLine in clipLines {
                let trimmed = clipLine.trimmingCharacters(in: .whitespaces)
                // Skip any section header in clipboard content
                if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                    continue
                }
                // Skip empty lines at start
                if outputLines.count == 1 && trimmed.isEmpty {
                    continue
                }
                outputLines.append(clipLine)
            }
        } else {
            // Keep other sections intact
            outputLines.append(section.header)
            outputLines.append(contentsOf: section.lines)
        }
    }

    // If no [default] section existed, add it
    if !foundDefault {
        if !outputLines.isEmpty {
            outputLines.append("")
        }
        outputLines.append("[default]")
        let clipLines = clipboardContent.components(separatedBy: .newlines)
        for clipLine in clipLines {
            let trimmed = clipLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                continue
            }
            outputLines.append(clipLine)
        }
    }

    // Write back to file
    let newContent = outputLines.joined(separator: "\n")
    try newContent.write(to: credentialsPath, atomically: true, encoding: .utf8)

    print("Successfully updated [default] AWS credentials")
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}

