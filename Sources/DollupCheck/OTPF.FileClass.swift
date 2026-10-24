import SystemIO

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
    public init?(filename: String, in path: FilePath? = nil) {
        guard filename.hasSuffix(".swift") else {
            return nil
        }

        let stemEnd: String.Index = filename.index(filename.endIndex, offsetBy: -6)
        let stem: Substring = filename[..<stemEnd]

        if  let special: Special = Special.init(rawValue: String.init(stem)) {
            if  case .Package = special, let path, path.components.count > 1 {
                self = .layout(.init(stem))
                return
            }
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
