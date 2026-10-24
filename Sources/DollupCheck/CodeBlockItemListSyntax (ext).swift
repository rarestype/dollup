import SwiftSyntax

extension CodeBlockItemListSyntax {
    var unrolled: [CodeBlockItemSyntax] {
        var result: [CodeBlockItemSyntax] = []
        for item: CodeBlockItemSyntax in self {
            if  case .decl(let declaration) = item.item,
                let ifConfig: IfConfigDeclSyntax = declaration.as(IfConfigDeclSyntax.self) {
                for clause: IfConfigClauseSyntax in ifConfig.clauses {
                    if  case .statements(let nested)? = clause.elements {
                        result.append(contentsOf: nested.unrolled)
                    }
                }
            } else {
                result.append(item)
            }
        }
        return result
    }
}
