//
//  StageOptions.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 10/1/20.
//

import ArgumentParser
import Environment
import Path
import VMwareFusion

/// Common arguments used by the individual stage subcommands.
struct StageOptions: ParsableArguments {
    @Option(name: .customLong("vmware-fusion"), help: "Fully qualified path to the VMware Fusion application.")
    var vmwareFusionPath = Path.root.join("Applications").join("VMware Fusion.app")

    /// A type to invoke `vmrun` and interact with virtual machines.
    var vmwareFusion: VMwareFusion {
        VMwareFusion(vmwareFusionPath)
    }

    /// Fully qualified path to the VMware Fusion `Info.plist` file.
    var vmwareFusionInfo: Path {
        vmwareFusionPath.join("Contents").join("Info.plist")
    }

    @Option(help: "Fully qualified path to directory where cloned images are stored.")
    var vmImagesPath = Path.home.join("Virtual Machines.localized")
}
