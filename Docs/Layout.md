# How dollup lays out code

Dollup changes only whitespace. By default, before it writes a file, it checks that the reformatted file has exactly the same tokens as the original, so a formatting bug can make code ugly, but it cannot change what the code means. Within that limit, dollup aims for a layout that is a fixed point: formatting a file a second time changes nothing.

This document describes the rules behind that layout, so that you can predict what dollup will do to a line before you run it.


## Line breaks are mostly yours

Dollup doesn’t reflow code. It adds line breaks for three reasons only: to expand a bracket that already spans lines, to start a run on a line of its own, and to wrap a line that is too long. A call written on one line stays on one line if it fits. If its arguments already span lines, the arguments move off the line of the opening parenthesis, the closing parenthesis moves onto a line of its own, and any argument that spans lines starts a line of its own, but arguments that share a line keep sharing it.

Dollup removes line breaks only where a break carries no meaning. A trailing comma joins the value before it, modifiers and attributes fold onto the line of the declaration they belong to, and the value after an argument label or an `=` joins the label or the `=`, unless the value is a run, or it follows an `=` and has no room on that line, as described under “Values after `=`” below. Each brace style also decides which line an opening bracket goes on: in the default Egyptian style, an opening bracket moves up to the end of the line before it, unless it starts an element of a list, such as an array literal, in which case it stays on its own line with the element.


## Indentation comes from syntax

A line’s indentation follows from the syntax around it, never from how it was indented before. Brackets and blocks indent their contents one level. A line that starts with an operator, the `.` of a member chain, or a `where` clause is indented one level past the line it continues. Nothing else that continues a statement gets extra indentation, including a value on the line after its `=`. The one exception is a run, described below, whose lines must align with each other.


## Values after `=`

A value on the line after its `=` moves up onto the line of the `=` when the joined line fits, or when the value has brackets of its own that wrapping can break to make room.

```swift
let request: Request = .init(
    method: .get,
    path: "/index.html",
    headers: headers
)
```

If the value has no brackets that wrapping could break, the type annotation is the fallback. A tuple, array, dictionary or function type in the annotation breaks like a list of its elements, and the value follows the closing bracket, so long as the rest of the line then fits.

```swift
let handler: (
    Request,
    Response
) async throws -> Void = configuration.handlers.defaultHandlerForUnmatchedRequests
```

Otherwise, the value stays on the line after the `=`, with no extra indentation. The contents of the value always break before the annotation does, and the annotation breaks only to keep the value on the line of its `=`.


## Runs

A **run** is a value whose lines align with each other. Dollup knows two kinds. In a run of ternaries, each arm after the first starts a line right after the `:` that ends the arm before it. A run of operators breaks lines only right after its binary operators, and it breaks at least once.

```swift
let direction: Direction? =
    p ? .up :
    q ? .down : nil
let area: Int =
    width * height +
    depth * height
```

After an `=` or an argument label, a run starts on a line of its own, one level in, even if its first line would fit after the `=`, because otherwise that line would start further right than the rest of the run. A bracket or multi-line string that starts an operand of a run stays on a line of its own too, as it would in a list, so the run still aligns when its first operand spans lines.

Dollup recognizes runs by where their lines break, never by operator precedence. Precedence comes from operator declarations, which dollup cannot see when they live in other files or modules, so it never groups operator sequences at all, and a custom operator counts the same as `+`. For the same reason, only `=` counts as an assignment. `=` is part of the language, while `+=` and other compound assignment operators are declared in a library like any other operator, so a run after one of them keeps the layout it has. So does a run after `return`, and so does a sequence written with its operators at the start of its lines, which dollup indents one level as continuations.

```swift
let total: Int = base
    + bonus
    + tax
```


## Wrapping

When a line is longer than the configured width, dollup breaks it at brackets. It breaks the braces of blocks and closures first, then the arguments of attributes, then the brackets of calls, parameter lists, tuples and collection literals, then generic angle brackets, then subscripts, then sugared types such as `[Int]`, and only then string literals. A call that wraps puts each of its arguments on a line of its own, while the arguments of a subscript or an attribute first move onto one line of their own together, and split one per line only if that line is still too long. Dollup never breaks a raw string literal, or inside the interpolation of a single-line string.

Wrapping only adds line breaks. After each round of wrapping, dollup expands any bracket that the round left spanning lines and joins any value that now fits after its `=`, then measures the lines again, until no line that is too long has anything left to break.
