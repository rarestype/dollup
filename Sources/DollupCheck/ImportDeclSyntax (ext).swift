import SwiftSyntax

extension ImportDeclSyntax {
    var exported: Bool {
        for element: AttributeListSyntax.Element in self.attributes {
            if  case .attribute(let attribute) = element,
                attribute.attributeName.trimmedDescription == "_exported" {
                return true
            }
        }
        return false
    }
}
