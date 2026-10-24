import DollupCheck
import SwiftDiagnostics
import SystemIO
import Testing

@Suite struct OneTypePerFileRules {
    @Test static func LayoutFileValid() {
        let source: String = """
        public struct Foo {
            public var x: Int
        }
        extension Foo {
            public func bar() {}
        }
        """
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
            source: source,
            in: FilePath.init("Foo.swift")
        )
        #expect(diagnostics.isEmpty)
    }

    @Test static func LayoutFileMismatch() {
        let source: String = """
        public struct Bar {}
        """
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let arrayDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: arraySource,
            in: FilePath.init("Array (ext).swift")
        )
        #expect(arrayDiagnostics.isEmpty)

        let dictSource: String = """
        extension Dictionary where Key == String {
            public func lookup() {}
        }
        """
        let dictDiagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
            source: source,
            in: FilePath.init("Foo (ext).swift")
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("cannot contain extension to 'Bar'") == true)
    }

    @Test static func ExtensionFilePrimaryTypeViolation() {
        let source: String = """
        public struct Foo {}
        """
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let emptyDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: "",
            in: FilePath.init("anchor.swift")
        )
        #expect(emptyDiagnostics.isEmpty)

        let nonEmptyDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: "import Foundation",
            in: FilePath.init("anchor.swift")
        )
        #expect(nonEmptyDiagnostics.count == 1)
        #expect(nonEmptyDiagnostics.first?.message.contains("'anchor.swift' must be empty") == true)
    }

    @Test static func ExportsSwift() {
        let validSource: String = """
        @_exported import SystemIO
        @_exported import SwiftSyntax
        """
        let validDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: validSource,
            in: FilePath.init("exports.swift")
        )
        #expect(validDiagnostics.isEmpty)

        let invalidSource: String = """
        import SystemIO
        """
        let invalidDiagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let misplacedDiagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let lexemesDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: lexemesSource,
            in: FilePath.init("lexemes.swift")
        )
        #expect(lexemesDiagnostics.isEmpty)

        let misplacedOperator: String = """
        infix operator >< : MultiplicationPrecedence
        public struct Foo {}
        """
        let misplacedDiagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let operatorsDiagnostics: [Diagnostic] = OneTypePerFile.check(
            source: operatorsSource,
            in: FilePath.init("operators.swift")
        )
        #expect(operatorsDiagnostics.isEmpty)

        let operatorsWithTypes: String = """
        public struct Foo {}
        """
        let operatorsTypeDiagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: [Diagnostic] = OneTypePerFile.check(
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
        let diagnostics: OneTypePerFile.Diagnostics? = OneTypePerFile.diagnose(
            source: source,
            in: FilePath.init("Foo.swift")
        )
        #expect(diagnostics != nil)
        let formatted: String = diagnostics?.description ?? ""
        #expect(formatted.contains("error: in 'Foo.swift':"))
        #expect(formatted.contains("one type per file violation"))
    }
}
