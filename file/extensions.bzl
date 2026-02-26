load(":repositories.bzl", "files")

file_tag = tag_class(
    attrs = {
        "bazelignore": attr.label(
            doc = "Bazelignore file.",
        ),
        "bazelrc": attr.string(
            doc = "Bazelrc file.",
            mandatory = True,
        ),
        "build": attr.label(
            doc = "BUILD file.",
            mandatory = True,
        ),
        "ignore_directories": attr.string_list(
            doc =
                "Directory patterns to ignore. See ignore_directories() in REPO.bazel.",
        ),
        "name": attr.string(
            doc = "Repository name.",
            mandatory = True,
        ),
    },
)

def _file_impl(module_ctx):
    for module in module_ctx.modules:
        for info in module.tags.files:
            files(
                name = info.name,
                bazelignore = info.bazelignore,
                bazelrc = info.bazelrc,
                build = info.build,
                ignore_directories = info.ignore_directories,
            )

    return module_ctx.extension_metadata(
        reproducible = True,
    )

file = module_extension(
    implementation = _file_impl,
    tag_classes = {"files": file_tag},
)
