import SystemPackage

public struct Diagnostics {
    public let file: FilePath?
    public let message: String

    public init(file: FilePath? = nil, message: String) {
        self.file = file
        self.message = message
    }
}

extension Diagnostics: CustomStringConvertible {
    public var description: String {
        if  let file: FilePath = self.file {
            """
            error: in '\(file)':
            \(self.message)
            """
        } else {
            """
            error:
            \(self.message)
            """
        }
    }
}
