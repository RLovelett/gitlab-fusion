//
//  VMwareFusion.swift
//  VMwareFusion
//
//  Created by Ryan Lovelett on 10/9/20.
//

import Foundation
import os.log
import Path

/// A type that manages interactions with VMware Fusion. Specifically it
/// interacts with `vmrun` to be able to manage VMware Fusion guests.
public struct VMwareFusion {

    public struct Error: Swift.Error, LocalizedError {
        private let exitCode: CInt
        private let stdout: String
        private let stderr: String

        init(exitCode: CInt, stdout: String, stderr: String) {
            self.exitCode = exitCode
            self.stdout = stdout
            self.stderr = stderr
        }

        public var errorDescription: String? {
            return stderr
        }
    }

    /// Fully qualified path to the VMware `vmrun` command.
    let executable: Path

    /// Create a new instance using the VMware Fusion application at the
    /// supplied `Path`.
    ///
    /// - Parameter vmwareFusion: Fully qualified path to the VMware Fusion
    /// application. Typically something like: `/Applications/VMware Fusion.app`
    public init<P: Pathish>(_ vmwareFusion: P) {
        executable = vmwareFusion.join("Contents").join("Public").join("vmrun")
    }

    /// Execute `vmrun` with the supplied arguments.
    ///
    /// This causes the program to run `vmrun` as a subprocess. This function
    /// monitors the output and termination status and reason for errors. If
    /// any errors are encountered they are reflected in the returned `Result`.
    /// Otherwise the `stdout` of the `vmrun` is returned unmodified.
    /// - Parameter arguments: The arguments to provide to `vmrun`.
    /// - Returns: A `Result` of the process run.
    /// - SeeAlso: https://developer.apple.com/documentation/foundation/process/1408983-arguments
    func vmrun(task: Executable = Process(), _ arguments: String...) -> Result<String, VMwareFusion.Error> {
        task.executableURL = executable.url
        task.arguments = arguments

        let stdout = Pipe()
        task.standardOutput = stdout

        let stderr = Pipe()
        task.standardError = stderr

        do {
            try task.run()
        } catch {
            os_log("%{public}@", log: log, type: .error, error as CVarArg)
            // This gets triggered if the executableURL does not exist or is not executable
            let message = "The supplied vmrun, \"\(executable)\", cannot be executed."
            let fusionError = Error(exitCode: 2, stdout: error.localizedDescription, stderr: message)
            return .failure(fusionError)
        }

        // Block until the task is finished.
        task.waitUntilExit()

        let out = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let err = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let exitCode = task.terminationStatus

        switch task.terminationReason {
        case .exit where exitCode == ERR_SUCCESS:
            return .success(out)
        case .uncaughtSignal, .exit:
            return .failure(Error(exitCode: exitCode, stdout: out, stderr: err))
        default:
            fatalError("An unknown case for `Process.TerminationReason` has been encountered. This is possible but unexpected.")
        }
    }
}

// MARK:- Protocols to help vmrun testability

/// A type that allows this process/program to run another program as a
/// subprocess and can monitor that program's execution.
///
/// For the most part this type enables `VMWareFusion` to be testable on a
/// machine without VMware Fusion being installed in it.
protocol Executable: class {
    init()
    var executableURL: URL? { get set }
    var arguments: [String]? { get set }
    var standardOutput: Any? { get set }
    var standardError: Any? { get set }
    var terminationStatus: CInt { get }
    var terminationReason: Process.TerminationReason { get }
    func run() throws
    func waitUntilExit()
}

/// Ensure that Process conforms to the testable subprocess protocol
extension Process: Executable { }
