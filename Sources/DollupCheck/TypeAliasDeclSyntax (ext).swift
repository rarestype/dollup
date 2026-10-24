import SwiftSyntax

extension TypeAliasDeclSyntax {
    func deprecationShim(for expectedType: String) -> Bool {
        for element: AttributeListSyntax.Element in self.attributes {
            guard case .attribute(let attribute) = element,
            "\(attribute.attributeName.trimmed)" == "available" else {
                continue
            }
            let arguments: String = attribute.arguments.map { "\($0.trimmed)" } ?? ""
            if  arguments.contains("deprecated") {
                if  arguments.contains("renamed: \"\(expectedType)\"") ||
                    self.initializer.value.canonicalTypeName == expectedType ||
                    "\(self.initializer.value.trimmed)" == expectedType {
                    return true
                }
            }
        }
        return false
    }
}
