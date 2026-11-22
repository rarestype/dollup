import SwiftSyntax

extension InitializerClauseSyntax {
    /// The type annotation of this value’s binding or binding condition, if it is a tuple,
    /// function, array, or dictionary type on one line, which the line wrapper can break when
    /// the value has nowhere to break.
    var breakableAnnotation: TypeSyntax? {
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
        return annotation.type.isBreakable ? annotation.type : nil
    }
}
extension TypeSyntax {
    /// Whether the line wrapper can break this type, which is true of a non-empty tuple type,
    /// a function type with parameters, which breaks like a tuple of its parameter types, and
    /// a sugared array or dictionary type.
    fileprivate var isBreakable: Bool {
        switch self.as(TypeSyntaxEnum.self) {
        case .tupleType(let tuple): !tuple.elements.isEmpty
        case .functionType(let function): !function.parameters.isEmpty
        case .attributedType(let attributed): attributed.baseType.isBreakable
        case .arrayType: true
        case .dictionaryType: true
        default: false
        }
    }
}
