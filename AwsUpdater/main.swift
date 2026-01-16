//
//  main.swift
//  AwsUpdater
//
//  Created by John Brosnan on 4/19/25.
//

import Foundation

// Parse command line arguments
func parseArguments() -> String {
    let args = CommandLine.arguments
    var profileName = "default"

    var i = 1
    while i < args.count {
        if args[i] == "-p" && i + 1 < args.count {
            profileName = args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }

    return profileName
}

let profileName = parseArguments()

// Get the credentials file path
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let credentialsPath = homeDirectory.appendingPathComponent(".aws/credentials")

// Create manager with default (production) dependencies
let manager = AWSCredentialsManager()

do {
    try manager.updateCredentials(at: credentialsPath, profileName: profileName)
    print("Successfully updated [\(profileName)] AWS credentials")
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
