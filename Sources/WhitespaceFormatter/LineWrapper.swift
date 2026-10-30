import SwiftSyntax

class LineWrapper: SyntaxVisitor {
    /// The original source text, used for measuring line lengths.
    let text: String
    private let wrap: AttributesOptions
    private var line: [String.Index: LinebreakContext].Index?
    private var lines: [String.Index: LinebreakContext]

    init(text: String, wrap: AttributesOptions, width: Int) {
        self.text = text
        self.wrap = wrap
        self.line = nil
        self.lines = Self.contexts(source: text, width: width)

        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
        switch node.accessors {
        case .accessors(let list):
            if  list.isEmpty {
                return .skipChildren
            }
        case .getter(let list):
            if  list.isEmpty {
                return .skipChildren
            }
        }

        switch self.limitViolated(by: node, tier: .block) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftBrace)
        self.break(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        if  node.statements.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .block) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftBrace)
        self.break(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        if  node.members.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .block) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftBrace)
        self.break(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if  node.statements.isEmpty,
            case nil = node.signature {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .block) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(closure: node)
        return .skipChildren
    }

    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        guard !node.elements.isEmpty else {
            // we cannot line wrap an empty array `[]` (well we could, but it would be weird)
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftSquare)
        for element: ArrayElementSyntax in node.elements {
            self.break(after: element)
        }
        return .skipChildren
    }
    override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .typeSugar) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftSquare)
        self.break(after: node.element)
        return .skipChildren
    }
    override func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
        guard case .elements(let elements) = node.content else {
            // we cannot line wrap a `[:]` dictionary literal
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftSquare)
        for element: DictionaryElementSyntax in elements {
            self.break(after: element)
        }
        return .skipChildren
    }
    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .typeSugar) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftSquare)
        self.break(after: node.value)
        return .skipChildren
    }

    override func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
        if node.elements.isEmpty {
            // we cannot line wrap an empty tuple `()` (well we could, but it would be weird)
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for element: LabeledExprSyntax in node.elements {
            self.break(after: element)
        }
        return .skipChildren
    }
    override func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
        if node.elements.isEmpty {
            // yes, it’s actually valid Swift, although not very useful
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for element: TuplePatternElementSyntax in node.elements {
            self.break(after: element)
        }
        return .skipChildren
    }
    override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
        if node.elements.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for element: TupleTypeElementSyntax in node.elements {
            self.break(after: element)
        }
        return .skipChildren
    }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        guard self.wrap.applies(to: node) else {
            return .skipChildren
        }

        guard
        let leftParen: TokenSyntax = node.leftParen,
        let arguments: AttributeSyntax.Arguments = node.arguments else {
            // perhaps there is something breakable inside the attribute type
            return .visitChildren
        }

        switch self.limitViolated(by: node, tier: .decorator) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: leftParen)

        switch arguments {
        #if canImport(SwiftSyntax603)
        case .specializedArguments(let arguments):
            self.break(after: arguments)
        #endif
        #if canImport(SwiftSyntax602)
        case .abiArguments(let arguments):
            self.break(after: arguments.provider)
        #else
        case .token(let token):
            self.break(after: token)
        case .string(let string):
            self.break(after: string)
        case .conventionArguments(let arguments):
            self.break(after: arguments)
        case .conventionWitnessMethodArguments(let arguments):
            self.break(after: arguments)
        case .opaqueReturnTypeOfAttributeArguments(let arguments):
            self.break(after: arguments)
        case .exposeAttributeArguments(let arguments):
            self.break(after: arguments)
        case .underscorePrivateAttributeArguments(let arguments):
            self.break(after: arguments)
        case .unavailableFromAsyncArguments(let arguments):
            self.break(after: arguments)
        #endif

        case .argumentList(let arguments):
            for argument: LabeledExprSyntax in arguments {
                self.break(after: argument)
            }
        case .availability(let arguments):
            for argument: AvailabilityArgumentSyntax in arguments {
                self.break(after: argument)
            }
        case .documentationArguments(let arguments):
            for argument: DocumentationAttributeArgumentSyntax in arguments {
                self.break(after: argument)
            }
        case .specializeArguments(let arguments):
            for argument: SpecializeAttributeArgumentListSyntax.Element in arguments {
                self.break(after: argument)
            }
        case .backDeployedArguments(let arguments):
            self.break(after: arguments)
        case .effectsArguments(let arguments):
            self.break(after: arguments)
        case .dynamicReplacementArguments(let arguments):
            self.break(after: arguments)
        case .implementsArguments(let arguments):
            self.break(after: arguments)
        case .differentiableArguments(let arguments):
            self.break(after: arguments)
        case .derivativeRegistrationArguments(let arguments):
            self.break(after: arguments)
        case .objCName(let arguments):
            self.break(after: arguments)
        case .originallyDefinedInArguments(let arguments):
            self.break(after: arguments)
        }

        return .skipChildren
    }
    override func visit(_ node: ClosureParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.parameters.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for parameter: ClosureParameterSyntax in node.parameters {
            self.break(after: parameter)
        }
        return .skipChildren
    }
    override func visit(_ node: EnumCaseParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for parameter: EnumCaseParameterSyntax in node.parameters {
            self.break(after: parameter)
        }
        return .skipChildren
    }
    override func visit(_ node: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.parameters.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for parameter: FunctionParameterSyntax in node.parameters {
            self.break(after: parameter)
        }
        return .skipChildren
    }
    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        if node.parameters.isEmpty {
            return .skipChildren
        }

        switch self.limitViolated(by: (node.leftParen, node.rightParen), tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftParen)
        for parameter: TupleTypeElementSyntax in node.parameters {
            self.break(after: parameter)
        }
        return .skipChildren
    }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.calledExpression)
        return self.visit(
            leftDelimiter: node.leftParen,
            arguments: node.arguments,
            rightDelimiter: node.rightParen,
            trailingClosure: node.trailingClosure,
            additionalClosures: node.additionalTrailingClosures,
            tier: .inline
        )
    }
    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.macroName)
        self.walkIfPresent(node.genericArgumentClause)
        return self.visit(
            leftDelimiter: node.leftParen,
            arguments: node.arguments,
            rightDelimiter: node.rightParen,
            trailingClosure: node.trailingClosure,
            additionalClosures: node.additionalTrailingClosures,
            tier: .inline
        )
    }

    override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.calledExpression)
        return self.visit(
            leftDelimiter: node.leftSquare,
            arguments: node.arguments,
            rightDelimiter: node.rightSquare,
            trailingClosure: node.trailingClosure,
            additionalClosures: node.additionalTrailingClosures,
            tier: .subscript
        )
    }

    override func visit(_ node: GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .angles) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftAngle)
        for argument: GenericArgumentSyntax in node.arguments {
            self.break(after: argument)
        }
        return .skipChildren
    }
    override func visit(_ node: GenericParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .angles) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftAngle)
        for parameter: GenericParameterSyntax in node.parameters {
            self.break(after: parameter)
        }
        return .skipChildren
    }
    override func visit(
        _ node: PrimaryAssociatedTypeClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .angles) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.leftAngle)
        for type: PrimaryAssociatedTypeSyntax in node.primaryAssociatedTypes {
            self.break(after: type)
        }
        return .skipChildren
    }

    // `if`, `for`, and friends are not themselves wrappable, rather it is the
    // ``CodeBlockSyntax`` nodes inside them that are wrappable

    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        switch self.limitViolated(by: node, tier: .block) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        self.break(after: node.label)
        return .skipChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        guard
        case nil = node.openingPounds,
        case nil = node.closingPounds else {
            // we cannot safely break raw string literals
            return .visitChildren
        }

        switch self.limitViolated(by: node, tier: .string) {
        case nil:
            for case .expressionSegment(let expression) in node.segments {
                switch self.limitViolated(by: expression, tier: .inline) {
                case nil:
                    self.walk(expression)

                case true?:
                    self.break(after: expression.leftParen)
                    self.break(before: expression.rightParen)

                case false?:
                    continue
                }
            }
            return .skipChildren

        case true?:
            break

        case false?:
            return .skipChildren
        }

        self.break(after: node.openingQuote, type: .quotesBefore)
        self.break(before: node.closingQuote, type: .quotesAfter)
        return .skipChildren
    }

    override func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
        guard node.requirements.count > 1 else {
            // we can only break on commas
            return .visitChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        for requirement: GenericRequirementSyntax in node.requirements.dropLast() {
            self.break(after: requirement)
        }

        return .skipChildren
    }
    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        guard node.inheritedTypes.count > 1 else {
            return .visitChildren
        }

        switch self.limitViolated(by: node, tier: .inline) {
        case nil: return .visitChildren
        case true?: break
        case false?: return .skipChildren
        }

        for type: InheritedTypeSyntax in node.inheritedTypes.dropLast() {
            self.break(after: type)
        }
        return .skipChildren
    }
}
extension LineWrapper {
    private func walkIfPresent<Node>(_ node: Node?) where Node: SyntaxProtocol {
        if  let node: Node {
            self.walk(node)
        }
    }

