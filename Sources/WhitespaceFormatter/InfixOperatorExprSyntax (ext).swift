import SwiftSyntax

extension InfixOperatorExprSyntax {
    /// The `=` of the assignment this operator sequence makes, and the first operand of the value
    /// after it, if this node is the whole sequence and that value is a run of ternaries or of
    /// operators.
    ///
    /// The value is everything after the first `=` in source order, because an operator the
    /// operator table does not know can group the `=` inside its left operand.
    var assignedRun: (equal: TokenSyntax, value: ExprSyntax)? {
        if  case .infixOperatorExpr? = self.parent?.kind {
            return nil
        }
        let sequence: [ExprSyntax] = ExprSyntax.init(self).infixSequence
        guard
        let i: Int = sequence.firstIndex(where: { $0.is(AssignmentExprSyntax.self) }),
        let equal: AssignmentExprSyntax = sequence[i].as(AssignmentExprSyntax.self) else {
            return nil
        }
        let value: ArraySlice<ExprSyntax> = sequence[(i + 1)...]
        guard
        let first: ExprSyntax = value.first else {
            return nil
        }
        if  value.count == 1 ? first.isRun : ExprSyntax.isOperatorRun(value) {
            return (equal.equal, first)
        } else {
            return nil
        }
    }
}
