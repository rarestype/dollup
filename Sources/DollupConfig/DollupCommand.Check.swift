import ArgumentParser
import Dollup
import System_ArgumentParser
import SystemIO

extension DollupCommand where Configuration: DollupConfiguration {
    struct Check {
        @Argument(
            help: "Paths to Swift files or directories to check"
        ) var paths: [FilePath]
    }
}

extension DollupCommand.Check: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "check")
    }

    func run() throws {
        var failed: Bool = false
        for path: FilePath in self.paths {
            do {
                let diagnostics: [Diagnostics] = try Configuration.check(in: path)
                for diagnostic: Diagnostics in diagnostics {
                    print(diagnostic)
                    if  diagnostic.error {
                        failed = true
                    }
                }
            } catch {
                print("error checking file '\(path)': \(error)")
                failed = true
            }
        }
        if  failed {
            throw ExitCode.failure
        }
    }
}
