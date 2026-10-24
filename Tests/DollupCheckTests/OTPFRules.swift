import DollupCheck
import SwiftDiagnostics
import SystemIO
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
    }

    @Test static func FileClassClassification() {
        #expect(OTPF.FileClass.init(filename: "Package.swift") == .special(.Package))
        #expect(OTPF.FileClass.init(filename: "anchor.swift") == .special(.anchor))
        #expect(OTPF.FileClass.init(filename: "exports.swift") == .special(.exports))
        #expect(OTPF.FileClass.init(filename: "lexemes.swift") == .special(.lexemes))
        #expect(OTPF.FileClass.init(filename: "operators.swift") == .special(.operators))

        #expect(OTPF.FileClass.init(filename: "Foo (ext).swift") == .ext("Foo"))
        #expect(OTPF.FileClass.init(filename: "Outer.Inner (ext).swift") == .ext("Outer.Inner"))
        #expect(OTPF.FileClass.init(filename: "Foo (gen).swift") == .gen("Foo"))

        #expect(OTPF.FileClass.init(filename: "Foo.swift") == .layout("Foo"))
        #expect(OTPF.FileClass.init(filename: "Outer.Inner.swift") == .layout("Outer.Inner"))
        #expect(OTPF.FileClass.init(filename: "README.md") == nil)
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
            in: FilePath.init("default.swift")
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
            in: FilePath.init("Outer.default.swift")
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
            in: FilePath.init("Foo.swift")
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileMismatch() {
        let source: String = """
        public struct Bar {}
        """
        let diagnostics: [Diagnostic] = OTPF.check(
            source: source,
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Partition.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("Foo.Bar.swift")
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
            in: FilePath.init("Foo.Bar.swift")
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
            in: FilePath.init("Foo.Bar.swift")
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
            in: FilePath.init("Foo (ext).swift")
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
            in: FilePath.init("Array (ext).swift")
        )
        #expect(arrayDiagnostics.isEmpty)

        let dictSource: String = """
        extension Dictionary where Key == String {
            public func lookup() {}
        }
        """
        let dictDiagnostics: [Diagnostic] = OTPF.check(
            source: dictSource,
            in: FilePath.init("Dictionary (ext).swift")
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
            in: FilePath.init("Foo (ext).swift")
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
            in: FilePath.init("Foo (ext).swift")
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
            in: FilePath.init("Foo (ext).swift")
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
            in: FilePath.init("Foo+Bar.swift")
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
            in: FilePath.init("anchor.swift")
        )
        #expect(emptyDiagnostics.isEmpty)

        let nonEmptyDiagnostics: [Diagnostic] = OTPF.check(
            source: "import Foundation",
            in: FilePath.init("anchor.swift")
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
            in: FilePath.init("exports.swift")
        )
        #expect(validDiagnostics.isEmpty)

        let invalidSource: String = """
        import SystemIO
        """
        let invalidDiagnostics: [Diagnostic] = OTPF.check(
            source: invalidSource,
            in: FilePath.init("exports.swift")
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
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("lexemes.swift")
        )
        #expect(lexemesDiagnostics.isEmpty)

        let misplacedOperator: String = """
        infix operator >< : MultiplicationPrecedence
        public struct Foo {}
        """
        let misplacedDiagnostics: [Diagnostic] = OTPF.check(
            source: misplacedOperator,
            in: FilePath.init("Foo.swift")
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
            in: FilePath.init("operators.swift")
        )
        #expect(operatorsDiagnostics.isEmpty)

        let operatorsWithTypes: String = """
        public struct Foo {}
        """
        let operatorsTypeDiagnostics: [Diagnostic] = OTPF.check(
            source: operatorsWithTypes,
            in: FilePath.init("operators.swift")
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
            in: FilePath.init("Foo.swift")
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
        let diagnostics: OTPF.Diagnostics? = OTPF.diagnose(
            source: source,
            in: FilePath.init("Foo.swift")
        )
        #expect(diagnostics != nil)
        let formatted: String = diagnostics?.description ?? ""
        #expect(formatted.contains("error: in 'Foo.swift':"))
        #expect(formatted.contains("one type per file violation"))
    }
}
