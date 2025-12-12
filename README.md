# PushTester

A native macOS application and CLI tool for testing Apple Push Notification Service (APNs). Easily send test push notifications to iOS/iPadOS devices during development.

## Features

### GUI App
- **Multiple Configurations** - Create and manage multiple APNs configurations for different apps
- **Environment Support** - Switch between Development (Sandbox) and Production APNs endpoints
- **Device Token Validation** - Automatic validation of 64-character hex device tokens
- **Auth Key Management** - Load .p8 authentication keys with automatic Key ID extraction from filename
- **JSON Payload Editor** - Full payload editor with formatting and validation
- **Real-time Feedback** - View HTTP status codes and error messages from APNs
- **Persistent Storage** - Configurations saved automatically between sessions

### CLI Tool
- **Scriptable** - Perfect for CI/CD pipelines and automation
- **Proper Argument Parsing** - Using Swift Argument Parser
- **Colored Output** - Pretty-printed responses with ANSI colors
- **Error Explanations** - Detailed explanations for common APNs errors
- **File Support** - Load payloads from JSON files

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building)
- Apple Developer Account with APNs key

## Installation

### Download DMG (Recommended)

1. Download the latest DMG from [Releases](https://github.com/botirjon/PushTester/releases)
2. Open the DMG file
3. Drag PushTester to your Applications folder
4. Right-click the app → **Open** (required for first launch)

### Install CLI

```bash
# From DMG - copy the pushtester binary
sudo cp /Volumes/PushTester/pushtester /usr/local/bin/

# Or build from source
swift build -c release
sudo cp .build/release/pushtester /usr/local/bin/
```

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/botirjon/PushTester.git
   cd PushTester
   ```

2. **Option A**: Open in Xcode
   ```bash
   open PushTester.xcodeproj
   ```
   Then build and run (⌘R)

3. **Option B**: Build both app and CLI
   ```bash
   ./scripts/build-dmg.sh
   ```
   - DMG: `build/PushTester.dmg`
   - CLI: `build/pushtester`

4. **Option C**: Build CLI only
   ```bash
   swift build -c release
   ```
   Binary at `.build/release/pushtester`

## Usage

### Prerequisites

Before using PushTester, you'll need:

1. **Team ID** - Your Apple Developer Team ID (found in [Apple Developer Account](https://developer.apple.com/account))
2. **Bundle ID** - The bundle identifier of your iOS app
3. **APNs Key (.p8 file)** - Authentication key from Apple Developer Portal
4. **Key ID** - The ID of your APNs key (auto-extracted if filename contains it)
5. **Device Token** - The 64-character hex token from your iOS device

### GUI App

1. Launch PushTester
2. Click **+** in the sidebar to create a new configuration
3. Fill in your Team ID and Bundle ID
4. Select the appropriate environment (Development/Production)
5. Load your .p8 authentication key file
6. Enter your device token
7. Customize the payload JSON (or use the default)
8. Click **Save Configuration** then **Send Push Notification**

### CLI Tool

#### Options

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--device-token` | The 64-character hex device token |
| `-b` | `--bundle-id` | App bundle identifier (e.g., com.example.app) |
| `-t` | `--team-id` | Apple Developer Team ID |
| `-k` | `--key-id` | APNs authentication key ID |
| | `--key-path` | Path to the .p8 authentication key file |
| `-p` | `--payload` | JSON payload string or @filename |
| | `--production` | Use production APNs (default: sandbox) |
| `-v` | `--verbose` | Show verbose output |
| `-h` | `--help` | Show help information |

#### Examples

```bash
# Basic usage with short flags
pushtester send \
  -d YOUR_64_CHAR_TOKEN \
  -b com.example.app \
  -t TEAM123456 \
  -k KEY123456 \
  --key-path ~/Keys/AuthKey.p8 \
  -p '{"aps":{"alert":"Hello World!"}}'

# Full flags version
pushtester send \
  --device-token YOUR_64_CHAR_TOKEN \
  --bundle-id com.example.app \
  --team-id TEAM123456 \
  --key-id KEY123456 \
  --key-path ~/Keys/AuthKey_KEY123456.p8 \
  --payload '{"aps":{"alert":"Hello World!"}}'

# Load payload from file
pushtester send \
  -d YOUR_TOKEN \
  -b com.example.app \
  -t TEAM123456 \
  -k KEY123456 \
  --key-path ~/Keys/AuthKey.p8 \
  -p @payload.json

# Production environment with verbose output
pushtester send \
  -d YOUR_TOKEN \
  -b com.example.app \
  -t TEAM123456 \
  -k KEY123456 \
  --key-path ~/Keys/AuthKey.p8 \
  -p '{"aps":{"alert":"Hello!"}}' \
  --production \
  --verbose

# Show help
pushtester --help
pushtester send --help
```

#### Output Examples

```
# Success
✓ Push notification sent successfully
  Status: 200 OK
  APNs ID: 12345-abcde-67890

# Error with explanation
✗ Push notification failed
  Status: 400 Bad Request
  Reason: BadDeviceToken

  Explanation:
  The device token is invalid. This usually means:
  • The token was generated for a different environment (sandbox vs production)
  • The token has been invalidated (app uninstalled or re-registered)
  • The token format is incorrect or corrupted
```

### Default Payload

```json
{
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "This is a test push notification"
    },
    "sound": "default",
    "badge": 1
  }
}
```

## Creating an APNs Key

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click **+** to create a new key
3. Enable **Apple Push Notifications service (APNs)**
4. Download the .p8 file (you can only download it once)
5. Note the Key ID shown in the portal

## Technical Details

- Uses ES256 (P-256 elliptic curve) for JWT signing
- Communicates via HTTP/2 with APNs servers
- GUI built with SwiftUI and CryptoKit
- CLI built with [Swift Argument Parser](https://github.com/apple/swift-argument-parser)

## License

MIT License - See [LICENSE](LICENSE) for details.
