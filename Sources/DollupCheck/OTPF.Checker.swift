import SwiftDiagnostics
import SwiftSyntax
import SystemIO

extension OTPF {
    struct Checker {
        let file: FilePath
        let filename: String
        let tree: SourceFileSyntax

        var diagnostics: [Diagnostic] = []

        init(tree: SourceFileSyntax, file: FilePath) {
            self.file = file
            self.filename = file.lastComponent?.string ?? ""
            self.tree = tree
        }

        mutating func check() -> [Diagnostic] {
            guard let fileClass: OTPF.FileClass = .init(filename: self.filename) else {
                return []
            }

            if  self.filename.contains("+") {
                self.diagnose(
                    node: .init(self.tree),
                    message: """
                    plus signs ('+') are never allowed in filenames; use ' (ext)' for extension files
                    """
                )
                return self.diagnostics
            }

            switch fileClass {
            case .special(let special):
                self.checkSpecial(special)

            case .ext(let primaryType), .gen(let primaryType):
                self.checkGlobalRestrictions()
                self.checkExtension(expectedType: primaryType)

            case .layout(let primaryType):
                self.checkGlobalRestrictions()
                self.checkLayout(primaryType)
            }

            return self.diagnostics
        }

        private mutating func checkSpecial(_ special: OTPF.FileClass.Special) {
            switch special {
            case .package:
                return

            case .anchor:
                if  !self.tree.statements.isEmpty {
                    self.diagnose(
                        node: .init(self.tree.statements.first!),
                        message: "'anchor.swift' must be empty"
                    )
                }

            case .exports:
                let statements: [CodeBlockItemSyntax] = self.unrollStatements(
                    self.tree.statements
                )
                for statement: CodeBlockItemSyntax in statements {
                    if  case .decl(let declaration) = statement.item,
                        let importDecl: ImportDeclSyntax = declaration.as(ImportDeclSyntax.self),
                        self.exportedImport(importDecl) {
                        continue
                    }
                    self.diagnose(
                        node: .init(statement),
                        message: """
                        'exports.swift' can only contain '@_exported import' statements
                        """
                    )
                }

            case .lexemes:
                let statements: [CodeBlockItemSyntax] = self.unrollStatements(
                    self.tree.statements
                )
                for statement: CodeBlockItemSyntax in statements {
                    if  case .decl(let declaration) = statement.item {
                        if  declaration.is(OperatorDeclSyntax.self) || declaration.is(
                                PrecedenceGroupDeclSyntax.self
                            ) {
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
                let statements: [CodeBlockItemSyntax] = self.unrollStatements(
                    self.tree.statements
                )
                for statement: CodeBlockItemSyntax in statements {
                    if  case .decl(let declaration) = statement.item,
                        self.primaryType(declaration) {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            'operators.swift' cannot declare types; it can only contain top-level operator functions
                            """
                        )
                    }
                }
            }
        }

        private mutating func checkGlobalRestrictions() {
            let statements: [CodeBlockItemSyntax] = self.unrollStatements(self.tree.statements)
            for statement: CodeBlockItemSyntax in statements {
                guard case .decl(let declaration) = statement.item else {
                    continue
                }
                if  let importDecl: ImportDeclSyntax = declaration.as(ImportDeclSyntax.self),
                    self.exportedImport(importDecl) {
                    self.diagnose(
                        node: .init(importDecl),
                        message: "'@_exported import' is prohibited outside 'exports.swift'"
                    )
                }
                if  declaration.is(OperatorDeclSyntax.self) || declaration.is(PrecedenceGroupDeclSyntax.self) {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        operator and precedencegroup declarations are prohibited outside 'lexemes.swift'
                        """
                    )
                }
            }
        }

        private mutating func checkExtension(expectedType: PrimaryType) {
            let statements: [CodeBlockItemSyntax] = self.unrollStatements(self.tree.statements)
            for statement: CodeBlockItemSyntax in statements {
                guard case .decl(let declaration) = statement.item else {
                    if  !statement.item.is(ImportDeclSyntax.self) {
                        self.diagnose(
                            node: .init(statement),
                            message: """
                            extension file '\(
                                self.filename
                            )' cannot contain top-level executable statements
                            """
                        )
                    }
                    continue
                }

                if  declaration.is(ImportDeclSyntax.self) {
                    continue
                }

                if  let extensionDecl: ExtensionDeclSyntax = declaration.as(ExtensionDeclSyntax.self) {
                    let target: PrimaryType = .init(self.canonicalTypeName(of: extensionDecl.extendedType))
                    let trimmed: PrimaryType = .init(extensionDecl.extendedType.trimmedDescription)
                    if  target != expectedType && trimmed != expectedType {
                        self.diagnose(
                            node: .init(extensionDecl),
                            message: """
                            extension file '\(self.filename)' cannot contain extension to '\(
                                extensionDecl.extendedType.trimmedDescription
                            )'; it must only extend '\(
                                expectedType.description
                            )'
                            """
                        )
                    }
                    self.checkExtensionMembers(
                        extensionDecl.memberBlock.members,
                        parentType: expectedType.description
                    )
                    continue
                }

                if  self.primaryType(declaration) {
                    let name: String = self.name(of: declaration) ?? "unnamed"
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        extension file '\(self.filename)' cannot define primary type '\(name)'
                        """
                    )
                    continue
                }

                if  let function: FunctionDeclSyntax = declaration.as(FunctionDeclSyntax.self) {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        extension file '\(self.filename)' cannot contain free function '\(
                            function.name.text
                        )'
                        """
                    )
                    continue
                }

                if  declaration.is(VariableDeclSyntax.self) {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        extension file '\(self.filename)' cannot contain top-level properties
                        """
                    )
                    continue
                }
            }
        }

        private mutating func checkLayout(_ primaryType: PrimaryType) {
            if  primaryType.isNested {
                self.checkNestedLayout(primaryType)
            } else {
                self.checkTopLevelLayout(primaryType)
            }
        }

        private mutating func checkNestedLayout(_ primaryType: PrimaryType) {
            let scopeName: String = primaryType.scope!
            let scopeType: PrimaryType = .init(scopeName)
            let innerName: String = primaryType.last

            var foreignExtensionCount: Int = 0
            var primaryTypeFound: Bool = false

            let statements: [CodeBlockItemSyntax] = self.unrollStatements(self.tree.statements)
            for statement: CodeBlockItemSyntax in statements {
                guard case .decl(let declaration) = statement.item else {
                    if  !statement.item.is(ImportDeclSyntax.self) {
                        self.diagnose(
                            node: .init(statement),
                            message: """
                            layout file '\(
                                self.filename
                            )' cannot contain top-level executable statements
                            """
                        )
                    }
                    continue
                }

                if  declaration.is(ImportDeclSyntax.self) {
                    continue
                }

                if  let extensionDecl: ExtensionDeclSyntax = declaration.as(ExtensionDeclSyntax.self) {
                    let target: PrimaryType = .init(self.canonicalTypeName(of: extensionDecl.extendedType))
                    let trimmed: PrimaryType = .init(extensionDecl.extendedType.trimmedDescription)

                    if  target == scopeType || trimmed == scopeType {
                        foreignExtensionCount += 1
                        if  foreignExtensionCount > 1 {
                            self.diagnose(
                                node: .init(extensionDecl),
                                message: """
                                layout file '\(
                                    self.filename
                                )' must contain only one extension to namespace '\(
                                    scopeName
                                )'
                                """
                            )
                        }
                        let members: [MemberBlockItemSyntax] = self.unrollMembers(
                            extensionDecl.memberBlock.members
                        )
                        for member: MemberBlockItemSyntax in members {
                            if  self.primaryType(member.decl) {
                                let name: String = self.name(of: member.decl) ?? ""
                                if  name == innerName {
                                    primaryTypeFound = true
                                    self.checkNestedMembers(member.decl, parentType: primaryType.description)
                                } else {
                                    self.diagnose(
                                        node: .init(member.decl),
                                        message: """
                                        foreign extension to '\(scopeName)' in '\(
                                            self.filename
                                        )' must contain nothing except the definition of '\(
                                            innerName
                                        )'
                                        """
                                    )
                                }
                            } else if let alias: TypeAliasDeclSyntax = member.decl.as(
                                    TypeAliasDeclSyntax.self
                                ) {
                                if  alias.name.text == innerName {
                                    primaryTypeFound = true
                                } else {
                                    self.diagnose(
                                        node: .init(alias),
                                        message: """
                                        foreign extension to '\(scopeName)' in '\(
                                            self.filename
                                        )' must contain nothing except the definition of '\(
                                            innerName
                                        )'
                                        """
                                    )
                                }
                            } else {
                                self.diagnose(
                                    node: .init(member.decl),
                                    message: """
                                    foreign extension to '\(scopeName)' in '\(
                                        self.filename
                                    )' must contain nothing except the definition of '\(
                                        innerName
                                    )'
                                    """
                                )
                            }
                        }
                    } else if target == primaryType || trimmed == primaryType {
                        self.checkExtensionMembers(
                            extensionDecl.memberBlock.members,
                            parentType: primaryType.description
                        )
                    } else {
                        self.diagnose(
                            node: .init(extensionDecl),
                            message: """
                            layout file '\(
                                self.filename
                            )' cannot contain extension to foreign type '\(
                                extensionDecl.extendedType.trimmedDescription
                            )'
                            """
                        )
                    }
                    continue
                }

                if  self.primaryType(declaration) {
                    let name: String = self.name(of: declaration) ?? "unnamed"
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        one type per file violation: found top-level type '\(
                            name
                        )' in nested layout file '\(
                            self.filename
                        )'
                        """
                    )
                    continue
                }

                if  let function: FunctionDeclSyntax = declaration.as(FunctionDeclSyntax.self) {
                    self.diagnose(
                        node: .init(declaration),
                        message: """
                        free function '\(
                            function.name.text
                        )' cannot appear in nested layout file '\(
                            self.filename
                        )'
                        """
                    )
                    continue
                }
            }

            if  !primaryTypeFound {
                self.diagnose(
                    node: .init(self.tree),
                    message: """
                    layout file '\(self.filename)' must define nested type '\(
                        innerName
                    )' inside 'extension \(
                        scopeName
                    )'
                    """
                )
            }
        }

        private mutating func checkTopLevelLayout(_ primaryType: PrimaryType) {
            let stem: String = primaryType.last
            let statements: [CodeBlockItemSyntax] = self.unrollStatements(self.tree.statements)
            let matchingPrimaryDeclaration: DeclSyntax? = statements.compactMap { (statement: CodeBlockItemSyntax) -> DeclSyntax? in
                guard case .decl(let declaration) = statement.item, self.primaryType(declaration) else {
                    return nil
                }
                return (self.name(of: declaration) == stem) ? declaration : nil
            }.first

            var primaryTypeFound: Bool = false
            var matchingFreeFunction: Bool = false
            var matchingTypealias: Bool = false
            var otherPrimaryTypeNames: [String] = []

            for statement: CodeBlockItemSyntax in statements {
                guard case .decl(let declaration) = statement.item else {
                    if  stem != "main", !statement.item.is(ImportDeclSyntax.self) {
                        self.diagnose(
                            node: .init(statement),
                            message: """
                            layout file '\(
                                self.filename
                            )' cannot contain top-level executable statements
                            """
                        )
                    }
                    continue
                }

                if  declaration.is(ImportDeclSyntax.self) {
                    continue
                }

                if  let extensionDecl: ExtensionDeclSyntax = declaration.as(ExtensionDeclSyntax.self) {
                    let target: PrimaryType = .init(self.canonicalTypeName(of: extensionDecl.extendedType))
                    let trimmed: PrimaryType = .init(extensionDecl.extendedType.trimmedDescription)
                    if  target == primaryType || trimmed == primaryType {
                        self.checkExtensionMembers(
                            extensionDecl.memberBlock.members,
                            parentType: primaryType.description
                        )
                    } else {
                        self.diagnose(
                            node: .init(extensionDecl),
                            message: """
                            layout file '\(
                                self.filename
                            )' cannot contain extension to foreign type '\(
                                extensionDecl.extendedType.trimmedDescription
                            )'
                            """
                        )
                    }
                    continue
                }

                if  self.primaryType(declaration) {
                    let name: String = self.name(of: declaration) ?? ""
                    if  name == stem {
                        primaryTypeFound = true
                        self.checkNestedMembers(declaration, parentType: primaryType.description)
                    } else if case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            one type per file violation: found type '\(name)' in file '\(
                                self.filename
                            )' which defines '\(
                                stem
                            )'
                            """
                        )
                    } else {
                        if  otherPrimaryTypeNames.isEmpty {
                            self.diagnose(
                                node: .init(declaration),
                                message: """
                                type '\(name)' does not match filename '\(self.filename)'
                                """
                            )
                        } else {
                            self.diagnose(
                                node: .init(declaration),
                                message: """
                                one type per file violation: found type '\(name)' in file '\(
                                    self.filename
                                )'
                                """
                            )
                        }
                        otherPrimaryTypeNames.append(name)
                    }
                    continue
                }

                if  let macro: MacroDeclSyntax = declaration.as(MacroDeclSyntax.self) {
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            macro '\(macro.name.text)' cannot coexist with type '\(stem)' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if macro.name.text == stem {
                        primaryTypeFound = true
                    } else {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            macro '\(macro.name.text)' does not match filename '\(
                                self.filename
                            )'
                            """
                        )
                    }
                    continue
                }

                if  let alias: TypeAliasDeclSyntax = declaration.as(TypeAliasDeclSyntax.self) {
                    if  self.deprecationShim(alias, for: stem) {
                        continue
                    }
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(alias),
                            message: """
                            typealias '\(alias.name.text)' cannot coexist with type '\(
                                stem
                            )' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if alias.name.text == stem {
                        matchingTypealias = true
                    } else {
                        self.diagnose(
                            node: .init(alias),
                            message: """
                            typealias '\(alias.name.text)' does not match filename '\(
                                self.filename
                            )'
                            """
                        )
                    }
                    continue
                }

                if  let function: FunctionDeclSyntax = declaration.as(FunctionDeclSyntax.self) {
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            free function '\(function.name.text)' cannot coexist with type '\(
                                stem
                            )' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if function.name.text == stem {
                        matchingFreeFunction = true
                    } else {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            free function '\(function.name.text)' does not match filename '\(
                                self.filename
                            )'
                            """
                        )
                    }
                    continue
                }

                if  let variable: VariableDeclSyntax = declaration.as(VariableDeclSyntax.self) {
                    for binding: PatternBindingSyntax in variable.bindings {
                        let propertyName: String = binding.pattern.trimmedDescription
                        if  case _? = matchingPrimaryDeclaration {
                            self.diagnose(
                                node: .init(declaration),
                                message: """
                                top-level property '\(propertyName)' cannot coexist with type '\(
                                    stem
                                )' in '\(
                                    self.filename
                                )'
                                """
                            )
                        } else if propertyName == stem {
                            matchingFreeFunction = true
                        }
                    }
                    continue
                }
            }

            if  !primaryTypeFound, !matchingFreeFunction, !matchingTypealias, stem != "main" {
                if  otherPrimaryTypeNames.isEmpty {
                    self.diagnose(
                        node: .init(self.tree),
                        message: "layout file '\(self.filename)' must define type '\(stem)'"
                    )
                }
            }
        }

        private mutating func checkNestedMembers(_ declaration: DeclSyntax, parentType: String) {
            let members: MemberBlockItemListSyntax?
            if  let structDecl: StructDeclSyntax = declaration.as(StructDeclSyntax.self) {
                members = structDecl.memberBlock.members
            } else if let classDecl: ClassDeclSyntax = declaration.as(ClassDeclSyntax.self) {
                members = classDecl.memberBlock.members
            } else if let enumDecl: EnumDeclSyntax = declaration.as(EnumDeclSyntax.self) {
                members = enumDecl.memberBlock.members
            } else if let actorDecl: ActorDeclSyntax = declaration.as(ActorDeclSyntax.self) {
                members = actorDecl.memberBlock.members
            } else if let protocolDecl: ProtocolDeclSyntax = declaration.as(ProtocolDeclSyntax.self) {
                members = protocolDecl.memberBlock.members
            } else {
                members = nil
            }

            guard let members: MemberBlockItemListSyntax else {
                return
            }
            self.checkExtensionMembers(members, parentType: parentType)
        }

        private mutating func checkExtensionMembers(
            _ members: MemberBlockItemListSyntax,
            parentType: String
        ) {
            let unrolled: [MemberBlockItemSyntax] = self.unrollMembers(members)
            for member: MemberBlockItemSyntax in unrolled {
                if  let enumDecl: EnumDeclSyntax = member.decl.as(EnumDeclSyntax.self) {
                    let (keynum, simple): (Bool, Bool) = self.exemptKeynum(enumDecl)
                    if  keynum && simple {
                        continue
                    }
                    if  keynum && !simple {
                        self.diagnose(
                            node: .init(enumDecl),
                            message: """
                            schema keynum '\(
                                enumDecl.name.text
                            )' has grown members beyond enum cases and must be defined in its own file '\(
                                parentType
                            ).\(
                                enumDecl.name.text
                            ).swift'
                            """
                        )
                        continue
                    }
                    self.diagnose(
                        node: .init(enumDecl),
                        message: """
                        nested type '\(enumDecl.name.text)' must be defined in its own file '\(
                            parentType
                        ).\(
                            enumDecl.name.text
                        ).swift'
                        """
                    )
                    continue
                }

                if  self.primaryType(member.decl) {
                    let name: String = self.name(of: member.decl) ?? "unnamed"
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

        private mutating func diagnose(node: Syntax, message: String) {
            let diagnostic: Diagnostic = .init(
                node: node,
                position: node.positionAfterSkippingLeadingTrivia,
                message: DiagnosticMessage.init(message)
            )
            self.diagnostics.append(diagnostic)
        }

        private func unrollStatements(
            _ statements: CodeBlockItemListSyntax
        ) -> [CodeBlockItemSyntax] {
            var result: [CodeBlockItemSyntax] = []
            for item: CodeBlockItemSyntax in statements {
                if  case .decl(let declaration) = item.item,
                    let ifConfig: IfConfigDeclSyntax = declaration.as(IfConfigDeclSyntax.self) {
                    for clause: IfConfigClauseSyntax in ifConfig.clauses {
                        if  case .statements(let nested)? = clause.elements {
                            result.append(contentsOf: self.unrollStatements(nested))
                        }
                    }
                } else {
                    result.append(item)
                }
            }
            return result
        }

        private func unrollMembers(
            _ members: MemberBlockItemListSyntax
        ) -> [MemberBlockItemSyntax] {
            var result: [MemberBlockItemSyntax] = []
            for member: MemberBlockItemSyntax in members {
                if  let ifConfig: IfConfigDeclSyntax = member.decl.as(IfConfigDeclSyntax.self) {
                    for clause: IfConfigClauseSyntax in ifConfig.clauses {
                        if  case .decls(let nested)? = clause.elements {
                            result.append(contentsOf: self.unrollMembers(nested))
                        }
                    }
                } else {
                    result.append(member)
                }
            }
            return result
        }

        private func canonicalTypeName(of type: TypeSyntax) -> String {
            if  type.is(ArrayTypeSyntax.self) {
                return "Array"
            }
            if  type.is(DictionaryTypeSyntax.self) {
                return "Dictionary"
            }
            if  type.is(OptionalTypeSyntax.self) {
                return "Optional"
            }
            if  let member: MemberTypeSyntax = type.as(MemberTypeSyntax.self) {
                let base: String = self.canonicalTypeName(of: member.baseType)
                return "\(base).\(member.name.text)"
            }
            if  let identifier: IdentifierTypeSyntax = type.as(IdentifierTypeSyntax.self) {
                return identifier.name.text
            }
            return type.trimmedDescription
        }

        private func exemptKeynum(_ enumDecl: EnumDeclSyntax) -> (
            keynum: Bool,
            simple: Bool
        ) {
            let name: String = enumDecl.name.text
            let keyName: Bool = name.hasSuffix("Key") || name.hasSuffix("Keys")
            let keyInheritance: Bool = enumDecl.inheritanceClause?.inheritedTypes.contains { (inherited: InheritedTypeSyntax) in
                let text: String = inherited.type.trimmedDescription
                return text == "CodingKey" || text.hasSuffix(".CodingKey")
            } ?? false

            guard keyName || keyInheritance else {
                return (keynum: false, simple: false)
            }

            let members: [MemberBlockItemSyntax] = self.unrollMembers(
                enumDecl.memberBlock.members
            )
            var casesPresent: Bool = false
            for member: MemberBlockItemSyntax in members {
                if  member.decl.is(EnumCaseDeclSyntax.self) {
                    casesPresent = true
                } else {
                    return (keynum: true, simple: false)
                }
            }
            return (keynum: true, simple: casesPresent)
        }

        private func deprecationShim(
            _ alias: TypeAliasDeclSyntax,
            for expectedType: String
        ) -> Bool {
            for attributeElement: AttributeListSyntax.Element in alias.attributes {
                guard case .attribute(let attribute) = attributeElement,
                attribute.attributeName.trimmedDescription == "available" else {
                    continue
                }
                let arguments: String = attribute.arguments?.trimmedDescription ?? ""
                if  arguments.contains("deprecated") {
                    if  arguments.contains("renamed: \"\(expectedType)\"") ||
                        self.canonicalTypeName(of: alias.initializer.value) == expectedType ||
                        alias.initializer.value.trimmedDescription == expectedType {
                        return true
                    }
                }
            }
            return false
        }

        private func exportedImport(_ importDecl: ImportDeclSyntax) -> Bool {
            for attributeElement: AttributeListSyntax.Element in importDecl.attributes {
                if  case .attribute(let attribute) = attributeElement,
                    attribute.attributeName.trimmedDescription == "_exported" {
                    return true
                }
            }
            return false
        }

        private func primaryType(_ declaration: DeclSyntax) -> Bool {
            declaration.is(StructDeclSyntax.self) ||
            declaration.is(ClassDeclSyntax.self) ||
            declaration.is(EnumDeclSyntax.self) ||
            declaration.is(ActorDeclSyntax.self) ||
            declaration.is(ProtocolDeclSyntax.self)
        }

        private func name(of declaration: DeclSyntax) -> String? {
            let raw: String?
            if  let structDecl: StructDeclSyntax = declaration.as(StructDeclSyntax.self) { raw = structDecl.name.text }
            else if let classDecl: ClassDeclSyntax = declaration.as(ClassDeclSyntax.self) { raw = classDecl.name.text }
            else if let enumDecl: EnumDeclSyntax = declaration.as(EnumDeclSyntax.self) { raw = enumDecl.name.text }
            else if let actorDecl: ActorDeclSyntax = declaration.as(ActorDeclSyntax.self) { raw = actorDecl.name.text }
            else if let protocolDecl: ProtocolDeclSyntax = declaration.as(ProtocolDeclSyntax.self) { raw = protocolDecl.name.text }
            else { raw = nil }

            guard let raw else { return nil }
            return PrimaryType.init(raw).last
        }
    }
}
