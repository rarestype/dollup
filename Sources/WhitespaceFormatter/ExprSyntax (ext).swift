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
    /// closure, a non-empty array, dictionary, or tuple literal, or a closure, possibly marked
    /// with `try` or `await`.
    var makesRoom: Bool {
        if  let expression: TryExprSyntax = self.as(TryExprSyntax.self) {
            return expression.expression.makesRoom
        }
        if  let expression: AwaitExprSyntax = self.as(AwaitExprSyntax.self) {
            return expression.expression.makesRoom
        }
        if  let call: FunctionCallExprSyntax = self.as(FunctionCallExprSyntax.self) {
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftParen, call.rightParen),
                trailingClosure: call.trailingClosure
            )
        }
        if  let call: SubscriptCallExprSyntax = self.as(SubscriptCallExprSyntax.self) {
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftSquare, call.rightSquare),
                trailingClosure: call.trailingClosure
            )
        }
        if  let call: MacroExpansionExprSyntax = self.as(MacroExpansionExprSyntax.self) {
            return Self.makesRoom(
                arguments: call.arguments,
                between: (call.leftParen, call.rightParen),
                trailingClosure: call.trailingClosure
            )
        }
        if  let literal: ArrayExprSyntax = self.as(ArrayExprSyntax.self) {
            return !literal.elements.isEmpty && !literal.containsInteriorNewlines
        }
        if  let literal: DictionaryExprSyntax = self.as(DictionaryExprSyntax.self),
            case .elements = literal.content {
            return !literal.containsInteriorNewlines
        }
        if  let literal: TupleExprSyntax = self.as(TupleExprSyntax.self) {
            return !literal.elements.isEmpty && !literal.containsInteriorNewlines
        }
        if  let closure: ClosureExprSyntax = self.as(ClosureExprSyntax.self) {
            return !closure.containsInteriorNewlines
        }
        return false
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
            return !closure.containsInteriorNewlines
        }
        return false
    }
}
