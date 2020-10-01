//
//  Config.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Environment
import Foundation
import os.log
import Path

private let log = OSLog(subsystem: subsystem, category: "config")

private let discussion = """
This subcommand generates a properly formatted JSON string and serializes it to
STDOUT. The keys and values of the JSON string are further documented in the
custom executor documentation page.

https://docs.gitlab.com/runner/executors/custom.html#config
"""

/// The configuration stage is used to configure settings used during execution
/// of the VMware Fusion guest.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#config
struct Config: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "This subcommand should be called by the config_exec stage.",
        discussion: discussion
    )

    @OptionGroup()
    var options: StageOptions

    @Option(help: "The base directory where the working directory of the job will be created in the VMware Fusion guest.")
    var buildsDir = Path.root.join("Users").join("buildbot").join("builds")
        .join("runner-\(ciRunnerId)")
        .join("concurrent-\(ciConcurrentProjectId)")
        .join(ciProjectPath)

    @Option(help: "The base directory where local cache will be stored in the VMware Fusion guest.")
    var cacheDir = Path.root.join("Users").join("buildbot").join("cache")
        .join("runner-\(ciRunnerId)")
        .join("concurrent-\(ciConcurrentProjectId)")
        .join(ciProjectPath)

    @Option(help: "Defines whether the environment is shared between concurrent job or not.")
    var buildsDirIsShared = false

    @Option(help: "The hostname to associate with job’s \"metadata\".")
    var hostname = ProcessInfo.processInfo.hostName

    func run() throws {
        os_log("Configuration stage is starting.", log: log, type: .info)

        for (index, argument) in ProcessInfo.processInfo.arguments.enumerated() {
            os_log("Argument %{public}d - %{public}@", log: log, type: .debug, index, argument)
        }

        for (variable, value) in ProcessInfo.processInfo.environment {
            os_log("%{public}@=%{public}@", log: log, type: .debug, variable, value)
        }

        let driver = ConfigurationOutput.Driver(options.vmwareFusionInfo)
        let config = ConfigurationOutput(
            buildsDir: buildsDir.string,
            cacheDir: cacheDir.string,
            isBuildsDirShared: buildsDirIsShared,
            hostname: hostname,
            driver: driver
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(config)

        if let string = String(data: json, encoding: .utf8) {
            os_log("%{public}@", log: log, type: .info, string)
        } else {
            os_log("The encoded data was not a valid UTF-8 string.", log: log, type: .error)
        }

        FileHandle.standardOutput.write(json)
    }
}
