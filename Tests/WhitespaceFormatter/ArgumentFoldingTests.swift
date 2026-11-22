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
    private static func format(_ input: consuming String) throws -> String {
        let formatter: WhitespaceFormatter = .init { $0.foldArguments = true }
        var input: String = input
        try formatter.reformat(&input)
        return input
    }
}
