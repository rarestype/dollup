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
            case .Package:
                return

            case .anchor:
                if  !self.tree.statements.isEmpty {
                    self.diagnose(
                        node: .init(self.tree.statements.first!),
                        message: "'anchor.swift' must be empty"
                    )
                }

            case .exports:
                for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                    if  case .decl(let declaration) = statement.item,
                        let importDecl: ImportDeclSyntax = declaration.as(ImportDeclSyntax.self),
                        importDecl.isExported {
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
                for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
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
                for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                    if  case .decl(let declaration) = statement.item, declaration.isPrimaryType {
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
            for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
                guard case .decl(let declaration) = statement.item else {
                    continue
                }
                if  let importDecl: ImportDeclSyntax = declaration.as(ImportDeclSyntax.self),
                    importDecl.isExported {
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
            for statement: CodeBlockItemSyntax in self.tree.statements.unrolled {
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
                    let target: PrimaryType = extensionDecl.extendedType.primaryType
                    if  target != expectedType {
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

                if  declaration.isPrimaryType {
                    let name: String = declaration.primaryTypeName ?? "unnamed"
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
            let statements: [CodeBlockItemSyntax] = self.tree.statements.unrolled
            let matchingPrimaryDeclaration: DeclSyntax?
            if !primaryType.isNested {
                matchingPrimaryDeclaration = statements.compactMap { (statement: CodeBlockItemSyntax) -> DeclSyntax? in
                    guard case .decl(let declaration) = statement.item,
                          declaration.isPrimaryType,
                          declaration.primaryTypeName == primaryType.last else {
                        return nil
                    }
                    return declaration
                }.first
            } else {
                matchingPrimaryDeclaration = nil
            }

            var foreignExtensionCount: Int = 0
            var primaryTypeFound: Bool = false
            var matchingFreeFunction: Bool = false
            var matchingTypealias: Bool = false
            var otherPrimaryTypeNames: [String] = []

            for statement: CodeBlockItemSyntax in statements {
                guard case .decl(let declaration) = statement.item else {
                    if  self.filename != "main.swift", !statement.item.is(ImportDeclSyntax.self) {
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
                    let target: PrimaryType = extensionDecl.extendedType.primaryType
                    if  target == primaryType {
                        self.checkExtensionMembers(
                            extensionDecl.memberBlock.members,
                            parentType: primaryType.description
                        )
                    } else if let scope: String = primaryType.scope, target == PrimaryType(scope) {
                        foreignExtensionCount += 1
                        if  foreignExtensionCount > 1 {
                            self.diagnose(
                                node: .init(extensionDecl),
                                message: """
                                layout file '\(
                                    self.filename
                                )' must contain only one extension to namespace '\(
                                    scope
                                )'
                                """
                            )
                        }
                        for member: MemberBlockItemSyntax in extensionDecl.memberBlock.members.unrolled {
                            if  member.decl.isPrimaryType {
                                let name: String = member.decl.primaryTypeName ?? ""
                                if  name == primaryType.last {
                                    primaryTypeFound = true
                                    self.checkNestedMembers(member.decl, parentType: primaryType.description)
                                } else {
                                    self.diagnose(
                                        node: .init(member.decl),
                                        message: """
                                        foreign extension to '\(scope)' in '\(
                                            self.filename
                                        )' must contain nothing except the definition of '\(
                                            primaryType.last
                                        )'
                                        """
                                    )
                                }
                            } else if let alias: TypeAliasDeclSyntax = member.decl.as(TypeAliasDeclSyntax.self) {
                                if  alias.name.text == primaryType.last {
                                    primaryTypeFound = true
                                } else {
                                    self.diagnose(
                                        node: .init(alias),
                                        message: """
                                        foreign extension to '\(scope)' in '\(
                                            self.filename
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
                                        self.filename
                                    )' must contain nothing except the definition of '\(
                                        primaryType.last
                                    )'
                                    """
                                )
                            }
                        }
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

                if  declaration.isPrimaryType {
                    let name: String = declaration.primaryTypeName ?? "unnamed"
                    if  primaryType.isNested {
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
                    } else if name == primaryType.last {
                        primaryTypeFound = true
                        self.checkNestedMembers(declaration, parentType: primaryType.description)
                    } else if case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            one type per file violation: found type '\(name)' in file '\(
                                self.filename
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

                if  let function: FunctionDeclSyntax = declaration.as(FunctionDeclSyntax.self) {
                    if  primaryType.isNested {
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
                    } else if case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            free function '\(function.name.text)' cannot coexist with type '\(
                                primaryType.last
                            )' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if function.name.text == primaryType.last {
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

                if  let macro: MacroDeclSyntax = declaration.as(MacroDeclSyntax.self) {
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(declaration),
                            message: """
                            macro '\(macro.name.text)' cannot coexist with type '\(primaryType.last)' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if macro.name.text == primaryType.last {
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
                    if  self.deprecationShim(alias, for: primaryType.last) {
                        continue
                    }
                    if  case _? = matchingPrimaryDeclaration {
                        self.diagnose(
                            node: .init(alias),
                            message: """
                            typealias '\(alias.name.text)' cannot coexist with type '\(
                                primaryType.last
                            )' in '\(
                                self.filename
                            )'
                            """
                        )
                    } else if alias.name.text == primaryType.last {
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

                if  let variable: VariableDeclSyntax = declaration.as(VariableDeclSyntax.self) {
                    for binding: PatternBindingSyntax in variable.bindings {
                        let propertyName: String = binding.pattern.trimmedDescription
                        if  case _? = matchingPrimaryDeclaration {
                            self.diagnose(
                                node: .init(declaration),
                                message: """
                                top-level property '\(propertyName)' cannot coexist with type '\(
                                    primaryType.last
                                )' in '\(
                                    self.filename
                                )'
                                """
                            )
                        } else if propertyName == primaryType.last {
                            matchingFreeFunction = true
                        }
                    }
                    continue
                }
            }

            if  primaryType.isNested {
                if  !primaryTypeFound {
                    self.diagnose(
                        node: .init(self.tree),
                        message: """
                        layout file '\(self.filename)' must define nested type '\(
                            primaryType.last
                        )' inside 'extension \(
                            primaryType.scope!
                        )'
                        """
                    )
                }
            } else {
                if  !primaryTypeFound, !matchingFreeFunction, !matchingTypealias, self.filename != "main.swift" {
                    if  otherPrimaryTypeNames.isEmpty {
                        self.diagnose(
                            node: .init(self.tree),
                            message: "layout file '\(self.filename)' must define type '\(primaryType.last)'"
                        )
                    }
                }
            }
        }

        private mutating func checkNestedMembers(_ declaration: DeclSyntax, parentType: String) {
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

                if  member.decl.isPrimaryType {
                    let name: String = member.decl.primaryTypeName ?? "unnamed"
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

            let members: [MemberBlockItemSyntax] = enumDecl.memberBlock.members.unrolled
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
                        alias.initializer.value.canonicalTypeName == expectedType ||
                        alias.initializer.value.trimmedDescription == expectedType {
                        return true
                    }
                }
            }
            return false
        }
    }
}
