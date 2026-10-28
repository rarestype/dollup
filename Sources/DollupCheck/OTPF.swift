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
    public static func manifest(name: String) -> Bool {
        let filename: Substring
        if  let slash: String.Index = name.lastIndex(of: "/") {
            let next: String.Index = name.index(after: slash)
            filename = name[next...]
        } else {
            filename = name[...]
        }

        if  filename == "Package.swift" {
            return true
        }
        guard filename.hasPrefix("Package@swift-"),
              filename.hasSuffix(".swift") else {
            return false
        }
        let versionStart: String.Index = filename.index(filename.startIndex, offsetBy: 14)
        let versionEnd: String.Index = filename.index(filename.endIndex, offsetBy: -6)
        guard versionStart < versionEnd else {
            return false
        }
        let version: Substring = filename[versionStart ..< versionEnd]
        let parts: [Substring] = version.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let major: Substring = parts.first,
              let minor: Substring = parts.last,
              !major.isEmpty,
              !minor.isEmpty,
              major.allSatisfy({ $0 >= "0" && $0 <= "9" }),
              minor.allSatisfy({ $0 >= "0" && $0 <= "9" }) else {
            return false
        }
        return true
    }
}
