import DollupConfig
import SystemIO

extension DollupConfigRules {
    enum DefaultConfig: DollupConfiguration {
        static func configure(file _: FilePath?, settings _: inout DollupSettings) throws {}
    }
}
