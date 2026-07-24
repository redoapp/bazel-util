load(
    "//bazel:repo.bzl",
    "BAZELIGNORE_PATH",
    "BUILD_PATH",
    "REPO_PATH",
    "bazelignore_parse",
)

def _files_impl(ctx):
    bazelignore = ctx.attr.bazelignore
    bazelrc = ctx.attr.bazelrc
    build = ctx.attr.build
    ignore_directories_manifest = ctx.attr.ignore_directories_manifest
    workspace_root = ctx.workspace_root

    ctx.symlink(build, BUILD_PATH)

    if ignore_directories_manifest:
        ignore_directories = [
            path
            for path in ctx.read(ignore_directories_manifest).split("\n")
            if path and not path.startswith("#")
        ]
    else:
        ignore_directories = []

    ctx.template(
        "gen/%s" % BUILD_PATH,
        Label("gen.BUILD.bazel.tpl"),
        executable = False,
        substitutions = {
            "%{generate_rules}": repr(str(Label("//generate:rules.bzl"))),
            "%{ignore_directories_manifest}": repr(str(ignore_directories_manifest)),
            "%{repo}": repr(str(
                ignore_directories_manifest.relative("//:%s" % REPO_PATH),
            )),
            "%{rules}": repr(str(Label("rules.bzl"))),
        },
    )

    ctx.template(
        "packages/%s" % BUILD_PATH,
        Label("packages.BUILD.bazel.tpl"),
        executable = False,
        substitutions = {
            "%{bazelrc}": repr(bazelrc),
            "%{exclude_directories}": repr(ignore_directories),
            "%{rules}": repr(str(Label("rules.bzl"))),
        },
    )

    ctx.symlink(workspace_root, _FILES_PATH)

    if bazelignore:
        ignores = [
            "%s/%s" % (_FILES_PATH, ignore)
            for ignore in bazelignore_parse(ctx.read(bazelignore))
        ]
        ctx.file(BAZELIGNORE_PATH, "\n".join(ignores), executable = False)

    ignore_directories = [
        "%s/%s" % (_FILES_PATH, ignore)
        for ignore in ignore_directories
    ]
    ctx.template(
        REPO_PATH,
        Label("files.REPO.bazel.tpl"),
        executable = False,
        substitutions = {
            "%{ignore_directories}": repr(ignore_directories),
        },
    )

files = repository_rule(
    implementation = _files_impl,
    attrs = {
        "bazelignore": attr.label(allow_single_file = True),
        "bazelrc": attr.string(mandatory = True),
        "build": attr.label(allow_single_file = True, mandatory = True),
        "ignore_directories_manifest": attr.label(
            allow_single_file = True,
            doc =
                "File of newline-delimited directory patterns to ignore, generated " +
                "from ignore_directories() in REPO.bazel of the same repository.",
        ),
    },
)

_FILES_PATH = "files"

def _paths_filter(ctx):
    manifest = ctx.attr.manifest

    files = ctx.read(manifest).strip().split("\n")

    ctx.template(
        "BUILD.bazel",
        Label("paths_filter.BUILD.bazel.tpl"),
        executable = False,
        substitutions = {
            '"%{file_rules}"': repr(str(Label("//file:rules.bzl"))),
        },
    )
    ctx.template(
        "files.bzl",
        Label("paths_filter.bzl.tpl"),
        executable = False,
        substitutions = {
            "%{files}": json.encode(files),
        },
    )

paths_filter = repository_rule(
    attrs = {
        "manifest": attr.label(
            doc = "A file listing file paths.",
            mandatory = True,
        ),
    },
    doc = "Manifest files.",
    implementation = _paths_filter,
)
