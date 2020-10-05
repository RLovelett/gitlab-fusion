//
//  validate.swift
//  VMwareFusion
//
//  Created by Ryan Lovelett on 10/9/20.
//

import Darwin
import os.log

let log = OSLog(subsystem: "me.lovelett.gitlab-fusion", category: "VMWareFusion")

/// Check to see if a `String` is a valid IP address.
///
/// Use `inet_pton` to validate if a provided string is either a valid IPv4 or
/// IPv6 address.
///
/// - SeeAlso: https://stackoverflow.com/a/37071903/247730
/// - Parameter ipToValidate: `String` to validate.
/// - Returns: `true` if it is a valid IP; `false` otherwise.
func validate(ipAddress ipToValidate: String) -> Bool {
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
