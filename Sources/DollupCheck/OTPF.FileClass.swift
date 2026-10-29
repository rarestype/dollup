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
        guard
        let dot: String.Index = name.lastIndex(of: "."),
        name[dot...] == ".swift" else {
            return nil
        }

        let stem: Substring = name[..<dot]
        if  let special: Special = Special.init(rawValue: String.init(stem)) {
            self = .special(special)
            return
        }
        if  let space: String.Index = stem.lastIndex(of: " ") {
            switch stem[space...] {
            case " (ext)":
                self = .ext(.init(stem[..<space]))
                return
            case " (gen)":
                self = .gen(.init(stem[..<space]))
                return
            default:
                break
            }
        }
        if  OTPF.manifest(name: name) {
            self = .layout("Package")
        } else {
            self = .layout(.init(stem))
        }
    }
}
