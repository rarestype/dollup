extension OTPF {
    public struct PrimaryType {
        public let scope: String?
        public let last: String
        public let encased: Bool

        public init(scope: String? = nil, last: String, encased: Bool = false) {
            self.scope = scope
            self.last = last
            self.encased = encased
        }
    }
}

extension OTPF.PrimaryType {
    public init(_ name: String) {
        self.init(name[...])
    }

    public init(_ name: Substring) {
        let (scope, last, encased): (String?, String, Bool) = Self.parse(name)
        self.init(scope: scope, last: last, encased: encased)
    }

    public var nested: Bool {
        self.scope != nil
    }

    public var unencased: String {
        if  let scope: String = self.scope {
            return "\(scope).\(self.last)"
        } else {
            return self.last
        }
    }
}

extension OTPF.PrimaryType {
    private static func parse(_ string: Substring) -> (
        scope: String?,
        last: String,
        encased: Bool
    ) {
        var raw: Substring = string
        while let first: Character = raw.first, first.isWhitespace {
            raw = raw.dropFirst()
        }
        while let last: Character = raw.last, last.isWhitespace {
            raw = raw.dropLast()
        }

        guard let dot: Substring.Index = raw.lastIndex(of: ".") else {
            let (last, encased): (String, Bool) = Self.unencase(raw)
            return (nil, last, encased)
        }

        let rawScope: Substring = raw[..<dot]
        let rawLast: Substring = raw[raw.index(after: dot)...]

        var scope: String = ""
        var remainder: Substring = rawScope
        while let dotIndex: Substring.Index = remainder.firstIndex(of: ".") {
            scope.append(Self.unencase(remainder[..<dotIndex]).unencased)
            scope.append(".")
            remainder = remainder[remainder.index(after: dotIndex)...]
        }
        scope.append(Self.unencase(remainder).unencased)

        let (last, encased): (String, Bool) = Self.unencase(rawLast)
        return (scope, last, encased)
    }

    private static func unencase(_ token: Substring) -> (unencased: String, encased: Bool) {
        if  token.hasPrefix("`"), token.hasSuffix("`"), token.count >= 2 {
            let inner: Substring = token.dropFirst().dropLast()
            return (String.init(inner), true)
        }
        return (String.init(token), false)
    }
}

extension OTPF.PrimaryType: Equatable {
    public static func == (a: Self, b: Self) -> Bool {
        (a.scope, a.last) == (b.scope, b.last)
    }
}

extension OTPF.PrimaryType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.scope)
        hasher.combine(self.last)
    }
}

extension OTPF.PrimaryType: CustomStringConvertible {
    public var description: String {
        let last: String = self.encased ? "`\(self.last)`" : self.last
        if  let scope: String = self.scope {
            return "\(scope).\(last)"
        } else {
            return last
        }
    }
}

extension OTPF.PrimaryType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
