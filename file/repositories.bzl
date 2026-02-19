def _files_impl(repository_ctx):
    bazelignore = repository_ctx.attr.bazelignore
    bazelrc = repository_ctx.attr.bazelrc
    build = repository_ctx.attr.build
    excludes = repository_ctx.attr.excludes
    ignore_directories = repository_ctx.attr.ignore_directories
    packages_build = repository_ctx.attr._packages_build
    root_file = repository_ctx.attr.root_file
    rules = repository_ctx.attr._rules

    repository_ctx.symlink(build, "BUILD.bazel")

    repository_ctx.template(
        "packages/BUILD.bazel",
        packages_build,
        executable = False,
        substitutions = {
            '["%{excludes}"]': repr(excludes),
            '"%{bazelrc}"': repr(bazelrc),
            '"%{rules}"': repr(str(rules)),
        },
    )

    root = repository_ctx.path(root_file).dirname
    repository_ctx.symlink(root, "files")

    if bazelignore:
        ignores = repository_ctx.read(bazelignore).splitlines()

        # https://github.com/bazelbuild/bazel/blob/4948ddd514ed5b0ede57d4c2231516bbe8c4fcb4/src/main/java/com/google/devtools/build/lib/skyframe/IgnoredSubdirectoriesFunction.java#L202
        ignores = ["files/%s" % ignore for ignore in ignores if ignore and not ignore.startswith("#")]
        repository_ctx.file(".bazelignore", "\n".join(ignores))

    ignore_directories = ["files/%s" % ignore for ignore in ignore_directories]
    repository_ctx.template(
        "REPO.bazel",
        Label("files.REPO.bazel.tpl"),
        executable = False,
        substitutions = {
            "%{ignore_directories}": repr(ignore_directories),
        },
    )

    return repository_ctx.repo_metadata(
        reproducible = True,
    )

files = repository_rule(
    implementation = _files_impl,
    attrs = {
        "bazelignore": attr.label(allow_single_file = True),
        "bazelrc": attr.string(mandatory = True),
        "build": attr.label(allow_single_file = True, mandatory = True),
        "excludes": attr.string_list(
            doc = "Directory names to exclude from traversal",
        ),
        "ignore_directories": attr.string_list(
            doc = "Directory patterns to ignore. See ignore_directories() in REPO.bazel.",
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
