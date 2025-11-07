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

// Read the credentials file
do {
    let content = try String(contentsOf: credentialsPath, encoding: .utf8)
    var lines = content.components(separatedBy: .newlines)
    
    // Filter out lines starting with 'aws_' and blank lines
    lines = lines.filter { line in
        !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !line.hasPrefix("aws_")
    }
    
    // Get clipboard contents
    let pasteboard = NSPasteboard.general
    guard let clipboardContent = pasteboard.string(forType: .string) else {
        print("Error: No text found in clipboard")
        exit(1)
    }
    
    // Append clipboard content
    lines.append(clipboardContent)
    
    // Join lines and write back to file
    let newContent = lines.joined(separator: "\n")
    try newContent.write(to: credentialsPath, atomically: true, encoding: .utf8)
    
    print("Successfully updated AWS credentials file")
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}

