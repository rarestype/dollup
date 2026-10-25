extension OTPF {
    public enum FileClass {
        case special(Special)
        case ext(PrimaryType)
        case gen(PrimaryType)
        case layout(PrimaryType)
    }
}

extension OTPF.FileClass: Hashable {}

extension OTPF.FileClass {
    public init?(name: String) {
        guard name.hasSuffix(".swift") else {
            return nil
        }

        let stemEnd: String.Index = name.index(name.endIndex, offsetBy: -6)
        let stem: Substring = name[..<stemEnd]

        if  let special: Special = Special.init(rawValue: String.init(stem)) {
            self = .special(special)
        } else if stem.hasSuffix(" (ext)") {
            let typeEnd: String.Index = stem.index(stem.endIndex, offsetBy: -6)
            self = .ext(.init(stem[..<typeEnd]))
        } else if stem.hasSuffix(" (gen)") {
            let typeEnd: String.Index = stem.index(stem.endIndex, offsetBy: -6)
            self = .gen(.init(stem[..<typeEnd]))
        } else {
            self = .layout(.init(stem))
        }
    }
}
