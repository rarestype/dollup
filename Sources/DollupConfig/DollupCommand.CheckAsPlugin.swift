import ArgumentParser

extension DollupCommand where Configuration: DollupConfiguration {
    struct CheckAsPlugin {
        @OptionGroup var options: PluginOptions
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
        try self.options.run(action: "checking") { try Configuration.check(on: $0) }
    }
}
