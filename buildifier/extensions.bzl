load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(":repositories.bzl", "buildifier_http")

_buildifier_toolchain = tag_class(
    attrs = {
        "sha256s": attr.string_dict(),
        "version": attr.string(mandatory = True),
    },
)

_FACTS_KEY = "_"

_FACTS_VERSION = "1"

def _buildifier_impl(module_ctx):
    version = None
    for module in module_ctx.modules:
        for toolchain in module.tags.toolchain:
            if version == None or versions.is_at_least(version, toolchain.version):
                version = toolchain.version
    version = version or "8.2.1"

    facts = module_ctx.facts.get(_FACTS_KEY)
    if facts and facts["_version"] != _FACTS_VERSION:
        facts = None

    if facts != None:
        sha256s = facts["sha256s"]
    else:
        sha256s = {}
        module_ctx.download(
            output = "release.json",
            url = "https://api.github.com/repos/bazelbuild/buildtools/releases/tags/v%s" % version,
        )
        release = json.decode(module_ctx.read("release.json"))
        for asset in release["assets"]:
            if not asset["name"].startswith("buildifier-"):
                continue
            sha256s[asset["name"]] = asset["digest"].replace("sha256:", "")

    for platform_name, platform in _platforms.items():
        buildifier_http(
            name = "buildifier_%s" % platform_name.replace("-", "_"),
            sha256 = sha256s[platform.path],
            url = "https://github.com/bazelbuild/buildtools/releases/download/v%s/%s" % (version, platform.path),
        )

    return module_ctx.extension_metadata(
        facts = {_FACTS_KEY: {"sha256s": sha256s, "_version": _FACTS_VERSION}},
        reproducible = True,
    )

buildifier = module_extension(
    implementation = _buildifier_impl,
    tag_classes = {"toolchain": _buildifier_toolchain},
)

_platforms = {
    "darwin-amd64": struct(path = "buildifier-darwin-amd64"),
    "darwin-arm64": struct(path = "buildifier-darwin-arm64"),
    "linux-amd64": struct(path = "buildifier-linux-amd64"),
    "linux-arm64": struct(path = "buildifier-linux-arm64"),
    "windows-amd64": struct(path = "buildifier-windows-amd64.exe"),
}
