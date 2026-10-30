import Testing
import WhitespaceFormatter

@Suite struct ColonSpacingTests {
    @Test static func DictionaryLiterals() throws {
        let input: String = """
        let a: [String:Int] = [:]
        let b: [String :Int] = [
            "x":1,
            "y" : 2,
            "z"  :   3
        ]
        """
        let expected: String = """
        let a: [String: Int] = [:]
        let b: [String: Int] = [
            "x": 1,
            "y": 2,
            "z":   3
        ]
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func SwitchCases() throws {
        let input: String = """
        switch value {
        case .foo : break
        case .bar: break
        case .baz  :break
        default :   break
        }
        """
        let expected: String = """
        switch value {
        case .foo: break
        case .bar: break
        case .baz: break
        default:   break
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func FunctionNames() throws {
        let input: String = """
        function(_:)
        """
        let expected: String = """
        function(_:)
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func OperatorDeclarations() throws {
        let input: String = """
        infix operator ^^:RangeFormationPrecedence
        infix operator <- : RangeFormationPrecedence
        """
        let expected: String = """
        infix operator ^^ : RangeFormationPrecedence
        infix operator <- : RangeFormationPrecedence
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func Available() throws {
        let input: String = """
        @available(*, deprecated, renamed:"bar")
        var foo: Int { 1 }
        """
        let expected: String = """
        @available(*, deprecated, renamed: "bar")
        var foo: Int { 1 }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func Ternaries() throws {
        let input: String = """
        let x: Int = condition ? 1:2
        let y: Int = condition ? 1 :2
        let z: Int = condition
        ? 1
        :2
        """
        let expected: String = """
        let x: Int = condition ? 1 : 2
        let y: Int = condition ? 1 : 2
        let z: Int = condition
            ? 1
            : 2
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func Attributes() throws {
        let input: String = """
        @_documentation(metadata: "see: merge(appending:)")
        func merged() {}
        """
        let expected: String = """
        @_documentation(metadata: "see: merge(appending:)")
        func merged() {}
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func IfPrefixOperator() throws {
        let input: String = """
        if  !foo {
        }
        if  ~~bar {
        }
        if  baz {
        }
        """
        let expected: String = """
        if !foo {
        }
        if ~~bar {
        }
        if  baz {
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
}
extension ColonSpacingTests {
    private static func format(_ input: consuming String) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.formatColonPadding = true }
        var input: String = input
        try formatter.reformat(&input, check: true)
        return input
    }
}
