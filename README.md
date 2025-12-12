# PushTester

A native macOS application for testing Apple Push Notification Service (APNs). Easily send test push notifications to iOS/iPadOS devices during development.

## Features

- **Multiple Configurations** - Create and manage multiple APNs configurations for different apps
- **Environment Support** - Switch between Development (Sandbox) and Production APNs endpoints
- **Device Token Validation** - Automatic validation of 64-character hex device tokens
- **Auth Key Management** - Load .p8 authentication keys with automatic Key ID extraction from filename
- **JSON Payload Editor** - Full payload editor with formatting and validation
- **Real-time Feedback** - View HTTP status codes and error messages from APNs
- **Persistent Storage** - Configurations saved automatically between sessions

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building)
- Apple Developer Account with APNs key

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/botirjon/PushTester.git
   cd PushTester
   ```

2. Open in Xcode:
   ```bash
   open PushTester.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

### Prerequisites

Before using PushTester, you'll need:

1. **Team ID** - Your Apple Developer Team ID (found in [Apple Developer Account](https://developer.apple.com/account))
2. **Bundle ID** - The bundle identifier of your iOS app
3. **APNs Key (.p8 file)** - Authentication key from Apple Developer Portal
4. **Key ID** - The ID of your APNs key (auto-extracted if filename contains it)
5. **Device Token** - The 64-character hex token from your iOS device

### Getting Started

1. Launch PushTester
2. Click **+** in the sidebar to create a new configuration
3. Fill in your Team ID and Bundle ID
4. Select the appropriate environment (Development/Production)
5. Load your .p8 authentication key file
6. Enter your device token
7. Customize the payload JSON (or use the default)
8. Click **Save Configuration** then **Send Push Notification**

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
- Built with SwiftUI and CryptoKit (no external dependencies)

## License

MIT License - See [LICENSE](LICENSE) for details.
