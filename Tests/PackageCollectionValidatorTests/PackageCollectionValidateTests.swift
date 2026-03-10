//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020-2023 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Testing

import Basics
@testable import PackageCollectionValidator
@testable import TestUtilities

@Suite("PackageCollectionValidate Tests")
struct PackageCollectionValidateTests {
    @Test func help() throws {
        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--help"])
        #expect(result.stdout.contains("USAGE: package-collection-validate <input-path> [--warnings-as-errors] [--verbose]"))
    }

    @Test func good() throws {
        let inputFilePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "valid.json")

        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--verbose", inputFilePath.pathString])
        #expect(result.stdout.contains("The package collection is valid."))
        #expect(result.exitCode == 0)
    }

    @Test func badJSON() throws {
        let inputFilePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "bad.json")

        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--verbose", inputFilePath.pathString])
        #expect(result.stderr.contains("Failed to parse package collection"))
        #expect(result.exitCode != 0)
    }

    @Test func collectionWithErrors() throws {
        let inputFilePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "error-no-packages.json")

        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--verbose", inputFilePath.pathString])
        #expect(result.stdout.contains("must contain at least one package"))
        #expect(result.exitCode != 0)
    }

    @Test func collectionWithWarnings() throws {
        let inputFilePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "warning-too-many-versions.json")

        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--verbose", inputFilePath.pathString])
        #expect(result.stdout.contains("includes too many major versions"))
        #expect(result.exitCode == 0)
    }

    @Test func warningsAsErrors() throws {
        let inputFilePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "warning-too-many-versions.json")

        let result = try executeCommand(executable: "package-collection-validate", arguments: ["--warnings-as-errors", "--verbose", inputFilePath.pathString])
        #expect(result.stderr.contains("includes too many major versions"))
        #expect(result.exitCode != 0)
    }
}
