import ArgumentParser

extension DollupCommand where Configuration: DollupConfiguration {
    struct FormatAsPlugin {
        @OptionGroup var options: PluginOptions
    }
}
extension DollupCommand.FormatAsPlugin: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "format-as-plugin",
            shouldDisplay: false
        )
    }

    func run() throws {
        try self.options.run(action: "formatting") {
            try Configuration.run(on: $0)
            return nil
        }
    }
}
