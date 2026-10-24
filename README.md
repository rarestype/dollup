<div align="center">

🎀 &nbsp; **dollup** &nbsp; 🎀

a formally sound, risk-aware swift code formatter

</div>


## Introduction

Dollup is a Swift formatter that emphasizes soundness of transformations and transparent risk management. It was created out of a recognition that many existing Swift formatters may subtly alter the semantics of reformatted Swift code, and often mix safe and unsafe transformations within the same formatting commands, which undermines developer confidence when formatting large tracts of code at scale.

Dollup takes a different approach. It makes an effort to segregate formatting passes by risk of semantic corruption, distinguishing between operations that can safely run continuously and automatically, moderate complexity rewrites that can be automated but need to be performed carefully in isolation and applied through pull requests, and higher level refactors that require manual review. This enables developers to make informed decisions about the level of human oversight needed when enforcing formatting styles at the organizational level.

<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [STATUS TABLE] -->
| Platform | Status |
| -------- | ------ |
| 🐧 Linux | [![Status](https://raw.githubusercontent.com/rarestype/dollup/refs/badges/ci/Tests/Linux/status.svg)](https://github.com/rarestype/dollup/actions/workflows/Tests.yml) |
| 🍏 Darwin | [![Status](https://raw.githubusercontent.com/rarestype/dollup/refs/badges/ci/Tests/macOS/status.svg)](https://github.com/rarestype/dollup/actions/workflows/Tests.yml) |
| 💝 Release | [![Status](https://raw.githubusercontent.com/rarestype/dollup/refs/badges/ci/SemanticRelease/_all/status.svg)](https://github.com/rarestype/dollup/actions/workflows/SemanticRelease.yml) |
<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [STATUS TABLE] -->

## Using prebuilt binaries

Dollup is easiest to use in precompiled form. The binaries are distributed from a parallel repo, [`ordo-one/dollup`](https://github.com/ordo-one/dollup).

<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [ManifestDependency] -->
```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/dollup", from: "1.3.0"),
]
```

<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [ManifestDependency] -->

Adding the binary package dependency will automatically make the plugin available.

```bash
swift package dollup --allow-writing-to-package-directory
```

Some people find it helpful to add formatting enforcement to their CI pipelines.

```yaml
-   name: 🎀 Format 🎀
    run: |
        swift package dollup --allow-writing-to-package-directory
        git diff --exit-code
```

Note that prebuilt binaries are only available for select platforms.

<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [Downloads] -->
| Platform | Architecture | Download |
| -------- | ------------ | -------- |
| 🍏 macOS | arm64 | [zip](https://get.rarestype.com/dollup/1.3.0/macOS-arm64/dollup.artifactbundle.zip) |
| 🐧 Linux | arm64 | [zip](https://get.rarestype.com/dollup/1.3.0/Linux-aarch64/dollup.artifactbundle.zip) |
| 🐧 Linux | x86_64 | [zip](https://get.rarestype.com/dollup/1.3.0/Linux-x86_64/dollup.artifactbundle.zip) |

<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [Downloads] -->


## Building from source

To build the `dollup` executable, you will need the Swift 6.2 (or newer) toolchain. Navigate to the project's root directory and run the following command:

```bash
swift build
```

The compiled executable will be located in the `.build/debug` directory.

## Usage

Most users find the SwiftPM package plugin command to be simpler to use and sufficient for their formatting needs. Some users, typically those working on code generation systems, find it motivating to run `dollup` directly, as an executable.

To format a Swift file or all Swift files within a directory, run the `dollup` executable with the path to the file or directory as an argument, which will reformat the specified file in place.

```bash
swift run dollup [file-path]
```

When a directory is provided, `dollup` will recursively format all `.swift` files within it.

### Checking file organization

To check that Swift files adhere to the One Type Per File (OTPF) file organization standard, run `dollup check`:

```bash
swift run dollup check [paths ...]
```

When a directory is provided, `dollup check` will recursively check all `.swift` files within it. It emits source-annotated diagnostics for any violations and exits with a non-zero exit code if violations are found, without modifying any files in place.


## Configuration

Dollup is configured by creating a Swift executable that conforms to the `DollupConfiguration` protocol. This allows you to specify formatting options in a declarative way.

Here's an example of a simple configuration file:

```swift
import DollupConfig
import SystemPackage

@main enum Main: DollupConfiguration {
    public static func configure(file _: FilePath?, settings: inout DollupSettings) {
        settings.check = true
        settings.whitespace {
            $0.width = 96
            $0.braces = .egyptian

            $0.indent.spaces = 4
            $0.indent.ifConfig = false

            $0.formatColonPadding = true
            $0.keywordsOnSameLine = true
        }
    }

    public static func filter(file: FilePath) -> Bool {
        true // run on all files
    }
    public static func report(file: FilePath) {
        print("> reformatted '\(file)'")
    }
}
```

This configuration specifies that the code should be formatted with a maximum line width of 96 characters, Egyptian-style braces, and an indent width of 4 spaces. It also enables the integrity check, which ensures that the reformatted code is semantically equivalent to the original.
