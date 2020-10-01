//
//  StageOptions.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 10/1/20.
//

import ArgumentParser
import Environment
import Path

/// Common arguments used by the individual stage subcommands.
struct StageOptions: ParsableArguments {
    @Option(help: "Fully qualified path to the VMware Fusion application.")
    var vmwareFusion = Path.root.join("Applications").join("VMware Fusion.app")

    /// Fully qualified path to the VMware Fusion `Info.plist` file.
    var vmwareFusionInfo: Path {
        vmwareFusion.join("Contents").join("Info.plist")
    }

    /// Fully qualified path to the VMware `vmrun` command.
    var vmrunPath: Path {
        vmwareFusion.join("Contents").join("Public").join("vmrun")
    }

    @Option(help: "Fully qualified path to directory where cloned images are stored.")
    var vmImagesPath = Path.home.join("Virtual Machines.localized")
}
