import DollupConfig
import SystemPackage

extension DollupConfigTests {
    enum DefaultConfig: DollupConfiguration {
        static func configure(file _: FilePath?, settings _: inout DollupSettings) throws {}
    }
}
