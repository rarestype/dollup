import SwiftDiagnostics
import SwiftSyntax

extension OTPF {
    struct Checker {
        let name: String
        let tree: SourceFileSyntax

        var diagnostics: [Diagnostic]

        init(tree: SourceFileSyntax, name: String) {
            self.name = name
            self.tree = tree
            self.diagnostics = []
        }
    }
}

extension OTPF.Checker {
    mutating func check() -> [Diagnostic] {
        guard let fileClass: OTPF.FileClass = .init(name: self.name) else {
            return []
        }

        if  self.name.contains("+") {
            self.diagnose(
                node: .init(self.tree),
                message: """
                plus signs ('+') are never allowed in filenames; use ' (ext)' for extension files
                """
            )
            return self.diagnostics
        }

        if  OTPF.manifest(name: self.name),
            case _? = self.toolsVersion {
            guard
            let declaration: Syntax = self.packageDeclaration else {
                return self.diagnostics
            }
            self.diagnose(
                node: declaration,
                message: """
                declares type ‘Package’ but looks like a package manifest (starts \
                with “// swift-tools-version:”), this is probably unintentional
                """,
                severity: .warning
            )
        }

        switch fileClass {
        case .special(let special):
            self.check(special: special)

        case .ext(let primaryType), .gen(let primaryType):
            self.checkGlobalRestrictions()
            self.checkExtension(expectedType: primaryType)

        case .layout(let primaryType):
            self.checkGlobalRestrictions()
            self.checkLayout(primaryType)
        }

        return self.diagnostics
    }

    private mutating func check(special: OTPF.FileClass.Special) {
        switch special {
        case .anchor:
            if  !self.tree.statements.isEmpty {
                self.diagnose(
                    node: .init(self.tree.statements.first!),
                    message: "'anchor.swift' must be empty"
                )
            }

        case .exports:
            for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                if  case .decl(let declaration) = statement.item {
                    if  let importDeclaration: ImportDeclSyntax = declaration.as(
                            ImportDeclSyntax.self
                        ),
                            importDeclaration.exported {
                        continue
                    }
                }
                self.diagnose(
                    node: .init(statement),
                    message: """
                    'exports.swift' can only contain '@_exported import' statements
                    """
                )
            }

        case .lexemes:
            for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                if  case .decl(let declaration) = statement.item {
                    if  declaration.is(ImportDeclSyntax.self) ||
                        declaration.is(OperatorDeclSyntax.self) ||
                        declaration.is(PrecedenceGroupDeclSyntax.self) {
                        continue
                    }
                }
                self.diagnose(
                    node: .init(statement),
                    message: """
                    'lexemes.swift' can only contain operator and precedencegroup declarations
                    """
                )
            }

