import DollupConfig
import SystemIO
import Testing

@Suite struct DollupConfigRules {
    @Test static func CheckFiltration() throws {
        #expect(try DefaultConfig.check(file: "Package.swift"))
        #expect(try DefaultConfig.check(file: "./Package.swift"))
        #expect(try DefaultConfig.check(file: "/swift/project/Package.swift"))
        #expect(try DefaultConfig.check(file: "Sources/Target/Foo.swift"))
    }

    @Test static func CheckWitness() throws {
        let validName: FilePath.Component = "Foo.swift"
        let validSource: String = "public struct Foo {}"
        let validResult: Diagnostics? = try DefaultConfig.check(
            name: validName,
            text: validSource
        )
        #expect(validResult == nil)

        let invalidSource: String = "public struct Bar {}"
        let invalidResult: Diagnostics? = try DefaultConfig.check(
            name: validName,
            text: invalidSource
        )
        #expect(invalidResult != nil)
        #expect(invalidResult?.error == true)
        #expect(invalidResult?.message.contains("type 'Bar' does not match filename") == true)

        let manifestName: FilePath.Component = "Package.swift"
        let manifestSource: String = """
        // swift-tools-version:6.2
        import PackageDescription
        let package = Package(name: "Foo")
        """
        let manifestResult: Diagnostics? = try DefaultConfig.check(
            name: manifestName,
            text: manifestSource
        )
        #expect(manifestResult == nil)

        let lookalikeSource: String = """
        // swift-tools-version:6.2
        struct Package {}
        """
        let lookalikeResult: Diagnostics? = try DefaultConfig.check(
            name: manifestName,
            text: lookalikeSource
        )
        #expect(lookalikeResult != nil)
        #expect(lookalikeResult?.error == false)
        #expect(
            lookalikeResult?.message.contains(
                "declares type ‘Package’ but looks like a package manifest"
            ) == true
        )
    }

    @Test static func DiagnosticsDescription() {
        let path: FilePath = "Sources/Target/Foo.swift"
        let withPath: Diagnostics = .init(
            file: path,
            message: "sample error"
        )
        #expect(withPath.description.contains("error: in 'Sources/Target/Foo.swift':"))
        #expect(withPath.description.contains("sample error"))

        let withoutPath: Diagnostics = .init(message: "sample error")
        #expect(withoutPath.description.starts(with: "error:\nsample error"))

        let warningWithPath: Diagnostics = .init(
            file: path,
            message: "sample warning",
            error: false
        )
        #expect(warningWithPath.description.contains("warning: in 'Sources/Target/Foo.swift':"))
        #expect(warningWithPath.description.contains("sample warning"))
    }
}
