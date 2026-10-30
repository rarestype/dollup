import SwiftDiagnostics
import SwiftSyntax

final class BracketCalculator: SyntaxVisitor {
    private var matched: [AbsolutePosition: BracketSide]
    private var errored: MismatchError?

    private let style: BraceStyle
    private var stack: [Scope]
    private var line: UInt

    init(style: BraceStyle) {
        self.matched = [:]
        self.errored = nil

        self.style = style
        self.stack = []
        self.line = 0
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        guard case .multilineStringQuote = node.openingQuote.tokenKind else {
            return .visitChildren
        }

        self.skip((node.openingPounds ?? node.openingQuote).leadingTrivia)
        self.push(node.openingPounds ?? node.openingQuote, type: .quotes)
        self.skip(node.openingQuote.trailingTrivia)

        self.walk(node.segments)

        self.skip(node.closingQuote.leadingTrivia)
        self.pop(node.closingQuote, type: .quotes)
        self.skip(node.closingQuote.trailingTrivia)

        return .skipChildren
    }

    override func visit(
        _ node: MultipleTrailingClosureElementSyntax
    ) -> SyntaxVisitorContinueKind {
        self.matched[node.label.positionAfterSkippingLeadingTrivia] = .bridging
        return .visitChildren
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        if  let elseKeyword: TokenSyntax = node.elseKeyword {
            self.matched[elseKeyword.positionAfterSkippingLeadingTrivia] = .bridging
        }
        return .visitChildren
    }
    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        for catchClause: CatchClauseSyntax in node.catchClauses {
            let catchKeyword: TokenSyntax = catchClause.catchKeyword
            self.matched[catchKeyword.positionAfterSkippingLeadingTrivia] = .bridging
        }
        return .visitChildren
    }
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        self.matched[node.elseKeyword.positionAfterSkippingLeadingTrivia] = .bridging
        return .visitChildren
    }
    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        self.matched[node.whileKeyword.positionAfterSkippingLeadingTrivia] = .bridging
        return .visitChildren
    }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        self.skip(token.leadingTrivia)

        switch token.tokenKind {
        case .leftBrace:
            self.push(token, type: .brace)
        case .leftSquare:
            self.push(token, type: .square)
        case .leftParen:
            self.push(token, type: .parenthesis)

        case .rightBrace:
            self.pop(token, type: .brace)
        case .rightSquare:
            self.pop(token, type: .square)
        case .rightParen:
            self.pop(token, type: .parenthesis)
        default:
            if  let last: Int = self.stack.indices.last {
                self.stack[last].empty = false
            }
        }

        self.skip(token.trailingTrivia)
        return .skipChildren
    }
}
extension BracketCalculator {
    var brackets: [AbsolutePosition: BracketSide] {
        get throws {
            if  let error: MismatchError = self.errored {
                throw error
            } else {
                return self.matched
            }
        }
    }
}
extension BracketCalculator {
    /// Despite official documentation, newlines can and do appear in trailing trivia.
    /// One example is the trailing newline after a multiline opening string quote.
    private func skip(_ trivia: Trivia) {
        for piece: TriviaPiece in trivia {
            // we don’t care about absolute line numbers, we just want to know if we crossed
            // a line boundary
            switch piece {
            case .carriageReturnLineFeeds: self.line += 1
            case .newlines: self.line += 1
            default: continue
            }
        }
    }
    private func push(_ token: TokenSyntax, type: BracketType) {
        guard case nil = self.errored else {
            return
        }

        var element: Syntax? = token.parent

        while let parent: Syntax = element?.parent, !parent.kind.isSyntaxCollection {
            element = parent
        }

        let position: AbsolutePosition = token.positionAfterSkippingLeadingTrivia
        let soft: Bool

        if case position? = element?.positionAfterSkippingLeadingTrivia {
            soft = false
        } else {
            soft = self.style.moves(type)
        }

        if  let last: Int = self.stack.indices.last {
            self.stack[last].empty = false
        }

        self.stack.append(
            .init(
                type: type,
                soft: soft,
                line: self.line,
                open: token,
                empty: true
            )
        )
    }
    private func pop(_ token: TokenSyntax, type: BracketType) {
        guard case nil = self.errored,
        let scope: Scope = self.stack.popLast() else {
            return
        }

        if  scope.type != type {
            self.errored = .init(
                expected: scope.type,
                found: type,
                token: token
            )
            return
        }

        let position: AbsolutePosition = token.positionAfterSkippingLeadingTrivia

        if  scope.soft, scope.line < self.line {
            // delimiters are movable if they are on a different line
            // than their opening delimiter
            self.matched[scope.open.positionAfterSkippingLeadingTrivia] = .opening
            if  case .egyptian = self.style,
                case .brace = type,
                scope.empty,
                Self.foldsEmpty(token),
                scope.open.trailingTrivia.isWhitespace,
                token.leadingTrivia.isWhitespace {
                self.matched[position] = .closing
            }
        }
    }

    private static func foldsEmpty(_ token: TokenSyntax) -> Bool {
        guard let parent: Syntax = token.parent else {
            return false
        }
        switch parent.kind {
        case .accessorBlock, .memberBlock, .precedenceGroupDecl:
            return true
        case .codeBlock:
            switch parent.parent?.kind {
            case .accessorDecl,
                .deinitializerDecl,
                .forStmt,
                .functionDecl,
                .initializerDecl,
                .macroDecl,
                .repeatStmt,
                .whileStmt:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
