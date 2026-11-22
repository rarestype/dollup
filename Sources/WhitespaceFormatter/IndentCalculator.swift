import SwiftSyntax
import SwiftParser

class IndentCalculator: SyntaxVisitor {
    private(set) var hangingOffsets: [Int: Int]
    private(set) var regions: [IndentRegion]
    private var level: Int
    private var rawContext: Bool

    private let options: IndentOptions

    init(options: IndentOptions) {
        self.hangingOffsets = [:]
        self.regions = [.init(start: 0, indent: 0, prefix: nil, suffix: nil, escapable: true)]
        self.level = 0
        self.rawContext = false

        self.options = options

        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        if  self.options.ifConfig {
            self.visit(indentingClauses: node)
            return .skipChildren
        } else {
            return .visitChildren
        }
    }
    override func visit(_ node: PostfixIfConfigExprSyntax) -> SyntaxVisitorContinueKind {
        if  let chain: MemberChain = .init(unrolling: node) {
            self.visit(chain: chain)
        } else {
            self.walkIfPresent(node.base)
            self.walk(node.config)
        }
        return .skipChildren
    }

    override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftBrace)
        self.walk(node.accessors)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftBrace)
        self.walk(node.statements)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftBrace)
        self.walk(node.members)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftBrace)
        self.walk(node.groupAttributes)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftBrace)
        self.walkIfPresent(node.signature)
        self.walk(node.statements)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }

    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftSquare)
        self.walk(node.elements)
        self.deindent(before: node.rightSquare)
        return .skipChildren
    }
    override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftSquare)
        self.walk(node.element)
        self.deindent(before: node.rightSquare)
        return .skipChildren
    }
    override func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftSquare)
        self.walk(node.content)
        self.deindent(before: node.rightSquare)
        return .skipChildren
    }
    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftSquare)
        self.walk(node.key)
        self.walk(node.colon)
        self.walk(node.value)
        self.deindent(before: node.rightSquare)
        return .skipChildren
    }

    override func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.elements)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.elements)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.elements)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.atSign)
        self.walk(node.attributeName)
        if let left: TokenSyntax = node.leftParen {
            self.indent(after: left)
        }
        self.walkIfPresent(node.arguments)
        if let right: TokenSyntax = node.rightParen {
            self.deindent(before: right)
        }
        return .skipChildren
    }
    override func visit(_ node: ClosureParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.parameters)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: EnumCaseParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.parameters)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.parameters)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftParen)
        self.walk(node.parameters)
        self.deindent(before: node.rightParen)
        self.walkIfPresent(node.effectSpecifiers)
        self.walk(node.returnClause)
        return .skipChildren
    }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if  let chain: MemberChain = .init(unrolling: node) {
            self.visit(chain: chain)
        } else {
            self.walk(node.calledExpression)
            self.visit(
                leftDelimiter: node.leftParen,
                arguments: node.arguments,
                rightDelimiter: node.rightParen,
                trailingClosure: node.trailingClosure,
                additionalClosures: node.additionalTrailingClosures
            )
        }
        return .skipChildren
    }
    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.pound)
        self.walk(node.macroName)
        self.walkIfPresent(node.genericArgumentClause)
        self.visit(
            leftDelimiter: node.leftParen,
            arguments: node.arguments,
            rightDelimiter: node.rightParen,
            trailingClosure: node.trailingClosure,
            additionalClosures: node.additionalTrailingClosures
        )
        return .skipChildren
    }
    override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
        if  let chain: MemberChain = .init(unrolling: node) {
            self.visit(chain: chain)
        } else {
            self.walk(node.calledExpression)
            self.visit(
                leftDelimiter: node.leftSquare,
                arguments: node.arguments,
                rightDelimiter: node.rightSquare,
                trailingClosure: node.trailingClosure,
                additionalClosures: node.additionalTrailingClosures
            )
        }
        return .skipChildren
    }

    override func visit(_ node: GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftAngle)
        self.walk(node.arguments)
        self.deindent(before: node.rightAngle)
        return .skipChildren
    }
    override func visit(_ node: GenericParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftAngle)
        self.walk(node.parameters)
        self.walkIfPresent(node.genericWhereClause)
        self.deindent(before: node.rightAngle)
        return .skipChildren
    }
    override func visit(
        _ node: PrimaryAssociatedTypeClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        self.indent(after: node.leftAngle)
        self.walk(node.primaryAssociatedTypes)
        self.deindent(before: node.rightAngle)
        return .skipChildren
    }

    override func visit(_ node: ConditionElementListSyntax) -> SyntaxVisitorContinueKind {
        let hangingLimit: Int
        if case .guardStmt? = node.parent?.kind {
            hangingLimit = 0
        } else {
            hangingLimit = -4
        }

        var identifier: TokenSyntax? = nil
        var skip: Bool = true
        for line: ConditionElementSyntax in node {
            defer { skip = false }

            switch line.condition {
            case .availability(let condition):
                let start: AbsolutePosition = condition.positionAfterSkippingLeadingTrivia
                // outdent the `#` prefix
                self.hangingOffsets[start.utf8Offset] = max(-1, hangingLimit)
                self.walk(condition)
                identifier = nil

            case .matchingPattern(let condition):
                self.walk(condition)
                identifier = nil

            case .optionalBinding(let condition):
                self.walk(condition)

                // This is a special case for `if  let` with two spaces. This style is used
                // to indicate the start of a hanging-indented condition list where subsequent
                // conditions should be aligned with the first binding.
                if  let previous: TokenSyntax = condition.bindingSpecifier.previousToken(
                        viewMode: .sourceAccurate
                    ),
                        previous.tokenKind == .keyword(.if),
                       !previous.lacksPrecedingNewline,
                        previous.trailingTrivia == [.spaces(2)] {
                    skip = false
                }

                if  skip, condition.lacksPrecedingNewline {
                    identifier = nil
                } else if
                    let pattern: IdentifierPatternSyntax = condition.pattern.as(
                        IdentifierPatternSyntax.self
                    ) {
                    identifier = pattern.identifier
                } else {
                    identifier = nil
                }
            case .expression(let expression):
                let start: AbsolutePosition = expression.positionAfterSkippingLeadingTrivia

                var alignedWithPrevious: Bool = false
                var column: Int = 0

                scan:
                for token: TokenSyntax in expression.tokens(viewMode: .sourceAccurate) {
                    switch token.tokenKind {
                    case .prefixOperator(let prefix):
                        column -= prefix.count
                    case .identifier(let name):
                        if case name? = identifier?.text {
                            column += self.options.spaces
                            alignedWithPrevious = true
                        }

                        break scan
                    default:
                        break scan
                    }
                }

                if  column != 0 {
                    self.hangingOffsets[start.utf8Offset] = max(column, hangingLimit)
                }
                if !alignedWithPrevious {
                    identifier = nil
                }

                self.walk(expression)
            }
        }
        return .skipChildren
    }
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.ifKeyword)

        self.walk(node.conditions)

        self.outdent(token: node.body.leftBrace)

        self.walk(node.body.statements)

        self.deindent(before: node.body.rightBrace)

        guard
        let elseKeyword: TokenSyntax = node.elseKeyword,
        let elseBody: IfExprSyntax.ElseBody = node.elseBody else {
            return .skipChildren
        }

        self.walk(elseKeyword)
        switch elseBody {
        case .ifExpr(let elseIf):
            self.walk(elseIf)

        case .codeBlock(let codeBlock):
            self.indent(after: codeBlock.leftBrace)
            self.walk(codeBlock.statements)
            self.deindent(before: codeBlock.rightBrace)
        }

        return .skipChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.forKeyword)

        self.walkIfPresent(node.tryKeyword)
        self.walkIfPresent(node.awaitKeyword)

        #if canImport(SwiftSyntax602)
        self.walkIfPresent(node.unsafeKeyword)
        #endif

        self.walkIfPresent(node.caseKeyword)
        self.walk(node.pattern)
        self.walkIfPresent(node.typeAnnotation)
        self.walk(node.inKeyword)
        self.walk(node.sequence)
        self.walkIfPresent(node.whereClause)

        self.outdent(token: node.body.leftBrace)

        self.walk(node.body.statements)

        self.deindent(before: node.body.rightBrace)
        return .skipChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.whileKeyword)

        self.walk(node.conditions)

        self.outdent(token: node.body.leftBrace)

        self.walk(node.body.statements)

        self.deindent(before: node.body.rightBrace)

        return .skipChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.repeatKeyword)

        self.indent(after: node.body.leftBrace)
        self.walk(node.body.statements)
        self.deindent(before: node.body.rightBrace)

        self.walk(node.whileKeyword)
        self.walk(node.condition)

        return .skipChildren
    }

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        guard self.options.switch else {
            return .visitChildren
        }

        self.walk(node.switchKeyword)
        self.walk(node.subject)
        self.indent(after: node.leftBrace)
        self.walk(node.cases)
        self.deindent(before: node.rightBrace)
        return .skipChildren
    }
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        self.walkIfPresent(node.attribute)
        switch node.label {
        case .case(let patterns):
            self.indent(after: patterns.caseKeyword)
            self.walk(patterns.caseItems)
            self.walk(patterns.colon)
            self.walk(node.statements)

        case .default(let label):
            self.indent(after: label.defaultKeyword)
            self.walk(label.colon)
            self.walk(node.statements)
        }
        self.walk(node.statements)
        self.deindent(at: node.statements.endPosition)
        return .skipChildren
    }

    // even if we did not care about indenting string literal interpolations, we would still
    // need to emit a new region for the interior of the interpolation, to prevent prefixed
    // regions from leaking whitespace into adjacent tokens
    override func visit(_ node: ExpressionSegmentSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.backslash)
        self.walkIfPresent(node.pounds)
        self.indent(after: node.leftParen)
        self.walk(node.expressions)
        self.deindent(before: node.rightParen)
        return .skipChildren
    }
    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        if case _? = node.openingPounds {
            self.rawContext = true
        }

        var segments: StringLiteralSegmentListSyntax.Iterator = node.segments.makeIterator()
        var current: StringLiteralSegmentListSyntax.Element? = segments.next()
        var newline: Bool = true
        while let segment: StringLiteralSegmentListSyntax.Element = current {
            let next: StringLiteralSegmentListSyntax.Element? = segments.next()

            switch segment {
            case .expressionSegment(let node):
                self.walk(node)

            case .stringSegment(let node):
                let firstOfLine: Bool = newline
                let lastOfLine: Bool?

                var content: Substring = node.content.text[...]
                if  case "\n"? = content.last {
                    // the trailing newline is handled by the line-based reindenter
                    content.removeLast()
                    lastOfLine = true
                    newline = true
                } else if node.trailingTrivia == [.backslashes(1), .newlines(1)] {
                    // line continuation
                    lastOfLine = false
                    newline = true
                } else if
                    case nil = next {
                    // last segment in the literal
                    lastOfLine = true
                    // this will never be read
                    newline = false
                } else {
                    lastOfLine = nil
                    newline = false
                }

                let whitespaceLeft: Substring
                let whitespaceRight: Substring

                if  let last: String.Index = content.lastIndex(where: { !$0.isWhitespace }) {
                    let i: String.Index = content.index(after: last)

                    whitespaceLeft = content.prefix(while: \.isWhitespace)
                    whitespaceRight = content[i...]
                } else if case true? = lastOfLine {
                    // if the segment is all whitespace, it is considered a suffix, not a prefix
                    whitespaceLeft = ""
                    whitespaceRight = content[...]
                } else {
                    // but only if there were no other segments on the same line
                    whitespaceLeft = content[...]
                    whitespaceRight = ""
                }

                if  firstOfLine || lastOfLine ?? false {
                    self.region(
                        start: node.positionAfterSkippingLeadingTrivia,
                        delta: 0,
                        prefix: whitespaceLeft.isEmpty ? nil : whitespaceLeft,
                        suffix: whitespaceRight.isEmpty ? nil : whitespaceRight
                    )
                }
                if  let lastOfLine: Bool {
                    self.region(
                        start: lastOfLine
                            ? node.endPositionBeforeTrailingTrivia
                            : node.endPositionBeforeTrailingTrivia.advanced(by: 1),
                        delta: 0,
                        prefix: nil,
                        suffix: nil
                    )
                }
            }

            current = next
        }

        if case _? = node.closingPounds {
            self.rawContext = false
        }

        return .skipChildren
    }

    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        self.indent(token: node.operator)
        return .skipChildren
    }
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        self.walk(node.condition)
        self.indent(token: node.questionMark)
        self.walk(node.thenExpression)
        self.indent(token: node.colon)
        self.walk(node.elseExpression)
        return .skipChildren
    }

    override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        // a run of ternaries or operators on its own line after the `=` of a binding is
        // indented one level past it, while any other value after the `=` is not
        guard !node.value.lacksPrecedingNewline,
        node.value.isRun else {
            return .visitChildren
        }
        self.walk(node.equal)
        self.indent(after: node.equal)
        self.walk(node.value)
        self.deindent(at: node.value.endPosition)
        return .skipChildren
    }
    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        // a run on its own line after the `=` of an assignment is indented one level past it
        guard
        let (equal, value): (TokenSyntax, ExprSyntax) = node.assignedRun,
        !value.lacksPrecedingNewline else {
            return .visitChildren
        }
        for element: ExprSyntax in ExprSyntax.init(node).infixSequence {
            self.walk(element)
            if  element.id == equal.parent?.id {
                self.indent(after: equal)
            }
        }
        self.deindent(at: node.endPosition)
        return .skipChildren
    }
    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        // a run on its own line after a label is indented one level past it
        guard
        let colon: TokenSyntax = node.colon,
        !node.expression.lacksPrecedingNewline,
        node.expression.isRun else {
            return .visitChildren
        }
        self.walkIfPresent(node.label)
        self.walk(colon)
        self.indent(after: colon)
        self.walk(node.expression)
        self.deindent(at: node.expression.endPosition)
        self.walkIfPresent(node.trailingComma)
        return .skipChildren
    }
    override func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
        // in barbie’s dollup, the `where` keyword is allowed to appear on a new line,
        // and also introduces a new indentation level

        // this makes `where` special
        self.indent(before: node.whereKeyword)
        self.walk(node.requirements)
        self.deindent(at: node.requirements.endPosition)
        return .skipChildren
    }
    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        self.indent(after: node.colon)
        self.walk(node.inheritedTypes)
        self.deindent(at: node.inheritedTypes.endPosition)
        return .skipChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if  let chain: MemberChain = .init(unrolling: node) {
            self.visit(chain: chain)
        } else {
            self.walkIfPresent(node.base)
            self.walk(node.period)
            self.walk(node.declName)
        }
        return .skipChildren
    }
}
extension IndentCalculator {
    private func walkIfPresent<Node>(_ node: Node?) where Node: SyntaxProtocol {
        if  let node: Node {
            self.walk(node)
        }
    }
    private func visit(indentingClauses node: IfConfigDeclSyntax) {
        var first: Bool = true
        for clause: IfConfigClauseSyntax in node.clauses {
            if  first {
                first = false
            } else {
                self.deindent(before: clause.poundKeyword)
            }
            self.indent(after: clause.poundKeyword)

            self.walkIfPresent(clause.condition)
            self.walkIfPresent(clause.elements)
        }
        self.deindent(before: node.poundEndif)
    }

