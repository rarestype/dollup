import SwiftSyntax

public struct AttributesOptions {
    public var _alignment: Bool
    public var _alwaysEmitIntoClient: Bool
    public var attached: Bool
    public var available: Bool
    public var backDeployed: Bool
    public var _cdecl: Bool
    public var discardableResult: Bool
    public var _disfavoredOverload: Bool
    public var _documentation: Bool
    public var dynamicCallable: Bool
    public var dynamicMemberLookup: Bool
    public var _effects: Bool
    public var _exported: Bool
    public var freestanding: Bool
    public var frozen: Bool
    public var globalActor: Bool
    public var _hasStorage: Bool
    public var _implements: Bool
    public var _implementationOnly: Bool
    public var inlinable: Bool
    public var inline: Bool
    public var nonobjc: Bool
    public var _nonSendable: Bool
    public var main: Bool
    public var _marker: Bool
    public var objc: Bool
    public var objcMembers: Bool
    public var _optimize: Bool
    public var preconcurrency: Bool
    public var propertyWrapper: Bool
    public var resultBuilder: Bool
    public var _semantics: Bool
    public var _silgen_name: Bool
    public var _specialize: Bool
    public var _spi: Bool
    public var testable: Bool
    public var _transparent: Bool
    public var usableFromInline: Bool
    public var _weakLinked: Bool

    @available(*, unavailable, message: "@autoclosure is never foldable")
    public var autoclosure: Bool { false }
    @available(*, unavailable, message: "@convention is never foldable")
    public var convention: Bool { false }
    @available(*, unavailable, message: "@escaping is never foldable")
    public var escaping: Bool { false }
    @available(*, unavailable, message: "@unchecked is never foldable")
    public var unchecked: Bool { false }
    @available(*, unavailable, message: "@unknown is never foldable")
    public var unknown: Bool { false }

    public var allOthers: DefaultBehavior
}
extension AttributesOptions {
    static var foldDefaults: Self {
        .init(
            _alignment: true,
            _alwaysEmitIntoClient: true,
            attached: false,
            available: false,
            backDeployed: false,
            _cdecl: false,
            discardableResult: false,
            _disfavoredOverload: false,
            _documentation: false,
            dynamicCallable: true,
            dynamicMemberLookup: true,
            _effects: true,
            _exported: true,
            freestanding: false,
            frozen: true,
            globalActor: true,
            _hasStorage: true,
            _implements: false,
            _implementationOnly: true,
            inlinable: true,
            inline: true,
            nonobjc: true,
            _nonSendable: true,
            main: true,
            _marker: true,
            objc: true,
            objcMembers: true,
            _optimize: true,
            preconcurrency: true,
            propertyWrapper: true,
            resultBuilder: true,
            _semantics: false,
            _silgen_name: false,
            _specialize: false,
            _spi: true,
            testable: true,
            _transparent: true,
            usableFromInline: true,
            _weakLinked: true,
            allOthers: .nameOnly
        )
    }
    static var wrapDefaults: Self {
        .init(
            _alignment: false,
            _alwaysEmitIntoClient: false,
            attached: true,
            available: true,
            backDeployed: false,
            _cdecl: false,
            discardableResult: false,
            _disfavoredOverload: false,
            _documentation: true,
            dynamicCallable: false,
            dynamicMemberLookup: false,
            _effects: false,
            _exported: false,
            freestanding: true,
            frozen: false,
            globalActor: false,
            _hasStorage: false,
            _implements: false,
            _implementationOnly: false,
            inlinable: false,
            inline: false,
            nonobjc: false,
            _nonSendable: false,
            main: false,
            _marker: false,
            objc: false,
            objcMembers: false,
            _optimize: false,
            preconcurrency: false,
            propertyWrapper: false,
            resultBuilder: false,
            _semantics: false,
            _silgen_name: false,
            _specialize: true,
            _spi: false,
            testable: false,
            _transparent: false,
            usableFromInline: false,
            _weakLinked: false,
            allOthers: .always
        )
    }
}
extension AttributesOptions {
    func applies(to node: AttributeSyntax) -> Bool {
        guard
        let name: TokenSyntax = node.attributeName.as(IdentifierTypeSyntax.self)?.name else {
            return false
        }

        switch name.text {
        case "_alignment": return self._alignment
        case "_alwaysEmitIntoClient": return self._alwaysEmitIntoClient
        case "attached": return self.attached
        case "available": return self.available
        case "backDeployed": return self.backDeployed
        case "_cdecl": return self._cdecl
        case "discardableResult": return self.discardableResult
        case "_disfavoredOverload": return self._disfavoredOverload
        case "_documentation": return self._documentation
        case "dynamicCallable": return self.dynamicCallable
        case "dynamicMemberLookup": return self.dynamicMemberLookup
        case "_effects": return self._effects
        case "_exported": return self._exported
        case "freestanding": return self.freestanding
        case "frozen": return self.frozen
        case "globalActor": return self.globalActor
        case "_hasStorage": return self._hasStorage
        case "_implements": return self._implements
        case "_implementationOnly": return self._implementationOnly
        case "inlinable": return self.inlinable
        case "inline": return self.inline
        case "nonobjc": return self.nonobjc
        case "_nonSendable": return self._nonSendable
        case "main": return self.main
        case "_marker": return self._marker
        case "objc": return self.objc
        case "objcMembers": return self.objcMembers
        case "_optimize": return self._optimize
        case "preconcurrency": return self.preconcurrency
        case "propertyWrapper": return self.propertyWrapper
        case "resultBuilder": return self.resultBuilder
        case "_semantics": return self._semantics
        case "_silgen_name": return self._silgen_name
        case "_specialize": return self._specialize
        case "_spi": return self._spi
        case "testable": return self.testable
        case "_transparent": return self._transparent
        case "usableFromInline": return self.usableFromInline
        case "_weakLinked": return self._weakLinked
        default: break
        }

        switch self.allOthers {
        case .always:
            return true

        case .nameOnly:
            if case .argumentList(let arguments)? = node.arguments {
                return arguments.isEmpty
            } else {
                return true
            }

        case .never:
            return false
        }
    }
}
