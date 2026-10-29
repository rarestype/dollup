# Rarest SwiftSyntax style guide

This document supplements the [Swift style guide](Swift.md) for code that uses SwiftSyntax, such as formatters, linters and macros. Everything in the Swift style guide still applies; this document only covers what is specific to SwiftSyntax.


## Reading source text

A syntax node’s `description` is its source text *including* its leading and trailing trivia, which means the whitespace, newlines and comments around it. Comparing or printing it leaks that trivia into the result, and the bug only shows up when the input happens to be formatted differently. Interpolate the node’s `trimmed` form, or read the `text` of a token.

```swift
// good
if  "\(attribute.attributeName.trimmed)" == "available" {}
let name: String = declaration.name.text

// bad — includes any trivia attached to the node
if  attribute.attributeName.description == "available" {}
```


## Reading comments and whitespace

The parser has already split comments and whitespace into trivia pieces, so read those pieces instead of serializing the tree and scanning the text again. For example, the comment that opens a file is a piece of the file’s leading trivia.

```swift
// good — skip whitespace pieces, then match the first comment
for piece: TriviaPiece in tree.leadingTrivia.pieces {
    switch piece {
    case .newlines, .carriageReturnLineFeeds, .spaces, .tabs:
        continue
    case .lineComment(let text):
        return text
    default:
        return nil
    }
}
return nil

// bad — serializes the whole tree, then rediscovers the lines by hand
let text: String = tree.description
```

Documentation comments are separate kinds of piece (`.docLineComment` and `.docBlockComment`), so a `case .lineComment` pattern doesn’t match `///` lines by accident.


## Naming cast nodes

When you cast a node with `as(_:)`, name the result after the kind of node, spelled out, as the Swift style guide requires for all names. Shadow the uncast node when you no longer need it.

```swift
// good
if  let extensionDeclaration: ExtensionDeclSyntax = declaration.as(ExtensionDeclSyntax.self) {}

// bad
if  let extDecl: ExtensionDeclSyntax = decl.as(ExtensionDeclSyntax.self) {}
```


## Where node helpers go

A helper that answers a question about one kind of node belongs in an extension on that node type, in that type’s extension file, such as `TypeAliasDeclSyntax (ext).swift`, as described under “Where helpers go” in the Swift style guide.
