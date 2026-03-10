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
@testable import PackageCollectionDiff
@testable import TestUtilities

@Suite("PackageCollectionDiff Tests")
struct PackageCollectionDiffTests {
    @Test func help() throws {
        let result = try executeCommand(executable: "package-collection-diff", arguments: ["--help"])
        #expect(result.stdout.contains("USAGE: package-collection-diff <collection-one-path> <collection-two-path> [--verbose]"))
    }

    @Test func same() throws {
        let path = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "test.json")

        let result = try executeCommand(executable: "package-collection-diff", arguments: [path.pathString, path.pathString])
        #expect(result.stdout.contains("The package collections are the same."))
        #expect(result.exitCode == 0)
    }

    @Test func differentGeneratedAt() throws {
        let pathOne = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "test.json")
        let pathTwo = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "test_diff_generated_at.json")

        // Two collections with only `generatedAt` being different are considered the same
        let result = try executeCommand(executable: "package-collection-diff", arguments: [pathOne.pathString, pathTwo.pathString])
        #expect(result.stdout.contains("The package collections are the same."))
        #expect(result.exitCode == 0)
    }

    @Test func differentPackages() throws {
        let pathOne = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "test.json")
        let pathTwo = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "test_diff_packages.json")

        let result = try executeCommand(executable: "package-collection-diff", arguments: [pathOne.pathString, pathTwo.pathString])
        #expect(result.stdout.contains("The package collections are different."))
        #expect(result.exitCode == 0)
    }
}
