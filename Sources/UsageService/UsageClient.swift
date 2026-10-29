import Foundation
import Darwin
import AllowanceCore

public protocol UsageFetching {
    func fetch() throws -> UsageSnapshot
}

// Only this file knows how to communicate with the bundled Codex executable.
public struct UsageClient: UsageFetching {
    let executable: URL?
    let timeout: TimeInterval

    public init(executable: URL? = nil, timeout: TimeInterval = 20) {
        self.executable = executable
        self.timeout = timeout
    }

    private func findExecutable() throws -> URL {
        if let executable { return executable }
        let homes = ["/Applications", NSHomeDirectory() + "/Applications"]
        let paths = homes.flatMap { folder in [
            folder + "/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            folder + "/Codex.app/Contents/Resources/codex",
            folder + "/Codex.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
        ] }
        guard let path = paths.first(where: FileManager.default.isExecutableFile(atPath:)) else {
            throw UsageError.cliMissing
        }
        return URL(fileURLWithPath: path)
    }

    public func fetch() throws -> UsageSnapshot {
        let process = Process()
        process.executableURL = try findExecutable()
        process.arguments = ["app-server"]
        let input = Pipe(), output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { throw UsageError.launchFailed }
        // Close the parent copies of the child's pipe endpoints so EOF works.
        try? input.fileHandleForReading.close()
        try? output.fileHandleForWriting.close()
        defer {
            try? input.fileHandleForWriting.close()
            try? output.fileHandleForReading.close()
            if process.isRunning { process.terminate() }
            let deadline = ProcessInfo.processInfo.systemUptime + 0.5
            while process.isRunning && ProcessInfo.processInfo.systemUptime < deadline { usleep(10_000) }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()
        }
        func send(_ request: [String: Any]) throws {
            var bytes = try JSONSerialization.data(withJSONObject: request)
            bytes.append(10)
            try input.fileHandleForWriting.write(contentsOf: bytes)
        }
        try send(["id": 1, "method": "initialize", "params": [
            "clientInfo": ["name": "codex_allowance_bar", "version": "2.0"]
        ]])
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var buffer = Data()
        var totalBytes = 0
        var initialized = false
        var bytes = [UInt8](repeating: 0, count: 8192)
        while true {
            let remaining = deadline - ProcessInfo.processInfo.systemUptime
            guard remaining > 0 else { throw UsageError.timedOut }
            var descriptor = pollfd(fd: output.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0)
            let ready = poll(&descriptor, 1, Int32(max(1, min(remaining * 1000, 20_000))))
            if ready < 0 {
                if errno == EINTR { continue }
                throw UsageError.connectionClosed
            }
            if ready == 0 { throw UsageError.timedOut }
            let count = Darwin.read(descriptor.fd, &bytes, bytes.count)
            if count < 0 && errno == EINTR { continue }
            guard count > 0 else { throw UsageError.connectionClosed }
            totalBytes += count
            guard totalBytes <= 1_048_576 else { throw UsageError.tooMuchData }
            buffer.append(contentsOf: bytes.prefix(count))
            while let newline = buffer.firstIndex(of: 10) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                      let id = message["id"] as? Int else { continue }
                if message["error"] != nil { throw UsageError.requestFailed }
                if id == 1 && !initialized {
                    guard message["result"] != nil else { throw UsageError.invalidResponse }
                    initialized = true
                    try send(["method": "initialized"])
                    try send(["id": 2, "method": "account/rateLimits/read"])
                } else if id == 2 && initialized {
                    return try UsageDecoder.decode(line)
                }
            }
        }
    }
}
