import SwiftParser
import SwiftSyntax

struct Source: ~Copyable {
    private(set) var text: String
    private(set) var tree: Syntax

    private init(text: String, tree: Syntax) {
        self.text = text
        self.tree = tree
    }
}
extension Source {
    init(text: String) {
        self.text = text
        self.tree = Self.parse(text: self.text)
    }

    mutating func reparse() {
        self.tree = Self.parse(text: self.text)
    }

    /// Parses the text without grouping operator sequences, so every sequence stays flat, in
    /// source order. Nothing in the formatter depends on operator precedence, and grouping
    /// would depend on operator declarations that the formatter cannot see.
    static func parse(text: String) -> Syntax {
        Syntax.init(Parser.parse(source: text))
    }
}
extension Source {
    mutating func update(text: consuming String) {
        self.update(text: text, didChange: !self.text.utf8.elementsEqual(text.utf8))
    }
    mutating func update(text: consuming String, didChange: Bool) {
        self.text = text
        if  didChange {
            self.reparse()
        }
    }
    mutating func update(with text: consuming String, onChange: (consuming String) -> String) {
        if !self.text.utf8.elementsEqual(text.utf8) {
            self.update(text: onChange(text), didChange: true)
        }
    }
}
