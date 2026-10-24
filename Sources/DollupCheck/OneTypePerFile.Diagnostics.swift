import SystemPackage

extension OneTypePerFile {
    public struct Diagnostics: Sendable {
        public let file: FilePath
        public let message: String

        public init(file: FilePath, message: String) {
            self.file = file
            self.message = message
        }
    }
}
extension OneTypePerFile.Diagnostics: CustomStringConvertible {
    public var description: String {
        """
        error: in '\(self.file)':
        \(self.message)
        """
    }
}
