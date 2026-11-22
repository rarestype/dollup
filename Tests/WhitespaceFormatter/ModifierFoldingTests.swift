import Testing
import WhitespaceFormatter

@Suite struct ModifierFoldingTests {
    @Test static func ModifiersOnly() throws {
        let input: String = """
        public
        struct Foo {
            private
            static func bar() {}
        }
        """
        let expected: String = """
        public struct Foo {
            private static func bar() {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func ModifiersWithAttributes() throws {
        let input: String = """
        @frozen
        public
        struct Foo {
            @inlinable
            public
            static func bar() {}
        }
        """
        let expected: String = """
        @frozen public struct Foo {
            @inlinable public static func bar() {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func EffectsSpecifiers() throws {
        let input: String = """
        public struct Foo {
            @inlinable
            public
            static func bar()
                async throws {}

            public
            subscript(index: Int) -> Int {
                get
                async throws { 0 }
            }
            public internal(set)
            subscript(index: Int) -> String {
                get { 0 }

                @inlinable
                set(value) {}
            }
        }
        """
        let expected: String = """
        public struct Foo {
            @inlinable public static func bar() async throws {}

            public subscript(index: Int) -> Int {
                get async throws { 0 }
            }
            public internal(set) subscript(index: Int) -> String {
                get { 0 }

                @inlinable set(value) {}
            }
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func MultipleAttributes() throws {
        let input: String = """
        public struct Foo {
            @available(*, deprecated)
            @inline(__always)
            @inlinable
            public
            static func foo() async throws {}
        }
        """
        let expected: String = """
        public struct Foo {
            @available(*, deprecated)
            @inline(__always) @inlinable public static func foo() async throws {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func LongAttributes() throws {
        let input: String = """
        public struct Foo {
            @available(*, unavailable, message: "Use `foo()` instead", renamed: "foo")
            public
            static func bar() async throws {}

            @inline(__always)
            func baz() {}

            @CustomMacro(a: "blah blah", b: "blah blah", c: "blah", d: "blah")
            public
            static func qux() {}
        }
        """
        let expected: String = """
        public struct Foo {
            @available(*, unavailable, message: "Use `foo()` instead", renamed: "foo")
            public static func bar() async throws {}

            @inline(__always) func baz() {}

            @CustomMacro(a: "blah blah", b: "blah blah", c: "blah", d: "blah")
            public static func qux() {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func BrokenAttributes() throws {
        let input: String = """
        @CustomMacro(
            foo: "blah",
            bar: "blah",
        )
        public struct Foo {
            @CustomMacro(
                foo: "blah",
                bar: "blah",
            )
            public func foo() {}
        }
        """
        let expected: String = """
        @CustomMacro(
            foo: "blah",
            bar: "blah",
        ) public struct Foo {
            @CustomMacro(
                foo: "blah",
                bar: "blah",
            ) public func foo() {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func ConditionalAttributes() throws {
        let input: String = """
        #if os(macOS) || os(iOS)
        @Observable
        #endif
        @MainActor
        public final class Observable {
            init() {}
        }
        """
        let expected: String = """
        #if os(macOS) || os(iOS)
        @Observable
        #endif
        @MainActor public final class Observable {
            init() {}
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func ConditionalAttributesAfterFoldableAttribute() throws {
        let input: String = """
        @inlinable
        #if os(macOS)
        @available(*, unavailable)
        #endif
        public func foo() {}
        """
        let expected: String = """
        @inlinable
        #if os(macOS)
        @available(*, unavailable)
        #endif
        public func foo() {}
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func WrappedAttribute() throws {
        let input: String = """
        @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, visionOS 1, \
        message: "use the other one, please")
        public func f() {}
        """
        let expected: String = """
        @available(
            iOS 13, macOS 10.15, tvOS 13, watchOS 6, visionOS 1, \
        message: "use the other one, please"
        ) public func f() {}
        """

        #expect(try self.format(input) == expected + "\n")
    }
}
extension ModifierFoldingTests {
    private static func format(
        _ input: consuming String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.foldKeywords = true }
        return try formatter.reformat(input, sourceLocation: sourceLocation)
    }
}
