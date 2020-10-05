//
//  PrivateKey.swift
//  SecureShell
//
//  Created by Ryan Lovelett on 10/5/20.
//

import Clibssh
import Path

/// Private key used with the SecureShell public-key infrastructure (PKI).
final class PrivateKey: CustomStringConvertible {
    let key: ssh_key

    /// Create an instance from a key at a path.
    /// - Parameter path: Path to the private key.
    /// - Throws: `SecureShellError` if the private key cannot be loaded.
    init(contentsOfFile path: Path) throws {
        var file: ssh_key?
        let returnCode = path.string.withCString { body in
            ssh_pki_import_privkey_file(body, nil, nil, nil, &file)
        }
        guard returnCode == SSH_OK, let privateKey = file else {
            ssh_key_free(file)
            throw SecureShellError("Could not import private key at \(path)")
        }
        self.key = privateKey
    }

    deinit {
        ssh_key_free(key)
    }

    /// The type of the key (e.g., `ssh-rsa` or `ssh-ed25519`).
    var description: String {
        let type = ssh_key_type(key)
        let name = ssh_key_type_to_char(type)
        return name.map { String(cString: $0) } ?? "unknown"
    }
}
