//
//  VirtualMachine.swift
//  VMwareFusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import Foundation
import os.log
import Path

/// Encapsulates the interactions with a given VMware Fusion guest.
public struct VirtualMachine {
    private let path: Path
    private let fusion: VMwareFusion

    /// Create a new guest.
    ///
    /// - Parameters:
    ///   - path: Fully qualified path to a VMware Fusion guest.
    ///   - executable: Fully qualified path to VMware Fusion application.
    public init(image path: Path, executable: VMwareFusion) {
        self.path = path
        self.fusion = executable
    }

    /// Create a new guest.
    ///
    /// - Parameters:
    ///   - path: Fully qualified path to a VMware Fusion guest.
    ///   - fusion: An already create VMware Fusion application.
    private init(_ path: Path, _ fusion: VMwareFusion) {
        self.path = path
        self.fusion = fusion
    }

    /// The filename, without extension, of the provided VMware Fusion guest.
    public var name: String {
        path.basename(dropExtension: true)
    }

    /// Lists all snapshots in a virtual machine.
    public var snapshots: [String] {
        os_log("vmrun -T fusion listSnapshots %{public}@", log: log, type: .debug, path.string)
        let result = fusion.vmrun("-T", "fusion", "listSnapshots", path.string)
        switch result {
        case .success(let stdout):
            return Array(stdout.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }.dropFirst())
        default:
            return []
        }
    }

    /// Creates a snapshot of a virtual machine. Because Fusion supports
    /// multiple snapshots, you must provide the snapshot name.
    ///
    /// - Parameter name: Snapshot name
    /// - Throws: If the `vmrun` command fails.
    public func snapshot(_ name: String) throws {
        os_log("vmrun -T fusion snapshot %{public}@ %{public}@", log: log, type: .debug, path.string, name)
        let result = fusion.vmrun("-T", "fusion", "snapshot", path.string, name)
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            throw error
        }
    }

    /// Creates a copy of the virtual machine.
    ///
    /// - Parameters:
    ///   - destination: Fully qualified path to the new Fusion virtual machine.
    ///   - cloneName: The name of the new cloned virtual machine.
    ///   - snapshot: The snapshot to base the clone from.
    /// - Throws: If the `vmrun` command fails.
    /// - Returns: A new `VirtualMachine` initialized the new clone machine.
    public func clone(to destination: Path, named cloneName: String, linkedTo snapshot: String) throws -> VirtualMachine {
        os_log("vmrun -T fusion clone %{public}@ %{public}@ linked -snapshot=%{public}@ -cloneName=%{public}@", log: log, type: .debug, path.string, destination.string, snapshot, cloneName)
        let result = fusion.vmrun("-T", "fusion", "clone", path.string, destination.string, "linked", "-snapshot=\(snapshot)", "-cloneName=\(cloneName)")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            throw error
        }
        return VirtualMachine(destination, fusion)
    }

    /// Sets the virtual machine to its state at snapshot time.
    ///
    /// - Parameter snapshot: The name of the snapshot to revert to.
    /// - Throws: If the `vmrun` command fails.
    public func revert(to snapshot: String) throws {
        os_log("vmrun -T fusion revertToSnapshot %{public}@ %{public}@", log: log, type: .debug, path.string, snapshot)
        let result = fusion.vmrun("-T", "fusion", "revertToSnapshot", path.string, snapshot)
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            throw error
        }
    }

    /// Starts a virtual machine.
    ///
    /// If `true` is provided to the `hasGUI` option the machine starts
    /// interactively, which is displays the Fusion interface. If `false` is
    /// provided th e Fusion interface is suppressed.
    ///
    /// - Parameter hasGUI: Whether the virtual machine starts interactively or
    /// not.
    /// - Throws: If the `vmrun` command fails.
    public func start(hasGUI: Bool) throws {
        os_log("vmrun -T fusion start %{public}@ %{public}@", log: log, type: .debug, path.string, hasGUI ? "gui" : "nogui")
        let result = fusion.vmrun("-T", "fusion", "start", path.string, hasGUI ? "gui" : "nogui")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            throw error
        }
    }

    /// Stops a virtual machine.
    ///
    /// - Throws: If the `vmrun` command fails.
    public func stop() throws {
        os_log("vmrun -T fusion stop %{public}@ hard", log: log, type: .debug, path.string)
        let result = fusion.vmrun("-T", "fusion", "stop", path.string, "hard")
        switch result {
        case .success(let stdout):
            os_log("stdout: %{public}@", log: log, type: .debug, stdout)
        case .failure(let error):
            throw error
        }
    }

    /// Retrieves the IP address of the guest.
    ///
    /// The IP address is not available until the virtual machine powers on and
    /// requires the guest additions to be running.
    public var ip: String? {
        os_log("vmrun -T fusion getGuestIPAddress %{public}@ -wait", log: log, type: .debug, path.string)
        let result = fusion.vmrun("-T", "fusion", "getGuestIPAddress", path.string, "-wait")
        switch result {
        case .success(let ip) where validate(ipAddress: ip.trimmingCharacters(in: .whitespacesAndNewlines)):
            return ip.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return nil
        }
    }
}
