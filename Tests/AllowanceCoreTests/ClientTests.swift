import XCTest
import Darwin
import AllowanceCore
import UsageService

final class ClientTests: XCTestCase {
    func withServer(_ body: String, run: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("fake-codex")
        try ("#!/bin/bash\n" + body).write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        try run(executable)
    }

    func testHandshakeAndSplitResponse() throws {
        let future = Int(Date().timeIntervalSince1970) + 18000
        try withServer("""
        IFS= read -r line
        [[ "$line" == *'"initialize"'* ]] || exit 2
        printf '%s\\n' '{"id":1,"result":{}}'
        IFS= read -r line
        [[ "$line" == *'"initialized"'* ]] || exit 3
        IFS= read -r line
        [[ "$line" == *'account'*'rateLimits'*'read'* ]] || exit 4
        printf '%s' '{"id":2,"res'
        /bin/sleep 0.02
        printf '%s\\n' 'ult":{"rateLimits":{"primary":{"windowDurationMins":300,"usedPercent":21,"resetsAt":\(future)}}}}'
        """) { executable in
            let result = try UsageClient(executable: executable, timeout: 2).fetch()
            XCTAssertEqual(result.fiveHour?.remainingPercent, 79)
        }
    }
    func testTimeoutIsBounded() throws {
        try withServer("IFS= read -r line\nwhile IFS= read -r line; do :; done\n") { executable in
            let start = ProcessInfo.processInfo.systemUptime
            XCTAssertThrowsError(try UsageClient(executable: executable, timeout: 0.15).fetch()) { error in
                XCTAssertEqual(error as? UsageError, .timedOut)
            }
            XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 2)
        }
    }
    func testClosedConnectionReturnsError() throws {
        try withServer("IFS= read -r line\nexit 0\n") { executable in
            XCTAssertThrowsError(try UsageClient(executable: executable, timeout: 1).fetch()) { error in
                XCTAssertEqual(error as? UsageError, .connectionClosed)
            }
        }
    }
    func testRPCErrorIsReportedWithoutExposingItsPayload() throws {
        try withServer("IFS= read -r line\nprintf '%s\\n' '{\"id\":1,\"error\":{\"message\":\"private server detail\"}}'\n") { executable in
            XCTAssertThrowsError(try UsageClient(executable: executable).fetch()) { error in
                XCTAssertEqual(error as? UsageError, .requestFailed)
                XCTAssertFalse(error.localizedDescription.contains("private server detail"))
            }
        }
    }
}
