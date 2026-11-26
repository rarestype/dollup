import ArgumentParser
import SHA2
import System_ArgumentParser
import SystemIO

extension DollupCommand where Configuration: DollupDistribution {
    struct Distribute {
        @Option(
            name: .customLong("output"),
            help: "The root directory of the downstream distribution repository"
        ) var output: FilePath.Directory = "."

        @Option(
            name: .customLong("macOS"),
            help: "The artifact bundle URL for macOS (arm64)"
        ) var macOS: String

        @Option(
            name: .customLong("linux-x86-64"),
            help: "The artifact bundle URL for Linux (x86_64)"
        ) var linuxX86_64: String

        @Option(
            name: .customLong("linux-aarch64"),
            help: "The artifact bundle URL for Linux (aarch64)"
        ) var linuxAArch64: String
    }
}
extension DollupCommand.Distribute: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "distribute",
            abstract: """
            Generates a downstream binary distribution repository from macOS-arm64.zip, \
            Linux-x86_64.zip, and Linux-aarch64.zip in the working directory
            """
        )
    }

    func run() throws {
        let archives: (
            macOS: FilePath,
            linuxX86_64: FilePath,
            linuxAArch64: FilePath
        ) = (
            macOS: "macOS-arm64.zip",
            linuxX86_64: "Linux-x86_64.zip",
            linuxAArch64: "Linux-aarch64.zip"
        )
        let checksums: (
            macOS: SHA256,
            linuxX86_64: SHA256,
            linuxAArch64: SHA256
        ) = (
            macOS: .init(hashing: try archives.macOS.read()),
            linuxX86_64: .init(hashing: try archives.linuxX86_64.read()),
            linuxAArch64: .init(hashing: try archives.linuxAArch64.read())
        )

        print("macOS Checksum: \(checksums.macOS)")
        print("Linux Checksum (x86_64): \(checksums.linuxX86_64)")
        print("Linux Checksum (aarch64): \(checksums.linuxAArch64)")

        let manifest: FilePath = self.output / "Package.swift"
        try manifest.overwrite(with: self.manifest(checksums: checksums).utf8)

        let plugins: [(name: String, source: String)] = [
            (
                name: Configuration.plugin,
                source: self.plugin(
                    verb: Configuration.verb,
                    action: (subcommand: nil, progress: "Formatting", failure: "format"),
                    hint: """
                    ; to check source files, run 'swift package \(Configuration.checkVerb)'
                    """
                )
            ),
            (
                name: Configuration.checkPlugin,
                source: self.plugin(
                    verb: Configuration.checkVerb,
                    action: (subcommand: "check", progress: "Checking", failure: "check"),
                    hint: ""
                )
            ),
        ]
        for (name, source): (String, String) in plugins {
            let directory: FilePath.Directory = self.output / "Plugins" / name
            try directory.create()

            let plugin: FilePath = directory / "Main.swift"
            try plugin.overwrite(with: source.utf8)
        }
    }
}
extension DollupCommand.Distribute {
    func manifest(
        checksums: (
            macOS: SHA256,
            linuxX86_64: SHA256,
            linuxAArch64: SHA256
        )
    ) -> String {
        """
        // swift-tools-version: 6.2
        import PackageDescription

        let package: Package = .init(
            name: "\(Configuration.name)",
            products: [
                .plugin(
                    name: "\(Configuration.plugin)",
                    targets: ["\(Configuration.plugin)"]
                ),
                .plugin(
                    name: "\(Configuration.checkPlugin)",
                    targets: ["\(Configuration.checkPlugin)"]
                ),
                .executable(
                    name: "\(Configuration.name)",
                    targets: ["\(Configuration.binary)"]
                ),
            ],
            targets: [
                binary,

                .plugin(
                    name: "\(Configuration.plugin)",
                    capability: .command(
                        intent: .custom(
                            verb: "\(Configuration.verb)",
                            description: "format source files"
                        ),
                        permissions: [.writeToPackageDirectory(reason: "code formatter")],
                    ),
                    dependencies: [
                        .target(name: "\(Configuration.binary)"),
                    ]
                ),
                .plugin(
                    name: "\(Configuration.checkPlugin)",
                    capability: .command(
                        intent: .custom(
                            verb: "\(Configuration.checkVerb)",
                            description: "check source files"
                        ),
                    ),
                    dependencies: [
                        .target(name: "\(Configuration.binary)"),
                    ]
                ),
            ]
        )

        var binary: Target {
            var url: String {
                #if os(macOS)
                "\(self.macOS)"
                #elseif arch(x86_64)
                "\(self.linuxX86_64)"
                #else
                "\(self.linuxAArch64)"
                #endif
            }
            var checksum: String {
                #if os(macOS)
                "\(checksums.macOS)"
                #elseif arch(x86_64)
                "\(checksums.linuxX86_64)"
                #else
                "\(checksums.linuxAArch64)"
                #endif
            }

            return .binaryTarget(
                name: "\(Configuration.binary)",
                url: url,
                checksum: checksum
            )
        }

        """
    }

