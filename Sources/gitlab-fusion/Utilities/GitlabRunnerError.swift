//
//  GitlabRunnerError.swift
//  
//
//  Created by Ryan Lovelett on 9/27/20.
//

import Environment
import Foundation

private let defaultBuildFailureExitCode: Int32 = 1
private let defaultSystemFailureExitCode: Int32 = 2

enum GitlabRunnerError: Error {
    /// GitLab Runner provides `BUILD_FAILURE_EXIT_CODE` environment variable
    /// which should be used by the executable as an exit code to inform GitLab
    /// Runner that there is a failure on the users job. If the executable exits
    /// with the code from `BUILD_FAILURE_EXIT_CODE`, the build is marked as a
    /// failure appropriately in GitLab CI.
    ///
    /// If the script that the user defines inside of `.gitlab-ci.yml` file
    /// exits with a non-zero code, run_exec should exit with
    /// `BUILD_FAILURE_EXIT_CODE` value.
    ///
    /// - Note: From observation `BUILD_FAILURE_EXIT_CODE` is typically equal to
    /// `1`. Therefore, that will be the default error code for this.
    ///
    /// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#build-failure
    case buildFailure

    /// System failure can be communicated to GitLab Runner by exiting the
    /// process with the error code specified in the `SYSTEM_FAILURE_EXIT_CODE`.
    /// If this error code is returned, on certain stages GitLab Runner will
    /// retry the stage, if none of the retries are successful the job will be
    /// marked as failed.
    ///
    /// - Note: From observation `SYSTEM_FAILURE_EXIT_CODE` is typically equal
    /// to `2`. Therefore, that will be the default error code for this.
    ///
    /// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#system-failure
    case systemFailure

    case vmrunError(String)

    var exitCode: Int32 {
        switch self {
        case .buildFailure:
            return Environment.BUILD_FAILURE_EXIT_CODE ?? defaultBuildFailureExitCode
        case .systemFailure, .vmrunError(_):
            return Environment.SYSTEM_FAILURE_EXIT_CODE ?? defaultSystemFailureExitCode
        }
    }
}
