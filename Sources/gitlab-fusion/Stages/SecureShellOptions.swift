//
//  SecureShellOptions.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 10/10/20.
//

import ArgumentParser
import Environment
import Path
import VMwareFusion

/// Common arguments used by the individual stage subcommands.
struct SecureShellOptions: ParsableArguments {
    @Option(help: "User used to authenticate as over SSH to the VMware Fusion guest.")
    var sshUsername = "buildbot"

    @Option(help: "Path to a file from which the identity (private key) for public key authentication is read.")
    var sshIdentityFile = Path.applicationSupport / subsystem / "id_ed25519"
}
