import Testing
import WhitespaceFormatter

@Suite struct BraceStyleTests {
    @Test static func Inline() throws {
        let input: String = """
        let x: [Int] = y.map { $0 + 1 }
        """
        let egyptian: String = """
        let x: [Int] = y.map { $0 + 1 }
        """
        let allman: String = """
        let x: [Int] = y.map { $0 + 1 }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func RepeatWhile() throws {
        let input: String = """
        if condition {
            foo()
        }
        while condition {
            bar()
        }
        repeat {
            baz()
        } while condition
        repeat {
            baz()
        }
        while condition
        """
        let egyptian: String = """
        if condition {
            foo()
        }
        while condition {
            bar()
        }
        repeat {
            baz()
        } while condition
        repeat {
            baz()
        } while condition
        """
        let allman: String = """
        if condition
        {
            foo()
        }
        while condition
        {
            bar()
        }
        repeat
        {
            baz()
        }
        while condition
        repeat
        {
            baz()
        }
        while condition
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func DoCatch() throws {
        let input: String = """
        do {
        }
        do {
        } catch {
        }
        do
        {
        }
        catch
        {
        }
        catch
        {
        }
        """
        let egyptian: String = """
        do {
        }
        do {
        } catch {
        }
        do {
        } catch {
        } catch {
        }
        """
        let allman: String = """
        do
        {
        }
        do
        {
        }
        catch
        {
        }
        do
        {
        }
        catch
        {
        }
        catch
        {
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func GuardElse() throws {
        let input: String = """
        guard condition else {
            return foo()
        }
        guard condition
        else {
            return foo()
        }
        """
        let egyptian: String = """
        guard condition else {
            return foo()
        }
        guard condition else {
            return foo()
        }
        """
        let allman: String = """
        guard condition
        else
        {
            return foo()
        }
        guard condition
        else
        {
            return foo()
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func IfElse() throws {
        let input: String = """
        if condition {
            foo()
        }
            else {
            bar()
        }
        """
        let egyptian: String = """
        if condition {
            foo()
        } else {
            bar()
        }
        """
        let allman: String = """
        if condition
        {
            foo()
        }
        else
        {
            bar()
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func TrailingClosures() throws {
        let input: String = """
        foo() {
        } bar: {
        } baz: {
        }
        foo()
        {
        }
        bar:
        {
        }
        baz:
        {
        }
        """
        let egyptian: String = """
        foo() {
        } bar: {
        } baz: {
        }
        foo() {
        } bar: {
        } baz: {
        }
        """
        let allman: String = """
        foo()
        {
        }
        bar:
        {
        }
        baz:
        {
        }
        foo()
        {
        }
        bar:
        {
        }
        baz:
        {
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func TernaryExpressions() throws {
        let input: String = #"""
        let a = condition ? """
        blah blah blah
        """ : """
        blah blah blah
        """
        let b = condition ?
        """
        blah blah blah
        """ :
        """
        blah blah blah
        """
        """#
        let egyptian: String = #"""
        let a = condition ? """
        blah blah blah
        """ : """
        blah blah blah
        """
        let b = condition ? """
        blah blah blah
        """ : """
        blah blah blah
        """
        """#
        let allman: String = #"""
        let a = condition ?
        """
        blah blah blah
        """ :
        """
        blah blah blah
        """
        let b = condition ?
        """
        blah blah blah
        """ :
        """
        blah blah blah
        """
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func Tuples() throws {
        let input: String = """
        let a:
        (
            x: Int,
            y: Int
        ) = (
            x: 1,
            y: 2
        )
        let b: (
            x: Int,
            y: Int
        ) =
        (
            x: 1,
            y: 2
        )
        let c: (
            x: Int,
            y: Int
        )?? =
        (
            x: 1,
            y: 2
        )
        """
        let egyptian: String = """
        let a: (
            x: Int,
            y: Int
        ) = (
            x: 1,
            y: 2
        )
        let b: (
            x: Int,
            y: Int
        ) = (
            x: 1,
            y: 2
        )
        let c: (
            x: Int,
            y: Int
        )?? = (
            x: 1,
            y: 2
        )
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
    }
    @Test static func StandingExpressions() throws {
        let input: String = """
        do {
            {
            } ()
        }
        """
        let egyptian: String = """
        do {
            {
            } ()
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
    }
    @Test static func Arrays() throws {
        let input: String = """
        let a: [Int] = [
            1,
            2
        ]
        let b: [Int] =
        [
            1,
            2
        ]
        """
        let egyptian: String = """
        let a: [Int] = [
            1,
            2
        ]
        let b: [Int] = [
            1,
            2
        ]
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
    }
    @Test static func Strings() throws {
        let input: String = #"""
        let z1: String = """
        multiline
        string
        """
        let z2: String =
        """
        multiline
        string
        """
        """#
        let egyptian: String = #"""
        let z1: String = """
        multiline
        string
        """
        let z2: String = """
        multiline
        string
        """
        """#
        let allman: String = #"""
        let z1: String =
        """
        multiline
        string
        """
        let z2: String =
        """
        multiline
        string
        """
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func StringsWithPounds() throws {
        let input: String = ##"""
        let z1: String = #"""
        multiline
        string
        """#
        let z2: String =
        #"""
        multiline
        string
        """#
        """##
        let egyptian: String = ##"""
        let z1: String = #"""
        multiline
        string
        """#
        let z2: String = #"""
        multiline
        string
        """#
        """##
        let allman: String = ##"""
        let z1: String =
        #"""
        multiline
        string
        """#
        let z2: String =
        #"""
        multiline
        string
        """#
        """##

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func StringsAsCodeBlockItems() throws {
        let input: String = #"""
        if condition {
            """
            blah blah blah
            """
        }
        else
        {   """
            blah blah blah
            """
        }
        """#
        let egyptian: String = #"""
        if condition {
            """
            blah blah blah
            """
        } else {
            """
            blah blah blah
            """
        }
        """#
        let allman: String = #"""
        if condition
        {
            """
            blah blah blah
            """
        }
        else
        {
            """
            blah blah blah
            """
        }
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func FunctionTypes() throws {
        let input: String = #"""
        let f: (
            (
                Int,
                Int
            )
        ) -> Int
        let g: (
            (
                Int,
                Int
            )??
        ) -> Int
        """#
        let egyptian: String = #"""
        let f: (
            (
                Int,
                Int
            )
        ) -> Int
        let g: (
            (
                Int,
                Int
            )??
        ) -> Int
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
    }
    @Test static func ArgumentsWithoutLabels() throws {
        let input: String = #"""
        try foo(
            (
                x: 1,
                y: 2
            ),
            (
                x: 3,
                y: 4
            ),
        )
        """#
        let egyptian: String = #"""
        try foo(
            (
                x: 1,
                y: 2
            ),
            (
                x: 3,
                y: 4
            ),
        )
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
    }
    @Test static func Delimiters() throws {
        let input: String = #"""
        if condition
        {
            foo(
                x: 1,
                y: 2
            )
        }
            else {
            bar[
                x: 1,
                y: 2
            ]

            let z1: String = """
            multiline
            string
            """
            let z2: String =
            """
            multiline
            string
            """
        }
        """#
        let egyptian: String = #"""
        if condition {
            foo(
                x: 1,
                y: 2
            )
        } else {
            bar[
                x: 1,
                y: 2
            ]

            let z1: String = """
            multiline
            string
            """
            let z2: String = """
            multiline
            string
            """
        }
        """#
        let allman: String = #"""
        if condition
        {
            foo(
                x: 1,
                y: 2
            )
        }
        else
        {
            bar[
                x: 1,
                y: 2
            ]

            let z1: String =
            """
            multiline
            string
            """
            let z2: String =
            """
            multiline
            string
            """
        }
        """#

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func LineComment() throws {
        let input: String = """
        struct Foo//:~Copyable
        {
        }
        """
        let egyptian: String = """
        struct Foo/*:~Copyable*/ {
        }
        """
        let allman: String = """
        struct Foo//:~Copyable
        {
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func LineCommentInjection() throws {
        let input: String = """
        struct Foo//:~Copyable*/bar
        {
        }
        """
        let egyptian: String = """
        struct Foo/*/*:~Copyable*/bar*/ {
        }
        """
        let allman: String = """
        struct Foo//:~Copyable*/bar
        {
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
    @Test static func ClosureParameterClause() throws {
        let input: String = """
        let render: (Int, Bool) -> Void = {
            (count: Int, isEnabled: Bool) in
            print(count, isEnabled)
        }
        foo {
            (
                x: Int,
                y: Int
            ) -> Bool in
            x == y
        }
        """
        let egyptian: String = """
        let render: (Int, Bool) -> Void = { (count: Int, isEnabled: Bool) in
            print(count, isEnabled)
        }
        foo { (
                x: Int,
                y: Int
            ) -> Bool in
            x == y
        }
        """
        let allman: String = """
        let render: (Int, Bool) -> Void =
        {
            (count: Int, isEnabled: Bool) in
            print(count, isEnabled)
        }
        foo
        {
            (
                x: Int,
                y: Int
            ) -> Bool in
            x == y
        }
        """

        #expect(try self.egyptian(input) == egyptian + "\n")
        #expect(try self.allman(input) == allman + "\n")
    }
}
extension BraceStyleTests {
    private static func egyptian(_ input: consuming String) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.braces = .egyptian }
        var input: String = input
        try formatter.reformat(&input, check: true)
        return input
    }
    private static func allman(_ input: consuming String) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.braces = .allman }
        var input: String = input
        try formatter.reformat(&input, check: true)
        return input
    }
}
