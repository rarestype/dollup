import SystemPackage

extension FilePath {
    public var isPackageManifest: Bool {
        if  case "Package.swift"? = self.components.last?.string {
            true
        } else {
            false
        }
    }
}
