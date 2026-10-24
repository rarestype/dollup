extension OTPF {
    public enum FileClass: Hashable, Sendable {
        case special(Special)
        case ext(PrimaryType)
        case gen(PrimaryType)
        case layout(PrimaryType)
    }
}

extension OTPF.FileClass {
    public init?(filename: String) {
        guard filename.hasSuffix(".swift") else {
            return nil
        }

        let stem: String = .init(filename.dropLast(6))

        if  let special: Special = Special(rawValue: stem) {
            self = .special(special)
        } else if stem.hasSuffix(" (ext)") {
            self = .ext(.init(String(stem.dropLast(6))))
        } else if stem.hasSuffix(" (gen)") {
            self = .gen(.init(String(stem.dropLast(6))))
        } else {
            self = .layout(.init(stem))
        }
    }
}
