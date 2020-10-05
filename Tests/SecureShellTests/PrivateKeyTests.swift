//
//  PrivateKeyTests.swift
//  SecureShellTests
//
//  Created by Ryan Lovelett on 10/10/20.
//

import class Foundation.Bundle
import Path
@testable import SecureShell
import XCTest

final class PrivateKeyTests: XCTestCase {
    var idRsaWithoutPassword: Path {
        Bundle.module.path(forResource: "rsaWithoutPassword", ofType: nil)!
    }

    var idED25519WithoutPassword: Path {
        Bundle.module.path(forResource: "ed25519WithoutPassword", ofType: nil)!
    }

    var emptyFile: Path {
        Bundle.module.path(forResource: "emptyFile", ofType: nil)!
    }

    func testReadingPrivateKeyWithoutPassword() throws {
        let a = try PrivateKey(contentsOfFile: idRsaWithoutPassword)
        XCTAssertEqual(a.description, "ssh-rsa")
        let b = try PrivateKey(contentsOfFile: idED25519WithoutPassword)
        XCTAssertEqual(b.description, "ssh-ed25519")
    }

    func testReadingEmptyFile() throws {
        XCTAssertThrowsError(try PrivateKey(contentsOfFile: emptyFile)) { error in
            XCTAssertTrue(error is SecureShellError, "Unexpected error type: \(type(of: error))")
            XCTAssertTrue(error.localizedDescription.starts(with: "Could not import private key at"))
        }
    }
}

