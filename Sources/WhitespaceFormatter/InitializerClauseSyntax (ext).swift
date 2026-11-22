import SwiftSyntax

extension InitializerClauseSyntax {
    /// The type annotation of this value’s binding, if it is a tuple, array, or dictionary
    /// type on one line, which the line wrapper can break when the value has nowhere to break.
    var breakableAnnotation: TypeSyntax? {
        guard
        let binding: PatternBindingSyntax = self.parent?.as(PatternBindingSyntax.self),
        let annotation: TypeAnnotationSyntax = binding.typeAnnotation,
           !annotation.containsInteriorNewlines else {
            return nil
        }
        switch annotation.type.as(TypeSyntaxEnum.self) {
        case .tupleType(let tuple): return tuple.elements.isEmpty ? nil : annotation.type
        case .arrayType: return annotation.type
        case .dictionaryType: return annotation.type
        default: return nil
        }
    }
}
