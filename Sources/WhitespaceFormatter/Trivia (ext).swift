import SwiftSyntax

extension Trivia {
    var isWhitespace: Bool {
        for piece: TriviaPiece in self {
            switch piece {
            case .carriageReturns: continue
            case .carriageReturnLineFeeds: continue
            case .formfeeds: continue
            case .newlines: continue
            case .spaces: continue
            case .tabs: continue
            case .verticalTabs: continue
            default: return false
            }
        }
        return true
    }

    var containsNewlines: Bool {
        for piece: TriviaPiece in self {
            switch piece {
            case .carriageReturnLineFeeds: return true
            case .newlines: return true
            default: continue
            }
        }
        return false
    }

    var withoutTrailingSpaces: Self {
        guard let i: Int = self.pieces.lastIndex(
            where: {
                switch $0 {
                case .spaces: false
                case .tabs: false
                default: true
                }
            }
        ) else {
            return []
        }

        if case i? = self.pieces.indices.last {
            return self
        } else {
            return .init(pieces: self.pieces[...i])
        }
    }
}
