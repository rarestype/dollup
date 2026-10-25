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
    ) -> String? {
        let tree: SourceFileSyntax = Parser.parse(source: source)
        let diagnostics: [Diagnostic] = self.check(tree: tree, in: name)
        guard !diagnostics.isEmpty else {
            return nil
        }
        return DiagnosticsFormatter.annotatedSource(
            tree: tree,
            diags: diagnostics
        )
    }
}
