load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(":repositories.bzl", "ibazel_http")

_ibazel_toolchain = tag_class(
    attrs = {
        "sha256s": attr.string_dict(),
        "version": attr.string(mandatory = True),
    },
)

_FACTS_KEY = "_"

def _ibazel_impl(module_ctx):
    version = None
    for module in module_ctx.modules:
        for toolchain in module.tags.toolchain:
            if version == None or versions.is_at_least(version, toolchain.version):
                version = toolchain.version
    version = version or "0.26.8"

    facts = module_ctx.facts.get(_FACTS_KEY)

    sha256s = facts["sha256s"] if facts else None
    if sha256s == None:
        sha256s = {}
        module_ctx.download(
            output = "release.json",
            url = "https://api.github.com/repos/bazelbuild/bazel-watcher/releases/tags/v%s" % version,
        )
        release = json.decode(module_ctx.read("release.json"))
        for asset in release["assets"]:
            if not asset["name"].startswith("ibazel_"):
                continue
            sha256s[asset["name"]] = asset["digest"].replace("sha256:", "")

    for platform_name, platform in _platforms.items():
        ibazel_http(
            name = "ibazel_%s" % platform_name.replace("-", "_"),
            sha256 = sha256s[platform.path],
            url = "https://github.com/bazelbuild/bazel-watcher/releases/download/v%s/%s" % (version, platform.path),
        )

    return module_ctx.extension_metadata(
        facts = {_FACTS_KEY: {"sha256s": sha256s}},
        reproducible = True,
    )

ibazel = module_extension(
    implementation = _ibazel_impl,
    tag_classes = {"toolchain": _ibazel_toolchain},
)

_platforms = {
    "darwin-amd64": struct(path = "ibazel_darwin_amd64"),
    "darwin-arm64": struct(path = "ibazel_darwin_arm64"),
    "linux-amd64": struct(path = "ibazel_linux_amd64"),
    "linux-arm64": struct(path = "ibazel_linux_arm64"),
    "windows-amd64": struct(path = "ibazel_windows_amd64.exe"),
}
