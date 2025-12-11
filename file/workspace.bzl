_BUILD = """
load("@bazel_util//file:rules.bzl", "find_packages")

find_packages(
    name = "packages",
    excludes = {excludes},
    prefix = repository_name() + "//files",
    roots = [""],
    visibility = ["//visibility:public"],
)
"""

# Ideally, this would not have to nest the directory in a files/ directory, but
# https://github.com/bazelbuild/bazel/issues/16217 .
def _files_impl(ctx):
    ignores = ctx.attr.ignores
    excludes = ctx.attr.excludes

    ctx.file("WORKSPACE.bazel", executable = False)
    content = _BUILD.format(excludes = repr(excludes))
    content += ctx.read(ctx.attr.build)
    ctx.file("BUILD.bazel", content = content, executable = False)
    path = ctx.path(ctx.attr.root_file).dirname
    ignores = ignores + [
        "bazel-%s" % path.basename,
        "bazel-bin",
        "bazel-genrules",
        "bazel-out",
        "bazel-testlogs",
    ]
    ignores = ["files/%s" % ignore for ignore in ignores]
    ctx.file(".bazelignore", "\n".join(ignores))
    ctx.symlink(path, "files")

files = repository_rule(
    implementation = _files_impl,
    attrs = {
        "build": attr.label(
            allow_single_file = True,
        ),
        "excludes": attr.string_list(
            default = [],
            doc = "Directory names to exclude from traversal",
        ),
        "ignores": attr.string_list(),
        "root_file": attr.label(
            doc = "A file in the root",
        ),
    },
    local = True,
)
