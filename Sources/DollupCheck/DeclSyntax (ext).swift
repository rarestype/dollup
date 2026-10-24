import SwiftSyntax

extension DeclSyntax {
    var primaryType: Bool {
        self.is(StructDeclSyntax.self) ||
        self.is(ClassDeclSyntax.self) ||
        self.is(EnumDeclSyntax.self) ||
        self.is(ActorDeclSyntax.self) ||
        self.is(ProtocolDeclSyntax.self)
    }

    var primaryTypeName: String? {
        let raw: String?
        if  let declaration: StructDeclSyntax = self.as(StructDeclSyntax.self) {
            raw = declaration.name.text
        } else if let declaration: ClassDeclSyntax = self.as(ClassDeclSyntax.self) {
            raw = declaration.name.text
        } else if let declaration: EnumDeclSyntax = self.as(EnumDeclSyntax.self) {
            raw = declaration.name.text
        } else if let declaration: ActorDeclSyntax = self.as(ActorDeclSyntax.self) {
            raw = declaration.name.text
        } else if let declaration: ProtocolDeclSyntax = self.as(ProtocolDeclSyntax.self) {
            raw = declaration.name.text
        } else {
            raw = nil
        }

        guard let raw else {
            return nil
        }
        return OTPF.PrimaryType.init(raw).last
    }

    var memberBlockItemList: MemberBlockItemListSyntax? {
        if  let declaration: StructDeclSyntax = self.as(StructDeclSyntax.self) {
            return declaration.memberBlock.members
        } else if let declaration: ClassDeclSyntax = self.as(ClassDeclSyntax.self) {
            return declaration.memberBlock.members
        } else if let declaration: EnumDeclSyntax = self.as(EnumDeclSyntax.self) {
            return declaration.memberBlock.members
        } else if let declaration: ActorDeclSyntax = self.as(ActorDeclSyntax.self) {
            return declaration.memberBlock.members
        } else if let declaration: ProtocolDeclSyntax = self.as(ProtocolDeclSyntax.self) {
            return declaration.memberBlock.members
        } else {
            return nil
        }
    }
}
