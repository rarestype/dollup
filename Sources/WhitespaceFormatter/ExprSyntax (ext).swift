import SwiftSyntax

extension ExprSyntax {
    /// Whether this is a run of ternaries, `a ? x :` / `b ? y :` / `c ? z : w`, with each arm
    /// after the first starting a new line right after the `:` that precedes it. Effect markers
    /// (`try`, `await`, `unsafe`) may start the arms only if every arm starts with the same
    /// ones, since otherwise the arms cannot align.
    var isTernaryRun: Bool {
        if  let sequence: SequenceExprSyntax = self.as(SequenceExprSyntax.self) {
            Self.isTernaryRun(sequence.elements)
        } else {
            false
        }
    }
    /// Whether these elements of an operator sequence, in source order, are a run of
    /// ternaries.
    static func isTernaryRun(_ elements: some Sequence<ExprSyntax>) -> Bool {
        /// The markers that start the first arm.
        var markers: [String]? = nil
        /// The colon of the ternary that ends the previous arm.
        var colon: TokenSyntax? = nil
        /// The first element of the current arm.
        var start: ExprSyntax? = nil
        var chained: Bool = false
        for element: ExprSyntax in elements {
            guard
            let ternary: UnresolvedTernaryExprSyntax = element.as(
                UnresolvedTernaryExprSyntax.self
            ) else {
                start = start ?? element
                continue
            }
            guard
            let first: ExprSyntax = start else {
                return false
            }
            let (next, _): ([String], ExprSyntax) = first.effectMarkers
            if  let colon: TokenSyntax {
                if  colon.leadingTrivia.containsNewlines ||
                    first.lacksPrecedingNewline ||
                    next != markers {
                    return false
                }
                chained = true
            } else {
                markers = next
            }
            colon = ternary.colon
            start = nil
        }
        return chained
    }
    /// Whether this is a run of operators, `a * b +` / `c * d`, which breaks lines only right
    /// after its binary operators, and does so at least once.
    var isOperatorRun: Bool {
        if  let sequence: SequenceExprSyntax = self.as(SequenceExprSyntax.self) {
            Self.isOperatorRun(sequence.elements)
        } else {
            false
        }
    }
    /// Whether this is a run of ternaries or a run of operators, whose lines align with each
    /// other.
    var isRun: Bool {
        self.isTernaryRun || self.isOperatorRun
    }
    /// Whether these elements of an operator sequence, in source order, are a run of
    /// operators.
    ///
    /// The run is defined by where its lines break, not by how its operators group, since the
    /// grouping would depend on operator declarations the formatter cannot see.
    static func isOperatorRun(_ elements: some Sequence<ExprSyntax>) -> Bool {
        var previous: ExprSyntax? = nil
        var broken: Bool = false
        for element: ExprSyntax in elements {
            defer {
                previous = element
            }
            guard
            let previous: ExprSyntax,
            !element.lacksPrecedingNewline else {
                continue
            }
            if  previous.is(BinaryOperatorExprSyntax.self) {
                broken = true
            } else {
                return false
            }
        }
        return broken
    }
    /// Whether these elements of an operator sequence, in source order, are a run of
    /// ternaries or a run of operators.
    static func isRun(_ elements: some Collection<ExprSyntax>) -> Bool {
        Self.isTernaryRun(elements) || Self.isOperatorRun(elements)
    }
    /// The `try`, `await`, and `unsafe` markers in front of this expression, in order, and the
    /// expression they apply to.
    private var effectMarkers: (markers: [String], expression: ExprSyntax) {
        var markers: [String] = []
        var expression: ExprSyntax = self
        while true {
            if  let `try`: TryExprSyntax = expression.as(TryExprSyntax.self) {
                markers.append("try\(`try`.questionOrExclamationMark?.text ?? "")")
                expression = `try`.expression
            } else if
                let `await`: AwaitExprSyntax = expression.as(AwaitExprSyntax.self) {
                markers.append("await")
                expression = `await`.expression
            } else if
                let unsafe: UnsafeExprSyntax = expression.as(UnsafeExprSyntax.self) {
                markers.append("unsafe")
                expression = unsafe.expression
            } else {
                return (markers, expression)
            }
        }
    }
}
extension ExprSyntax {
    /// Whether the line wrapper can break this expression at brackets of its own that are
    /// still on one line: a call, subscript, or macro expansion with arguments or a trailing
    /// closure, a non-empty array, dictionary, or tuple literal, or a closure that is not an
    /// empty `{}`, possibly marked with `try`, `await`, or `unsafe`.
    var makesRoom: Bool {
        switch self.as(ExprSyntaxEnum.self) {
        case .tryExpr(let expression):
            return expression.expression.makesRoom
        case .awaitExpr(let expression):
            return expression.expression.makesRoom
        case .unsafeExpr(let expression):
            return expression.expression.makesRoom
        case .functionCallExpr(let call):
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftParen, call.rightParen),
                trailingClosure: call.trailingClosure
            )
        case .subscriptCallExpr(let call):
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftSquare, call.rightSquare),
                trailingClosure: call.trailingClosure
            )
        case .macroExpansionExpr(let call):
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftParen, call.rightParen),
                trailingClosure: call.trailingClosure
            )
        case .arrayExpr(let literal):
            return !literal.elements.isEmpty && !literal.containsInteriorNewlines
        case .dictionaryExpr(let literal):
            if  case .elements = literal.content {
                return !literal.containsInteriorNewlines
            } else {
                return false
            }
        case .tupleExpr(let literal):
            return !literal.elements.isEmpty && !literal.containsInteriorNewlines
        case .closureExpr(let closure):
            return Self.makesRoom(closure: closure)
        default:
            return false
        }
    }

    private static func makesRoom(
        arguments: LabeledExprListSyntax,
        between delimiters: (TokenSyntax?, TokenSyntax?),
        trailingClosure: ClosureExprSyntax?
    ) -> Bool {
        if  let left: TokenSyntax = delimiters.0,
            let right: TokenSyntax = delimiters.1,
           !arguments.isEmpty,
           !arguments.containsInteriorNewlines(between: (left, right)) {
            return true
        }
        if  let closure: ClosureExprSyntax = trailingClosure {
            return Self.makesRoom(closure: closure)
        }
        return false
    }
    /// Whether the line wrapper can break a closure that is still on one line, which it
    /// cannot if the closure is an empty `{}`.
    private static func makesRoom(closure: ClosureExprSyntax) -> Bool {
        if  closure.statements.isEmpty,
            case nil = closure.signature {
            return false
        }
        return !closure.containsInteriorNewlines
    }
}
