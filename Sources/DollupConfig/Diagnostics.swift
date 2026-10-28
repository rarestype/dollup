import SystemPackage

public struct Diagnostics {
    public let file: FilePath?
    public let message: String
    public let error: Bool

    public init(file: FilePath? = nil, message: String, error: Bool = true) {
        self.file = file
        self.message = message
        self.error = error
    }
}

extension Diagnostics: CustomStringConvertible {
    public var description: String {
        let prefix: String = self.error ? "error" : "warning"
        if  let file: FilePath = self.file {
            return """
            \(prefix): in '\(file)':
            \(self.message)
            """
        } else {
            return """
            \(prefix):
            \(self.message)
            """
        }
    }
}
