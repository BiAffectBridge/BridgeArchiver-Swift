# BridgeArchiver-Swift

Creates encrypted zip archives for secure data upload to the [Grip Research](https://www.grip-research.org/) platform. Used by BiAffect and other Bridge study apps to package on-device collected data before uploading it to the server.

## What it does

1. Creates a zip archive from files, raw `Data`, or strings.
2. CMS-encrypts the archive using an X.509 public key (`.pem` file) provided by the Bridge study. The server decrypts uploads using the corresponding private key.
3. Deletes the unencrypted archive after encryption.

CMS encryption ([RFC 5652](https://tools.ietf.org/html/rfc5652)) is implemented via OpenSSL and is supported on iOS only. On macOS/watchOS/tvOS, `encryptArchive(using:)` throws `BridgeArchiverError.encryptionNotSupported`.

## Usage

```swift
let archiver = try BridgeArchiver()
try await archiver.addFile(data: jsonData, filepath: "data/sensors.json", contentType: "application/json")
try await archiver.addFile(fileURL: videoURL, filepath: "data/video.mp4")
let encryptedURL = try await archiver.encryptArchive(using: "/path/to/study-public-key.pem")
// upload encryptedURL to Bridge
```

## Platforms

- iOS 14+
- macOS 11+ (zip only; encryption not supported)
- watchOS 4+
- tvOS 14+

## Dependencies

- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) — zip archive creation
- OpenSSL (pre-built xcframework at `openssl/build/openssl.xcframework`) — CMS encryption

## Updating OpenSSL

The pre-built OpenSSL xcframework is committed at `openssl/build/openssl.xcframework`. To upgrade to a new OpenSSL version:

1. Edit the `VERSION` variable at the top of `openssl/rebuild-openssl.sh`.
2. Run the script (requires Xcode with iOS SDK installed):
   ```bash
   ./openssl/rebuild-openssl.sh
   ```
   The script downloads the OpenSSL source tarball automatically, compiles it for iOS device (arm64) and simulator (arm64/x86_64), and replaces `openssl/build/openssl.xcframework`.
3. Build and test to confirm the new xcframework works:
   ```bash
   swift build
   swift test
   ```
4. Commit the updated `openssl/build/openssl.xcframework`.

The current OpenSSL version is **3.5.7** (LTS, supported through April 2030).
