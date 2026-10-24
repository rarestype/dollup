import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SystemIO

public enum OTPF {
    public typealias Diagnostics = DollupCheck.Diagnostics

    public static func check(
        source: String,
        in file: FilePath
    ) -> [Diagnostic] {
        let tree: SourceFileSyntax = Parser.parse(source: source)
        return self.check(tree: tree, in: file)
    }

    public static func check(
        tree: SourceFileSyntax,
        in file: FilePath
    ) -> [Diagnostic] {
        var checker: Checker = .init(tree: tree, path: file)
        return checker.check()
    }

    public static func diagnose(
        source: String,
        in file: FilePath
    ) -> Diagnostics? {
        let tree: SourceFileSyntax = Parser.parse(source: source)
        let diagnostics: [Diagnostic] = self.check(tree: tree, in: file)
        guard !diagnostics.isEmpty else {
            return nil
        }
        let annotated: String = DiagnosticsFormatter.annotatedSource(
            tree: tree,
            diags: diagnostics
        )
        return .init(file: file, message: annotated)
    }
}

@available(*, deprecated, renamed: "OTPF")
public typealias OneTypePerFile = OTPF
