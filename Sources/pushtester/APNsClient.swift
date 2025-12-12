//
//  APNsClient.swift
//  pushtester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import CryptoKit

// MARK: - Error Types

enum APNsError: LocalizedError {
    case invalidAuthKey(String)
    case invalidPayload
    case invalidDeviceToken
    case networkError(String)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidAuthKey(let detail):
            return "Invalid authentication key: \(detail)"
        case .invalidPayload:
            return "Invalid JSON payload"
        case .invalidDeviceToken:
            return "Invalid device token"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

// MARK: - Response

struct APNsResponse {
    let statusCode: Int
    let success: Bool
    let reason: String?
    let apnsId: String?
}

// MARK: - Client

class APNsClient {

    func send(
        deviceToken: String,
        bundleId: String,
        teamId: String,
        keyId: String,
        keyPath: String,
        payload: String,
        isProduction: Bool
    ) async throws -> APNsResponse {

        guard let payloadData = payload.data(using: .utf8) else {
            throw APNsError.invalidPayload
        }

        let jwt = try generateJWT(teamId: teamId, keyId: keyId, keyPath: keyPath)

        let endpoint = isProduction
            ? "https://api.push.apple.com"
            : "https://api.development.push.apple.com"

        let urlString = "\(endpoint)/3/device/\(deviceToken)"
        guard let url = URL(string: urlString) else {
            throw APNsError.invalidDeviceToken
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("bearer \(jwt)", forHTTPHeaderField: "authorization")
        request.setValue(bundleId, forHTTPHeaderField: "apns-topic")
        request.httpBody = payloadData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APNsError.networkError("Invalid response")
        }

        let apnsId = httpResponse.value(forHTTPHeaderField: "apns-id")

        var reason: String?
        if !data.isEmpty,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorReason = json["reason"] as? String {
            reason = errorReason
        }

        return APNsResponse(
            statusCode: httpResponse.statusCode,
            success: httpResponse.statusCode == 200,
            reason: reason,
            apnsId: apnsId
        )
    }

    // MARK: - JWT Generation

    private func generateJWT(teamId: String, keyId: String, keyPath: String) throws -> String {
        guard let keyData = FileManager.default.contents(atPath: keyPath),
              let keyString = String(data: keyData, encoding: .utf8) else {
            throw APNsError.invalidAuthKey("Cannot read key file")
        }

        let privateKey = try loadPrivateKey(from: keyString)

        let header = JWTHeader(alg: "ES256", kid: keyId)
        let claims = JWTClaims(iss: teamId, iat: Int(Date().timeIntervalSince1970))

        let headerBase64 = try base64URLEncode(header)
        let claimsBase64 = try base64URLEncode(claims)

        let signatureInput = "\(headerBase64).\(claimsBase64)"
        let signature = try sign(signatureInput, with: privateKey)

        return "\(signatureInput).\(signature)"
    }

    private func loadPrivateKey(from pemString: String) throws -> P256.Signing.PrivateKey {
        let keyString = pemString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: keyString) else {
            throw APNsError.invalidAuthKey("Invalid base64 encoding")
        }

        // The .p8 file contains a PKCS#8 formatted key
        if keyData.count > 32 {
            if let rawKey = extractP256KeyFromPKCS8(keyData) {
                return try P256.Signing.PrivateKey(rawRepresentation: rawKey)
            }
        }

        // Fallback attempts
        do {
            return try P256.Signing.PrivateKey(x963Representation: keyData)
        } catch {
            return try P256.Signing.PrivateKey(rawRepresentation: keyData)
        }
    }

    private func extractP256KeyFromPKCS8(_ data: Data) -> Data? {
        let bytes = [UInt8](data)

        // Search for the private key marker in the ASN.1 structure
        // Look for 0x04 0x20 (OCTET STRING of 32 bytes) followed by the key
        for i in 0..<(bytes.count - 33) {
            if bytes[i] == 0x04 && bytes[i + 1] == 0x20 {
                let keyStart = i + 2
                let keyEnd = keyStart + 32
                if keyEnd <= bytes.count {
                    return Data(bytes[keyStart..<keyEnd])
                }
            }
        }

        // Alternative: for some PKCS#8 structures, try last 32 bytes
        if data.count >= 32 {
            return data.suffix(32)
        }

        return nil
    }

    private func base64URLEncode<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func sign(_ input: String, with privateKey: P256.Signing.PrivateKey) throws -> String {
        let inputData = Data(input.utf8)
        let signature = try privateKey.signature(for: inputData)
        return signature.rawRepresentation.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - JWT Structures

private struct JWTHeader: Codable {
    let alg: String
    let kid: String
}

private struct JWTClaims: Codable {
    let iss: String
    let iat: Int
}
