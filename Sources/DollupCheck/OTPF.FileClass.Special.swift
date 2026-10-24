extension OTPF.FileClass {
    public enum Special: String, Hashable, Sendable {
        case anchor
        case exports
        case lexemes
        case operators
        case package = "Package"
    }
}
