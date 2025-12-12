//
//  TokenValidator.swift
//  pushtester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct TokenValidator {

    /// Validates a device token and returns an error message if invalid, or nil if valid
    func validate(_ token: String) -> String? {
        // Remove any whitespace or formatting
        let cleanToken = token
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()

        // Check length
        if cleanToken.isEmpty {
            return "Device token cannot be empty"
        }

        if cleanToken.count != 64 {
            return "Device token must be exactly 64 characters (got \(cleanToken.count))"
        }

        // Check for valid hex characters
        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdef")
        let tokenCharacters = CharacterSet(charactersIn: cleanToken)

        if !hexCharacters.isSuperset(of: tokenCharacters) {
            return "Device token must contain only hexadecimal characters (0-9, a-f)"
        }

        return nil
    }

    /// Returns a cleaned version of the token (lowercase, no spaces or brackets)
    func clean(_ token: String) -> String {
        return token
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()
    }
}
