import SwiftSyntax

extension TypeSyntax {
    /// The delimiter that starts the last line of this type once the line wrapper breaks it,
    /// if it can: the closing bracket of a non-empty tuple type, of the parameters of a
    /// function type, which breaks like a tuple of its parameter types, or of a sugared array
    /// or dictionary type.
    var closingDelimiter: TokenSyntax? {
        switch self.as(TypeSyntaxEnum.self) {
        case .tupleType(let tuple): tuple.elements.isEmpty ? nil : tuple.rightParen
        case .functionType(let function):
            function.parameters.isEmpty ? nil : function.rightParen
        case .attributedType(let attributed): attributed.baseType.closingDelimiter
        case .arrayType(let array): array.rightSquare
        case .dictionaryType(let dictionary): dictionary.rightSquare
        default: nil
        }
    }
}
