import SwiftDiagnostics
import SwiftParser
import SwiftSyntax

public enum OTPF {
    public static func check(
        source: String,
        in name: String
    ) -> [Diagnostic] {
        let tree: SourceFileSyntax = Parser.parse(source: source)
        return self.check(tree: tree, in: name)
    }

    public static func check(
        tree: SourceFileSyntax,
        in name: String
    ) -> [Diagnostic] {
        var checker: Checker = .init(tree: tree, name: name)
        return checker.check()
    }

    public static func diagnose(
        source: String,
        in name: String
    ) -> (message: String, error: Bool)? {
        let tree: SourceFileSyntax = Parser.parse(source: source)
        let diagnostics: [Diagnostic] = self.check(tree: tree, in: name)
        guard !diagnostics.isEmpty else {
            return nil
        }
        let message: String = DiagnosticsFormatter.annotatedSource(
            tree: tree,
            diags: diagnostics
        )
        let error: Bool = diagnostics.contains { $0.diagMessage.severity == .error }
        return (message: message, error: error)
    }
}

extension OTPF {
    @_spi(testable) public static func manifest(name: String) -> Bool {
        if  name == "Package.swift" {
            return true
        }
        let pattern: Regex<AnyRegexOutput> = try! .init(
            #"Package@swift-(\d+)(?:\.(\d+))?(?:\.(\d+))?\.swift"#
        )
        if  case _? = try? pattern.wholeMatch(in: name) {
            return true
        }
        return false
    }
}
