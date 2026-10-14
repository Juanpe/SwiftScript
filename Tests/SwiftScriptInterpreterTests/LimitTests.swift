import Foundation
import Testing
@testable import SwiftScriptInterpreter

@Suite("Limits")
struct LimitTests {
    @Test func cancellingStopsAnEndlessLoop() async throws {
        let task = Task {
            try await Interpreter().eval("var i = 0\nwhile true { i += 1 }\ni")
        }
        try await Task.sleep(for: .milliseconds(200))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func cancellingStopsEndlessRecursion() async throws {
        let task = Task {
            try await Interpreter().eval("func f(_ n: Int) -> Int { f(n + 1) }\nf(0)")
        }
        try await Task.sleep(for: .milliseconds(200))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func callDepthLimitStopsRecursion() async throws {
        let interp = Interpreter()
        interp.maxCallDepth = 50
        await #expect(throws: (any Error).self) {
            try await interp.eval("func f(_ n: Int) -> Int { f(n + 1) }\nf(0)")
        }
        // Calls within the limit still run, and the depth is released.
        let r = try await interp.eval("func d(_ n: Int) -> Int { n == 0 ? 0 : 1 + d(n - 1) }\nd(40)")
        #expect(r == .int(40))
    }

    @Test func noLimitByDefault() async throws {
        let r = try await Interpreter().eval("func d(_ n: Int) -> Int { n == 0 ? 0 : 1 + d(n - 1) }\nd(600)")
        #expect(r == .int(600))
    }
}
