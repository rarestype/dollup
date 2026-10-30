import SwiftSyntax

struct BracketAligner {
    private let brackets: [AbsolutePosition: BracketSide]
    private let style: BraceStyle

    init(style: BraceStyle, brackets: [AbsolutePosition: BracketSide]) {
        self.brackets = brackets
        self.style = style
    }

}
extension BracketAligner: VerticalFolder {
    var separator: TriviaPiece { self.style.before }

    func fold(_ node: TokenSyntax) -> Bool? {
        switch node.tokenKind {
        case .leftBrace: self.foldAsOpening(node: node)
        case .rightBrace: self.foldAsClosing(node: node)
        case .leftSquare: self.foldAsOpening(node: node)
        case .leftParen: self.foldAsOpening(node: node)
        case .multilineStringQuote: self.foldAsOpening(node: node)
        case .rawStringPoundDelimiter: self.foldAsOpening(node: node)
        case .keyword(.else): self.foldAsBridging(node: node)
        case .keyword(.catch): self.foldAsBridging(node: node)
        case .keyword(.while): self.foldAsBridging(node: node)
        case .identifier: self.foldAsBridging(node: node)
        default: nil
        }
    }
}
extension BracketAligner {
    private func foldAsOpening(node: TokenSyntax) -> Bool? {
        if  case .opening? = self.brackets[node.positionAfterSkippingLeadingTrivia] {
            return true
        } else {
            return nil
        }
    }
    private func foldAsBridging(node: TokenSyntax) -> Bool? {
        if  case .bridging? = self.brackets[node.positionAfterSkippingLeadingTrivia] {
            return true
        } else {
            return nil
        }
    }
    private func foldAsClosing(node: TokenSyntax) -> Bool? {
        if  case .closing? = self.brackets[node.positionAfterSkippingLeadingTrivia] {
            return false
        } else {
            return nil
        }
    }
}
