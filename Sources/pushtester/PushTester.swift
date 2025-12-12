//
//  PushTester.swift
//  pushtester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import ArgumentParser
import Foundation

@main
struct PushTester: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pushtester",
        abstract: "Send test push notifications via Apple Push Notification Service (APNs)",
        version: "1.0.0",
        subcommands: [Send.self],
        defaultSubcommand: Send.self
    )
}

struct Send: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Send a push notification to a device"
    )

    @Option(name: [.short, .customLong("device-token")], help: "The 64-character hex device token")
    var deviceToken: String

    @Option(name: [.short, .customLong("bundle-id")], help: "The app's bundle identifier (e.g., com.example.app)")
    var bundleId: String

    @Option(name: [.short, .customLong("team-id")], help: "Your Apple Developer Team ID")
    var teamId: String

    @Option(name: [.short, .customLong("key-id")], help: "The APNs authentication key ID")
    var keyId: String

    @Option(name: [.customLong("key-path")], help: "Path to the .p8 authentication key file")
    var keyPath: String

    @Option(name: [.short, .long], help: "JSON payload string or @filename to read from file")
    var payload: String

    @Flag(name: .long, help: "Use production APNs environment (default is sandbox)")
    var production: Bool = false

    @Flag(name: [.short, .long], help: "Show verbose output including request details")
    var verbose: Bool = false

    mutating func run() async throws {
        let output = OutputFormatter()

        // Validate device token
        let validator = TokenValidator()
        if let error = validator.validate(deviceToken) {
            output.printError("Invalid device token", details: error)
            throw ExitCode.failure
        }

        // Load payload
        let payloadString: String
        if payload.hasPrefix("@") {
            let filePath = String(payload.dropFirst())
            let expandedPath = NSString(string: filePath).expandingTildeInPath
            guard let data = FileManager.default.contents(atPath: expandedPath),
                  let content = String(data: data, encoding: .utf8) else {
                output.printError("Cannot read payload file", details: "File not found or unreadable: \(filePath)")
                throw ExitCode.failure
            }
            payloadString = content
        } else {
            payloadString = payload
        }

        // Validate JSON
        guard let payloadData = payloadString.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: payloadData)) != nil else {
            output.printError("Invalid JSON payload", details: "The payload is not valid JSON")
            throw ExitCode.failure
        }

        // Expand key path
        let expandedKeyPath = NSString(string: keyPath).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedKeyPath) else {
            output.printError("Key file not found", details: "File does not exist: \(keyPath)")
            throw ExitCode.failure
        }

        if verbose {
            output.printInfo("Configuration:")
            output.printDetail("Device Token", deviceToken)
            output.printDetail("Bundle ID", bundleId)
            output.printDetail("Team ID", teamId)
            output.printDetail("Key ID", keyId)
            output.printDetail("Key Path", expandedKeyPath)
            output.printDetail("Environment", production ? "Production" : "Sandbox")
            output.printDetail("Payload", payloadString)
            print()
        }

        // Send push notification
        let client = APNsClient()

        do {
            let response = try await client.send(
                deviceToken: deviceToken,
                bundleId: bundleId,
                teamId: teamId,
                keyId: keyId,
                keyPath: expandedKeyPath,
                payload: payloadString,
                isProduction: production
            )

            if response.success {
                output.printSuccess("Push notification sent successfully")
                output.printDetail("Status", "\(response.statusCode) OK")
                if let apnsId = response.apnsId {
                    output.printDetail("APNs ID", apnsId)
                }
            } else {
                output.printError("Push notification failed", details: nil)
                output.printDetail("Status", "\(response.statusCode)")
                if let reason = response.reason {
                    output.printDetail("Reason", reason)
                    if let explanation = output.explainError(reason) {
                        print()
                        output.printExplanation(explanation)
                    }
                }
                throw ExitCode.failure
            }
        } catch let error as APNsError {
            output.printError("Failed to send push", details: error.localizedDescription)
            throw ExitCode.failure
        }
    }
}
