import SwiftSyntax

extension InitializerClauseSyntax {
    /// Whether this is the value of a binding whose type annotation the line wrapper breaks
    /// before the value: a tuple, array, or dictionary type.
    var annotationMakesRoom: Bool {
        guard
        let binding: PatternBindingSyntax = self.parent?.as(PatternBindingSyntax.self),
        let annotation: TypeAnnotationSyntax = binding.typeAnnotation else {
            return false
        }
        switch annotation.type.kind {
        case .tupleType, .arrayType, .dictionaryType: return true
        default: return false
        }
    }
}
