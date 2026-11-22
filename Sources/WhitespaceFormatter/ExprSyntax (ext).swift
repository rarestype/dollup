import SwiftSyntax

extension ExprSyntax {
    /// Whether this is a run of ternaries, `a ? x :` / `b ? y :` / `c ? z : w`, with each arm
    /// after the first starting a new line right after the `:` that precedes it. Effect markers
    /// (`try`, `await`, `unsafe`) may start the arms only if every arm starts with the same
    /// ones, since otherwise the arms cannot align.
    var isTernaryRun: Bool {
        let (markers, first): ([String], ExprSyntax) = self.effectMarkers
        guard
        var link: TernaryExprSyntax = first.as(TernaryExprSyntax.self) else {
            return false
        }
        var chained: Bool = false
        while true {
            let (next, arm): ([String], ExprSyntax) = link.elseExpression.effectMarkers
            guard
            let arm: TernaryExprSyntax = arm.as(TernaryExprSyntax.self) else {
                return chained
            }
            if  link.colon.leadingTrivia.containsNewlines ||
                link.elseExpression.lacksPrecedingNewline ||
                next != markers {
                return false
            }
            chained = true
            link = arm
        }
    }
    /// Whether this is a run of operators, `a * b +` / `c * d`, which breaks lines only right
    /// after its infix operators, and does so at least once. Effect markers (`try`, `await`,
    /// `unsafe`) may start the run.
    ///
    /// The run is defined by where its lines break, not by how its operators group, since the
    /// grouping comes from an operator table that does not know operators declared in other
    /// files.
    var isOperatorRun: Bool {
        let (_, expression): ([String], ExprSyntax) = self.effectMarkers
        return Self.isOperatorRun(expression.infixSequence[...])
    }
    /// Whether this is a run of ternaries or a run of operators, whose lines align with each
    /// other.
    var isRun: Bool {
        self.isTernaryRun || self.isOperatorRun
    }
    /// The operands and operators of this sequence of infix operators, alternating, in source
    /// order. Source order survives any grouping, including the left-to-right grouping the
    /// operator table falls back to around an operator it does not know.
    var infixSequence: [ExprSyntax] {
        var sequence: [ExprSyntax] = []
        self.append(to: &sequence)
        return sequence
    }
    private func append(to sequence: inout [ExprSyntax]) {
        if  let infix: InfixOperatorExprSyntax = self.as(InfixOperatorExprSyntax.self) {
            infix.leftOperand.append(to: &sequence)
            sequence.append(infix.operator)
            infix.rightOperand.append(to: &sequence)
        } else {
            sequence.append(self)
        }
    }
    /// Whether the alternating operands and operators are a run of operators: at least one
    /// operator, none of which starts a line, and at least one operand that does.
    static func isOperatorRun(_ sequence: ArraySlice<ExprSyntax>) -> Bool {
        var broken: Bool = false
        for i: Int in stride(from: sequence.startIndex + 1, to: sequence.endIndex, by: 2) {
            if !sequence[i].lacksPrecedingNewline {
                return false
            }
            if !sequence[i + 1].lacksPrecedingNewline {
                broken = true
            }
        }
        return broken
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
