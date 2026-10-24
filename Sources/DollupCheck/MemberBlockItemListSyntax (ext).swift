import SwiftSyntax

extension MemberBlockItemListSyntax {
    var unrolled: [MemberBlockItemSyntax] {
        self.reduce(into: []) {
            if  let ifConfig: IfConfigDeclSyntax = $1.decl.as(IfConfigDeclSyntax.self) {
                for clause: IfConfigClauseSyntax in ifConfig.clauses {
                    if  case .decls(let nested)? = clause.elements {
                        $0.append(contentsOf: nested.unrolled)
                    }
                }
            } else {
                $0.append($1)
            }
        }
    }
}
