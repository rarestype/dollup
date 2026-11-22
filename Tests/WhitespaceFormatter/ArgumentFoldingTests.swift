import Testing
import WhitespaceFormatter

@Suite struct ArgumentFoldingTests {
    @Test static func Labeled() throws {
        let input: String = """
        public struct Foo {
            func foo() {
                self.f(
                    x:
                    xValue
                    ,
                    y:
                    yValue
                    ,
                )
            }
        }
        """
        let expected: String = """
        public struct Foo {
            func foo() {
                self.f(
                    x: xValue,
                    y: yValue,
                )
            }
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func Unlabeled() throws {
        let input: String = """
        public struct Foo {
            func foo() {
                self.f(
                    xValue
                    ,
                    yValue
                    ,
                )
            }
        }
        """
        let expected: String = """
        public struct Foo {
            func foo() {
                self.f(
                    xValue,
                    yValue,
                )
            }
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func TernaryRun() throws {
        let input: String = """
        f(
        x: a ? .up :
        b ? .down : nil,
        y:
        c ? .up :
        d ? .down : nil,
        z: try p(a) ? .up :
        try p(b) ? .down : nil,
        )
        """
        let expected: String = """
        f(
            x:
                a ? .up :
                b ? .down : nil,
            y:
                c ? .up :
                d ? .down : nil,
            z:
                try p(a) ? .up :
                try p(b) ? .down : nil,
        )
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func OperatorRun() throws {
        let input: String = """
        f(
        x: a * b +
        c * d,
        y: a <> b +
        c,
        z: a + b
        )
        """
        let expected: String = """
        f(
            x:
                a * b +
                c * d,
            y:
                a <> b +
                c,
            z: a + b
        )
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func RunsAfterEqual() throws {
        let input: String = """
        let a: Direction? = p ? .up :
        q ? .down : nil
        let b: Int = a * b +
        c * d
        self.c = a * b +
        c * d
        y = a <- b +
        c
        k += a +
        b
        let d: Int = a ?? try b +
        c
        let e: Double = a * b +
        c * d as Double
        let f: Int = a +
        try b
        * c
        let lead: Int = a
        + b
        func f() -> Int {
        return a +
        b
        }
        """
        let expected: String = """
        let a: Direction? =
            p ? .up :
            q ? .down : nil
        let b: Int =
            a * b +
            c * d
        self.c =
            a * b +
            c * d
        y =
            a <- b +
            c
        k += a +
        b
        let d: Int =
            a ?? try b +
            c
        let e: Double =
            a * b +
            c * d as Double
        let f: Int = a +
        try b
            * c
        let lead: Int = a
            + b
        func f() -> Int {
            return a +
            b
        }
        """

        #expect(try self.format(input) == expected + "\n")
    }
    @Test static func TernaryRunPulledUp() throws {
        let input: String = """
        f(
            single:
                a ? .up :
                nil,
            partial:
                a ? .up : b ? .down :
                c ? .left : nil,
            leading:
                a ? .up
                : b ? .down
                : nil,
            effects:
                try p(a) ? .up :
                p(b) ? .down : nil,
        )
        """
        let expected: String = """
        f(
            single: a ? .up :
            nil,
            partial: a ? .up : b ? .down :
            c ? .left : nil,
            leading: a ? .up
                : b ? .down
                : nil,
            effects: try p(a) ? .up :
            p(b) ? .down : nil,
        )
        """

        #expect(try self.format(input) == expected + "\n")
    }
}
extension ArgumentFoldingTests {
    private static func format(
        _ input: consuming String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.foldArguments = true }
        return try formatter.reformat(input, sourceLocation: sourceLocation)
    }
}
