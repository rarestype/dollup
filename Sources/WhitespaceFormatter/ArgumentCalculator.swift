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
           !node.expression.isTernaryRun {
            self.movable[node.expression.positionAfterSkippingLeadingTrivia] = true
        }
        if  let trailingComma: TokenSyntax = node.trailingComma,
               !trailingComma.lacksPrecedingNewline {
            self.movable[trailingComma.positionAfterSkippingLeadingTrivia] = false
        }

        return .visitChildren
    }
    override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        guard
        let first: TokenSyntax = node.value.firstToken(viewMode: .sourceAccurate),
            first.leadingTrivia.containsNewlines else {
            return .visitChildren
        }
        switch first.tokenKind {
        case .leftSquare, .leftParen, .leftBrace, .multilineStringQuote, .rawStringPoundDelimiter:
            // a value that starts with a bracket or a multiline string that spans lines is left
            // to the brace style
            if  node.value.containsInteriorNewlines {
                return .visitChildren
            }
        default:
            break
        }
        // a value moves up onto the line of its `=` if the joined line fits, or if the line
        // wrapper can make room for it by breaking brackets
        if  self.fits(joining: node) || node.annotationMakesRoom || node.value.makesRoom {
            self.movable[first.positionAfterSkippingLeadingTrivia] = true
        }
        return .visitChildren
    }
}
extension ArgumentCalculator {
    private func fits(joining node: InitializerClauseSyntax) -> Bool {
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

        let joined: Int = self.text[start ..< equal].count + 1 + self.text[value ..< end].count
        return joined <= self.width
    }
}
