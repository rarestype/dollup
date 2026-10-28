import DollupCheck
import SwiftDiagnostics
import Testing

@Suite struct OTPFRules {
    @Test static func PrimaryTypeParsing() {
        let topLevel: OTPF.PrimaryType = "Foo"
        #expect(topLevel.scope == nil)
        #expect(topLevel.last == "Foo")
        #expect(!topLevel.nested)
        #expect(!topLevel.encased)
        #expect(topLevel.unencased == "Foo")
        #expect(topLevel.description == "Foo")

        let nested: OTPF.PrimaryType = "Outer.Inner"
        #expect(nested.scope == "Outer")
        #expect(nested.last == "Inner")
        #expect(nested.nested)
        #expect(!nested.encased)
        #expect(nested.unencased == "Outer.Inner")
        #expect(nested.description == "Outer.Inner")

        let deep: OTPF.PrimaryType = "A.B.C"
        #expect(deep.scope == "A.B")
        #expect(deep.last == "C")
        #expect(deep.nested)
        #expect(!deep.encased)
        #expect(deep.unencased == "A.B.C")

        let keyword: OTPF.PrimaryType = "`default`"
        #expect(keyword.scope == nil)
        #expect(keyword.last == "default")
        #expect(keyword.encased)
        #expect(keyword.unencased == "default")
        #expect(keyword.description == "`default`")
        #expect(keyword == "default")

        let nestedKeyword: OTPF.PrimaryType = "Outer.`default`"
        #expect(nestedKeyword.scope == "Outer")
        #expect(nestedKeyword.last == "default")
        #expect(nestedKeyword.encased)
        #expect(nestedKeyword.unencased == "Outer.default")
        #expect(nestedKeyword.description == "Outer.`default`")
        #expect(nestedKeyword == "Outer.default")

        let encased: OTPF.PrimaryType = "`Outer`.Inner"
        #expect(encased.scope == "Outer")
        #expect(encased.last == "Inner")
        #expect(!encased.encased)
        #expect(encased.unencased == "Outer.Inner")
        #expect(encased.description == "Outer.Inner")

        let deepEncased: OTPF.PrimaryType = "`A`.`B`.`C`"
        #expect(deepEncased.scope == "A.B")
        #expect(deepEncased.last == "C")
        #expect(deepEncased.encased)
        #expect(deepEncased.unencased == "A.B.C")
        #expect(deepEncased.description == "A.B.`C`")
    }

    @Test static func FileClassClassification() {
        #expect(OTPF.FileClass.init(name: "Package.swift") == .layout("Package"))
        #expect(OTPF.FileClass.init(name: "anchor.swift") == .special(.anchor))
        #expect(OTPF.FileClass.init(name: "exports.swift") == .special(.exports))
        #expect(OTPF.FileClass.init(name: "lexemes.swift") == .special(.lexemes))
        #expect(OTPF.FileClass.init(name: "operators.swift") == .special(.operators))

        #expect(OTPF.FileClass.init(name: "Foo (ext).swift") == .ext("Foo"))
        #expect(OTPF.FileClass.init(name: "Outer.Inner (ext).swift") == .ext("Outer.Inner"))
        #expect(OTPF.FileClass.init(name: "Foo (gen).swift") == .gen("Foo"))

        #expect(OTPF.FileClass.init(name: "Foo.swift") == .layout("Foo"))
        #expect(OTPF.FileClass.init(name: "Outer.Inner.swift") == .layout("Outer.Inner"))
        #expect(OTPF.FileClass.init(name: "README.md") == nil)
    }

