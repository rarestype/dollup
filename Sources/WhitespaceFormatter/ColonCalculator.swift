import SwiftSyntax

final class ColonCalculator: SyntaxVisitor {
    private var colons: [AbsolutePosition: ColonSpacing]

    init() {
        self.colons = [:]
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: LabeledStmtSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: MultipleTrailingClosureElementSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .allowed)
        return .visitChildren
    }
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .allowed)
        return .visitChildren
    }

    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .both)
        return .visitChildren
    }

    override func visit(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .both)
        return .visitChildren
    }

    override func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
        if case .colon(let colon) = node.content {
            self.mark(colon, as: .none)
        }
        return .visitChildren
    }
    override func visit(_ node: DeclNameArgumentSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .none)
        return .visitChildren
    }

    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .allowed)
        return .visitChildren
    }

    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: LayoutRequirementSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }


    // for some reason this is not a normal labeled expression
    override func visit(
        _ node: AvailabilityLabeledArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: DocumentationAttributeArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: LabeledSpecializeArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: SpecializeAvailabilityArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: SpecializeTargetFunctionArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: ObjCSelectorPieceSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .none)
        return .visitChildren
    }
    override func visit(
        _ node: DifferentiabilityWithRespectToArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: DerivativeAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: BackDeployedAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: OriginallyDefinedInAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
    override func visit(
        _ node: DynamicReplacementAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        self.mark(node.colon, as: .right)
        return .visitChildren
    }
}
extension ColonCalculator {
    private func mark(_ token: TokenSyntax?, as alignment: ColonSpacing) {
        guard let token: TokenSyntax else {
            return
        }
        self.mark(token, as: alignment)
    }
    private func mark(_ token: TokenSyntax, as alignment: ColonSpacing) {
        self.colons[token.positionAfterSkippingLeadingTrivia] = alignment
    }
}
extension ColonCalculator {
    func reformat(tokens: TokenSequence) throws -> String {
        var tokens: TokenSequence.Iterator = tokens.makeIterator()
        var next: TokenSyntax? = tokens.next()
        var text: String = ""

        while let current: TokenSyntax = next {
            next = tokens.next()

            guard let next: TokenSyntax else {
                text += "\(current)"
                break
            }

            if  case .colon = next.tokenKind {
                switch self.colons[next.positionAfterSkippingLeadingTrivia] {
                case .both?:
                    // a ternary colon does not need padding
                    text += "\(current.withoutTrailingSpaces)"

                    if !next.leadingTrivia.containsNewlines {
                        text.append(" ")
                    }

                default:
                    text += "\(current.withoutTrailingSpaces)"
                }
            } else if case .colon = current.tokenKind {
                if  next.leadingTrivia.containsNewlines {
                    // a colon that appears at the end of a line does not need padding
                    text += "\(current)"
                    continue
                }

                switch self.colons[current.positionAfterSkippingLeadingTrivia] {
                case .allowed?:
                    text += "\(current)"

                    if  current.trailingTrivia.isEmpty {
                        text.append(" ")
                    }

                case .none?:
                    text += "\(current.withoutTrailingSpaces)"

                case .both?:
                    fallthrough

                case .right?:
                    // colon has padding, that may need to be collapsed
                    text += "\(current.withoutTrailingSpaces)"
                    text.append(" ")

                case nil:
                    throw UnmarkedError.init(token: current)
                }
            } else if
                case .keyword(.if) = current.tokenKind,
                case .prefixOperator = next.tokenKind,
               !next.leadingTrivia.containsNewlines {
                text += "\(current.withoutTrailingSpaces)"
                text.append(" ")
            } else {
                text += "\(current)"
            }
        }

        return text
    }
}
