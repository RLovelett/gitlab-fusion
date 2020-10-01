//
//  main.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Environment
import Foundation

let subsystem = "me.lovelett.gitlab-fusion"

private let discussion = """
The gitlab-fusion executor allows for the creation of a clean build environment
for every job executed by CI. Any guest that VMware Fusion supports should be
supported by this executor.

All guests should have the VMware Fusion guest additions installed and expose
an SSH server.

For information about a custom executors lifecycle and how to configure GitLab
to use this executor see: https://docs.gitlab.com/runner/executors/custom.html.
"""

/// The unique ID of runner being used.
///
/// This is pulled from the environment variable `CUSTOM_ENV_CI_RUNNER_ID`. If
/// that variable is unset then the value defaults to `0`.
///
/// The `CUSTOM_ENV_CI_RUNNER_ID` is a variation on the typical GitLab
/// predefined environment variable `CI_RUNNER_ID`. The environment variables
/// provided by GitLab are prefixed with `CUSTOM_ENV_` to prevent conflicts with
/// system environment variables.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#stages
/// - SeeAlso: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
let ciRunnerId = Environment.CUSTOM_ENV_CI_RUNNER_ID ?? 0

/// Unique ID of build execution within a single executor and project.
///
/// This is pulled from the environment variable
/// `CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID`. If that variable is unset then the
/// value defaults to `0`.
///
/// The `CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID` is a variation on the typical
/// GitLab predefined environment variable `CI_CONCURRENT_PROJECT_ID`. The
/// environment variables provided by GitLab are prefixed with `CUSTOM_ENV_` to
/// prevent conflicts with system environment variables.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#stages
/// - SeeAlso: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
let ciConcurrentProjectId = Environment.CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID ?? 0

/// The namespace with project name.
///
/// This is pulled from the environment variable
/// `CUSTOM_ENV_CI_PROJECT_PATH`. If that variable is unset then the value
/// defaults to an empty string (e.g., `""`).
///
/// The `CUSTOM_ENV_CI_PROJECT_PATH` is a variation on the typical  GitLab
/// predefined environment variable `CI_PROJECT_PATH`. The environment variables
/// provided by GitLab are prefixed with `CUSTOM_ENV_` to prevent conflicts with
/// system environment variables.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#stages
/// - SeeAlso: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
let ciProjectPath = Environment.CUSTOM_ENV_CI_PROJECT_PATH ?? ""

/// Collects the command-line options that were passed to `gitlab-fusion` and
/// dispatches them to the appropriate subcommands (executor stages).
struct GitlabFusion: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A custom GitLab Runner executor to enable running jobs inside VMware Fusion.",
        discussion: discussion,
        subcommands: [
            Config.self,
            Prepare.self,
            Run.self,
            Cleanup.self
        ],
        defaultSubcommand: Run.self
    )
}

GitlabFusion.main()
