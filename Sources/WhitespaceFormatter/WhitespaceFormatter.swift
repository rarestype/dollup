import SwiftOperators
import SwiftParser
import SwiftSyntax

/// This pass detects Google-style “code rectangles”, and reformats Swift code to fit within a
/// specified maximum line length.
public struct WhitespaceFormatter {
    private let options: WhitespaceOptions
}
extension WhitespaceFormatter {
    public init(configure: (inout WhitespaceOptions) throws -> ()) rethrows {
        var options: WhitespaceOptions = .init()
        try configure(&options)
        self.init(options: options)
    }
}
extension WhitespaceFormatter {
    public func reformat(_ text: inout String, check: Bool) throws {
        var source: Source = .init(operators: self.options.operators, text: consume text)
        defer {
            text = source.text
        }

        let original: Syntax = source.tree
        let expander: LineExpander = .init(text: source.text)
        ;   expander.walk(source.tree)

        // it would not make much sense to check for line length violations if the indentation
        // were not correct
        if  expander.linebreaks.isEmpty {
            source.update(text: self.reindent(expander.text))
        } else {
            let expanded: String = expander.text.insert(linebreaks: expander.linebreaks)
            source.update(text: self.reindent(expanded), didChange: true)
        }

        // this pass assumes the indentation is already correct
        if  let style: BraceStyle = self.options.braces {
            let calculator: BracketCalculator = .init(style: style)
            ;   calculator.walk(source.tree)

            let aligner: BracketAligner = .init(style: style, brackets: try calculator.brackets)
            let aligned: String = aligner.rewrite(source.tree)

            source.update(with: aligned, onChange: self.reindent)
        }
        if  self.options.foldArguments {
            self.foldArguments(&source)
        }
        if  self.options.foldKeywords {
            self.foldKeywords(&source)
        }
        if  self.options.formatColonPadding {
            let calculator: ColonCalculator = .init()
            ;   calculator.walk(source.tree)

            let reformatted: String = try calculator.reformat(
                tokens: source.tree.tokens(viewMode: .sourceAccurate)
            )

            source.update(with: reformatted, onChange: self.reindent)
        }

        while true {
            let wrapper: LineWrapper = .init(
                text: source.text,
                wrap: self.options.wrapAttribute,
                width: self.options.width
            )
            ;   wrapper.walk(source.tree)

            let linebreaks: [Linebreak] = wrapper.linebreaks
            if  linebreaks.isEmpty {
                break
            }

            source.update(
                text: self.reindent(wrapper.text.insert(linebreaks: linebreaks)),
                didChange: true
            )
            // after wrapping, a value after `=` may fit on its line, and an attribute whose
            // closing parenthesis now starts a line folds the declaration after it
            if  self.options.foldArguments {
                self.foldArguments(&source)
            }
            if  self.options.foldKeywords {
                self.foldKeywords(&source)
            }
        }

        guard check else {
            return
        }

        let expectedSequence: TokenSequence = original.tokens(viewMode: .sourceAccurate)
        // perform integrity check
        var expected: TokenSequence.Iterator = expectedSequence.makeIterator()
        var rawQuote: String? = nil

        for token in source.tree.tokens(viewMode: .sourceAccurate) {
            guard let original: TokenSyntax = expected.next() else {
                fatalError("reformatted source has more tokens than original!!!")
            }

            if case .rawStringPoundDelimiter(let pattern) = token.tokenKind {
                if  let opening: String = rawQuote {
                    if  opening != pattern {
                        fatalError("mismatched raw string delimiters!!!")
                    }
                    rawQuote = nil
                } else {
                    rawQuote = pattern
                }
            }

            if token.trimmed.text == original.trimmed.text {
                continue
            }

            switch (original.tokenKind, token.tokenKind) {
            case (.stringQuote, .multilineStringQuote):
                // allow replacing `"` with `"""`
                continue

            case (.stringSegment(let before), .stringSegment(let after)):
                if case _? = rawQuote {
                    // if we got here, we have mismatched raw string delimiters, and
                    // normalization is not applicable
                    fallthrough
                }

                let before: [Unicode.Scalar] = .decode(literal: before)
                let after: [Unicode.Scalar] = .decode(literal: after)

                guard before == after else {
                    fallthrough
                }

            default:
                fatalError(
                    """
                    reformatted source does not match original!!!
                    expected: \(original.trimmed.text.debugDescription)
                    found:    \(token.trimmed.text.debugDescription)
                    """
                )
            }
        }

        guard case nil = expected.next() else {
            fatalError("reformatted source has fewer tokens than original!!!")
        }
    }

    private func foldArguments(_ source: inout Source) {
        let calculator: ArgumentCalculator = .init(
            text: source.text,
            width: self.options.width
        )
        ;   calculator.walk(source.tree)

        let aligner: TokenFolder = .init(movable: calculator.movable)
        let aligned: String = aligner.rewrite(source.tree)

        source.update(with: aligned, onChange: self.reindent)
    }
    private func foldKeywords(_ source: inout Source) {
        let calculator: ModifierCalculator = .init(fold: self.options.foldAttribute)
        ;   calculator.walk(source.tree)

        let aligner: ModifierFolder = .init(movable: calculator.movable)
        let aligned: String = aligner.rewrite(source.tree)

        source.update(with: aligned, onChange: self.reindent)
    }