    private func visit(chain: MemberChain) {
        self.walk(chain.base)

        var afterMultilineExpression: Bool = chain.base.containsInteriorNewlines
        var indented: Bool = false
        var deindent: AbsolutePosition? = nil

        for link: MemberChain.Link in chain.flattened {
            if  let period: TokenSyntax = link.period {
                if !indented, !afterMultilineExpression, !period.lacksPrecedingNewline {
                    indented = true
                    self.indent(before: period)
                }
                self.walk(period)
            }

            switch link {
            case .property(_, let name):
                self.walk(name)

            case .function(_, let name, let node):
                self.walk(name)
                if  self.visit(
                        leftDelimiter: node.leftParen,
                        arguments: node.arguments,
                        rightDelimiter: node.rightParen,
                        trailingClosure: node.trailingClosure,
                        additionalClosures: node.additionalTrailingClosures
                    ) {
                    afterMultilineExpression = true
                }

            case .subscript(_, let name, let node):
                self.walk(name)
                if  self.visit(
                        leftDelimiter: node.leftSquare,
                        arguments: node.arguments,
                        rightDelimiter: node.rightSquare,
                        trailingClosure: node.trailingClosure,
                        additionalClosures: node.additionalTrailingClosures
                    ) {
                    afterMultilineExpression = true
                }

            case .postfixIfConfig(let node):
                self.walk(node.config)
                afterMultilineExpression = true

            case .postfixOperator(let node):
                self.walk(node)
            }

            if  indented {
                deindent = link.endPositionBeforeTrailingTrivia
            }
        }

        if  let deindent: AbsolutePosition {
            self.deindent(at: deindent)
        } else if indented {
            fatalError("Expected deindent position for indented member chain")
        }
    }

