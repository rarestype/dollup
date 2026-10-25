import DollupConfig
import SystemPackage
import Testing

@Suite struct DollupConfigTests {
    @Test static func PackageManifestDetection() {
        #expect(FilePath.init("Package.swift").packageManifest)
        #expect(FilePath.init("./Package.swift").packageManifest)
        #expect(FilePath.init("/swift/project/Package.swift").packageManifest)
        #expect(FilePath.init("Benchmarks/Package.swift").packageManifest)

        #expect(!FilePath.init("Sources/Target/Foo.swift").packageManifest)
        #expect(!FilePath.init("Package.json").packageManifest)
    }

    @Test static func CheckFiltration() throws {
        #expect(try !DefaultConfig.check(file: FilePath.init("Package.swift")))
        #expect(try !DefaultConfig.check(file: FilePath.init("./Package.swift")))
        #expect(try !DefaultConfig.check(file: FilePath.init("/swift/dollup/Package.swift")))
        #expect(try DefaultConfig.check(file: FilePath.init("Sources/Target/Foo.swift")))
    }

    @Test static func CheckWitness() throws {
        let validName: FilePath.Component = FilePath.Component.init("Foo.swift")!
        let validSource: String = """
        public struct Foo {}
        """
        let validResult: Diagnostics? = try DefaultConfig.check(
            name: validName,
            text: validSource
        )
        #expect(validResult == nil)

        let invalidSource: String = """
        public struct Bar {}
        """
        let invalidResult: Diagnostics? = try DefaultConfig.check(
            name: validName,
            text: invalidSource
        )
        #expect(invalidResult != nil)
        #expect(invalidResult?.message.contains("type 'Bar' does not match filename") == true)
    }

    @Test static func DiagnosticsDescription() {
        let path: FilePath = FilePath.init("Sources/Target/Foo.swift")
        let withPath: Diagnostics = .init(
            file: path,
            message: "sample error"
        )
        #expect(withPath.description.contains("error: in 'Sources/Target/Foo.swift':"))
        #expect(withPath.description.contains("sample error"))

        let withoutPath: Diagnostics = .init(message: "sample error")
        #expect(withoutPath.description.hasPrefix("error:\nsample error"))
    }
}
