//
//  OutputFormatter.swift
//  pushtester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct OutputFormatter {

    // MARK: - ANSI Colors

    private let reset = "\u{001B}[0m"
    private let bold = "\u{001B}[1m"
    private let dim = "\u{001B}[2m"

    private let red = "\u{001B}[31m"
    private let green = "\u{001B}[32m"
    private let yellow = "\u{001B}[33m"
    private let blue = "\u{001B}[34m"
    private let cyan = "\u{001B}[36m"

    private var useColors: Bool {
        // Check if stdout is a terminal
        return isatty(STDOUT_FILENO) != 0
    }

    // MARK: - Output Methods

    func printSuccess(_ message: String) {
        if useColors {
            print("\(green)\(bold)✓\(reset) \(green)\(message)\(reset)")
        } else {
            print("✓ \(message)")
        }
    }

    func printError(_ message: String, details: String?) {
        if useColors {
            print("\(red)\(bold)✗\(reset) \(red)\(message)\(reset)")
            if let details = details {
                print("  \(dim)\(details)\(reset)")
            }
        } else {
            print("✗ \(message)")
            if let details = details {
                print("  \(details)")
            }
        }
    }

    func printInfo(_ message: String) {
        if useColors {
            print("\(cyan)\(bold)\(message)\(reset)")
        } else {
            print(message)
        }
    }

    func printDetail(_ label: String, _ value: String) {
        if useColors {
            print("  \(dim)\(label):\(reset) \(value)")
        } else {
            print("  \(label): \(value)")
        }
    }

    func printExplanation(_ text: String) {
        if useColors {
            print("  \(yellow)\(bold)Explanation:\(reset)")
            for line in text.split(separator: "\n") {
                print("  \(dim)\(line)\(reset)")
            }
        } else {
            print("  Explanation:")
            for line in text.split(separator: "\n") {
                print("  \(line)")
            }
        }
    }

    // MARK: - Error Explanations

    func explainError(_ reason: String) -> String? {
        switch reason {
        case "BadDeviceToken":
            return """
                The device token is invalid. This usually means:
                • The token was generated for a different environment (sandbox vs production)
                • The token has been invalidated (app uninstalled or re-registered)
                • The token format is incorrect or corrupted
                """

        case "Unregistered":
            return """
                The device token is no longer active. This means:
                • The app has been uninstalled from the device
                • The user disabled push notifications for this app
                • The token has expired and needs to be refreshed
                """

        case "BadCertificate", "BadCertificateEnvironment":
            return """
                There's a problem with your authentication:
                • The .p8 key may not have APNs permissions enabled
                • You might be using a sandbox token with production endpoint (or vice versa)
                • The key may have been revoked in the Apple Developer Portal
                """

        case "ExpiredProviderToken":
            return """
                The JWT token has expired. This is usually a clock sync issue:
                • Check that your system clock is accurate
                • JWTs are only valid for 1 hour after generation
                """

        case "InvalidProviderToken":
            return """
                The JWT token is invalid. Check:
                • Team ID is correct and matches your Apple Developer account
                • Key ID matches the .p8 file you're using
                • The .p8 file is complete and not corrupted
                """

        case "MissingProviderToken":
            return """
                No authentication token was provided. This is an internal error.
                Please report this issue.
                """

        case "TopicDisallowed":
            return """
                The bundle ID (topic) is not allowed. This means:
                • The bundle ID doesn't match any app in your team
                • The .p8 key doesn't have permission for this app
                • Check that the bundle ID is spelled correctly
                """

        case "BadMessageId":
            return """
                The apns-id header value is invalid.
                This shouldn't happen with this tool - please report the issue.
                """

        case "PayloadEmpty":
            return """
                The push notification payload is empty.
                Provide a valid JSON payload with at least an 'aps' key.
                """

        case "PayloadTooLarge":
            return """
                The payload exceeds the maximum allowed size:
                • Regular notifications: 4KB max
                • VoIP notifications: 5KB max
                Reduce the size of your payload content.
                """

        case "BadTopic":
            return """
                The bundle ID (topic) is invalid:
                • Check that the bundle ID format is correct (e.g., com.example.app)
                • Ensure there are no typos or extra characters
                """

        case "DeviceTokenNotForTopic":
            return """
                The device token doesn't match this bundle ID:
                • The token was generated for a different app
                • Verify you're using the correct token for this app
                """

        case "TooManyRequests":
            return """
                Too many requests to APNs. You're being rate-limited:
                • Wait a moment before sending more notifications
                • Reduce the frequency of push notifications
                """

        case "InternalServerError", "ServiceUnavailable", "Shutdown":
            return """
                APNs is experiencing issues:
                • This is a temporary server-side problem
                • Wait a few moments and try again
                • Check Apple's System Status page if the problem persists
                """

        default:
            return nil
        }
    }

    // MARK: - JSON Pretty Printing

    func prettyPrintJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }
}