    public func reindent(_ source: String) -> String {
        let (tree, _): (Syntax, [OperatorError]) = Source.parse(
            operators: self.options.operators,
            text: source
        )
        let indents: IndentCalculator = .init(options: self.options.indent)
        ;   indents.walk(tree)

        var exclude: BlockCommentCalculator = .init()
        ;   exclude.walk(tree)

        var lines: [Line] = Self.lines(of: source)
        // because of how the indenter is written, it always adds a blank line at the end,
        // which is desirable, but also requires us to remove any trailing blank lines to
        // prevent the formatter from adding more and more blank lines at the end of the file
        while case true? = lines.last?.range.isEmpty {
            lines.removeLast()
        }

        return Self.indent(
            lines: lines,
            by: self.options.indent.spaces,
            hangingOffsets: self.options.indent.hangConditions ? indents.hangingOffsets : nil,
            indents: indents.regions,
            exclude: exclude.regions,
        )
    }
}

extension WhitespaceFormatter {
    private static func indent(
        lines: [Line],
        by indent: Int,
        hangingOffsets: [Int: Int]?,
        indents: [IndentRegion],
        exclude: [BlockCommentRegion],
    ) -> String {
        var regions: (
            [IndentRegion].Iterator,
            [IndentRegion].Iterator,
            exclude: [BlockCommentRegion].Iterator
        ) = (
            indents.makeIterator(),
            indents.makeIterator(),
            exclude.makeIterator()
        )

        var current: (IndentRegion, IndentRegion, exclude: BlockCommentRegion)

        if  let a: IndentRegion = regions.0.next(),
            let b: IndentRegion = regions.1.next(),
            let exclude: BlockCommentRegion = regions.exclude.next() {
            current = (a, b, exclude)
        } else {
            fatalError("regions list is empty!!!")
        }

        var next: (IndentRegion?, IndentRegion?, exclude: BlockCommentRegion?) = (
            regions.0.next(),
            regions.1.next(),
            regions.exclude.next()
        )

        return lines.reduce(into: "") {
            while let region: BlockCommentRegion = next.exclude,
                region.start <= $1.range.lowerBound {
                current.exclude = region
                next.exclude = regions.exclude.next()
            }
            while let region: IndentRegion = next.0,
                region.start <= $1.range.lowerBound {
                current.0 = region
                next.0 = regions.0.next()
            }
            while let region: IndentRegion = next.1,
                region.start <= $1.range.upperBound {
                current.1 = region
                next.1 = regions.1.next()
            }

            if $1.range.isEmpty,
                case nil = current.0.prefix,
                case nil = current.1.suffix {
                // blank line, no prefix or suffix to preserve
            } else {
                let hangingOffset: Int = hangingOffsets?[$1.range.lowerBound] ?? 0
                let spaces: Int = current.exclude.comment
                    ? $1.column ?? 0
                    : max(current.0.indent * indent + hangingOffset, 0)

                for _: Int in 0 ..< spaces {
                    $0.append(" ")
                }
                if  let whitespace: Substring = current.0.prefix {
                    $0 += whitespace
                }

                $0 += $1.text

                escaping:
                if  let whitespace: Substring = current.1.suffix {
                    guard current.1.escapable else {
                        $0 += whitespace
                        break escaping
                    }

                    let last: String.Index = whitespace.index(before: whitespace.endIndex)
                    switch whitespace[last] {
                    case " ":
                        // this would be unlikely to survive editor trimming
                        $0 += whitespace[..<last]
                        $0 += "\\u{20}"
                    case "\t":
                        $0 += whitespace[..<last]
                        $0 += "\\t"
                    default:
                        $0 += whitespace
                    }
                }
            }

            $0.append("\n")
        }
    }

    private static func lines(of source: String) -> [Line] {
        let lines: [Substring] = source.split(
            omittingEmptySubsequences: false,
            whereSeparator: \.isNewline
        )
        return lines.map {
            let range: Range<String.Index>
            let column: Int?

            if  let first: String.Index = $0.firstIndex(where: { !$0.isWhitespace }),
                let last: String.Index = $0.lastIndex(where: { !$0.isWhitespace }) {
                range = first ..< $0.index(after: last)
                column = $0.distance(from: $0.startIndex, to: first)
            } else {
                range = $0.startIndex ..< $0.startIndex
                column = nil
            }

            let text: Substring = $0[range]

            guard
            let start: String.Index = range.lowerBound.samePosition(in: source.utf8),
            let end: String.Index = range.upperBound.samePosition(in: source.utf8) else {
                fatalError("could not convert string index to utf8 offset!!!")
            }

            return .init(
                range: source.utf8.distance(from: source.utf8.startIndex, to: start)
                    ..< source.utf8.distance(from: source.utf8.startIndex, to: end),
                column: column,
                text: text,
            )
        }
    }
}
