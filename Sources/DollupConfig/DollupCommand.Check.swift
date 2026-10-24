import ArgumentParser
import Dollup
import DollupCheck
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
                let diagnostics: [OneTypePerFile.Diagnostics] = try Configuration.check(in: path)
                if !diagnostics.isEmpty {
                    failed = true
                    for diagnostic: OneTypePerFile.Diagnostics in diagnostics {
                        print(diagnostic)
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
