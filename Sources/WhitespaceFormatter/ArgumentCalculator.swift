import SwiftSyntax

final class ArgumentCalculator: SyntaxVisitor {
    private(set) var movable: [AbsolutePosition: Bool]

    init() {
        self.movable = [:]
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
}
