fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android check

```sh
[bundle exec] fastlane android check
```

Check the Play Store service-account key works

### android build

```sh
[bundle exec] fastlane android build
```

Build a signed release app bundle (no upload)

### android internal

```sh
[bundle exec] fastlane android internal
```

Build and upload to the Internal testing track

Options: notes:"What's new text"

### android production

```sh
[bundle exec] fastlane android production
```

Build and upload to Production (bumps version patch, e.g. 3.3.3 -> 3.3.4)

Options: notes:"What's new text" rollout:0.2 (staged rollout fraction, default full) force:true (skip the confirmation prompt)

### android patch

```sh
[bundle exec] fastlane android patch
```

Push a Shorebird code-push patch to already-installed apps (no Play Store review)

Dart-only changes; native changes (plugins, permissions, Gradle) still need `internal`/`production`

Options: release:"3.3.5+335" (default: the version in pubspec.yaml, i.e. the last store upload) staging:true (testers only, promote later)

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote the latest Internal build to Production without rebuilding

Options: rollout:0.2 (staged rollout fraction, default full) force:true (skip the confirmation prompt)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
