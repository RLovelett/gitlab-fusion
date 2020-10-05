//
//  Session.swift
//  SecureShell
//
//  Created by Ryan Lovelett on 10/5/20.
//

import Clibssh
import Path

/// A `Session` encapsulates the entire lifetime of the connection with a remote
/// machine. A `Session` is responsible for connecting and authenticating the
/// server and the user.
public final class Session {
    /// A reference to the libssh session
    private let session: ssh_session

    /// Create a new session.
    ///
    /// - Warning: This may currently be unsafe to call multiple times because
    /// of the `ssh_set_log_callback`. Never really tested that.
    /// - Parameters:
    ///   - host: The hostname or ip address to connect to.
    ///   - port: The port to connect to.
    ///   - username: The username for authentication.
    /// - Throws: `SecureShellError` if the session cannot be initialized.
    public init(host: String, port: UInt32 = 22, username: String) throws {
        ssh_set_log_callback(sshLoggingCallback)

        // Allocate a new `ssh_session`
        guard let newSession = ssh_new() else {
            throw SecureShellError("A ssh_session could not be allocated.")
        }
        session = newSession

        do {
            try set(host, for: SSH_OPTIONS_HOST, on: session)
            try set(port, for: SSH_OPTIONS_PORT, on: session)
            try set(SSH_LOG_DEBUG, for: SSH_OPTIONS_LOG_VERBOSITY, on: session)
            try set(username, for: SSH_OPTIONS_USER, on: session)
            try SecureShell.connect(using: session)
        } catch {
            // Must cleanup because `deinit` is not called when failable
            // initializers fail. Go figure.
            // https://www.jessesquires.com/blog/2020/10/08/swift-deinit-is-not-called-for-failable-initializers/
            ssh_free(session)
            throw error
        }
    }

    deinit {
        ssh_disconnect(session)
        ssh_free(session)
    }

    /// Path to a file from which the identity (private key) for public key
    /// authentication is read.
    ///
    /// - Parameter path: Path to identity private key.
    /// - Throws: `SecureShellError` if authentication fails.
    public func authenticate(withIdentity path: Path) throws {
        let key = try PrivateKey(contentsOfFile: path)
        let returnCode = ssh_auth_e(rawValue: ssh_userauth_publickey(session, nil, key.key))

        guard returnCode == SSH_AUTH_SUCCESS else {
            throw SecureShellError(session, description: "Could not authenticate with identity \(path).")
        }
    }

    /// Create a new `Channel` in the current session.
    /// - Throws: If the `Channel` could not be created.
    /// - Returns: A new `Channel` in the current session.
    public func openChannel() throws -> Channel {
        try Channel(session)
    }
}

// MARK:- Idiomatic Swift wrappers around libssh C functions

/// Set options on the SSH session.
///
/// This is a wrapper around `ssh_options_set` to allow more idiomatic Swift
/// interaction with the libssh function.
///
/// - Note: See `ssh_options_set` for documentation on all the available options.
/// - Parameters:
///   - string: The value to set for the specified option.
///   - option: The option type to set. See `ssh_options_set` for documentation
///   of available options.
///   - session: The allocated SSH session to set the option on.
/// - Throws: If the option could not be set.
private func set<Value>(_ value: Value, for option: ssh_options_e, on session: ssh_session) throws {
    let returnValue = withUnsafePointer(to: value) {
        ssh_options_set(session, option, $0)
    }
    guard returnValue == SSH_OK else {
        throw SecureShellError(session, description: "Unable to set \(value) for \(option)")
    }
}

/// Set options on the SSH session.
///
/// This is a wrapper around `ssh_options_set` to allow more idiomatic Swift
/// interaction with the libssh function.
///
/// - Note: See `ssh_options_set` for documentation on all the available options.
/// - Parameters:
///   - string: The value to set for the specified option.
///   - option: The option type to set. See `ssh_options_set` for documentation
///   of available options.
///   - session: The allocated SSH session to set the option on.
/// - Throws: If the option could not be set.
private func set(_ string: String, for option: ssh_options_e, on session: ssh_session) throws {
    let returnValue = string.withCString {
        ssh_options_set(session, option, $0)
    }
    guard returnValue == SSH_OK else {
        throw SecureShellError(session, description: "Unable to set \(string) for \(option)")
    }
}

/// Attempt to connect to the remote SSH server.
///
/// - Parameter session: The SSH session to connect.
/// - Throws: `SecureShellError` if authentication fails.
private func connect(using session: ssh_session) throws {
    let returnValue = ssh_connect(session)
    guard returnValue == SSH_OK else {
        throw SecureShellError(session, description: "Unable to connect to session")
    }
}
