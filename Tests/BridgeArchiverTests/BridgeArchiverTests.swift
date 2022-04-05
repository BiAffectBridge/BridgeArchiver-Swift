import XCTest
@testable import BridgeArchiver
import ZIPFoundation

final class BridgeArchiverTests: XCTestCase {
    
    struct ExampleObjectA : Codable, Hashable {
        let foo: String
    }
    
    func testExampleArchive() {
        guard let archiver = BridgeArchiver() else {
            XCTFail("Failed to create archiver.")
            return
        }
        
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
        
        do {
            try archiver.addFile(fileURL: exampleAURL, filepath: exampleAFilePath, createdOn: exampleACreatedOn, contentType: exampleAContentType)
            try archiver.addFile(data: exampleBData, filepath: exampleBFilePath, createdOn: exampleBCreatedOn, contentType: exampleBContentType)
            try archiver.addFile(dataString: exampleCString, filepath: exampleCFilePath, createdOn: exampleCCreatedOn, contentType: exampleCContentType)
            
            let expectedFiles = [
                FileEntry(filename: exampleAFilePath, createdOn: exampleACreatedOn, contentType: exampleAContentType),
                FileEntry(filename: exampleBFilePath, createdOn: exampleBCreatedOn, contentType: exampleBContentType),
                FileEntry(filename: exampleCFilePath, createdOn: exampleCCreatedOn, contentType: exampleCContentType),
            ]
            XCTAssertEqual(expectedFiles, archiver.files)
            
            // Note: Can't test the archive without using the same code that archived it.
            // Manually check the archive when/if the code changes.
            guard let archiveURL = archiver.archiveURL else {
                XCTFail("archiver.archiveURL should not be nil.")
                return
            }
            print(archiveURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: archiveURL.path))
            
            guard let pemPath = Bundle.module.path(forResource: "example", ofType: "pem") else {
                XCTFail("Failed to get pem file")
                return
            }
            let encryptedURL = try archiver.encryptArchive(using: pemPath)
            XCTAssertEqual(encryptedURL, archiver.encryptedURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: encryptedURL.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path))
            XCTAssertNil(archiver.archiveURL)
            XCTAssertNil(archiver.archive)
            
        } catch let err {
            XCTFail("Failed to archive example. \(err)")
        }
    }
}

