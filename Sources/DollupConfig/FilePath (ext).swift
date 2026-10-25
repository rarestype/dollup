import SystemPackage

extension FilePath {
    public var packageManifest: Bool {
        if  case "Package.swift"? = self.components.last?.string {
            true
        } else {
            false
        }
    }
}
