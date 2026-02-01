load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(":repositories.bzl", "jsonschema_http_archive")

_jsonschema_toolchain = tag_class(
    attrs = {
        "sha256s": attr.string_dict(),
        "version": attr.string(mandatory = True),
    },
)

_FACTS_KEY = "_"

def _jsonschema_impl(module_ctx):
    version = None
    for module in module_ctx.modules:
        for toolchain in module.tags.toolchain:
            if version == None or versions.is_at_least(version, toolchain.version):
                version = toolchain.version
    version = version or "12.10.1"

    facts = module_ctx.facts.get(_FACTS_KEY)

    sha256s = module_ctx.facts.get("sha256s")
    if sha256s == None:
        sha256s = {}
        module_ctx.download(
            output = "release.json",
            url = "https://api.github.com/repos/sourcemeta/jsonschema/releases/tags/v%s" % version,
        )
        release = json.decode(module_ctx.read("release.json"))
        for asset in release["assets"]:
            sha256s[asset["name"]] = asset["digest"].replace("sha256:", "")

    for platform in _platforms:
        jsonschema_http_archive(
            name = "jsonschema_%s" % platform.replace("-", "_"),
            sha256 = sha256s["jsonschema-%s-%s.zip" % (version, platform)],
            url = "https://github.com/sourcemeta/jsonschema/releases/download/v%s/jsonschema-%s-%s.zip" % (version, version, platform),
        )

    return module_ctx.extension_metadata(
        facts = {_FACTS_KEY: {"sha256s": sha256s}},
        reproducible = True,
    )

jsonschema = module_extension(
    implementation = _jsonschema_impl,
    tag_classes = {"toolchain": _jsonschema_toolchain},
)

_platforms = [
    "darwin-arm64",
    "darwin-x86_64",
    "linux-arm64",
    "linux-x86_64",
    "windows-x86_64",
]
