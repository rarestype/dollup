import Dollup
import DollupCheck
import SystemIO

public protocol DollupConfiguration {
    static func configure(file: FilePath?, settings: inout DollupSettings) throws
    static func filter(file: FilePath) throws -> Bool
    static func report(file: FilePath) throws

    static func check(file: FilePath) throws -> Bool
    static func check(name: FilePath.Component, text: String) throws -> Diagnostics?
}
extension DollupConfiguration {
    public static func filter(file _: FilePath) throws -> Bool { true }
    public static func report(file _: FilePath) throws {}

    public static func check(file: FilePath) throws -> Bool {
        try self.filter(file: file)
    }

    public static func check(
        name: FilePath.Component,
        text: String
    ) throws -> Diagnostics? {
        if  let (message, error): (String, Bool) = OTPF.diagnose(source: text, in: name.string) {
            Diagnostics.init(message: message, error: error)
        } else {
            nil
        }
    }
}
extension DollupConfiguration {
    public static func format(
        _ source: String,
        id: FilePath? = nil
    ) throws -> String? {
        var settings: DollupSettings = .init()
        try self.configure(file: id, settings: &settings)
        var after: String = source

        try settings.whitespace.reformat(&after, check: settings.check)

        if !after.utf8.elementsEqual(source.utf8) {
            return after
        } else {
            return nil
        }
    }
}
extension DollupConfiguration {
    @MainActor public static func main() {
        DollupCommand<Self>.Format.main()
    }
}
extension DollupConfiguration {
    public static func run(in path: FilePath) throws {
        guard
        let status: FileStatus = try path.status else {
            return
        }

        if  status.is(.regular) {
            try self.run(on: path)
            return
        }

        guard status.is(.directory) else {
            throw """
            path '\(path)' is not a file or directory
            """ as DollupError
        }

        try path.directory.walk {
            let path: FilePath = $0 / $1
            if  case true? = try path.status?.is(.regular),
                case "swift" = $1.extension {
                try self.run(on: path)
            }
        } directory: { _, component in
            if  component.string.hasPrefix(".") {
                nil
            } else {
                .descend
            }
        }
    }

    public static func run(on file: FilePath) throws {
        if  try self.filter(file: file),
            let formatted: String = try self.format(try file.read(), id: file) {
            try self.report(file: file)
            try file.overwrite(with: [UInt8].init(formatted.utf8)[...])
        }
    }
}

extension DollupConfiguration {
    public static func check(in path: FilePath) throws -> [Diagnostics] {
        guard
        let status: FileStatus = try path.status else {
            throw """
            path '\(path)' does not exist
            """ as DollupError
        }

        if  status.is(.regular) {
            if  let diagnostics: Diagnostics = try self.check(on: path) {
                return [diagnostics]
            } else {
                return []
            }
        }

        guard status.is(.directory) else {
            throw """
            path '\(path)' is not a file or directory
            """ as DollupError
        }

        var results: [Diagnostics] = []
        try path.directory.walk {
            let path: FilePath = $0 / $1
            if  case true? = try path.status?.is(.regular),
                case "swift" = $1.extension {
                if  let diagnostics: Diagnostics = try self.check(on: path) {
                    results.append(diagnostics)
                }
            }
        } directory: { _, component in
            if  component.string.hasPrefix(".") {
                nil
            } else {
                .descend
            }
        }
        return results
    }

    public static func check(on file: FilePath) throws -> Diagnostics? {
        guard try self.check(file: file),
        let component: FilePath.Component = file.components.last else {
            return nil
        }
        let text: String = try file.read()
        guard let diagnostics: Diagnostics = try self.check(name: component, text: text) else {
            return nil
        }
        return Diagnostics.init(file: file, message: diagnostics.message, error: diagnostics.error)
    }
}
