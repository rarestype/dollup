import SwiftSyntax

extension DeclSyntax {
    var isPrimaryType: Bool {
        self.is(StructDeclSyntax.self) ||
        self.is(ClassDeclSyntax.self) ||
        self.is(EnumDeclSyntax.self) ||
        self.is(ActorDeclSyntax.self) ||
        self.is(ProtocolDeclSyntax.self)
    }

    var primaryTypeName: String? {
        let raw: String?
        if  let structDecl: StructDeclSyntax = self.as(StructDeclSyntax.self) {
            raw = structDecl.name.text
        } else if let classDecl: ClassDeclSyntax = self.as(ClassDeclSyntax.self) {
            raw = classDecl.name.text
        } else if let enumDecl: EnumDeclSyntax = self.as(EnumDeclSyntax.self) {
            raw = enumDecl.name.text
        } else if let actorDecl: ActorDeclSyntax = self.as(ActorDeclSyntax.self) {
            raw = actorDecl.name.text
        } else if let protocolDecl: ProtocolDeclSyntax = self.as(ProtocolDeclSyntax.self) {
            raw = protocolDecl.name.text
        } else {
            raw = nil
        }

        guard let raw else {
            return nil
        }
        return OTPF.PrimaryType(raw).last
    }

    var memberBlockItemList: MemberBlockItemListSyntax? {
        if  let structDecl: StructDeclSyntax = self.as(StructDeclSyntax.self) {
            return structDecl.memberBlock.members
        } else if let classDecl: ClassDeclSyntax = self.as(ClassDeclSyntax.self) {
            return classDecl.memberBlock.members
        } else if let enumDecl: EnumDeclSyntax = self.as(EnumDeclSyntax.self) {
            return enumDecl.memberBlock.members
        } else if let actorDecl: ActorDeclSyntax = self.as(ActorDeclSyntax.self) {
            return actorDecl.memberBlock.members
        } else if let protocolDecl: ProtocolDeclSyntax = self.as(ProtocolDeclSyntax.self) {
            return protocolDecl.memberBlock.members
        } else {
            return nil
        }
    }
}