    /// The source of a generated command plugin. It runs the tool on the package manifest
    /// and plugins with `action.subcommand`, or the default subcommand if nil, then runs the
    /// `-as-plugin` form of that subcommand on the Swift files of each target. The plugin
    /// refuses a first argument that isn’t an option, which it would otherwise ignore.
    func plugin(
        verb: String,
        action: (subcommand: String?, progress: String, failure: String),
        hint: String
    ) -> String {
        let subcommand: (package: String, target: String) = action.subcommand.map {
            (package: "[\"\($0)\"] + paths", target: "\($0)-as-plugin")
        } ?? (package: "paths", target: "format-as-plugin")
        return #"""
        import Foundation
        import PackagePlugin

        @main struct Main: CommandPlugin {
            func performCommand(context: PluginContext, arguments: [String]) async throws {
                // SwiftPM passes its own options through, so only refuse a subcommand or path
                if  let argument: String = arguments.first,
                    !argument.starts(with: "-") {
                    Diagnostics.error(
                        """
                        💔 '\#(verb)' \#(action.failure)s the whole package, so it takes no \
                        subcommands or paths, but was given '\(argument)'\#(hint)
                        """
                    )
                    return
                }

                let tool: PluginContext.Tool = try context.tool(named: "\#(Configuration.name)")
                let manifest: URL = context.package.directoryURL.appendingPathComponent(
                    "Package.swift"
                )
                let plugins: URL = context.package.directoryURL.appendingPathComponent(
                    "Plugins"
                )

                var paths: [String] = [manifest.path]
                if  FileManager.default.fileExists(atPath: plugins.path) {
                    paths.append(plugins.path)
                }
                try Self.run(tool, arguments: \#(subcommand.package))

                for case let target as SwiftSourceModuleTarget in context.package.targets {
                    let files: FileList = target.sourceFiles(withSuffix: ".swift")
                    if  files.isEmpty {
                        continue
                    }

                    print("\#(action.progress) '\(target.name)'")

                    let filelist: URL = context.pluginWorkDirectoryURL.appendingPathComponent(
                        "\(target.name).filelist"
                    )
                    var list: String = ""
                    for file: File in files {
                        list += "\(file.url.path)\n"
                    }
                    try list.write(to: filelist, atomically: true, encoding: .utf8)

                    var invocation: [String] = [
                        "\#(subcommand.target)",
                        "--target", target.name,
                    ]
                    for dependency: any Target in target.recursiveTargetDependencies {
                        invocation += ["--dependency", dependency.name]
                    }
                    invocation += ["--filelist", filelist.path]

                    try Self.run(tool, arguments: invocation)
                }
            }

            private static func run(_ tool: PluginContext.Tool, arguments: [String]) throws {
                let process: Process = try .run(tool.url, arguments: arguments)
                ;   process.waitUntilExit()

                guard case .exit = process.terminationReason,
                case 0 = process.terminationStatus else {
                    Diagnostics.error(
                        """
                        💔 \#(Configuration.name) \#(action.failure) failed: \
                        \(process.terminationReason), \(process.terminationStatus)
                        """
                    )
                    return
                }
            }
        }

        """#
    }
}
