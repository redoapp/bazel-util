def _files_impl(repository_ctx):
    bazelignore = repository_ctx.attr.bazelignore
    bazelrc = repository_ctx.attr.bazelrc
    build = repository_ctx.attr.build
    excludes = repository_ctx.attr.excludes
    packages_build = repository_ctx.attr._packages_build
    rules = repository_ctx.attr._rules

    repository_ctx.symlink(build, "BUILD.bazel")

    repository_ctx.template("packages/BUILD.bazel", packages_build, executable = False, substitutions = {
        '["%{excludes}"]': repr(excludes),
        '"%{bazelrc}"': repr(bazelrc),
        '"%{rules}"': repr(str(rules)),
    })

    path = repository_ctx.path(repository_ctx.attr.root_file).dirname
    ignores = [
        "bazel-%s" % path.basename,
        "bazel-bin",
        "bazel-genrules",
        "bazel-out",
        "bazel-testlogs",
    ]
    if bazelignore:
        ignores += repository_ctx.read(repository_ctx.attr.bazelignore).splitlines()
    repository_ctx.file(".bazelignore", "\n".join(["files/%s" % ignore for ignore in ignores]))

    repository_ctx.symlink(path, "files")

files = repository_rule(
    implementation = _files_impl,
    attrs = {
        "bazelignore": attr.label(allow_single_file = True),
        "bazelrc": attr.string(mandatory = True),
        "build": attr.label(allow_single_file = True, mandatory = True),
        "excludes": attr.string_list(
            default = [],
            doc = "Directory names to exclude from traversal",
        ),
        "root_file": attr.label(
            doc = "A file in the root",
        ),
        "_packages_build": attr.label(
            allow_single_file = True,
            default = "packages.BUILD.bazel",
        ),
        "_rules": attr.label(default = "rules.bzl"),
    },
)
