import ArgumentParser

struct DollupCommand<Configuration> {}
extension DollupCommand: Decodable {}
extension DollupCommand: ParsableArguments {}
extension DollupCommand: ParsableCommand
    where Configuration: DollupConfiguration & DollupDistribution {
    static var configuration: CommandConfiguration {
        .init(
            commandName: Configuration.name,
            subcommands: [
                Format.self,
                Check.self,
                FormatAsPlugin.self,
                Bundle.self,
                Distribute.self,
            ],
            defaultSubcommand: Format.self
        )
    }
}
