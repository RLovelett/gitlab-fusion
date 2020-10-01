//
//  VirtualMachine.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import Foundation
import os.log
import Path

private func validate(ipAddress ipToValidate: String) -> Bool {
    var sin = sockaddr_in()
    var sin6 = sockaddr_in6()

    if ipToValidate.withCString({ inet_pton(AF_INET6, $0, &sin6.sin6_addr) }) == 1 {
        // IPv6
        return true
    } else if ipToValidate.withCString({ inet_pton(AF_INET, $0, &sin.sin_addr) }) == 1 {
        // IPv4
        return true
    }

    return false
}

private func vmrun(_ executable: Path) -> (String...) -> Result<String, GitlabRunnerError> {
    return { (arguments: String...) -> Result<String, GitlabRunnerError> in
        let task = Process()
        task.executableURL = executable.url
        task.arguments = arguments

        let stdout = Pipe()
        task.standardOutput = stdout

        let stderr = Pipe()
        task.standardError = stderr

        do {
            try task.run()
        } catch let error {
            dump(error)
            fatalError("TODO: Figure out what would actually trigger this.")
        }

        // Block until the task is finished.
        task.waitUntilExit()

        switch task.terminationReason {
        case .exit:
            let out = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            return .success(out)
        case .uncaughtSignal:
            let err = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            return .failure(.vmrunError(err))
        default:
            fatalError("An unknown case for `Process.TerminationReason` has been encountered. This is possible but unexpected.")
        }
    }
}

private let log = OSLog(subsystem: subsystem, category: "VirtualMachine")

struct VirtualMachine {
    private let path: Path
    private let executable: (String...) -> Result<String, GitlabRunnerError>

    init(image path: Path, executable: Path) {
        self.path = path
        self.executable = vmrun(executable)
    }

    private init(_ path: Path, _ executable: @escaping (String...) -> Result<String, GitlabRunnerError>) {
        self.path = path
        self.executable = executable
    }

    var name: String {
        path.basename(dropExtension: true)
    }

    var snapshots: [String] {
        os_log("vmrun -T fusion listSnapshots %{public}@", log: log, type: .debug, path.string)
        let result = executable("-T", "fusion", "listSnapshots", path.string)
        switch result {
        case .success(let stdout):
            return Array(stdout.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }.dropFirst())
        default:
            return []
        }
    }

    func snapshot(_ name: String) throws {
        os_log("vmrun -T fusion snapshot %{public}@ %{public}@", log: log, type: .debug, path.string, name)
        let result = executable("-T", "fusion", "snapshot", path.string, name)
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }

    func clone(to destination: Path, named cloneName: String, linkedTo snapshot: String) throws -> VirtualMachine {
        os_log("vmrun -T fusion clone %{public}@ %{public}@ linked -snapshot=%{public}@ -cloneName=%{public}@", log: log, type: .debug, path.string, destination.string, snapshot, cloneName)
        let result = executable("-T", "fusion", "clone", path.string, destination.string, "linked", "-snapshot=\(snapshot)", "-cloneName=\(cloneName)")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
        return VirtualMachine(destination, executable)
    }

    func revert(to snapshot: String) throws {
        os_log("vmrun -T fusion revertToSnapshot %{public}@ %{public}@", log: log, type: .debug, path.string, snapshot)
        let result = executable("-T", "fusion", "revertToSnapshot", path.string, snapshot)
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }

    func start(hasGUI: Bool) throws {
        os_log("vmrun -T fusion start %{public}@ %{public}@", log: log, type: .debug, path.string, hasGUI ? "gui" : "nogui")
        let result = executable("-T", "fusion", "start", path.string, hasGUI ? "gui" : "nogui")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }

    func stop() throws {
        os_log("vmrun -T fusion stop %{public}@ hard", log: log, type: .debug, path.string)
        let result = executable("-T", "fusion", "stop", path.string, "hard")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }

    var ip: String? {
        os_log("vmrun -T fusion getGuestIPAddress %{public}@ -wait", log: log, type: .debug, path.string)
        let result = executable("-T", "fusion", "getGuestIPAddress", path.string, "-wait")
        switch result {
        case .success(let ip) where validate(ipAddress: ip.trimmingCharacters(in: .whitespacesAndNewlines)):
            return ip.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return nil
        }
    }
}
