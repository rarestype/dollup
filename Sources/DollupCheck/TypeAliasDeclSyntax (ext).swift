import SwiftSyntax

extension TypeAliasDeclSyntax {
    func deprecationShim(for expected: String) -> Bool {
        for element: AttributeListSyntax.Element in self.attributes {
            guard case .attribute(let attribute) = element,
            "\(attribute.attributeName.trimmed)" == "available",
            let arguments: AttributeSyntax.Arguments = attribute.arguments else {
                continue
            }
            let text: String = "\(arguments.trimmed)"
            if  text.contains("deprecated"),
                text.contains("renamed: \"\(expected)\"") ||
                self.initializer.value.canonicalTypeName == expected ||
                "\(self.initializer.value.trimmed)" == expected {
                return true
            }
        }
        return false
    }
}