    @discardableResult private func visit(
        leftDelimiter: TokenSyntax?,
        arguments: LabeledExprListSyntax,
        rightDelimiter: TokenSyntax?,
        trailingClosure: ClosureExprSyntax?,
        additionalClosures: MultipleTrailingClosureElementListSyntax,
    ) -> Bool {
        if  let left: TokenSyntax = leftDelimiter {
            self.indent(after: left)
        }

        self.walk(arguments)

        if let right: TokenSyntax = rightDelimiter {
            self.deindent(before: right)
        }

        self.walkIfPresent(trailingClosure)
        self.walkIfPresent(additionalClosures)

        if  case true? = leftDelimiter?.containsPrecedingOrInteriorNewlines {
            return true
        } else if arguments.containsPrecedingOrInteriorNewlines {
            return true
        } else if
            case true? = rightDelimiter?.containsPrecedingOrInteriorNewlines {
            return true
        } else if
            case true? = trailingClosure?.containsPrecedingOrInteriorNewlines {
            return true
        } else if additionalClosures.containsPrecedingOrInteriorNewlines {
            return true
        } else {
            return false
        }
    }

    private func outdent(token: TokenSyntax) {
        self.region(start: token.positionAfterSkippingLeadingTrivia, delta: -1)
        self.region(start: token.endPosition, delta: +1)
    }
    private func indent(token: TokenSyntax) {
        self.region(start: token.positionAfterSkippingLeadingTrivia, delta: +1)
        self.region(start: token.endPosition, delta: -1)
    }
    private func indent(before left: TokenSyntax) {
        // TokenSyntax has no children to walk
        self.region(start: left.positionAfterSkippingLeadingTrivia, delta: +1)
    }
    private func indent(after left: TokenSyntax) {
        self.region(start: left.endPosition, delta: +1)
    }
    private func deindent(before right: TokenSyntax) {
        self.region(start: right.positionAfterSkippingLeadingTrivia, delta: -1)
    }
    private func deindent(at position: AbsolutePosition) {
        self.region(start: position, delta: -1)
    }

    private func region(
        start: AbsolutePosition,
        delta: Int,
        prefix: Substring? = nil,
        suffix: Substring? = nil
    ) {
        self.level += delta
        self.regions.append(
            .init(
                start: start.utf8Offset,
                indent: self.level,
                prefix: prefix,
                suffix: suffix,
                escapable: !self.rawContext
            )
        )
    }
}
