import Foundation
import CryptoKit
import Security

enum APNsError: LocalizedError {
    case invalidAuthKey
    case invalidPayload
    case invalidDeviceToken
    case networkError(String)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidAuthKey:
            return "Invalid or missing auth key file"
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

struct APNsResponse {
    let statusCode: Int
    let body: String
    let success: Bool
}

class APNsService {
    static let shared = APNsService()

    private init() {}

    func sendPush(configuration: PushConfiguration) async throws -> APNsResponse {
        guard !configuration.deviceToken.isEmpty else {
            throw APNsError.invalidDeviceToken
        }

        guard let payloadData = configuration.payload.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: payloadData) else {
            throw APNsError.invalidPayload
        }

        let jwt = try generateJWT(configuration: configuration)

        let endpoint = configuration.isProduction
            ? "https://api.push.apple.com"
            : "https://api.development.push.apple.com"

        let urlString = "\(endpoint)/3/device/\(configuration.deviceToken)"
        guard let url = URL(string: urlString) else {
            throw APNsError.invalidDeviceToken
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("bearer \(jwt)", forHTTPHeaderField: "authorization")
        request.setValue(configuration.bundleId, forHTTPHeaderField: "apns-topic")
        request.httpBody = payloadData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APNsError.networkError("Invalid response")
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""

        return APNsResponse(
            statusCode: httpResponse.statusCode,
            body: responseBody,
            success: httpResponse.statusCode == 200
        )
    }

    private func generateJWT(configuration: PushConfiguration) throws -> String {
        let authKeyPath = configuration.authKeyPath
        guard let keyData = FileManager.default.contents(atPath: authKeyPath),
              let keyString = String(data: keyData, encoding: .utf8) else {
            throw APNsError.invalidAuthKey
        }

        let privateKey = try loadPrivateKey(from: keyString)

        let header = JWTHeader(alg: "ES256", kid: configuration.authKeyId)
        let claims = JWTClaims(iss: configuration.teamId, iat: Int(Date().timeIntervalSince1970))

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
            throw APNsError.invalidAuthKey
        }

        // The .p8 file contains a PKCS#8 formatted key
        // We need to extract the raw key bytes (last 32 bytes for P-256)
        // PKCS#8 structure: SEQUENCE { SEQUENCE { OID, OID }, OCTET STRING { SEQUENCE { INTEGER, OCTET STRING } } }
        // For P-256, the private key is 32 bytes at a specific offset

        // Try to parse as PKCS#8 first
        if keyData.count > 32 {
            // Find the raw 32-byte key - it's typically at the end after the ASN.1 wrapper
            // For Apple's .p8 files, the structure is consistent
            let rawKeyData = extractP256KeyFromPKCS8(keyData)
            if let rawKey = rawKeyData {
                return try P256.Signing.PrivateKey(rawRepresentation: rawKey)
            }
        }

        // Fallback: try x963 representation
        do {
            return try P256.Signing.PrivateKey(x963Representation: keyData)
        } catch {
            // Last resort: try raw representation
            return try P256.Signing.PrivateKey(rawRepresentation: keyData)
        }
    }

    private func extractP256KeyFromPKCS8(_ data: Data) -> Data? {
        // Apple's .p8 files use PKCS#8 format
        // The structure typically ends with the 32-byte private key
        // Look for the pattern: 04 20 (OCTET STRING of 32 bytes) followed by the key

        let bytes = [UInt8](data)

        // Search for the private key marker in the ASN.1 structure
        for i in 0..<(bytes.count - 33) {
            if bytes[i] == 0x04 && bytes[i + 1] == 0x20 {
                // Found OCTET STRING with 32 bytes length
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

private struct JWTHeader: Codable {
    let alg: String
    let kid: String
}

private struct JWTClaims: Codable {
    let iss: String
    let iat: Int
}
