load(":repositories.bzl", "git_changed_files")

configure_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "root_file": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _git_impl(module_ctx):
    for module in module_ctx.modules:
        for configure in module.tags.configure:
            git_changed_files(
                name = "%s_changed_files" % configure.name,
                root_file = configure.root_file,
            )

git = module_extension(
    implementation = _git_impl,
    tag_classes = {"configure": configure_tag},
)
