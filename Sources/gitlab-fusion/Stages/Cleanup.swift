//
//  Cleanup.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Environment
import Foundation
import os.log
import Path
import VMwareFusion

private let log = OSLog(subsystem: subsystem, category: "cleanup")

private let discussion = """
The cleanup subcommand is responsible for stopping the cloned VMware Fusion
guest.

https://docs.gitlab.com/runner/executors/custom.html#cleanup
"""

/// The cleanup subcommand is responsible for stopping the cloned VMware Fusion
/// guest.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#run
struct Cleanup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "This subcommand should be called by the cleanup_exec stage.",
        discussion: discussion
    )

    @OptionGroup()
    var options: StageOptions

    // MARK: - Virtual Machine runtime specific arguments

    @Argument(help: "Fully qualified path to the base VMware Fusion guest.")
    var baseVMPath: Path

    // MARK: - Cleanup Steps

    func run() throws {
        os_log("Cleanup stage is starting.", log: log, type: .info)

        os_log("The base VMware Fusion guest is %{public}@", log: log, type: .info, baseVMPath.string)
        let base = VirtualMachine(image: baseVMPath, executable: options.vmwareFusion)

        /// The name of VMware Fusion guest created by the clone operation
        let clonedGuestName = "\(base.name)-\(ciServerHost)-runner-\(ciRunnerId)-concurrent-\(ciConcurrentProjectId)"

        /// The path of the VMware Fusion guest created by the clone operation
        let clonedGuestPath = options.vmImagesPath
            .join("\(clonedGuestName).vmwarevm")
            .join("\(clonedGuestName).vmx")

        os_log("The cloned VMware Fusion guest is %{public}@", log: log, type: .info, clonedGuestPath.string)
        let clone = VirtualMachine(image: clonedGuestPath, executable: options.vmwareFusion)

        do {
            try clone.stop()
        } catch {
            os_log("Could not stop the VMware Fusion guest.", log: log, type: .error)
            throw ExitCode(GitlabRunnerError.systemFailure)
        }
    }
}
