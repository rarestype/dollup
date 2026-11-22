import SwiftSyntax

extension SequenceExprSyntax {
    /// The first `=` of this sequence and the elements of the value after it, if the sequence
    /// makes an assignment and that value is a run of ternaries or of operators.
    var assignedRun: (equal: AssignmentExprSyntax, value: Slice<ExprListSyntax>)? {
        guard
        let i: ExprListSyntax.Index = self.elements.firstIndex(
            where: { $0.is(AssignmentExprSyntax.self) }
        ) else {
            return nil
        }
        let value: Slice<ExprListSyntax> = self.elements[self.elements.index(after: i)...]
        if  ExprSyntax.isRun(value) {
            return (self.elements[i].cast(AssignmentExprSyntax.self), value)
        } else {
            return nil
        }
    }
}
