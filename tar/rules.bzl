load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_util//util:path.bzl", "runfile_path")

def _tar_filter_impl(ctx):
    actions = ctx.actions
    filter = ctx.executable._filter
    excludes = ctx.attr.excludes
    name = ctx.attr.name
    src = ctx.file.src

    if src.basename.endswith(".tar.gz"):
        compression = "gz"
        extension = "tar.gz"
    elif src.basename.endswith(".tgz"):
        compression = "gz"
        extension = "tgz"
    else:
        compression = None
        extension = "tar"

    output = actions.declare_file("%s.%s" % (name, extension))

    args = actions.args()
    if compression:
        args.add("--compression", compression)
    for exclude in excludes:
        args.add("--exclude", exclude)
    args.add(src)
    args.add(output)
    actions.run(
        arguments = [args],
        inputs = [src],
        outputs = [output],
        executable = filter,
    )

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

tar_filter = rule(
    attrs = {
        "src": attr.label(allow_single_file = [".tar", ".tar.gz", ".tgz"]),
        "excludes": attr.string_list(),
        "_filter": attr.label(
            cfg = "exec",
            default = "//tar/filter:bin",
            executable = True,
        ),
    },
    implementation = _tar_filter_impl,
)