    @Test static func LayoutFileWithBacktickKeyword() {
        let source: String = """
        public struct `default` {
            public var value: Int
        }
        extension `default` {
            public func helper() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "default.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func NestedLayoutFileWithBacktickKeyword() {
        let source: String = """
        extension Outer {
            public struct `default` {
                public var value: Int
            }
        }
        extension Outer.`default` {
            public func helper() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Outer.default.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileValid() {
        let source: String = """
        public struct Foo {
            public var x: Int
        }
        extension Foo {
            public func bar() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileMismatch() {
        let source: String = """
        public struct Bar {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("does not match filename") == true)
    }

    @Test static func LayoutFileMultipleTypes() {
        let source: String = """
        public struct Foo {}
        public struct Bar {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "found type 'Bar' in file 'Foo.swift' which defines 'Foo'"
            ) == true
        )
    }

    @Test static func LayoutFileNestedTypeViolation() {
        let source: String = """
        public struct Foo {
            public struct Nested {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "nested type 'Nested' must be defined in its own file 'Foo.Nested.swift'"
            ) == true
        )
    }

    @Test static func LayoutFileForeignExtension() {
        let source: String = """
        public struct Foo {}
        extension Bar {
            public func helper() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "cannot contain extension to foreign type 'Bar'"
            ) == true
        )
    }

    @Test static func LayoutFileSimpleKeynumExempt() {
        let source: String = """
        public struct Foo {
            public enum CodingKeys: String, CodingKey {
                case id
                case name
            }
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileComplexKeynumViolates() {
        let source: String = """
        public struct Foo {
            public enum CodingKeys: String, CodingKey {
                case id
                case name
                public var helper: String { "help" }
            }
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "schema keynum 'CodingKeys' has grown members beyond enum cases"
            ) == true
        )
    }

    @Test static func LayoutFileDeprecationShimExempt() {
        let source: String = """
        public struct Foo {}

        @available(*, deprecated, renamed: "Foo")
        public typealias OldFoo = Foo
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileFreeFunctionAlone() {
        let source: String = """
        public func Partition(slice: inout [Int]) {}
        public func Partition(slice: inout [String]) {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Partition.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileFreeFunctionWithPrimaryType() {
        let source: String = """
        public struct Foo {}
        public func Foo() {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "free function 'Foo' cannot coexist with type 'Foo'"
            ) == true
        )
    }

    @Test static func NestedLayoutFileValid() {
        let source: String = """
        extension Foo {
            public struct Bar {
                public var val: Int
            }
        }
        extension Foo.Bar {
            public func doSomething() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.Bar.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func NestedLayoutFileForeignExtensionSiblingViolation() {
        let source: String = """
        extension Foo {
            public struct Bar {}
            public func sibling() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.Bar.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                """
                foreign extension to 'Foo' in 'Foo.Bar.swift' must contain nothing except the definition of 'Bar'
                """
            ) == true
        )
    }

    @Test static func NestedLayoutFileTopLevelTypeViolation() {
        let source: String = """
        public struct Bar {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.Bar.swift"
        )
        #expect(
            diagnostics.contains {
                $0.message.contains("found top-level type 'Bar' in nested layout file")
            }
        )
    }

    @Test static func ExtensionFileValid() {
        let source: String = """
        extension Foo {
            public func extra() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo (ext).swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func ExtensionFileCollectionTypes() {
        let arraySource: String = """
        extension [Int] {
            public func sum() -> Int { 0 }
        }
        extension Array where Element == String {
            public func joinedNames() -> String { "" }
        }
        """
        let arrayDiagnostics: [Diagnostic] = OTPF.check(
            source: arraySource,
            in: "Array (ext).swift"
        )
        #expect(arrayDiagnostics.isEmpty)

        let dictSource: String = """
        extension Dictionary where Key == String {
            public func lookup() {}
        }
        """
        let dictDiagnostics: [Diagnostic] = OTPF.check(
            source: dictSource,
            in: "Dictionary (ext).swift"
        )
        #expect(dictDiagnostics.isEmpty)
    }

    @Test static func ExtensionFileForeignViolation() {
        let source: String = """
        extension Foo {
            public func f() {}
        }
        extension Bar {
            public func b() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo (ext).swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains("cannot contain extension to 'Bar'") == true
        )
    }

    @Test static func ExtensionFilePrimaryTypeViolation() {
        let source: String = """
        public struct Foo {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo (ext).swift"
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("cannot define primary type 'Foo'") == true)
    }

    @Test static func ExtensionFileWitnessTypealias() {
        let source: String = """
        extension Foo: Equatable {
            public typealias Witness = Int
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo (ext).swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func FilenamePlusSignBanned() {
        let source: String = """
        extension Foo {
            public func bar() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo+Bar.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "plus signs ('+') are never allowed in filenames"
            ) == true
        )
    }

    @Test static func AnchorSwift() {
        let emptyDiagnostics: [Diagnostic] = OTPF.check(
            source: "",
            in: "anchor.swift"
        )
        #expect(emptyDiagnostics.isEmpty)

        let nonEmptyDiagnostics: [Diagnostic] = OTPF.check(
            source: "import Foundation",
            in: "anchor.swift"
        )
        #expect(nonEmptyDiagnostics.count == 1)
        #expect(
            nonEmptyDiagnostics.first?.message.contains("'anchor.swift' must be empty") == true
        )
    }

    @Test static func ExportsSwift() {
        let validSource: String = """
        @_exported import SystemIO
        @_exported import SwiftSyntax
        """
        let validDiagnostics: [Diagnostic] = OTPF.check(
            source: validSource,
            in: "exports.swift"
        )
        #expect(validDiagnostics.isEmpty)

        let invalidSource: String = """
        import SystemIO
        """
        let invalidDiagnostics: [Diagnostic] = OTPF.check(
            source: invalidSource,
            in: "exports.swift"
        )
        #expect(invalidDiagnostics.count == 1)
        #expect(
            invalidDiagnostics.first?.message.contains(
                "'exports.swift' can only contain '@_exported import' statements"
            ) == true
        )

        let misplacedExport: String = """
        @_exported import SystemIO
        public struct Foo {}
        """
        let misplacedDiagnostics: [Diagnostic] = OTPF.check(
            source: misplacedExport,
            in: "Foo.swift"
        )
        #expect(misplacedDiagnostics.count == 1)
        #expect(
            misplacedDiagnostics.first?.message.contains(
                "'@_exported import' is prohibited outside 'exports.swift'"
            ) == true
        )
    }

    @Test static func LexemesAndOperatorsSwift() {
        let lexemesSource: String = """
        infix operator >< : MultiplicationPrecedence
        precedencegroup CustomPrecedence {
            higherThan: MultiplicationPrecedence
        }
        """
        let lexemesDiagnostics: [Diagnostic] = OTPF.check(
            source: lexemesSource,
            in: "lexemes.swift"
        )
        #expect(lexemesDiagnostics.isEmpty)

        let misplacedOperator: String = """
        infix operator >< : MultiplicationPrecedence
        public struct Foo {}
        """
        let misplacedDiagnostics: [Diagnostic] = OTPF.check(
            source: misplacedOperator,
            in: "Foo.swift"
        )
        #expect(
            misplacedDiagnostics.contains {
                $0.message.contains(
                    """
                    operator and precedencegroup declarations are prohibited outside 'lexemes.swift'
                    """
                )
            }
        )

        let operatorsSource: String = """
        public func + (a: Foo, b: Foo) -> Foo { a }
        """
        let operatorsDiagnostics: [Diagnostic] = OTPF.check(
            source: operatorsSource,
            in: "operators.swift"
        )
        #expect(operatorsDiagnostics.isEmpty)

        let operatorsWithTypes: String = """
        public struct Foo {}
        """
        let operatorsTypeDiagnostics: [Diagnostic] = OTPF.check(
            source: operatorsWithTypes,
            in: "operators.swift"
        )
        #expect(operatorsTypeDiagnostics.count == 1)
        #expect(
            operatorsTypeDiagnostics.first?.message.contains(
                "'operators.swift' cannot declare types"
            ) == true
        )
    }

    @Test static func ConditionalCompilationUnrolling() {
        let source: String = """
        public struct Foo {
            #if os(Linux)
            public struct NestedLinux {}
            #else
            public struct NestedDarwin {}
            #endif
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 2)
        #expect(diagnostics.contains { $0.message.contains("NestedLinux") })
        #expect(diagnostics.contains { $0.message.contains("NestedDarwin") })
    }

    @Test static func DiagnoseFormatting() {
        let source: String = """
        public struct Foo {}
        public struct Bar {}
        """
        let formatted: (message: String, error: Bool)? = OTPF.diagnose(
            source: source,
            in: "Foo.swift"
        )
        #expect(formatted != nil)
        #expect(formatted?.message.contains("one type per file violation") == true)
        #expect(formatted?.error == true)
    }

    @Test static func ExtensionFileNestedTypeSuggestion() {
        let source: String = """
        extension Foo {
            struct Bar {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.Bar (ext).swift"
        )
        #expect(diagnostics.count == 2)
        #expect(diagnostics.contains { $0.message.contains("Foo.Bar.swift") })
        #expect(!diagnostics.contains { $0.message.contains("Foo.Bar.Bar.swift") })
    }

    @Test static func LayoutFileFreeFunctionWithStrayProperty() {
        let source: String = """
        func Partition(slice: inout [Int]) {}
        let unrelated: Int = 13
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Partition.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "top-level property 'unrelated' does not match filename 'Partition.swift'"
            ) == true
        )
    }

    @Test static func ExtensionFileStrayDeclarations() {
        let source: String = """
        extension Foo {}
        typealias Unrelated = Int
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo (ext).swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "extension file 'Foo (ext).swift' cannot contain top-level declarations"
            ) == true
        )
    }

    @Test static func LexemesAndOperatorsWithImports() {
        let source: String = """
        import Fraction

        infix operator <> : MultiplicationPrecedence
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "lexemes.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func PackageManifestDetection() {
        #expect(OTPF.manifest(name: "Package.swift"))
        #expect(OTPF.manifest(name: "./Package.swift"))
        #expect(OTPF.manifest(name: "Sources/X/Package.swift"))
        #expect(OTPF.manifest(name: "/swift/project/Package.swift"))
        #expect(OTPF.manifest(name: "Package@swift-5.9.swift"))
        #expect(OTPF.manifest(name: "Package@swift-6.2.swift"))
        #expect(OTPF.manifest(name: "Package@swift-10.15.swift"))

        #expect(!OTPF.manifest(name: "Package@swift-5.swift"))
        #expect(!OTPF.manifest(name: "Package@swift-5.9.1.swift"))
        #expect(!OTPF.manifest(name: "Package@swift-foo.swift"))
        #expect(!OTPF.manifest(name: "Foo.swift"))
        #expect(!OTPF.manifest(name: "Package.json"))
    }

    @Test static func PackageSwiftRootManifest() {
        let manifest: String = """
        // swift-tools-version:6.2
        import PackageDescription

        let package = Package(
            name: "Dollup"
        )
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: manifest,
            in: "Package.swift"
        )
        #expect(diagnostics.isEmpty)

        let manifestWithBlanks: String = """


        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "Dollup"
        )
        """
        let blankDiagnostics: [Diagnostic] = OTPF.check(
            source: manifestWithBlanks,
            in: "Package.swift"
        )
        #expect(blankDiagnostics.isEmpty)
    }

    @Test static func PackageSwiftVersionSpecificManifest() {
        let versionManifest: String = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "Dollup"
        )
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: versionManifest,
            in: "Package@swift-5.9.swift"
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func PackageSwiftTargetWithToolsVersionWarning() {
        let source: String = """
        // swift-tools-version:6.2
        struct Package {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Sources/X/Package.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.diagMessage.severity == .warning)
        #expect(
            diagnostics.first?.message.contains(
                "file 'Sources/X/Package.swift' declares type ‘Package’ but looks like a package manifest (starts with “// swift-tools-version:”), this is probably unintentional"
            ) == true
        )
    }

    @Test static func PackageSwiftTargetWithToolsVersionWarningAndError() {
        let source: String = """
        // swift-tools-version:6.2
        struct Package {}
        struct Other {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Package.swift"
        )
        #expect(diagnostics.count == 2)
        #expect(diagnostics.contains { $0.diagMessage.severity == .warning })
        #expect(diagnostics.contains { $0.diagMessage.severity == .error })
        #expect(
            diagnostics.contains {
                $0.message.contains("one type per file violation: found type 'Other' in file 'Package.swift'")
            }
        )
    }

    @Test static func PackageSwiftInTargetIsLayoutFile() {
        let targetSource: String = """
        struct Package {}
        struct Other {}
        """
        let targetDiagnostics: [Diagnostic] = OTPF.check(
            source: targetSource,
            in: "Package.swift"
        )
        #expect(targetDiagnostics.count == 1)
        #expect(targetDiagnostics.first?.diagMessage.severity == .error)
        #expect(
            targetDiagnostics.first?.message.contains(
                "one type per file violation: found type 'Other' in file 'Package.swift'"
            ) == true
        )

        let validSource: String = """
        struct Package {}
        """
        let validDiagnostics: [Diagnostic] = OTPF.check(
            source: validSource,
            in: "Package.swift"
        )
        #expect(validDiagnostics.isEmpty)

        let nonManifestSource: String = """
        // Copyright 2026
        // swift-tools-version:6.2
        struct Other {}
        """
        let nonManifestDiagnostics: [Diagnostic] = OTPF.check(
            source: nonManifestSource,
            in: "Package.swift"
        )
        #expect(!nonManifestDiagnostics.isEmpty)
        #expect(nonManifestDiagnostics.allSatisfy { $0.diagMessage.severity == .error })
    }

    @Test static func LayoutFileMismatchExtensionNoise() {
        let source: String = """
        public struct Bar {}
        extension Bar {
            public func a() {}
        }
        extension Bar {
            public func b() {}
        }
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: "Foo.swift"
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message.contains(
                "type 'Bar' does not match filename 'Foo.swift'"
            ) == true
        )
    }
}
