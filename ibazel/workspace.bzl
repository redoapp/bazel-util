load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(":ibazel.bzl", "IBAZEL_REPOS")

def ibazel_repositories(version = "v0.21.4"):
    for name, info in IBAZEL_REPOS[version].items():
        http_file(
            name = "ibazel_%s" % name,
            executable = True,
            sha256 = info.sha256,
            url = "https://github.com/bazelbuild/bazel-watcher/releases/download/%s/%s" % (version, info.path),
        )

def ibazel_toolchains():
    native.register_toolchains(
        str(Label(":macos_amd64_toolchain")),
        str(Label(":macos_arm64_toolchain")),
        str(Label(":linux_amd64_toolchain")),
        str(Label(":linux_arm64_toolchain")),
        str(Label(":windows_amd64_toolchain")),
        str(Label(":src_toolchain")),
    )
