//
//  Channel.swift
//  SecureShell
//
//  Created by Ryan Lovelett on 10/5/20.
//

import Clibssh
import Foundation

/// A `Channel` represents a sub-process of a single `Session`.
///
/// More precisely, a `Channel` wraps `libssh`'s `ssh_channel` struct and
/// manages the lifecycle of that struct. Additionally it provides Swift native
/// wrapper helpers for a subset of the available `libssh` C APIs.
public final class Channel {
    /// Reference to the `libssh` channel structure.
    private let channel: ssh_channel

    /// Pointer to the first element in channel read buffer.
    private let channelReadBufferPointer: UnsafeMutableRawPointer

    /// A data buffer to store read bytes from the channel.
    private let channelReadBuffer: UnsafeMutablePointer<CChar>

    /// The read buffer is 4x the memory page size. 4 is an arbitrary choice.
    private let bufferSize = 4 * sysconf(_SC_PAGESIZE)

    /// This enum is meant to give a human readable name to the magic numbers
    /// of `0` and `1` that can be given to `libssh` read methods:
    /// `ssh_channel_read`, `ssh_channel_read_timeout`,
    /// `ssh_channel_read_nonblocking`.
    private enum Stream: CInt {
        case stdout = 0
        case stderr = 1
    }

    /// Allocate and open a channel suited for a shell, not TCP forwarding, for
    /// a given `Session`.
    ///
    /// - Parameter session: The session to open the channel in.
    /// - Throws: If the channel cannot be allocated or opened.
    init(_ session: ssh_session) throws {
        // Allocate a `ssh_channel`
        guard let channel = ssh_channel_new(session) else {
            throw SecureShellError(session, description: "A ssh_channel could not be allocated.")
        }

        // Open a session channel to run a shell command
        let returnCode = ssh_channel_open_session(channel)
        guard returnCode == SSH_OK else {
            // Must cleanup because `deinit` is not called when failable
            // initializers fail. Go figure.
            // https://www.jessesquires.com/blog/2020/10/08/swift-deinit-is-not-called-for-failable-initializers/
            ssh_channel_free(channel)
            throw SecureShellError(session, description: "The channel could not open a session.")
        }
        self.channel = channel

        channelReadBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(bufferSize))
        channelReadBufferPointer = UnsafeMutableRawPointer(channelReadBuffer)
    }

    deinit {
        channelReadBuffer.deallocate()
        ssh_channel_close(channel)
        ssh_channel_free(channel)
    }

    /// Check if remote has sent an EOF.
    /// - Returns: `false` if there is no EOF. `true` otherwise.
    private var isEOF: Bool {
        let eof = ssh_channel_is_eof(channel)
        return (eof == 0) ? false : true
    }

    /// Check if the channel is open or not.
    /// - Returns: `false` if the channel is closed. `true` otherwise.
    private var isOpen: Bool {
        let open = ssh_channel_is_open(channel)
        return (open == 0) ? false : true
    }

    /// Check if the channel is closed or not.
    /// - Returns: `false` if the channel is opened. `true` otherwise.
    private var isClosed: Bool {
        let closed = ssh_channel_is_closed(channel)
        return (closed == 0) ? false : true
    }

    /// Get the exit status of the channel. This is the equivalent of the error
    /// code from the executed instruction.
    private var exitCode: CInt {
        ssh_channel_get_exit_status(channel)
    }

    /// Read data from either the standard stream (stdout) or an error stream
    /// (stderr).
    ///
    /// - Parameter stream: The stream to attempt to read data from.
    /// - Returns: `Data` if a 1 or more bytes are returned from the selected
    /// stream. If there is an error or no bytes are returned from stream then
    /// the method returns `nil`.
    private func read(stream: Stream = .stdout) -> Data? {
        let returnCode = ssh_channel_read_timeout(
            channel,
            channelReadBufferPointer,
            UInt32(bufferSize),
            stream.rawValue,
            250
        )

        guard returnCode != SSH_ERROR else {
            fatalError("Reading from \(stream)")
        }

        if returnCode > 0 {
            return Data(bytes: channelReadBufferPointer, count: Int(returnCode))
        }

        return nil
    }

    /// Run a shell command without an interactive shell.
    ///
    /// - Note: This is similar to `sh -c command`.
    /// - Parameters:
    ///   - command: Command to execute on the remote.
    ///   - stdout: File descriptor to write the data from the remote standard stream.
    ///   - stderr: File descriptor to write the data from the remote error stream.
    /// - Returns: Error code from the executed instruction.
    public func execute(_ command: String, stdout: FileHandle? = nil, stderr: FileHandle? = nil) -> CInt {
        let returnCode = command.withCString {
            ssh_channel_request_exec(channel, $0)
        }

        guard returnCode == SSH_OK else {
            fatalError("The channel could not execute the command: \(command)")
        }

        while isOpen && !isEOF {
            if let buffer = read(stream: .stdout) {
                stdout?.write(buffer)
            }

            if let buffer = read(stream: .stderr) {
                stdout?.write(buffer)
            }
        }

        return exitCode
    }
}