    private func visit(
        leftDelimiter: TokenSyntax?,
        arguments: LabeledExprListSyntax,
        rightDelimiter: TokenSyntax?,
        trailingClosure: ClosureExprSyntax?,
        additionalClosures: MultipleTrailingClosureElementListSyntax,
        tier: LinebreakTier
    ) -> SyntaxVisitorContinueKind {
        for labeled: MultipleTrailingClosureElementSyntax in additionalClosures.reversed() {
            if case true? = self.limitViolated(by: labeled, tier: .block) {
                self.break(closure: labeled.closure)
                return .skipChildren
            }
        }
        if  let closure: ClosureExprSyntax = trailingClosure,
            case true? = self.limitViolated(by: closure, tier: .block) {
            self.break(closure: closure)
            return .skipChildren
        }
        // try breaking the argument list (it is not a single node)
        if !arguments.isEmpty,
            let leftDelimiter: TokenSyntax = leftDelimiter,
            let rightDelimiter: TokenSyntax = rightDelimiter,
            case true? = self.limitViolated(
                by: (leftDelimiter, rightDelimiter),
                tier: tier
            ) {
            self.break(after: leftDelimiter)
            for parameter: LabeledExprSyntax in arguments {
                self.break(after: parameter)
            }
            return .skipChildren
        } else {
            return .visitChildren
        }
    }


