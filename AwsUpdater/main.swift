//
//  main.swift
//  AwsUpdater
//
//  Created by John Brosnan on 4/19/25.
//

import Foundation

enum Command {
    case help
    case listProfiles
    case update(profileName: String)
}

func printHelp() {
    let help = """
    AwsUpdater - Update AWS credentials from clipboard

    Usage: AwsUpdater [options]

    Options:
      -h, --help    Show this help message
      -l            List all profiles in the credentials file
      -p <profile>  Specify the profile to update (default: "default")

    Examples:
      AwsUpdater              Update the default profile with clipboard contents
      AwsUpdater -p prod      Update the "prod" profile with clipboard contents
      AwsUpdater -l           List all available profiles
    """
    print(help)
}

func parseArguments() -> Command {
    let args = CommandLine.arguments
    var profileName = "default"

    var i = 1
    while i < args.count {
        switch args[i] {
        case "-h", "--help":
            return .help
        case "-l":
            return .listProfiles
        case "-p":
            if i + 1 < args.count {
                profileName = args[i + 1]
                i += 2
            } else {
                print("Error: -p requires a profile name")
                exit(1)
            }
        default:
            i += 1
        }
    }

    return .update(profileName: profileName)
}

func listProfiles(at credentialsPath: URL) {
    let fileProvider = SystemFileProvider()
    let updater = CredentialsUpdater()

    do {
        let content = try fileProvider.read(from: credentialsPath)
        let sections = updater.parseSections(content)
        let profileNames = updater.extractProfileNames(from: sections)

        if profileNames.isEmpty {
            print("No profiles found in credentials file")
        } else {
            print("Available profiles:")
            for name in profileNames {
                print("  \(name)")
            }
        }
    } catch {
        print("Error reading credentials file: \(error.localizedDescription)")
        exit(1)
    }
}

let command = parseArguments()

// Get the credentials file path
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let credentialsPath = homeDirectory.appendingPathComponent(".aws/credentials")

switch command {
case .help:
    printHelp()

case .listProfiles:
    listProfiles(at: credentialsPath)

case .update(let profileName):
    let manager = AWSCredentialsManager()
    do {
        try manager.updateCredentials(at: credentialsPath, profileName: profileName)
        print("Successfully updated [\(profileName)] AWS credentials")
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}
