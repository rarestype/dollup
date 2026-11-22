import SwiftSyntax

extension InitializerClauseSyntax {
    /// The closing delimiter of the type annotation of this value’s binding or binding
    /// condition, if the annotation is on one line and the line wrapper can break it when the
    /// value has nowhere to break.
    var annotationClosingDelimiter: TokenSyntax? {
        let annotation: TypeAnnotationSyntax?
        switch self.parent?.as(SyntaxEnum.self) {
        case .patternBinding(let binding)?: annotation = binding.typeAnnotation
        case .optionalBindingCondition(let condition)?: annotation = condition.typeAnnotation
        default: annotation = nil
        }
        guard
        let annotation: TypeAnnotationSyntax,
           !annotation.containsInteriorNewlines else {
            return nil
        }
        return annotation.type.closingDelimiter
    }
}
