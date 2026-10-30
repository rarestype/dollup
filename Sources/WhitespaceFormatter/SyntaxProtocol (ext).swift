import SwiftSyntax

extension SyntaxProtocol {
    func containsInteriorNewlines(between delimiter: (TokenSyntax, TokenSyntax)) -> Bool {
        let tokens: TokenSequence = self.tokens(viewMode: .sourceAccurate)
        for token: TokenSyntax in tokens {
            // only leading trivia can ever contain newlines
            for case .newlines in token.leadingTrivia {
                return true
            }
        }
        for case .newlines in delimiter.1.leadingTrivia {
            return true
        }
        return false
    }
    var containsPrecedingOrInteriorNewlines: Bool {
        for token: TokenSyntax in self.tokens(viewMode: .sourceAccurate) {
            // only leading trivia can ever contain newlines
            for case .newlines in token.leadingTrivia {
                return true
            }
        }
        return false
    }
    var containsInteriorNewlines: Bool {
        let tokens: TokenSequence = self.tokens(viewMode: .sourceAccurate)
        for token: TokenSyntax in tokens.dropFirst() {
            for case .newlines in token.leadingTrivia {
                return true
            }
        }
        return false
    }
    var lacksPrecedingNewline: Bool {
        for case .newlines in self.leadingTrivia {
            return false
        }
        return true
    }

    var withoutTrailingSpaces: Self {
        self.with(\.trailingTrivia, self.trailingTrivia.withoutTrailingSpaces)
    }

    var foldsEmpty: Bool {
        switch self.kind {
        case .accessorBlock: true
        case .memberBlock: true
        case .precedenceGroupDecl: true
        case .codeBlock:
            switch self.parent?.kind {
            case .accessorDecl: true
            case .deinitializerDecl: true
            case .forStmt: true
            case .functionDecl: true
            case .initializerDecl: true
            case .macroDecl: true
            case .repeatStmt: true
            case .whileStmt: true
            default: false
            }
        default: false
        }
    }
}
