import Testing
import WhitespaceFormatter

extension WhitespaceFormatter {
    static func reindent(_ source: String, by indent: Int) throws -> String {
        let formatter: Self = .init {
            $0.indent.ifConfig = true
            $0.indent.spaces = indent
        }
        let once: String = formatter.reindent(source)
        #expect(formatter.reindent(once) == once, "reindenting again changes the output")
        return once
    }
    static func reformat(
        _ source: consuming String,
        indent: Int = 4,
        width: Int = 96
    ) throws -> String {
        let formatter: Self = .init {
            $0.indent.ifConfig = false
            $0.indent.spaces = indent

            $0.width = width
        }
        var source: String = source
        try formatter.reformatIdempotently(&source)
        return source
    }
}
extension WhitespaceFormatter {
    /// Reformats the source, and records an issue if reformatting the result again would
    /// change it.
    func reformatIdempotently(_ source: inout String) throws {
        try self.reformat(&source, check: true)

        var again: String = source
        try self.reformat(&again, check: true)
        #expect(again == source, "reformatting again changes the output")
    }
}
