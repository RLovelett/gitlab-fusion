//
//  Run.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Environment
import Foundation
import os.log
import Path
import Shout

private let log = OSLog(subsystem: subsystem, category: "run")

private let discussion = """
The run subcommand is responsible for executing the scripts provided by GitLab
Runner in the prepared VMware Fusion guest.

Provided that the prepare stage has already been performed this command is safe
to call multiple times.

https://docs.gitlab.com/runner/executors/custom.html#run
"""

/// The run subcommand is responsible for executing the scripts provided by
/// GitLab Runner in the prepared VMware Fusion guest.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#run
struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "This subcommand should be called by the run_exec stage.",
        discussion: discussion
    )

    @OptionGroup()
    var options: StageOptions

    // MARK: - Secure Shell (SSH) specific arguments

    @Option(help: "User used to authenticate as over SSH to the VMware Fusion guest.")
    var sshUsername = "buildbot"

    @Option(help: "Password used to authenticate as over SSH to the VMware Fusion guest.")
    var sshPassword = "Time2Build"

    // MARK: - Virtual Machine runtime specific arguments

    @Argument(help: "Fully qualified path to the base VMware Fusion guest.")
    var baseVMPath: Path

    // MARK: - GitLab Arguments

    @Argument(help: "The path to the script that GitLab Runner creates for the executor to run.")
    var scriptFile: Path

    @Argument(help: "The name of the sub-stage provided to the executor by the GitLab Runner.")
    var subStage: String

    // MARK: - Run steps

    func run() throws {
        os_log("Run stage %{public}@ is starting.", log: log, type: .info, subStage)

        os_log("The base VMware Fusion guest is %{public}@", log: log, type: .info, baseVMPath.string)
        let base = VirtualMachine(image: baseVMPath, executable: options.vmrunPath)

        /// The name of VMware Fusion guest created by the clone operation
        let clonedGuestName = "\(base.name)-runner-\(ciRunnerId)-concurrent-\(ciConcurrentProjectId)"

        /// The path of the VMware Fusion guest created by the clone operation
        let clonedGuestPath = options.vmImagesPath
            .join("\(clonedGuestName).vmwarevm")
            .join("\(clonedGuestName).vmx")

        os_log("The cloned VMware Fusion guest is %{public}@", log: log, type: .info, clonedGuestPath.string)
        let clone = VirtualMachine(image: clonedGuestPath, executable: options.vmrunPath)

        guard let ip = clone.ip else {
            throw GitlabRunnerError.systemFailure
        }

        let script = try String(contentsOf: scriptFile)
        os_log("Running script:\n%{public}@", log: log, type: .info, script)

        let ssh = try SSH(host: ip)
        try ssh.authenticate(username: sshUsername, password: sshPassword)
        let exitCode = try ssh.execute(script) { output in
            print(output)
        }

        if exitCode == 0 {
            os_log("Run stage %{public}@ returned %{public}d.", log: log, type: .info, subStage, exitCode)
        } else {
            os_log("Run stage %{public}@ returned %{public}d.", log: log, type: .error, subStage, exitCode)
            throw GitlabRunnerError.buildFailure
        }
    }
}
