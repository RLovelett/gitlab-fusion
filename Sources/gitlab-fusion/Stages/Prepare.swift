//
//  Prepare.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Environment
import Foundation
import os.log
import Path
import SecureShell
import VMwareFusion

private let log = OSLog(subsystem: subsystem, category: "prepare")

private let discussion = """
The prepare subcommand is responsible for creating the clean and isolated build
environment that the job will use.

To achieve the goal of a clean and isolated build environment this command must
be provided the path to a base VMware Guest. The prepare subcommand will then
create a snapshot on base VMware Guest (if necessary) and then make a linked
clone of the snapshot (if necessary).

The linked clone will also have a snapshot created. This snapshots will
represent the clean base state of any job. Finally, the subcommand will restore
from the snapshot and start the cloned VMware Guest.

Once the guest is started. The subcommand will wait for the guest to boot and
provide its IP address via the VMware Guest Additions. Before signaling that
the guest is working the prepare subcommand will also ensure that the SSH
server is responding and that the supplied credentials work.

https://docs.gitlab.com/runner/executors/custom.html#prepare
"""

/// The prepare stage is responsible for creating the clean and isolated build
/// environment that the job will use.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#prepare
struct Prepare: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "This subcommand should be called by the prepare_exec stage.",
        discussion: discussion
    )

    @OptionGroup()
    var options: StageOptions

    // MARK: - Virtual Machine runtime specific arguments

    @Argument(help: "Fully qualified path to the base VMware Fusion guest.")
    var baseVMPath: Path

    @Flag(help: "Determines if the VMware Fusion guest is started interactively.")
    var isGUI = false

    // MARK: - Secure Shell (SSH) specific arguments

    @OptionGroup()
    var sshOptions: SecureShellOptions

    // MARK: - Validating the command-line input

    func validate() throws {
        guard options.vmImagesPath.exists, options.vmImagesPath.isWritable else {
            os_log("%{public}@ does not exist.", log: log, type: .error, options.vmImagesPath.string)
            throw GitlabRunnerError.systemFailure
        }
    }

    // MARK: - Prepare steps

    func run() throws {
        os_log("Prepare stage is starting.", log: log, type: .info)

        os_log("The base VMware Fusion guest is %{public}@", log: log, type: .debug, baseVMPath.string)
        let base = VirtualMachine(image: baseVMPath, executable: options.vmwareFusion)

        // Check if the snapshot exists (creating it if necessary)
        let rootSnapshotname = subsystem
        if !base.snapshots.contains(rootSnapshotname) {
            FileHandle.standardOutput
                .write(line: "Creating snapshot \"\(rootSnapshotname)\" in base guest \"\(base.name)\"...")
            try base.snapshot(rootSnapshotname)
        }

        // Check if the snapshot exists (creating it if necessary)
        let cloneBaseSnapshotname = "\(ciServerHost)-runner-\(ciRunnerId)-concurrent-\(ciConcurrentProjectId)"
        if !base.snapshots.contains(cloneBaseSnapshotname) {
            FileHandle.standardOutput
                .write(line: "Creating snapshot \"\(cloneBaseSnapshotname)\" in base guest \"\(base.name)\"...")
            // Ensure that the common base snapshot is used
            try base.revert(to: rootSnapshotname)
            try base.snapshot(cloneBaseSnapshotname)
        }

        /// The path of the VMware Fusion guest created by the clone operation
        let clonedGuestName = "\(base.name)-\(ciServerHost)-runner-\(ciRunnerId)-concurrent-\(ciConcurrentProjectId)"
        let clonedGuestPath = options.vmImagesPath
            .join("\(clonedGuestName).vmwarevm")
            .join("\(clonedGuestName).vmx")

        // Check if the VM image exists
        let clone: VirtualMachine
        if !clonedGuestPath.exists {
            FileHandle.standardOutput
                .write(line: "Cloning from snapshot \"\(cloneBaseSnapshotname)\" in base guest \"\(base.name)\" to \"\(clonedGuestName)\"...")
            clone = try base.clone(to: clonedGuestPath, named: clonedGuestName, linkedTo: cloneBaseSnapshotname)
        } else {
            clone = VirtualMachine(image: clonedGuestPath, executable: options.vmwareFusion)
        }

        /// The name of the snapshot to create on linked clone
        let cloneGuestSnapshotName = clonedGuestName

        // Check if the snapshot exists
        if clone.snapshots.contains(cloneGuestSnapshotName) {
            FileHandle.standardOutput
                .write(line: "Restoring guest \"\(clonedGuestName)\" from snapshot \"\(cloneGuestSnapshotName)\"...")
            try clone.revert(to: cloneGuestSnapshotName)
        } else {
            FileHandle.standardOutput
                .write(line: "Creating snapshot \"\(cloneGuestSnapshotName)\" in guest \"\(clonedGuestName)\"...")
            try clone.snapshot(cloneGuestSnapshotName)
        }

        FileHandle.standardOutput.write(line: "Starting guest \"\(clonedGuestName)\"...")
        try clone.start(hasGUI: isGUI)

        FileHandle.standardOutput.write(line: "Waiting for guest \"\(clonedGuestName)\" to become responsive...")
        guard let ip = clone.ip else {
            throw GitlabRunnerError.systemFailure
        }

        // Wait for ssh to become available
        for _ in 1...60 {
            // TODO: Retry if connection times out
            let session = try Session(host: ip, username: sshOptions.sshUsername)
            try session.authenticate(withIdentity: sshOptions.sshIdentityFile)
            let channel = try session.openChannel()
            let exitCode = channel.execute("echo -n 2>&1")

            if exitCode == 0 {
                return
            }

            sleep(60)
        }

        // TODO: Actually handle this case better
        // 'Waited 60 seconds for sshd to start, exiting...'
        throw GitlabRunnerError.systemFailure
    }
}
