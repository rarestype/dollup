import ArgumentParser
import System_ArgumentParser
import SystemIO

extension DollupCommand where Configuration: DollupConfiguration {
    struct CheckAsPlugin {
        @Option(
            name: .customLong("filelist"),
            help: "Path to a newline-delimited list of files to check"
        ) var filelist: FilePath

        // Passed by the generated command plugin for future target- and
        // dependency-scoped rules (#45).
        @Option(
            name: .customLong("target"),
            help: "The name of the target being checked"
        ) var target: String

        @Option(
            name: .customLong("dependency"),
            help: "A target dependency of the target being checked"
        ) var dependencies: [String] = []
    }
}
extension DollupCommand.CheckAsPlugin: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "check-as-plugin",
            shouldDisplay: false
        )
    }

    func run() throws {
        var failed: Bool = false
        try self.filelist.readLines { (line: Substring) in
            guard !line.isEmpty else {
                return
            }
            let file: FilePath = .init(String.init(line))
            do {
                if  let diagnostics: Diagnostics = try Configuration.check(on: file) {
                    print(diagnostics)
                    if  diagnostics.error {
                        failed = true
                    }
                }
            } catch {
                print("error checking file '\(file)': \(error)")
                failed = true
            }
        }
        if  failed {
            throw ExitCode.failure
        }
    }
}
