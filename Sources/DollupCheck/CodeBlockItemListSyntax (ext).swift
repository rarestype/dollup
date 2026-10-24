import SwiftSyntax

extension CodeBlockItemListSyntax {
    var unrolled: [CodeBlockItemSyntax] {
        self.reduce(into: []) {
            if  case .decl(let declaration) = $1.item,
                let ifConfig: IfConfigDeclSyntax = declaration.as(IfConfigDeclSyntax.self) {
                for clause: IfConfigClauseSyntax in ifConfig.clauses {
                    if  case .statements(let nested)? = clause.elements {
                        $0.append(contentsOf: nested.unrolled)
                    }
                }
            } else {
                $0.append($1)
            }
        }
    }
}
