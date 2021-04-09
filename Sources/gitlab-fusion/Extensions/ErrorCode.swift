//
//  ErrorCode.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 4/9/20.
//

import ArgumentParser

extension ArgumentParser.ExitCode {
    init(_ error: GitlabRunnerError) {
        self.init(error.exitCode)
    }
}
