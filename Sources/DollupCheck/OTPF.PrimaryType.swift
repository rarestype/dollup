extension OTPF {
    public struct PrimaryType: Hashable {
        public let scope: String?
        public let last: String
        public let encased: Bool

        public var isNested: Bool {
            self.scope != nil
        }

        public init(scope: String? = nil, last: String, encased: Bool = false) {
            self.scope = scope
            self.last = last
            self.encased = encased
        }

        public init(_ name: String) {
            let (scope, last, encased): (String?, String, Bool) = Self.parse(name)
            self.scope = scope
            self.last = last
            self.encased = encased
        }
    }
}

extension OTPF.PrimaryType {
    private static func parse(_ string: String) -> (String?, String, Bool) {
        var raw: Substring = string[...]
        while let first: Character = raw.first, first.isWhitespace {
            raw = raw.dropFirst()
        }
        while let last: Character = raw.last, last.isWhitespace {
            raw = raw.dropLast()
        }

        guard let dotIndex: Substring.Index = raw.lastIndex(of: ".") else {
            let (unencasedLast, encased): (String, Bool) = Self.unencase(String(raw))
            return (nil, unencasedLast, encased)
        }

        let rawScope: Substring = raw[..<dotIndex]
        let rawLast: Substring = raw[raw.index(after: dotIndex)...]

        let unencasedScope: String = rawScope
            .split(separator: ".")
            .map { Self.unencase(String($0)).0 }
            .joined(separator: ".")

        let (unencasedLast, encased): (String, Bool) = Self.unencase(String(rawLast))
        return (unencasedScope, unencasedLast, encased)
    }

    private static func unencase(_ token: String) -> (String, Bool) {
        if  token.hasPrefix("`"), token.hasSuffix("`"), token.count >= 2 {
            return (String(token.dropFirst().dropLast()), true)
        }
        return (token, false)
    }
}

extension OTPF.PrimaryType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.scope == rhs.scope && lhs.last == rhs.last
    }
}

extension OTPF.PrimaryType {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.scope)
        hasher.combine(self.last)
    }
}

extension OTPF.PrimaryType: CustomStringConvertible {
    public var description: String {
        let lastDisplay: String = self.encased ? "`\(self.last)`" : self.last
        if  let scope: String = self.scope {
            return "\(scope).\(lastDisplay)"
        } else {
            return lastDisplay
        }
    }
}

extension OTPF.PrimaryType {
    public var unencased: String {
        if  let scope: String = self.scope {
            return "\(scope).\(self.last)"
        } else {
            return self.last
        }
    }
}

extension OTPF.PrimaryType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
