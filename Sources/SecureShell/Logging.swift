//
//  Logging.swift
//  SecureShell
//
//  Created by Ryan Lovelett on 10/9/20.
//

import Clibssh
import os.log

let log = OSLog(subsystem: "me.lovelett.gitlab-fusion", category: "SecureShell")

/// Handle logging messages provided by libssh.
///
/// - Parameters:
///   - priority: Priority of the log, the smaller being the more important.
///   - function: The function name calling the the logging fucntions.
///   - buffer: The actual message.
///   - userdata: Userdata to be passed to the callback function.
func sshLoggingCallback(priority: Int32, function: UnsafePointer<CChar>?, buffer: UnsafePointer<CChar>?, userdata: UnsafeMutableRawPointer?) {
    let message = buffer.map { String(cString: $0) } ?? ""
    switch priority {
    case SSH_LOG_WARN:
        // Show only warnings
        os_log("%{public}@", log: log, type: .error, message)
    case SSH_LOG_INFO:
        // Get some information what's going on
        os_log("%{public}@", log: log, type: .info, message)
    case SSH_LOG_DEBUG, SSH_LOG_TRACE:
        // Get detailed debuging information
        // Get trace output, packet information,
        os_log("%{public}@", log: log, type: .debug, message)
    default:
        os_log("%{public}@", log: log, type: .default, message)
    }
}
