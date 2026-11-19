import SwiftSyntax

extension SyntaxProtocol {
    func containsInteriorNewlines(between delimiter: (TokenSyntax, TokenSyntax)) -> Bool {
        let tokens: TokenSequence = self.tokens(viewMode: .sourceAccurate)
        for token: TokenSyntax in tokens {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return delimiter.1.leadingTrivia.containsNewlines
    }
    var containsPrecedingOrInteriorNewlines: Bool {
        for token: TokenSyntax in self.tokens(viewMode: .sourceAccurate) {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return false
    }
    var containsInteriorNewlines: Bool {
        var tokens: TokenSequence.Iterator = self.tokens(
            viewMode: .sourceAccurate
        ).makeIterator()
        if  let first: TokenSyntax = tokens.next(),
                first.trailingTrivia.containsNewlines {
            return true
        }
        while let token: TokenSyntax = tokens.next() {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return false
    }
    var lacksPrecedingNewline: Bool {
        !self.leadingTrivia.containsNewlines
    }

    var withoutTrailingSpaces: Self {
        self.with(\.trailingTrivia, self.trailingTrivia.withoutTrailingSpaces)
    }

    /// Only declarations and loop bodies fold empty `{}` blocks onto a single line;
    /// conditional (`if`, `else`, `guard`), `do`/`catch`, `defer`, and closure blocks
    /// stay expanded across lines when written with a newline.
    var foldsEmpty: Bool {
        switch self.kind {
        case .accessorBlock: true
        case .memberBlock: true
        case .precedenceGroupDecl: true
        case .codeBlock:
            switch self.parent?.kind {
            case .accessorDecl: true
            case .deinitializerDecl: true
            case .forStmt: true
            case .functionDecl: true
            case .initializerDecl: true
            case .macroDecl: true
            case .repeatStmt: true
            case .whileStmt: true
            default: false
            }
        default: false
        }
    }
}
extension ExprSyntax {
    /// Whether this is a run of ternaries, `a ? x :` / `b ? y :` / `c ? z : w`, with each arm
    /// after the first starting a new line right after the `:` that precedes it. Effect markers
    /// (`try`, `await`, `unsafe`) may start the arms only if every arm starts with the same
    /// ones, since otherwise the arms cannot align.
    var isTernaryRun: Bool {
        let (markers, first): ([String], ExprSyntax) = self.effectMarkers
        guard
        let node: TernaryExprSyntax = first.as(TernaryExprSyntax.self),
        case _? = node.elseExpression.effectMarkers.expression.as(TernaryExprSyntax.self) else {
            return false
        }
        var link: TernaryExprSyntax = node
        while true {
            let (next, arm): ([String], ExprSyntax) = link.elseExpression.effectMarkers
            guard let arm: TernaryExprSyntax = arm.as(TernaryExprSyntax.self) else {
                return true
            }
            if  link.colon.leadingTrivia.containsNewlines ||
                link.elseExpression.lacksPrecedingNewline ||
                next != markers {
                return false
            }
            link = arm
        }
    }
    /// The `try`, `await`, and `unsafe` markers in front of this expression, in order, and the
    /// expression they apply to.
    private var effectMarkers: (markers: [String], expression: ExprSyntax) {
        var markers: [String] = []
        var expression: ExprSyntax = self
        while true {
            if  let node: TryExprSyntax = expression.as(TryExprSyntax.self) {
                markers.append("try\(node.questionOrExclamationMark?.text ?? "")")
                expression = node.expression
            } else if
                let node: AwaitExprSyntax = expression.as(AwaitExprSyntax.self) {
                markers.append("await")
                expression = node.expression
            } else if
                let node: UnsafeExprSyntax = expression.as(UnsafeExprSyntax.self) {
                markers.append("unsafe")
                expression = node.expression
            } else {
                return (markers, expression)
            }
        }
    }
}
