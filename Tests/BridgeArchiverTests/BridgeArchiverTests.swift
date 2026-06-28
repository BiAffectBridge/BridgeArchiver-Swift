import XCTest
import ZIPFoundation

@testable import BridgeArchiver

final class BridgeArchiverTests: XCTestCase {

    struct ExampleObjectA : Codable, Hashable {
        let foo: String
    }

    func testExampleArchive() async throws {
        let archiver = try BridgeArchiver()

        let exampleAURL = Bundle.module.url(forResource: "example", withExtension: "json")!
        let exampleAFilePath = "example/a.json"
        let exampleACreatedOn = Date().addingTimeInterval(-60*60)
        let exampleAContentType = "application/json"
        let exampleBData = "Hello, World!".data(using: .utf8)!
        let exampleBFilePath = "example/b.txt"
        let exampleBCreatedOn = Date()
        let exampleBContentType = "application/text"
        let exampleCString = "How much wood would a woodchuck chuck if a woodchuck could chuck wood?"
        let exampleCFilePath = "example/c.txt"
        let exampleCCreatedOn = Date()
        let exampleCContentType = "application/text"

        try await archiver.addFile(fileURL: exampleAURL, filepath: exampleAFilePath, createdOn: exampleACreatedOn, contentType: exampleAContentType)
        try await archiver.addFile(data: exampleBData, filepath: exampleBFilePath, createdOn: exampleBCreatedOn, contentType: exampleBContentType)
        try await archiver.addFile(dataString: exampleCString, filepath: exampleCFilePath, createdOn: exampleCCreatedOn, contentType: exampleCContentType)

        let expectedFiles = [
            FileEntry(filename: exampleAFilePath, createdOn: exampleACreatedOn, contentType: exampleAContentType),
            FileEntry(filename: exampleBFilePath, createdOn: exampleBCreatedOn, contentType: exampleBContentType),
            FileEntry(filename: exampleCFilePath, createdOn: exampleCCreatedOn, contentType: exampleCContentType),
        ]
        let files = await archiver.files
        XCTAssertEqual(expectedFiles, files)

        guard let archiveURL = await archiver.archiveURL else {
            XCTFail("archiver.archiveURL should not be nil.")
            return
        }
        print(archiveURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveURL.path))

        guard let pemPath = Bundle.module.path(forResource: "example", ofType: "pem") else {
            XCTFail("Failed to get pem file")
            return
        }

        #if os(iOS)
        let encryptedURL = try await archiver.encryptArchive(using: pemPath)
        let storedEncryptedURL = await archiver.encryptedURL
        XCTAssertEqual(encryptedURL, storedEncryptedURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: encryptedURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path))
        let postArchiveURL = await archiver.archiveURL
        XCTAssertNil(postArchiveURL)
        let isComplete = await archiver.isComplete
        XCTAssertTrue(isComplete)
        #else
        // CMSSupport is iOS-only; verify clean archive removal on other platforms.
        try await archiver.remove()
        #endif
    }
}
