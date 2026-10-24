import SwiftSyntax

extension MemberBlockItemListSyntax {
    var unrolled: [MemberBlockItemSyntax] {
        var result: [MemberBlockItemSyntax] = []
        for member: MemberBlockItemSyntax in self {
            if  let ifConfig: IfConfigDeclSyntax = member.decl.as(IfConfigDeclSyntax.self) {
                for clause: IfConfigClauseSyntax in ifConfig.clauses {
                    if  case .decls(let nested)? = clause.elements {
                        result.append(contentsOf: nested.unrolled)
                    }
                }
            } else {
                result.append(member)
            }
        }
        return result
    }
}
