//
//  SecureShellError.swift
//  SecureShell
//
//  Created by Ryan Lovelett on 10/5/20.
//

import Clibssh
import Foundation

/// Capture error text from libssh and provide them in a idiomatic Swift
/// structure.
struct SecureShellError: LocalizedError {
    /// The error text from the last error.
    let libsshErrorText: String

    /// A description provided in addition to the libssh error text.
    let description: String

    /// Initialize a new error without libssh error text.
    ///
    /// - Parameter description: An error with no libssh text.
    init(_ description: String) {
        self.description = description
        self.libsshErrorText = ""
    }

    /// Initialize a new error from a session and proving context description.
    ///
    /// - Parameter session: Attempt to extract error text from this session.
    /// - Parameter description: A description provided in addition to the libssh error text.
    init(_ session: ssh_session, description: String) {
        self.init(UnsafeMutableRawPointer(session), description)
    }

    /// Initialize a new error from a session and proving context description.
    ///
    /// - Parameter session: Attempt to extract error text from this session.
    /// - Parameter description: A description provided in addition to the libssh error text.
    private init(_ session: UnsafeMutableRawPointer, _ description: String) {
        self.description = description
        if let error = ssh_get_error(session) {
            libsshErrorText = String(cString: error)
        } else {
            libsshErrorText = "Was not able to infer the error from \(session)."
        }
    }
}
