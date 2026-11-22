import Testing
import WhitespaceFormatter

extension WhitespaceFormatter {
    static func reindent(
        _ source: String,
        by indent: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> String {
        let formatter: Self = .init {
            $0.indent.ifConfig = true
            $0.indent.spaces = indent
        }
        let once: String = formatter.reindent(source)
        #expect(
            formatter.reindent(once) == once,
            "reindenting again changes the output",
            sourceLocation: sourceLocation
        )
        return once
    }
    static func reformat(
        _ source: consuming String,
        indent: Int = 4,
        width: Int = 96,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> String {
        let formatter: Self = .init {
            $0.indent.ifConfig = false
            $0.indent.spaces = indent

            $0.width = width
        }
        return try formatter.reformat(source, sourceLocation: sourceLocation)
    }
}
extension WhitespaceFormatter {
    /// Reformats the source, and records an issue at `sourceLocation` if reformatting the
    /// result again would change it.
    func reformat(
        _ source: consuming String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> String {
        var once: String = source
        try self.reformat(&once, check: true)

        var again: String = once
        try self.reformat(&again, check: true)
        #expect(
            again == once,
            "reformatting again changes the output",
            sourceLocation: sourceLocation
        )
        return once
    }
}
