extension OTPF.FileClass {
    public enum Special: String {
        case anchor
        case exports
        case lexemes
        case operators
    }
}

extension OTPF.FileClass.Special: Hashable {}
