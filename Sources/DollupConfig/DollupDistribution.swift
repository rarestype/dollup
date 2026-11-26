public protocol DollupDistribution {
    /// The name of the executable and downstream package.
    static var name: String { get }
    /// The SwiftPM command plugin verb used to invoke the formatter.
    static var verb: String { get }
    /// The name of the generated SwiftPM command plugin product and target.
    static var plugin: String { get }
    /// The SwiftPM command plugin verb used to invoke the checker.
    static var checkVerb: String { get }
    /// The name of the generated SwiftPM checker plugin product and target.
    static var checkPlugin: String { get }
    /// The name of the generated SwiftPM binary target.
    static var binary: String { get }
}
extension DollupDistribution {
    public static var verb: String { Self.name }
    public static var checkVerb: String { "\(Self.verb)-check" }
    public static var checkPlugin: String { "\(Self.plugin)Check" }
}
extension DollupDistribution where Self: DollupConfiguration {
    @MainActor public static func main() {
        DollupCommand<Self>.main()
    }
}
