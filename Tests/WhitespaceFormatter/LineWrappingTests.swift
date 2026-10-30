import Testing
import WhitespaceFormatter

@Suite struct LineWrappingTests {
    @Test static func FunctionCall() throws {
        let input: String = """
        myFunction\
        (arg1: 1, arg2: 2, arg3: 3, arg4: 4, arg5: 5, arg6: 6, arg7: 7, arg8: 8, arg9: 9)
        """
        let expected: String = """
        myFunction(
            arg1: 1,
            arg2: 2,
            arg3: 3,
            arg4: 4,
            arg5: 5,
            arg6: 6,
            arg7: 7,
            arg8: 8,
            arg9: 9
        )
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 30) == expected + "\n")
    }

    @Test static func FunctionCallNested() throws {
        let input: String = """
        myFunction\
        (arg1: other(foo: 1, bar: 2, baz: 3), arg2: 3, arg3: 4, arg4: 5, arg5: 6, arg6: 7)
        """
        let expected: String = """
        myFunction(
            arg1: other(
                foo: 1,
                bar: 2,
                baz: 3
            ),
            arg2: 3,
            arg3: 4,
            arg4: 5,
            arg5: 6,
            arg6: 7
        )
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 30) == expected + "\n")
    }

    @Test static func FunctionCallTrailingClosure() throws {
        let input: String = """
        myFunction(arg1: 1, arg2: 2) { print("this is a long line that should be wrapped") }
        """
        let expected: String = #"""
        myFunction(arg1: 1, arg2: 2) {
            print(
                """
                this is a long line that should be wrapped
                """
            )
        }
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }
    @Test static func FunctionCallTrailingClosureWrappedArguments() throws {
        let input: String = """
        myFunction(arg1: 1, arg2: 2, arg3: 3, arg4: 4, arg5: 5, arg6: 6) {
            print("this is a long line that should be wrapped")
        }
        """
        let expected: String = """
        myFunction(
            arg1: 1,
            arg2: 2,
            arg3: 3,
            arg4: 4,
            arg5: 5,
            arg6: 6
        ) {
            print(
                \"""
                this is a long line that should be wrapped
                \"""
            )
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }
    @Test static func FunctionCallTrailingClosureMultiple() throws {
        ///                                                      | +60
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0("foo", "bar") { "blah blah blah" } content: { "blah blah blah" }
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0("foo", "bar") { "blah blah blah" } content: {
                    "blah blah blah"
                }
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func FunctionCallTrailingClosureMultipleBreaks() throws {
        ///                                                      | +60
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0("foo", "bar") { "blah blah blah blah" } content: { "blah blah blah" }
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0("foo", "bar") {
                    "blah blah blah blah"
                } content: {
                    "blah blah blah"
                }
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }

    @Test static func FunctionDeclaration() throws {
        let input: String = """
        func myFunction\
        (arg1: Int, arg2: String, arg3: Double, arg4: Bool, arg5: Int, arg6: String) -> Void
        """
        let expected: String = """
        func myFunction(
            arg1: Int,
            arg2: String,
            arg3: Double,
            arg4: Bool,
            arg5: Int,
            arg6: String
        ) -> Void
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 30) == expected + "\n")
    }
    @Test static func FunctionType() throws {
        let input: String = """
        let f: (Int, String, Double, Double, Double, Double) -> ()
        """
        let expected: String = """
        let f: (
            Int,
            String,
            Double,
            Double,
            Double,
            Double
        ) -> ()
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 30) == expected + "\n")
    }

    @Test static func InstanceFunction() throws {
        let input: String = """
        struct S {
            func foo(arg1: Int, arg2: String, arg3: Double, arg4: Bool, arg5: Int) -> Void {
                print("Hello, World!")
            }
        }
        """
        let expected: String = """
        struct S {
            func foo(
                arg1: Int,
                arg2: String,
                arg3: Double,
                arg4: Bool,
                arg5: Int
            ) -> Void {
                print("Hello, World!")
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func IfLet() throws {
        let input: String = """
        // This line is too long

        if  let users = fetchUsers(from: "production", sortedBy: "lastName") {
            print(users)
        }
        """
        let expected: String = """
        // This line is too long

        if  let users = fetchUsers(
                from: "production",
                sortedBy: "lastName"
            ) {
            print(users)
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func IfLetElseLet() throws {
        let input: String = """
        // This line is too long

        if let users = fetchUsers(from: "production", sortedBy: "lastName") {
            print(users)
        } else if let users = fetchUsers(from: "production", sortedBy: "lastName") {
            print(users)
        } else {
            print("No users found")
        }
        """
        let expected: String = """
        // This line is too long

        if let users = fetchUsers(
                from: "production",
                sortedBy: "lastName"
            ) {
            print(users)
        } else if let users = fetchUsers(
                from: "production",
                sortedBy: "lastName"
            ) {
            print(users)
        } else {
            print("No users found")
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func WhileLoopBodyIndentation() throws {
        let input: String = """
        while i < 10 {
            myFunction(arg1: 1, arg2: 2, arg3: 3, arg4: 4, arg5: 5, arg6: 6, arg7: 7, arg8: 8)
        }
        """
        let expected: String = """
        while i < 10 {
            myFunction(
                arg1: 1,
                arg2: 2,
                arg3: 3,
                arg4: 4,
                arg5: 5,
                arg6: 6,
                arg7: 7,
                arg8: 8
            )
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 80) == expected + "\n")
    }

    @Test static func Attribute() throws {
        let input: String = """
        @MacroWithVeryLongName(foo: "foo", bar: "bar", baz: "baz", quux: "quux") public enum E {
            case a
            case b
        }
        """
        let expected: String = """
        @MacroWithVeryLongName(
            foo: "foo",
            bar: "bar",
            baz: "baz",
            quux: "quux"
        ) public enum E {
            case a
            case b
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }
    @Test static func AttributeWrappingDisabled() throws {
        ///                                     | +40
        let input: String = """
        @inline(__always) enum BlahBlahBlahBlahBlah {
            case a
            case b
        }
        """
        let expected: String = """
        @inline(__always) enum BlahBlahBlahBlahBlah {
            case a
            case b
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func Parentheses() throws {
        let input: String = """
        let x: Int = (foo + bar + baz - qux) * (foo - bar + baz + qux)
        """

        let expected: String = """
        let x: Int = (
            foo + bar + baz - qux
        ) * (
            foo - bar + baz + qux
        )
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 24) == expected + "\n")
    }

    @Test static func GenericArguments() throws {
        let input: String = """
        func f(
            x: TypeName<Generic<VeryLongTypeName>, Generic<AnotherVeryLongTypeName>>
        )
        """
        let expected: String = """
        func f(
            x: TypeName<
                Generic<VeryLongTypeName>,
                Generic<AnotherVeryLongTypeName>
            >
        )
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func GenericWhereClause() throws {
        let input: String = """
        func f<T>(
            x: TypeName<Generic<T>, Generic<AVeryLongTypeName>>
        ) -> Int where Generic<T>: Protocol, T: AnotherProtocolWithLongName {
        }
        """
        let expected: String = """
        func f<T>(
            x: TypeName<
                Generic<T>,
                Generic<AVeryLongTypeName>
            >
        ) -> Int where Generic<T>: Protocol,
            T: AnotherProtocolWithLongName {
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }

    @Test static func StringLiteralLeadingWhitespace() throws {
        let input: String = """
        let x: String = "    foo"
        """
        let expected: String = #"""
        let x: String = """
            foo
        """
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 22) == expected + "\n")
    }
    @Test static func StringLiteralTrailingWhitespace() throws {
        let input: String = """
        let x: String = "foo    "
        """
        let expected: String = #"""
        let x: String = """
        foo   \u{20}
        """
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 22) == expected + "\n")
    }

    @Test static func StringLiteralOfWhitespace() throws {
        let input: String = """
        let x: String = "         "
        """
        let expected: String = #"""
        let x: String = """
                \u{20}
        """
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 22) == expected + "\n")
    }
    @Test static func StringLiteralWithPoundDelimiters() throws {
        /// We should leave these alone
        let input: String = """
        let x: String = #"         "#
        """
        let expected: String = """
        let x: String = #"         "#
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 22) == expected + "\n")
    }
    @Test static func StringWithMultilineInterpolation() throws {
        /// This should break the closure, not the subscript arguments
        ///                                                      | +60
        let input: String = #"""
        func f(i: Int) {
            let string: String = """
            blah blah blah blah blah blah blah blah blah \(bar[at: i]) blah blah
            """
        }
        """#
        ///                                                      | +60
        let expected: String = #"""
        func f(i: Int) {
            let string: String = """
            blah blah blah blah blah blah blah blah blah \(
                bar[at: i]
            ) blah blah
            """
        }
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }

    @Test static func OutOfOrderLinebreaking() throws {
        /// We should leave these alone
        let input: String = #"""
        var now: BenchmarkClock.Instant {
            return .init(_value: Duration(secondsComponent: Int64(seconds),
                                            attosecondsComponent: Int64(attoseconds)))
        }
        """#
        let expected: String = #"""
        var now: BenchmarkClock.Instant {
            return .init(
                _value: Duration(
                    secondsComponent: Int64(seconds),
                    attosecondsComponent: Int64(attoseconds)
                )
            )
        }
        """#

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }

    @Test static func NonGreedyFunctionSignature() throws {
        /// This should break the arguments, even though they do not overflow the line length
        ///                                                      | +60
        let input: String = """
        extension S {
            func function(x: [Unicode.Scalar: String]) -> Unicode.Scalar {
                "x"
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        extension S {
            func function(
                x: [Unicode.Scalar: String]
            ) -> Unicode.Scalar {
                "x"
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func NonGreedyFunctionGenericReturn() throws {
        /// This should break the arguments, even though they do not overflow the line length
        ///                                                      | +60
        let input: String = """
        extension S {
            func function(x: [Int: String]) -> Result<Unicode.Scalar, any Error> {
                "x"
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        extension S {
            func function(
                x: [Int: String]
            ) -> Result<Unicode.Scalar, any Error> {
                "x"
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func NonGreedySubscriptAssignment() throws {
        /// This should break the closure, not the string literal
        ///                                                      | +60
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["foo"] { "blah blah blah blah blah" } = "blah blah blah blah blah"
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["foo"] {
                    "blah blah blah blah blah"
                } = "blah blah blah blah blah"
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func NonGreedySubscriptArguments() throws {
        /// This should break the arguments, not the string literal
        ///                                                      | +60
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["blah blah blah blah blah"] = "blah blah blah blah blah"
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0[
                    "blah blah blah blah blah"
                ] = "blah blah blah blah blah"
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func NonGreedySubscriptPriority() throws {
        /// This should break the closure, not the subscript arguments
        ///                                                      | +60
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["blah blah blah blah blah"] { "blah blah blah blah blah" } = "blah blah blah"
            }
        }
        """
        ///                                                      | +60
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["blah blah blah blah blah"] {
                    "blah blah blah blah blah"
                } = "blah blah blah"
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 60) == expected + "\n")
    }
    @Test static func Atomics() throws {
        ///                                     | +40
        let input: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0["blah blah blah blah blah"] = ()
                $0["blah blah blah blah blah"] = []
                $0["blah blah blah blah blah"] = [:]
                $0["blah blah blah blah blah"] = ""
            }
        }
        """
        ///                                     | +40
        let expected: String = """
        func encode(to encoder: inout Encoder) {
            encoder {
                $0[
                    "blah blah blah blah blah"
                ] = ()
                $0[
                    "blah blah blah blah blah"
                ] = []
                $0[
                    "blah blah blah blah blah"
                ] = [:]
                $0[
                    "blah blah blah blah blah"
                ] = ""
            }
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }
    @Test static func ClosureParameterClause() throws {
        ///                                     | +40
        let input: String = """
        foo { (count: Int, isEnabled: Bool) in print(count) }
        foo { (veryLongCount: Int, isEnabled: Bool) in print(veryLongCount) }
        """
        ///                                     | +40
        let expected: String = """
        foo { (count: Int, isEnabled: Bool) in
            print(count)
        }
        foo { (
                veryLongCount: Int,
                isEnabled: Bool
            ) in
            print(veryLongCount)
        }
        """

        try #expect(WhitespaceFormatter.reformat(input, width: 40) == expected + "\n")
    }
}
