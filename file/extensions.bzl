load(":repositories.bzl", "files")

file_tag = tag_class(
    attrs = {
        "bazelignore": attr.label(allow_single_file = True),
        "bazelrc": attr.string(mandatory = True),
        "build": attr.label(allow_single_file = True, mandatory = True),
        "excludes": attr.string_list(),
        "name": attr.string(mandatory = True),
        "root_file": attr.label(allow_single_file = True, mandatory = True),
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
                excludes = info.excludes,
                root_file = info.root_file,
            )

    return module_ctx.extension_metadata(
        reproducible = True,
    )

file = module_extension(
    implementation = _file_impl,
    tag_classes = {"files": file_tag},
)
