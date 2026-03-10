//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2021-2023 Apple Inc. and the Swift Package Collection Generator project authors
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
@testable import PackageCollectionGenerator
import enum TSCBasic.ProcessEnv

@Suite("GitHubPackageMetadataProvider Tests")
struct GitHubPackageMetadataProviderTests {
    @Test func apiURL() throws {
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")
        let provider = GitHubPackageMetadataProvider()

        #expect(provider.apiURL("git@github.com:octocat/Hello-World.git") == apiURL)
        #expect(provider.apiURL("https://github.com/octocat/Hello-World.git") == apiURL)
        #expect(provider.apiURL("https://github.com/octocat/Hello-World") == apiURL)
        #expect(provider.apiURL("bad/Hello-World.git") == nil)
    }

    @Test func good() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            guard request.headers.get("Authorization").first == "token \(authTokens.first!.value)" else {
                return completion(.success(.init(statusCode: 401)))
            }

            switch (request.method, request.url) {
            case (.get, apiURL):
                let data = try! self.readGitHubData(filename: "metadata.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            case (.get, apiURL.appendingPathComponent("readme")):
                let data = try! self.readGitHubData(filename: "readme.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            case (.get, apiURL.appendingPathComponent("license")):
                let data = try! self.readGitHubData(filename: "license.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            default:
                fatalError("method and url should match")
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        let metadata = try await withCheckedThrowingContinuation { continuation in
            provider.get(repoURL) { result in
                continuation.resume(with: result)
            }
        }

        #expect(metadata.summary == "This your first repo!")
        #expect(metadata.keywords == ["octocat", "atom", "electron", "api"])
        #expect(metadata.readmeURL == URL(string: "https://raw.githubusercontent.com/octokit/octokit.rb/master/README.md"))
        #expect(metadata.license?.name == "MIT")
        #expect(metadata.license?.url == URL(string: "https://raw.githubusercontent.com/benbalter/gman/master/LICENSE?lab=true"))
    }

    @Test func invalidAuthToken() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            if request.headers.get("Authorization").first == "token \(authTokens.first!.value)" {
                completion(.success(.init(statusCode: 401)))
            } else {
                completion(.success(.init(statusCode: 500)))
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        
        await #expect(throws: GitHubPackageMetadataProvider.Errors.invalidAuthToken(apiURL)) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PackageBasicMetadata, Error>) in
                provider.get(repoURL) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func repoNotFound() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { _, _, completion in
            completion(.success(.init(statusCode: 404)))
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        
        await #expect(throws: GitHubPackageMetadataProvider.Errors.notFound(apiURL)) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PackageBasicMetadata, Error>) in
                provider.get(repoURL) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func othersNotFound() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            guard request.headers.get("Authorization").first == "token \(authTokens.first!.value)" else {
                return completion(.success(.init(statusCode: 401)))
            }

            switch (request.method, request.url) {
            case (.get, apiURL):
                let data = try! self.readGitHubData(filename: "metadata.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            default:
                completion(.success(.init(statusCode: 500)))
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        let metadata = try await withCheckedThrowingContinuation { continuation in
            provider.get(repoURL) { result in
                continuation.resume(with: result)
            }
        }

        #expect(metadata.summary == "This your first repo!")
        #expect(metadata.keywords == ["octocat", "atom", "electron", "api"])
        #expect(metadata.readmeURL == nil)
        #expect(metadata.license == nil)
    }

    @Test func permissionDenied() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!

        let handler: LegacyHTTPClient.Handler = { _, _, completion in
            completion(.success(.init(statusCode: 401)))
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(httpClient: httpClient)
        
        await #expect(throws: GitHubPackageMetadataProvider.Errors.permissionDenied(apiURL)) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PackageBasicMetadata, Error>) in
                provider.get(repoURL) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func invalidURL() async throws {
        let repoURL = URL(string: "/")!
        let provider = GitHubPackageMetadataProvider()
        
        await #expect(throws: GitHubPackageMetadataProvider.Errors.invalidGitURL(repoURL)) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PackageBasicMetadata, Error>) in
                provider.get(repoURL) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    private func readGitHubData(filename: String) throws -> Data? {
        let path = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "GitHub", filename)
        guard let contents = try? localFileSystem.readFileContents(path).contents else {
            return nil
        }
        return Data(contents)
    }
}
