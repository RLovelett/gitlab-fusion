//
//  Path+ExpressibleByArgument.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 9/27/20.
//

import ArgumentParser
import Path

extension Path: ExpressibleByArgument {

    public init?(argument: String) {
        self.init(argument)
    }

    public var defaultValueDescription: String {
        return self.string
    }

    public static var defaultCompletionKind: CompletionKind {
        .file()
    }

}
