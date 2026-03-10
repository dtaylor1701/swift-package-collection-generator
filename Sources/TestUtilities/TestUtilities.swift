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

import ArgumentParser
import TSCBasic
import Foundation

// From TSCTestSupport
func systemQuietly(_ args: [String]) throws {
    // Discard the output, by default.
    try Process.checkNonZeroExit(arguments: args)
}

public enum CommandExecutionError: Error {
    case executableNotFound(String)
}

public struct CommandResult {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
}

public func executeCommand(
    executable: String,
    arguments: [String],
    bundleURL: URL? = nil
) throws -> CommandResult {
    let executableDirectory: URL
    if let bundleURL = bundleURL {
        executableDirectory = bundleURL.lastPathComponent.hasSuffix("xctest")
            ? bundleURL.deletingLastPathComponent()
            : bundleURL
    } else {
        // Find the .build directory relative to this file
        let currentFilePath = URL(fileURLWithPath: #file)
        let projectRoot = currentFilePath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let buildDir = projectRoot.appendingPathComponent(".build")
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: buildDir, includingPropertiesForKeys: [.isExecutableKey])
        
        var commandURL: URL?
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent == executable {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isExecutableKey])
                if resourceValues?.isExecutable ?? false {
                    if !fileURL.path.contains(".dSYM") && !fileURL.path.contains(".build/checkouts") {
                        commandURL = fileURL
                        break
                    }
                }
            }
        }
        
        guard let finalCommandURL = commandURL else {
            throw CommandExecutionError.executableNotFound(executable)
        }
        executableDirectory = finalCommandURL.deletingLastPathComponent()
    }

    let commandURL = executableDirectory.appendingPathComponent(executable)
    guard (try? commandURL.checkResourceIsReachable()) ?? false else {
        throw CommandExecutionError.executableNotFound(commandURL.standardizedFileURL.path)
    }

    let process = Process()
    process.executableURL = commandURL
    process.arguments = arguments

    let output = Pipe()
    process.standardOutput = output
    let error = Pipe()
    process.standardError = error

    try process.run()
    process.waitUntilExit()

    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let outputActual = String(data: outputData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

    let errorData = error.fileHandleForReading.readDataToEndOfFile()
    let errorActual = String(data: errorData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

    return CommandResult(stdout: outputActual, stderr: errorActual, exitCode: process.terminationStatus)
}
