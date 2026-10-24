import SwiftSyntax

extension ImportDeclSyntax {
    var isExported: Bool {
        for attributeElement: AttributeListSyntax.Element in self.attributes {
            if  case .attribute(let attribute) = attributeElement,
                attribute.attributeName.trimmedDescription == "_exported" {
                return true
            }
        }
        return false
    }
}
