//
//  main.swift
//  AwsUpdater
//
//  Created by John Brosnan on 4/19/25.
//

import Foundation

// Get the credentials file path
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let credentialsPath = homeDirectory.appendingPathComponent(".aws/credentials")

// Create manager with default (production) dependencies
let manager = AWSCredentialsManager()

do {
    try manager.updateCredentials(at: credentialsPath)
    print("Successfully updated [default] AWS credentials")
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
