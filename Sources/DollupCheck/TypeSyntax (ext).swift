import SwiftSyntax

extension TypeSyntax {
    var canonicalTypeName: String {
        if  self.is(ArrayTypeSyntax.self) {
            return "Array"
        }
        if  self.is(DictionaryTypeSyntax.self) {
            return "Dictionary"
        }
        if  self.is(OptionalTypeSyntax.self) {
            return "Optional"
        }
        if  let member: MemberTypeSyntax = self.as(MemberTypeSyntax.self) {
            let base: String = member.baseType.canonicalTypeName
            return "\(base).\(member.name.text)"
        }
        if  let identifier: IdentifierTypeSyntax = self.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }
        return self.trimmedDescription
    }

    var primaryType: OTPF.PrimaryType {
        .init(self.canonicalTypeName)
    }
}
