//
//  ConfigurationOutput.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import Foundation
import Path

/// A type used to decode a `Info.plist` file.
private struct InfoPlist: Decodable {
    let CFBundleShortVersionString: String
}

/// A structure to be JSON encoded and provided as the output of the
/// `config_exec` stage.
///
/// - SeeAlso: https://docs.gitlab.com/runner/executors/custom.html#config
struct ConfigurationOutput: Encodable {
    /// Information about the driver to be used in Gitlab Runner logging.
    struct Driver: Encodable {
        /// The user-defined name for the driver. Printed with the
        /// `Using custom executor...` line. If undefined, no information about
        /// driver is printed.
        let name: String

        /// The user-defined version for the drive. Printed with the
        /// `Using custom executor...` line. If undefined, only the name
        /// information is printed.
        let version: String

        /// Create version information about the driver by interrogating the
        /// VMware Fusion `Info.plist` provided.
        /// - Parameter infoPlist: A `Path` to the `Info.plist` to get version information from.
        init(_ infoPlist: Path) {
            let vmwareFusionVersion = { () -> String in
                let decoder = PropertyListDecoder()
                let data = try? Data(contentsOf: infoPlist)
                let plist = data.flatMap { try? decoder.decode(InfoPlist.self, from: $0) }
                return plist?.CFBundleShortVersionString ?? "unknown"
            }()

            name = "gitlab-fusion"
            version = "1.0.0-rc.1 — VMware Fusion \(vmwareFusionVersion)"
        }
    }

    /// The base directory where the working directory of the job will be created.
    let buildsDir: String

    /// The base directory where local cache will be stored.
    let cacheDir: String

    /// Defines whether the environment is shared between concurrent job or not.
    let isBuildsDirShared: Bool?

    /// The hostname to associate with job’s “metadata” stored by Runner.
    /// If undefined, the hostname is not set.
    let hostname: String?

    /// Information about the driver to be used in Gitlab Runner logging.
    let driver: Driver?
}
