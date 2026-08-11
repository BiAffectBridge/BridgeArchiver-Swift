import Foundation
import ZIPFoundation

public actor BridgeArchiver {
    private var archive: Archive?
    
    /// The URL to the unencrypted archive.
    public private(set) var archiveURL: URL?
    
    /// The URL to the encrypted archive.
    public private(set) var encryptedURL: URL?
    
    /// A list of the files included in the archive.
    public private(set) var files: [FileEntry] = []
    
    /// Has the archive been completed and stored?
    public var isComplete: Bool { archive == nil }
    
    /// Initialize the archiver.
    /// - parameters:
    ///     - archiveURL: The URL for the zip archive to create. If null, then a UUID will be used to create a unique file in the temporary directory.
    public init(archiveURL: URL? = nil) throws {
        let url = archiveURL ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString.suffix(8)).zip")
        self.archive = try Archive(url: url, accessMode: .create, pathEncoding: nil)
        self.archiveURL = url
    }
    
    public enum BridgeArchiverError : Error {
        case archiveClosed
        case invalidUTF8String(String)
        case filepathExists(String)
        case encryptionNotSupported
    }
    
    // -- MARK: Add files
    
    /// Add the file at the given URL to the archive.
    /// - parameters:
    ///     - fileURL: The URL for the file to add to the zip archive.
    ///     - filepath: The file path within the archive. If null, this will default to the last path component of the `fileURL`.
    ///     - createdOn: The file "createdOn" date.
    ///     - contentType: The content type for the file.
    public func addFile(fileURL: URL, filepath: String? = nil, createdOn: Date = Date(), contentType: String? = nil) throws {
        guard let archive = self.archive else {
            throw BridgeArchiverError.archiveClosed
        }
        let path = filepath ?? fileURL.lastPathComponent
        guard !files.contains(where: { path == $0.filename }) else {
            throw BridgeArchiverError.filepathExists(path)
        }
        try archive.addEntry(with: path, fileURL: fileURL)
        files.append(FileEntry(filename: path,
                               createdOn: createdOn,
                               contentType: contentType))
    }
    
    /// Add the data to the archive.
    /// - parameters:
    ///     - data: The data for the file within the zip archive.
    ///     - filepath: The file path within the archive.
    ///     - createdOn: The file "createdOn" date.
    ///     - contentType: The content type for the file.
    public func addFile(data: Data, filepath: String, createdOn: Date = Date(), contentType: String? = nil) throws {
        guard let archive = self.archive else {
            throw BridgeArchiverError.archiveClosed
        }
        guard !files.contains(where: { filepath == $0.filename }) else {
            throw BridgeArchiverError.filepathExists(filepath)
        }
        try archive.addEntry(with: filepath,
                             type: .file,
                             uncompressedSize: Int64(data.count),
                             modificationDate: createdOn,
                             provider: { (position, size) -> Data in
            data.subdata(in: Int(position)..<Int(position)+size)
        })
        files.append(FileEntry(filename: filepath,
                               createdOn: createdOn,
                               contentType: contentType))
    }
    
    /// Add the string to the archive as a UTF8-encoded string file.
    /// - parameters:
    ///     - dataString: The data for the file within the zip archive.
    ///     - filepath: The file path within the archive.
    ///     - createdOn: The file "createdOn" date.
    ///     - contentType: The content type for the file.
    public func addFile(dataString: String, filepath: String, createdOn: Date = Date(), contentType: String? = "application/json") throws {
        guard let data = dataString.data(using: .utf8) else {
            throw BridgeArchiverError.invalidUTF8String(dataString)
        }
        try self.addFile(data: data, filepath: filepath, createdOn: createdOn, contentType: contentType)
    }
    
    // -- MARK: Cleanup
    
    public func remove() throws {
        guard let _ = self.archive, let archiveURL = self.archiveURL else {
            throw BridgeArchiverError.archiveClosed
        }
        try FileManager.default.removeItem(at: archiveURL)
    }
    
    // -- MARK: Encrypting
    
    /// Encrypt the archive using the given pem file.
    /// - note: This will also delete the unencrypted zip file as a part of cleanup.
    /// - parameters:
    ///     - pemPath: Path to the .pem file to use with CMS encryption.
    ///     - url: Optional URL for the encrypted file. If null, then the  `archiveURL` will be appended with ".encrypted".
    @discardableResult
    public func encryptArchive(using pemPath: String, to url: URL? = nil) throws -> URL {
        guard let _ = self.archive, let archiveURL = self.archiveURL else {
            throw BridgeArchiverError.archiveClosed
        }
        let encryptedURL = url ?? archiveURL.appendingPathExtension("encrypted")
        let data = try Data(contentsOf: archiveURL)
        let (encryptedData, encrypted) = try CMSEncryption.cmsEncrypt(data, identityPath: pemPath)
        if !encrypted {
            throw BridgeArchiverError.encryptionNotSupported
        }
        try encryptedData.write(to: encryptedURL)
        try FileManager.default.removeItem(at: archiveURL)
        self.encryptedURL = encryptedURL
        self.archive = nil
        self.archiveURL = nil
        return encryptedURL
    }
}

/// Simple manifest entry that uses the serialization format of the Bridge Exporter v1 "info.json" file.
public struct FileEntry : Codable, Hashable, Sendable {
    public let filename: String
    public let createdOn: Date
    public let contentType: String?

    public init(filename: String, createdOn: Date, contentType: String?) {
        self.filename = filename
        self.createdOn = createdOn
        self.contentType = contentType
    }
}