        case .operators:
            for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                if  case .decl(let declaration) = statement.item {
                    if  declaration.is(ImportDeclSyntax.self) {
                        continue
                    }
                    if  case _? = declaration.primaryType {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            'operators.swift' cannot declare types; it can only contain top-level \
                            operator functions
                            """
                        )
                    }
                }
            }
        }
    }

    private mutating func checkGlobalRestrictions() {
        for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
            guard case .decl(let declaration) = statement.item else {
                continue
            }
            if  let importDeclaration: ImportDeclSyntax = declaration.as(ImportDeclSyntax.self),
                    importDeclaration.exported {
                self.diagnose(
                    node: .init(importDeclaration),
                    message: "'@_exported import' is prohibited outside 'exports.swift'"
                )
            }
            if  declaration.is(OperatorDeclSyntax.self) ||
                declaration.is(PrecedenceGroupDeclSyntax.self) {
                self.diagnose(
                    node: .init(declaration),
                    message: """
                    operator and precedencegroup declarations are prohibited outside \
                    'lexemes.swift'
                    """
                )
            }
        }
    }

    private mutating func checkExtension(expectedType: OTPF.PrimaryType) {
        for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
            guard case .decl(let declaration) = statement.item else {
                if  !statement.item.is(ImportDeclSyntax.self) {
                    self.diagnose(
                        node: .init(statement),
                        message: """
                        extension file '\(
                            self.name
                        )' cannot contain top-level executable statements
                        """
                    )
                }
                continue
            }

            if  declaration.is(ImportDeclSyntax.self) {
                continue
            }

            if  let extensionDeclaration: ExtensionDeclSyntax = declaration.as(
                    ExtensionDeclSyntax.self
                ) {
                let target: OTPF.PrimaryType = extensionDeclaration.extendedType.primaryType
                if  target != expectedType {
                    self.diagnose(
                        node: .init(extensionDeclaration),
                        message: """
                        extension file '\(self.name)' cannot contain extension to '\(
                            "\(extensionDeclaration.extendedType.trimmed)"
                        )'; it must only extend '\(
                            expectedType.description
                        )'
                        """
                    )
                }
                self.checkExtensionMembers(
                    extensionDeclaration.memberBlock.members,
                    parentType: target.description
                )
                continue
            }

            if  let declaredType: OTPF.PrimaryType = declaration.primaryType {
                self.diagnose(
                    node: .init(declaration),
                    message: """
                    extension file '\(self.name)' cannot define primary type '\(
                        declaredType.last
                    )'
                    """
                )
                continue
            }

            if  let functionDeclaration: FunctionDeclSyntax = declaration.as(
                    FunctionDeclSyntax.self
                ) {
                self.diagnose(
                    node: .init(declaration),
                    message: """
                    extension file '\(self.name)' cannot contain free function '\(
                        functionDeclaration.name.text
                    )'
                    """
                )
                continue
            }

            if  declaration.is(VariableDeclSyntax.self) {
                self.diagnose(
                    node: .init(declaration),
                    message: """
                    extension file '\(self.name)' cannot contain top-level properties
                    """
                )
                continue
            }

            self.diagnose(
                node: .init(declaration),
                message: """
                extension file '\(self.name)' cannot contain top-level declarations other than \
                extensions to '\(expectedType.description)'
                """
            )
        }
    }

    private mutating func checkLayout(_ primaryType: OTPF.PrimaryType) {
        let statements: [CodeBlockItemSyntax] = self.tree.statements.unrolled
        let matchingPrimaryDeclaration: DeclSyntax?
        let definedPrimaryType: OTPF.PrimaryType?
        if !primaryType.nested {
            matchingPrimaryDeclaration = statements.compactMap {
                guard case .decl(let declaration) = $0.item,
                declaration.primaryType?.last == primaryType.last else {
                    return nil
                }
                return declaration
            }.first

            definedPrimaryType = matchingPrimaryDeclaration?.primaryType ?? statements.compactMap {
                guard case .decl(let declaration) = $0.item else {
                    return nil
                }
                return declaration.primaryType
            }.first
        } else {
            matchingPrimaryDeclaration = nil
            definedPrimaryType = nil
        }

        var foreignExtensionCount: Int = 0
        var primaryTypeFound: Bool = false
        var matchingFreeFunction: Bool = false
        var matchingTypealias: Bool = false
        var otherPrimaryTypeNames: [String] = []

        for statement: CodeBlockItemSyntax in statements {
            guard case .decl(let declaration) = statement.item else {
                if  self.name != "main.swift", !statement.item.is(ImportDeclSyntax.self) {
                    self.diagnose(
                        node: .init(statement),
                        message: """
                        layout file '\(
                            self.name
                        )' cannot contain top-level executable statements
                        """
                    )
                }
                continue
            }

            if  declaration.is(ImportDeclSyntax.self) {
                continue
            }

            if  let extensionDeclaration: ExtensionDeclSyntax = declaration.as(
                    ExtensionDeclSyntax.self
                ) {
                let target: OTPF.PrimaryType = extensionDeclaration.extendedType.primaryType
                if  target == primaryType || (
                        !primaryType.nested && target == definedPrimaryType
                    ) {
                    self.checkExtensionMembers(
                        extensionDeclaration.memberBlock.members,
                        parentType: target.description
                    )
                } else if let scope: String = primaryType.scope,
                    target == OTPF.PrimaryType.init(scope) {
                    foreignExtensionCount += 1
                    if  foreignExtensionCount > 1 {
                        self.diagnose(
                            node: .init(extensionDeclaration),
                            message: """
                            layout file '\(
                                self.name
                            )' must contain only one extension to namespace '\(
                                scope
                            )'
                            """
                        )
                    }
                    for member: MemberBlockItemSyntax in extensionDeclaration.memberBlock.members.unrolled {
                        if  let memberType: OTPF.PrimaryType = member.decl.primaryType {
                            if  memberType.last == primaryType.last {
                                primaryTypeFound = true
                                self.checkNestedMembers(
                                    member.decl,
                                    parentType: primaryType.description
                                )
                            } else {
                                self.diagnose(
                                    node: .init(member.decl),
                                    message: """
                                    foreign extension to '\(scope)' in '\(
                                        self.name
                                    )' must contain nothing except the definition of '\(
                                        primaryType.last
                                    )'
                                    """
                                )
                            }
                        } else if let typealiasDeclaration: TypeAliasDeclSyntax = member.decl.as(
                                TypeAliasDeclSyntax.self
                            ) {
                            if  typealiasDeclaration.name.text == primaryType.last {
                                primaryTypeFound = true
                            } else {
                                self.diagnose(
                                    node: .init(typealiasDeclaration),
                                    message: """
                                    foreign extension to '\(scope)' in '\(
                                        self.name
                                    )' must contain nothing except the definition of '\(
                                        primaryType.last
                                    )'
                                    """
                                )
                            }
                        } else {
                            self.diagnose(
                                node: .init(member.decl),
                                message: """
                                foreign extension to '\(scope)' in '\(
                                    self.name
                                )' must contain nothing except the definition of '\(
                                    primaryType.last
                                )'
                                """
                            )
                        }
                    }
                } else {
                    self.diagnose(
                        node: .init(extensionDeclaration),
                        message: """
                        layout file '\(
                            self.name
                        )' cannot contain extension to foreign type '\(
                            "\(extensionDeclaration.extendedType.trimmed)"
                        )'
                        """
                    )
                }
                continue
            }

            if  let declaredType: OTPF.PrimaryType = declaration.primaryType {
                let name: String = declaredType.last
                if  primaryType.nested {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        one type per file violation: found top-level type '\(
                            name
                        )' in nested layout file '\(
                            self.name
                        )'
                        """
                    )
                } else if name == primaryType.last {
                    primaryTypeFound = true
                    self.checkNestedMembers(declaration, parentType: primaryType.description)
                } else if case _? = matchingPrimaryDeclaration {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        one type per file violation: found type '\(name)' in file '\(
                            self.name
                        )' which defines '\(
                            primaryType.last
                        )'
                        """
                    )
                } else {
                    if  otherPrimaryTypeNames.isEmpty {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            type '\(name)' does not match filename '\(self.name)'
                            """
                        )
                    } else {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            one type per file violation: found type '\(name)' in file '\(
                                self.name
                            )'
                            """
                        )
                    }
                    otherPrimaryTypeNames.append(name)
                }
                continue
            }

            if  let functionDeclaration: FunctionDeclSyntax = declaration.as(
                    FunctionDeclSyntax.self
                ) {
                if  primaryType.nested {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        free function '\(
                            functionDeclaration.name.text
                        )' cannot appear in nested layout file '\(
                            self.name
                        )'
                        """
                    )
                } else if case _? = matchingPrimaryDeclaration {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        free function '\(
                            functionDeclaration.name.text
                        )' cannot coexist with type '\(
                            primaryType.last
                        )' in '\(
                            self.name
                        )'
                        """
                    )
                } else if functionDeclaration.name.text == primaryType.last {
                    matchingFreeFunction = true
                } else {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        free function '\(
                            functionDeclaration.name.text
                        )' does not match filename '\(
                            self.name
                        )'
                        """
                    )
                }
                continue
            }

            if  let macroDeclaration: MacroDeclSyntax = declaration.as(MacroDeclSyntax.self) {
                if  case _? = matchingPrimaryDeclaration {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        macro '\(
                            macroDeclaration.name.text
                        )' cannot coexist with type '\(primaryType.last)' in '\(
                            self.name
                        )'
                        """
                    )
                } else if macroDeclaration.name.text == primaryType.last {
                    primaryTypeFound = true
                } else {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        macro '\(macroDeclaration.name.text)' does not match filename '\(
                            self.name
                        )'
                        """
                    )
                }
                continue
            }

            if  let typealiasDeclaration: TypeAliasDeclSyntax = declaration.as(
                    TypeAliasDeclSyntax.self
                ) {
                if  typealiasDeclaration.deprecationShim(for: primaryType.last) {
                    continue
                }
                if  case _? = matchingPrimaryDeclaration {
                    self.diagnose(
                        node: .init(typealiasDeclaration),
                        message: """
                        typealias '\(
                            typealiasDeclaration.name.text
                        )' cannot coexist with type '\(
                            primaryType.last
                        )' in '\(
                            self.name
                        )'
                        """
                    )
                } else if typealiasDeclaration.name.text == primaryType.last {
                    matchingTypealias = true
                } else {
                    self.diagnose(
                        node: .init(typealiasDeclaration),
                        message: """
                        typealias '\(
                            typealiasDeclaration.name.text
                        )' does not match filename '\(
                            self.name
                        )'
                        """
                    )
                }
                continue
            }

            if  let variableDeclaration: VariableDeclSyntax = declaration.as(
                    VariableDeclSyntax.self
                ) {
                for binding: PatternBindingSyntax in variableDeclaration.bindings {
                    let propertyName: String = "\(binding.pattern.trimmed)"
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            top-level property '\(propertyName)' cannot coexist with type '\(
                                primaryType.last
                            )' in '\(
                                self.name
                            )'
                            """
                        )
                    } else if propertyName == primaryType.last {
                        matchingFreeFunction = true
                    } else {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            top-level property '\(propertyName)' does not match filename '\(
                                self.name
                            )'
                            """
                        )
                    }
                }
                continue
            }
        }

        if  primaryType.nested {
            if  !primaryTypeFound {
                self.diagnose(
                    node: .init(self.tree),
                    message: """
                    layout file '\(self.name)' must define nested type '\(
                        primaryType.last
                    )' inside 'extension \(
                        primaryType.scope!
                    )'
                    """
                )
            }
        } else {
            if  !primaryTypeFound,
               !matchingFreeFunction,
               !matchingTypealias,
                self.name != "main.swift" {
                if  otherPrimaryTypeNames.isEmpty {
                    self.diagnose(
                        node: .init(self.tree),
                        message: """
                        layout file '\(self.name)' must define type '\(primaryType.last)'
                        """
                    )
                }
            }
        }
    }

    private mutating func checkNestedMembers(
        _ declaration: DeclSyntax,
        parentType: String
    ) {
        guard let members: MemberBlockItemListSyntax = declaration.memberBlockItemList else {
            return
        }
        self.checkExtensionMembers(members, parentType: parentType)
    }

    private mutating func checkExtensionMembers(
        _ members: MemberBlockItemListSyntax,
        parentType: String
    ) {
        for member: MemberBlockItemSyntax in members.unrolled {
            if  let enumDeclaration: EnumDeclSyntax = member.decl.as(EnumDeclSyntax.self) {
                let (keynum, simple): (keynum: Bool, simple: Bool) = Self.exemptKeynum(
                    enumDeclaration
                )
                switch (keynum, simple) {
                case (true, true):
                    continue

                case (true, false):
                    self.diagnose(
                        node: .init(enumDeclaration),
                        message: """
                        schema keynum '\(
                            enumDeclaration.name.text
                        )' has grown members beyond enum cases and must be defined in its own \
                        file '\(
                            parentType
                        ).\(
                            enumDeclaration.name.text
                        ).swift'
                        """
                    )
                    continue

                case (false, _):
                    self.diagnose(
                        node: .init(enumDeclaration),
                        message: """
                        nested type '\(enumDeclaration.name.text)' must be defined in its own \
                        file '\(
                            parentType
                        ).\(
                            enumDeclaration.name.text
                        ).swift'
                        """
                    )
                    continue
                }
            }

            if  let nestedType: OTPF.PrimaryType = member.decl.primaryType {
                let name: String = nestedType.last
                self.diagnose(
                    node: .init(member.decl),
                    message: """
                    nested type '\(name)' must be defined in its own file '\(parentType).\(
                        name
                    ).swift'
                    """
                )
            }
        }
    }

    private mutating func diagnose(
        node: Syntax,
        message: String,
        severity: DiagnosticSeverity = .error
    ) {
        let diagnostic: Diagnostic = .init(
            node: node,
            position: node.positionAfterSkippingLeadingTrivia,
            message: OTPF.DiagnosticMessage.init(message, severity: severity)
        )
        self.diagnostics.append(diagnostic)
    }

    private var toolsVersion: Substring? {
        for piece: TriviaPiece in self.tree.leadingTrivia.pieces {
            switch piece {
            case .newlines, .carriageReturnLineFeeds, .spaces, .tabs:
                continue
            case .lineComment(let text):
                let pattern: Regex<AnyRegexOutput> = try! .init(
                    #"^//\s*swift-tools-version:\s*(\S+)"#
                )
                guard
                let match: Regex<AnyRegexOutput>.Match = try? pattern.firstMatch(in: text),
                let version: Substring = match[1].substring else {
                    return nil
                }
                return version
            default:
                return nil
            }
        }
        return nil
    }

    private var packageDeclaration: Syntax? {
        for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
            guard case .decl(let declaration) = statement.item else {
                continue
            }
            if  case "Package"? = declaration.primaryType?.last {
                return .init(declaration)
            }
            if  let declaration: TypeAliasDeclSyntax = declaration.as(
                    TypeAliasDeclSyntax.self
                ),
                    declaration.name.text == "Package" {
                return .init(declaration)
            }
        }
        return nil
    }

    private static func exemptKeynum(_ enumDeclaration: EnumDeclSyntax) -> (
        keynum: Bool,
        simple: Bool
    ) {
        let name: String = enumDeclaration.name.text
        let keyName: Bool = name.hasSuffix("Key") || name.hasSuffix("Keys")
        let keyInheritance: Bool = enumDeclaration.inheritanceClause?.inheritedTypes.contains {
            let text: String = "\($0.type.trimmed)"
            return text == "CodingKey" || text.hasSuffix(".CodingKey")
        } ?? false

        guard keyName || keyInheritance else {
            return (keynum: false, simple: false)
        }

        let members: [MemberBlockItemSyntax] = enumDeclaration.memberBlock.members.unrolled
        var cases: Bool = false
        for member: MemberBlockItemSyntax in members {
            if  member.decl.is(EnumCaseDeclSyntax.self) {
                cases = true
            } else {
                return (keynum: true, simple: false)
            }
        }
        return (keynum: true, simple: cases)
    }
}
