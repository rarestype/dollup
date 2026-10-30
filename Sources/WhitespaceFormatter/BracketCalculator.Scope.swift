import SwiftSyntax

extension BracketCalculator {
    struct Scope {
        let type: BracketType
        let soft: Bool
        let line: UInt
        let open: TokenSyntax
        var empty: Bool
    }
}
