import SwiftOperators

public struct WhitespaceOptions {
    /// This table has no effect, because the formatter never groups operator sequences by
    /// precedence. It remains for source compatibility.
    public var operators: OperatorTable
    public var width: Int

    public var indent: IndentOptions
    public var braces: BraceStyle?
    public var formatColonPadding: Bool
    /// If true, newlines between colons (`:`) in labeled expressions and values will be
    /// removed, as well as newlines between expressions and trailing commas (`,`).
    public var foldArguments: Bool
    public var foldKeywords: Bool
    /// Use these options to control how attributes are folded. They have no effect unless
    /// ``foldKeywords`` is also enabled.
    public var foldAttribute: AttributesOptions
    public var wrapAttribute: AttributesOptions
}
extension WhitespaceOptions {
    init() {
        self.init(
            operators: .standardOperators,
            width: 96,
            indent: IndentOptions.init(
                spaces: 4,
                switch: false,
                ifConfig: false,
                hangConditions: true
            ),
            braces: .egyptian,
            formatColonPadding: true,
            foldArguments: true,
            foldKeywords: false,
            foldAttribute: .foldDefaults,
            wrapAttribute: .wrapDefaults
        )
    }
}
extension WhitespaceOptions {
    @available(*, deprecated, message: "Use 'foldKeywords' or 'foldAttribute' instead")
    public var keywordsOnSameLine: Bool {
        get { self.foldKeywords }
        set { self.foldKeywords = newValue }
    }
}
