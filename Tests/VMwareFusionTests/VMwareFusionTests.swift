//
//  VMwareFusionTests.swift
//  VMwareFusionTests
//
//  Created by Ryan Lovelett on 10/9/20.
//

import Foundation
@testable import VMwareFusion
import Path
import XCTest

// VMWareFusion is it's own target/module to work around SR-1393

final class VMwareFusionTests: XCTestCase {
    func testMissingExecutable() throws {
        let fusion = VMwareFusion(Path.root/"a")
        XCTAssertThrowsError(try fusion.vmrun("foo").get()) { error in
            XCTAssertTrue(error is VMwareFusion.Error, "Unexpected error type: \(type(of: error))")
            XCTAssertEqual(error.localizedDescription, "The supplied vmrun, \"/a/Contents/Public/vmrun\", cannot be executed.")
        }
    }

    func testNonZeroExit() throws {
        let fusion = VMwareFusion(Path.home)
        XCTAssertThrowsError(try fusion.vmrun(task: NonZeroExit(), "foo").get()) { error in
            XCTAssertTrue(error is VMwareFusion.Error, "Unexpected error type: \(type(of: error))")
            XCTAssertEqual(error.localizedDescription, "Matter tells space-time how to curve")
        }
    }

    func testHappyPath() throws {
        let fusion = VMwareFusion(Path.home)
        let result = fusion.vmrun(task: HappyPath(), "foo")
        XCTAssertEqual(try result.get(), "🥳")
    }
}

// MARK:- Conformances to Executable for mocking in tests

private final class NonZeroExit: Executable {
    init() {}
    var executableURL: URL?
    var arguments: [String]?
    var standardOutput: Any? {
        get { nil }
        set(newStdout) {
            if let pipe = newStdout as? Pipe {
                let data = "Space-time tells matter how to move".data(using: .utf8)!
                pipe.fileHandleForWriting.write(data)
                try! pipe.fileHandleForWriting.close()
            }
        }
    }
    var standardError: Any? {
        get { nil }
        set(newStderr) {
            if let pipe = newStderr as? Pipe {
                let data = "Matter tells space-time how to curve".data(using: .utf8)!
                pipe.fileHandleForWriting.write(data)
                try! pipe.fileHandleForWriting.close()
            }
        }
    }
    var terminationStatus: CInt { 2 }
    var terminationReason: Process.TerminationReason { .exit }
    func run() throws { }
    func waitUntilExit() { }
}

private final class HappyPath: Executable {
    init() {}
    var executableURL: URL?
    var arguments: [String]?
    var standardOutput: Any? {
        get { nil }
        set(newStdout) {
            if let pipe = newStdout as? Pipe {
                let data = "🥳".data(using: .utf8)!
                pipe.fileHandleForWriting.write(data)
                try! pipe.fileHandleForWriting.close()
            }
        }
    }
    var standardError: Any? {
        get { nil }
        set(newStderr) {
            if let pipe = newStderr as? Pipe {
                try! pipe.fileHandleForWriting.close()
            }
        }
    }
    var terminationStatus: CInt { 0 }
    var terminationReason: Process.TerminationReason { .exit }
    func run() throws { }
    func waitUntilExit() { }
}
