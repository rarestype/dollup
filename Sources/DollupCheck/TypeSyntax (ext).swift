import SwiftSyntax

extension TypeSyntax {
    /// Syntactically extracts the primary type identifier from this type expression.
    ///
    /// > Warning: This is a purely syntactic, single-file heuristic for OTPF file matching.
    /// > Mapping syntax forms such as array types or `Array<T>` to `"Array"` carries no
    /// > semantic type meaning without IndexStore / SourceKit-LSP symbol resolution context.
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
        return "\(self.trimmed)"
    }

    var primaryType: OTPF.PrimaryType {
        .init(self.canonicalTypeName)
    }
}
