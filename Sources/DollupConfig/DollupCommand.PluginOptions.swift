import ArgumentParser
import System_ArgumentParser
import SystemIO

extension DollupCommand {
    /// The options that the generated command plugins pass to the `-as-plugin` subcommands.
    struct PluginOptions {
        @Option(
            name: .customLong("filelist"),
            help: "Path to a newline-delimited list of files"
        ) var filelist: FilePath

        // Passed by the generated command plugins for future target- and
        // dependency-scoped rules (#45).
        @Option(
            name: .customLong("target"),
            help: "The name of the target the files belong to"
        ) var target: String

        @Option(
            name: .customLong("dependency"),
            help: "A target dependency of the target the files belong to"
        ) var dependencies: [String] = []
    }
}
extension DollupCommand.PluginOptions: ParsableArguments {}
extension DollupCommand.PluginOptions {
    /// Calls `body` on each file in the file list, and prints the diagnostics it returns.
    /// After the last file, this fails if `body` threw for any file, or returned an error.
    func run(action: String, _ body: (FilePath) throws -> Diagnostics?) throws {
        var failed: Bool = false
        try self.filelist.readLines { (line: Substring) in
            guard !line.isEmpty else {
                return
            }
            let file: FilePath = .init(String.init(line))
            do {
                if  let diagnostics: Diagnostics = try body(file) {
                    print(diagnostics)
                    if  diagnostics.error {
                        failed = true
                    }
                }
            } catch {
                print("error \(action) file '\(file)': \(error)")
                failed = true
            }
        }
        if  failed {
            throw ExitCode.failure
        }
    }
}