    private func limitViolated(by node: some SyntaxProtocol, tier: LinebreakTier) -> Bool? {
        self.limitViolated(
            by: node.positionAfterSkippingLeadingTrivia ..< node.endPositionBeforeTrailingTrivia,
            tier: tier
        )
    }
    private func limitViolated(
        by nodes: (some SyntaxProtocol, some SyntaxProtocol),
        tier: LinebreakTier
    ) -> Bool? {
        self.limitViolated(
            by: nodes.0.positionAfterSkippingLeadingTrivia
                ..< nodes.1.endPositionBeforeTrailingTrivia,
            tier: tier
        )
    }
    private func limitViolated(
        by range: Range<AbsolutePosition>,
        tier: LinebreakTier
    ) -> Bool? {
        let start: String.Index = self.text.utf8.index(
            self.text.utf8.startIndex,
            offsetBy: range.lowerBound.utf8Offset
        )
        let end: String.Index = self.text.utf8.index(
            self.text.utf8.startIndex,
            offsetBy: range.upperBound.utf8Offset
        )

        let line: String.Index

        if  let newline: String.Index = self.text[..<end].lastIndex(where: \.isNewline) {
            if  newline > start {
                // spans multiple lines, so computing line length is not meaningful
                self.line = nil
                return nil
            }

            line = self.text.index(after: newline)
        } else {
            // first line
            line = self.text.startIndex
        }

        self.line = self.lines.index(forKey: line)

        guard
        let line: [String.Index: LinebreakContext].Index = self.line else {
            // line fits within the limit
            return false
        }

        return {
            if  let prior: LinebreakTier = $0.tier, prior < tier {
                // we have already broken this line, and that line break is better
                return false
            } else if
                case tier? = $0.tier,
                case .rtl = tier.direction {
                // we have already broken this line at the same tier, and it is right-to-left
                return false
            } else {
                $0.tier = tier
                $0.breaks = []
                return true
            }
        } (&self.lines.values[line])
    }

    private func `break`(closure node: ClosureExprSyntax) {
        if  let signature: ClosureSignatureSyntax = node.signature {
            self.break(after: signature)
        } else {
            self.break(after: node.leftBrace)
        }

        self.break(before: node.rightBrace)
    }
    private func `break`(before node: some SyntaxProtocol, type: LinebreakType = .newline) {
        /// Line break position is after any leading trivia.
        self.break(at: node.positionAfterSkippingLeadingTrivia, type: type)
    }
    private func `break`(after node: some SyntaxProtocol, type: LinebreakType = .newline) {
        /// Line break position is after any trailing trivia, such as a trailing line comment.
        self.break(at: node.endPosition, type: type)
    }

    private func `break`(at position: AbsolutePosition, type: LinebreakType) {
        guard let line: [String.Index: LinebreakContext].Index = self.line else {
            fatalError("not a valid line to break!?!?")
        }

        let index: String.Index = self.text.utf8.index(
            self.text.utf8.startIndex,
            offsetBy: position.utf8Offset
        )

        self.lines.values[line].breaks.append(.init(index: index, type: type))
    }
}
extension LineWrapper {
    private static func contexts(
        source text: String,
        width: Int
    ) -> [String.Index: LinebreakContext] {
        var lines: [String.Index: LinebreakContext] = [:]
        var i: String.Index = text.startIndex
        while i < text.endIndex {
            let j: String.Index = text[i...].firstIndex(where: \.isNewline) ?? text.endIndex

            if  width < text[i ..< j].count {
                lines[i] = .init()
            }

            if  j < text.endIndex {
                i = text.index(after: j)
            } else {
                break
            }
        }
        return lines
    }

    var linebreaks: [Linebreak] {
        self.lines.values.flatMap(\.breaks)
    }
}
