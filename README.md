# Bazel Util

Bazel utilities.

- [Install](#Install)
-

## Install

```
# Bazel Util

BAZEL_UTIL_VERSION = "..." # commit

http_archive(
    name = "bazel_util",
    # sha256 = "...", # digest
    strip_prefix = "rivet-bazel-util-%s" % BAZEL_UTIL_VERSION,
    url = "https://github.com/redoapp/bazel-util/archive/%s.tar.gz" % BAZEL_UTIL_VERSION,
)
```

## Running

- **bazel-mrun:** Build and run multiple targets in parallel.
- **bazel-watchrun:** Build and run multiple targets, restarting them after
  changes.

### Install

#### Bazel repositority

Add this project as a Bazel repository to the workspace:

<details>
<summary>WORKSPACE.bazel</summary>

```bzl
load("@bazel_util//ibazel:workspace.bzl", "ibazel_repositories", "ibazel_toolchains")

ibazel_repositories()

ibazel_toolchains()
```

The `@bazel_util//ibazel:toolchain_type` toolchain will download a pre-build
executable of ibazel, if it exists. Otherwise, it will rely on `@bazel-watcher`
repo to build from source.

</details>

The targets can be invoked:

```sh
bazel run @bazel_util//mrun:bin -- target1 target2
bazel run @bazel_util//watchrun:bin -- target1 target2
```

#### Linux

Or it can be installed natively, by building and installing a tarball.

<details>
<summary>Installation</summary>

```sh
bazel build bazel:tar

rm -fr /opt/rivet-bazel-util mkdir /opt/rivet-bazel-util tar xf
bazel-bin/bazel/tar.tar -C /opt/rivet-bazel-util

printf '#!/bin/sh -e\nexec /opt/rivet-bazel-util/mrun "$@"\n' > /usr/local/bin/bazel-mrun
chmod +x /usr/local/bin/bazel-mrun
printf '#!/bin/sh -e\nexec /opt/rivet-bazel-util/watchrun "$@"\n' > /usr/local/bin/bazel-watchrun
chmod +x /usr/local/bin/bazel-watchrun
```

</details>

Note that bazel-watchrun relies on an aspect, and therefore still requires
adding the bazel_util repository to the workspace.

### bazel-mrun

Build and run multiple targets in parallel. Like
[`bazel run`](https://bazel.build/docs/user-manual#running-executables), but for
multiple targets.

#### Usage

<details>
<summary>Usage</summary>

```txt
usage: bazel-mrun [-h] [--alias TARGET=ALIAS] [--bazel-arg BAZEL_ARG]
                  [--parallelism PARALLELISM] [--width WIDTH]
                  [target [target ...]]

Build and run Bazel executables.

positional arguments:
  target                Targets to run

optional arguments:
  -h, --help            show this help message and exit
  --alias TARGET=ALIAS  aliases
  --bazel-arg BAZEL_ARG
                        bazel argument
  --parallelism PARALLELISM
                        maximum concurrent processes
  --width WIDTH
```

</details>

#### Implementation

<details>
<summary>Implementation</summary>

1. Query Bazel for the excutable outputs.
2. Builds the targets in parallel using `bazel build`.
3. Run each executable in parallel.
4. Prefix stdout and stderr with the target's name.
</details>

### bazel-watchrun

Build and run multiple targets, restarting them after changes. Like
[`ibazel run`](https://github.com/bazelbuild/bazel-watcher), but for multiple
targets.

#### Usage

<details>
<summary>Usage</summary>

```txt
usage: bazel-watchrun [-h] [--alias TARGET=NAME] [--bazel-arg BAZEL_ARG]
                      [--ibazel-arg IBAZEL_ARG] [--width WIDTH]
                      [target [target ...]]

Build and run Bazel executables.

positional arguments: target Targets to run

optional arguments: -h, --help show this help message and exit --alias
TARGET=NAME --bazel-arg BAZEL_ARG bazel argument --ibazel-arg IBAZEL_ARG ibazel
argument --width WIDTH
```

</details>

#### Controlling restarts

A target can control when it restarts by providing a `digest`
[output group](https://bazel.build/extending/rules#requesting_output_files)
consisting of a single file. The executable is restarted when the contents of
that file change. Bazel-watchrun will also send the executable
[ibazel-like events](https://github.com/bazelbuild/bazel-watcher#running-a-target)
on stdin.

For example, consider a webpack server. Changes to Node.js files (weback config,
npm dependencies) should trigger a restart, but changes to browser sources
should be quickly rebundled without a full process restart. To accomplish this,
the target provides a `digest` output group for the Node.js sources, and the
executable listens for build success notifications on stdin and checks for
changed browser sources.

#### Implementation

<details>
<summary>Implementation</summary>

1. Query Bazel for the excutable outputs.
2. Watch and rebuild the targets in parallel using `ibazel build`, including the
   additional `digest` output group. If the target does not already provide the
   `digest` output group, an aspect generates it by hashing the executable and
   runfile tree.
3. Read the profile events from ibazel. Each time a build is completed, check
   the digests, and restart any executable with a changed digest.
4. If the target provided its own digest, pass write ibazel-like events to its
   stdin.
5. Prefix stdout and stderr with the target's name.
</details>

## Directory

Create a directory from files:

```bzl
load("@bazel_util//file:rules.bzl", "directory")

directory(
    name = "example",
    srcs = glob(["**/*.txt"]),
)
```

Create a directory from a tarball:

```bzl
load("@bazel_util//file:rules.bzl", "untar")

untar(
    name = "example",
    src = "example.tar",
)
```

## Package-less Files

Access files without regard to package structure. This can be helpful for
formatting or Bazel integration tests.

### Workspace Example

Create a new repository containing all workspace files.

**WORKSPACE.bazel**

```bzl
files(
    name = "files"
    build = "BUILD.file.bazel",
    root_file = "//:WORKSPACE.bazel",
)
```

**BAZEL.bazel**

```
load("@bazel_util//file:rules.bzl", "bazelrc_deleted_packages")

bazelrc_deleted_packages(
    name = "bazelrc",
    output = "deleted_packages.bazelrc",
    packages = ["@files//:packages"],
)
```

**files.bazel**

```bzl
# note: files is the symlink to the workspace
filegroup(
    name = "example",
    srcs = glob(["files/**/*.txt"]),
    visibility = ["//visibility:public"],
)
```

Generate deleted_packages.bazelrc:

```
bazel run :bazelrc
```

(To check if this is up-to-date, run `bazel run :bazelrc.diff`.)

**.bazelrc**

```
import %workspace%/deleted.bazelrc
```

Now `@files//:example` is all \*.txt files in the workspace.

### Bazel Integration Test Example

Use files in the test directory as data for a Bazel integration test.

**BAZEL.bazel**

```
load("@bazel_util//file:rules.bzl", "bazelrc_deleted_packages", "find_packages")

filegroup(
    name = "test",
    srcs = glob(["test/**/*.bazel" "test/**/*.txt"]),
)

find_packages(
    name = "test_packages",
    roots = ["test"],
)

bazelrc_deleted_packages(
    name = "bazelrc",
    output = "deleted_packages.bazelrc",
    packages = [":test_packages"],
)
```

Generate `deleted_packages.bazelrc` by running:

```
bazel run :bazelrc
```

**.bazelrc**

```
import %workspace%/deleted_packages.bazelrc
```

## Generate

In some cases, it is necessary to version control build products in the
workspace (bootstrapping, working with other tools).

These rules build the outputs, and copy them to the workspace or check for
differences.

**BUILD.bazel**

```bzl
load("@bazel_util//file:rules.bzl", "bazelrc_deleted_packages")
load("@bazel_util//file:rules.bzl", "generate", "generate_test")

genrule(
    name = "example",
    cmd = "echo GENERATED! > $@",
    outs = ["out/example.txt"],
)

generate(
    name = "example_gen",
    srcs = "example.txt",
    data = ["out/example.txt"],
    data_strip_prefix = "out",
)

generate_test(
    name = "example_diff",
    generate = ":example_gen",
)

bazelrc_deleted_packages(
    name = "gen_bazelrc",
    output = "deleted.bazelrc",
    packages = ["@files//:packages"],
)
```

To overwrite the workspace file:

```bzl
bazel run :example_gen
```

To check for differences (e.g. in CI):

```bzl
bazel test :example_diff
```

## Format

Formatting is a particular case of the checked-in build products pattern.

The code formatting is a regular Bazel action. The formatted result can be using
to overwrite workspace files, or to check for differences.

This repository has rules for buildifier, black, and gofmt. It is also used for
[prettier](https://github.com/rivethealth/rules_javascript).

### Buildifier Example

**WORKSPACE.bazel**

```bzl
load("@bazel_util//buildifier:workspace.bzl", "buildifier_repositories", "buildifier_toolchains")

buildifier_repositories()

buildifier_toolchains()

files(
    name = "files"
    build = "BUILD.file.bazel",
    root_file = "//:WORKSPACE.bazel",
)
```

The `@bazel_util//buildifier:toolchain_type` toolchain will download a pre-build
executable of buildifier, if it exists. Otherwise, it will rely on the
`@com_github_bazelbuild_buildtools` repo to build from source.

**BUILD.bazel**

```bzl
load("@bazel_util//generate:rules.bzl", "format", "generate_test")

format(
    name = "buildifier_format",
    srcs = ["@files//:buildifier_files"],
    formatter = "@bazel_util//buildifier",
    strip_prefix = "files",
)

generate_test(
    name = "buildifier_diff",
    generate = ":format",
)
```

**files.bazel**

```bzl
filegroup(
    name = "buildifier_files",
    srcs = glob(
        [
            "files/**/*.bazel",
            "files/**/*.bzl",
            "files/**/BUILD",
            "files/**/WORKSPACE",
        ],
    ),
    visibility = ["//visibility:public"],
)
```

Generate deleted_packages.bazelrc:

```
bazel run :gen_bazelrc
```

**.bazelrc**

```
import %workspace%/deleted_packages.bazelrc
```

To format:

```sh
bazel run :buildifier_format
```

To check format:

```sh
bazel run :buildifier_diff
```
