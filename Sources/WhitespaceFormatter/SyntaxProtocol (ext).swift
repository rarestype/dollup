import SwiftSyntax

extension SyntaxProtocol {
    func containsInteriorNewlines(between delimiter: (TokenSyntax, TokenSyntax)) -> Bool {
        let tokens: TokenSequence = self.tokens(viewMode: .sourceAccurate)
        for token: TokenSyntax in tokens {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return delimiter.1.leadingTrivia.containsNewlines
    }
    var containsPrecedingOrInteriorNewlines: Bool {
        for token: TokenSyntax in self.tokens(viewMode: .sourceAccurate) {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return false
    }
    var containsInteriorNewlines: Bool {
        var tokens: TokenSequence.Iterator = self.tokens(
            viewMode: .sourceAccurate
        ).makeIterator()
        if  let first: TokenSyntax = tokens.next(),
                first.trailingTrivia.containsNewlines {
            return true
        }
        while let token: TokenSyntax = tokens.next() {
            if  token.leadingTrivia.containsNewlines ||
                token.trailingTrivia.containsNewlines {
                return true
            }
        }
        return false
    }
    var lacksPrecedingNewline: Bool {
        !self.leadingTrivia.containsNewlines
    }

    var withoutTrailingSpaces: Self {
        self.with(\.trailingTrivia, self.trailingTrivia.withoutTrailingSpaces)
    }
}
