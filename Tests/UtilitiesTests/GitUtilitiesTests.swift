//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift Package Collection Generator project authors
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

@testable import Utilities

@Suite("GitUtilities Tests")
struct GitUtilitiesTests {
    @Test func gitURL() throws {
        do {
            let gitURL = GitURL.from("https://github.com/octocat/Hello-World")
            #expect(gitURL?.host == "github.com")
            #expect(gitURL?.owner == "octocat")
            #expect(gitURL?.repository == "Hello-World")
        }

        do {
            let gitURL = GitURL.from("https://github.com/octocat/Hello-World.git")
            #expect(gitURL?.host == "github.com")
            #expect(gitURL?.owner == "octocat")
            #expect(gitURL?.repository == "Hello-World")
        }

        do {
            let gitURL = GitURL.from("git@github.com:octocat/Hello-World.git")
            #expect(gitURL?.host == "github.com")
            #expect(gitURL?.owner == "octocat")
            #expect(gitURL?.repository == "Hello-World")
        }

        #expect(GitURL.from("bad/Hello-World.git") == nil)
    }
}
