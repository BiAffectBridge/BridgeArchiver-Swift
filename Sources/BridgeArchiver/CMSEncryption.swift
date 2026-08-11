import Foundation
import CMSSupport

enum CMSEncryption {
    static func cmsEncrypt(_ data: Data, identityPath: String) throws -> (data: Data, encrypted: Bool) {
        #if os(iOS)
        (try CMSSupport.cmsEncrypt(data, identityPath: identityPath), true)
        #else
        (data, false)
        #endif
    }
}
