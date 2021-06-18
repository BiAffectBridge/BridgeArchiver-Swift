// BridgeArchiver.swift
//
//  Copyright © 2021 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation
import ZIPFoundation
import CMSSupport

public class BridgeArchiver {

    var archive: Archive?
    
    /// The URL to the unencrypted archive.
    public private(set) var archiveURL: URL?
    
    /// The URL to the encrypted archive.
    public private(set) var encryptedURL: URL?
    
    /// A list of the files included in the archive.
    public private(set) var files: [FileEntry] = []
    
    /// Initialize the archiver.
    /// - parameters:
    ///     - archiveURL: The URL for the zip archive to create. If null, then a UUID will be used to create a unique file in the temporary directory.
    public init?(archiveURL: URL? = nil) {
        let url = archiveURL ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString.suffix(8)).zip")
        guard let archive = Archive(url: url, accessMode: .create) else  {
            return nil
        }
        self.archive = archive
        self.archiveURL = url
    }
    
    public enum BridgeArchiverError : Error {
        case archiveClosed
        case invalidUTF8String(String)
        case filepathExists(String)
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
                             uncompressedSize: UInt32(data.count),
                             modificationDate: createdOn,
                             provider: { (position, size) -> Data in
            data.subdata(in: position..<position+size)
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
        let encryptedData = try CMSSupport.cmsEncrypt(data, identityPath: pemPath)
        try encryptedData.write(to: encryptedURL)
        try FileManager.default.removeItem(at: archiveURL)
        self.encryptedURL = encryptedURL
        self.archive = nil
        self.archiveURL = nil
        return encryptedURL
    }
}

/// Simple manifest entry that uses the serialization format of the Bridge Exporter v1 "info.json" file.
public struct FileEntry : Codable, Hashable {
    public let filename: String
    public let createdOn: Date
    public let contentType: String?
}

