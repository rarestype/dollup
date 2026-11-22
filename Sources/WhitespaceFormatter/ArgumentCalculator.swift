import SwiftSyntax

final class ArgumentCalculator: SyntaxVisitor {
    private(set) var movable: [AbsolutePosition: Bool]
    /// The source text, used for measuring line lengths.
    private let text: String
    private let width: Int

    init(text: String, width: Int) {
        self.movable = [:]
        self.text = text
        self.width = width
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        if  let _: TokenSyntax = node.colon,
           !node.expression.lacksPrecedingNewline,
           !node.expression.isRun {
            self.movable[node.expression.positionAfterSkippingLeadingTrivia] = true
        }
        if  let trailingComma: TokenSyntax = node.trailingComma,
               !trailingComma.lacksPrecedingNewline {
            self.movable[trailingComma.positionAfterSkippingLeadingTrivia] = false
        }

        return .visitChildren
    }
    override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        // a comment after the `=` stays where it is, and a run of ternaries or operators stays
        // on lines of its own, so they align
        guard node.equal.trailingTrivia.isWhitespace,
        !node.value.isRun,
        let first: TokenSyntax = node.value.firstToken(viewMode: .sourceAccurate),
            first.leadingTrivia.containsNewlines else {
            return .visitChildren
        }
        switch first.tokenKind {
        case .leftSquare,
            .leftParen,
            .leftBrace,
            .multilineStringQuote,
            .rawStringPoundDelimiter:
            // a value that starts with a bracket or a multiline string that spans lines is left
            // to the brace style
            if  node.value.containsInteriorNewlines {
                return .visitChildren
            }
        default:
            break
        }

        let line: (indent: Int, declaration: Int, value: Int) = self.measure(node)
        // a value moves up onto the line of its `=` if the joined line fits, or if the line
        // wrapper can make room for it by breaking brackets: those of the value first, or
        // otherwise those of the annotation, after whose closing bracket the rest of the
        // annotation and the value would then have to fit, as in `) throws -> T = value`
        if  line.declaration + 1 + line.value <= self.width || node.value.makesRoom {
            self.movable[first.positionAfterSkippingLeadingTrivia] = true
        } else if
            let delimiter: TokenSyntax = node.annotationClosingDelimiter,
            line.indent + self.length(from: delimiter, through: node.equal) + 1 + line.value
                <= self.width {
            self.movable[first.positionAfterSkippingLeadingTrivia] = true
        }
        return .visitChildren
    }
}
extension ArgumentCalculator {
    /// Measures the source text from the start of one token through the end of another.
    private func length(from first: TokenSyntax, through last: TokenSyntax) -> Int {
        let utf8: String.UTF8View = self.text.utf8
        let start: String.Index = utf8.index(
            utf8.startIndex,
            offsetBy: first.positionAfterSkippingLeadingTrivia.utf8Offset
        )
        let end: String.Index = utf8.index(
            utf8.startIndex,
            offsetBy: last.endPositionBeforeTrailingTrivia.utf8Offset
        )
        return self.text[start ..< end].count
    }
    /// Measures the indentation of the line of the `=`, its length up to and including the
    /// `=`, and the length of the first line of the value.
    private func measure(
        _ node: InitializerClauseSyntax
    ) -> (indent: Int, declaration: Int, value: Int) {
        let utf8: String.UTF8View = self.text.utf8
        let equal: String.Index = utf8.index(
            utf8.startIndex,
            offsetBy: node.equal.endPositionBeforeTrailingTrivia.utf8Offset
        )
        let value: String.Index = utf8.index(
            utf8.startIndex,
            offsetBy: node.value.positionAfterSkippingLeadingTrivia.utf8Offset
        )
        let start: String.Index = self.text[..<equal].lastIndex(where: \.isNewline).map {
            self.text.index(after: $0)
        } ?? self.text.startIndex
        let end: String.Index = self.text[value...].firstIndex(where: \.isNewline)
            ?? self.text.endIndex

        let declaration: Substring = self.text[start ..< equal]
        return (
            indent: declaration.prefix(while: \.isWhitespace).count,
            declaration: declaration.count,
            value: self.text[value ..< end].count
        )
    }
}
