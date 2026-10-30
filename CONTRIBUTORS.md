# Contributing to dollup

dollup is built on SwiftSyntax. In addition to the [Swift style guide](Agent/Swift.md), read and follow the [SwiftSyntax style guide](Agent/SwiftSyntax.md) ([raw](https://raw.githubusercontent.com/rarestype/dollup/master/Agent/SwiftSyntax.md)).


## Reviewing formatter changes

To run a formatter branch as the style guide asks, use the code of the repositories whose `Scripts/TestAll` checks dollup formatting as inputs: dollup itself, [jss](https://github.com/rarestype/jss), [rarestcheck](https://github.com/rarestype/rarestcheck), [swift-ion](https://github.com/rarestype/swift-ion) and [swift-json](https://github.com/rarestype/swift-json). `master` leaves their default branches unchanged, so a branch’s changes to them are exactly what it would do to our code. Export each one, rather than formatting a working copy:

```bash
mkdir -p corpus/swift-json
git -C swift-json archive origin/master Package.swift Snippets Sources |
    tar -x -C corpus/swift-json
```

Build `dollup` in release mode for `master` and for the branch, from one checkout, so SwiftSyntax only builds once. Run `git switch --detach` to the branch, then `swift build -c release --product dollup`, and copy the binary out of `.build` before you switch again. Format a copy of the inputs with each binary, run `diff -ru` on the two results, and format the branch’s output a second time to check that nothing changes.
