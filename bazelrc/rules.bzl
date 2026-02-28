load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS", "copy_file_action")
load("//generate:rules.bzl", "generate")
load("//util:path.bzl", "runfile_path")
load(":bazelrc.bzl", "BazelrcInfo")

def _bazelrc_group_impl(ctx):
    deps_bazelrc = [target[BazelrcInfo] for target in ctx.attr.deps]
    srcs = ctx.files.srcs

    transitive_files = depset(
        srcs,
        transitive = [bazelrc_info.transitive_files for bazelrc_info in deps_bazelrc],
    )

    bazelrc_info = BazelrcInfo(transitive_files = transitive_files)

    return [bazelrc_info]

bazelrc_group = rule(
    attrs = {
        "deps": attr.label_list(
            providers = [BazelrcInfo],
        ),
        "srcs": attr.label_list(
            allow_files = True,
        ),
    },
    implementation = _bazelrc_group_impl,
    provides = [BazelrcInfo],
)

def _bazelrc_impl(ctx):
    deps_bazelrc = [target[BazelrcInfo] for target in ctx.attr.deps]
    label = ctx.label
    path = ctx.attr.path or ctx.attr.name
    srcs = ctx.files.srcs
    workspace = ctx.workspace_name

    transitive_files = depset(
        srcs,
        transitive = [bazelrc_info.transitive_files for bazelrc_info in deps_bazelrc],
    )

    bazelrc_content = ""
    outputs = []
    for file in transitive_files.to_list():
        if not file.root.path and file.is_source:
            workspace_path = file.path
        else:
            r_path = runfile_path(workspace, file)
            output = ctx.actions.declare_file("%s/%s" % (path, r_path))
            outputs.append(output)
            copy_file_action(ctx, src = file, dst = output)
            workspace_path = "/".join([part for part in [label.package, path, r_path] if part])
        bazelrc_content += "import %%workspace%%/%s\n" % workspace_path

    bazelrc = ctx.actions.declare_file("%s.bazelrc" % path)
    ctx.actions.write(output = bazelrc, content = bazelrc_content)

    default_info = DefaultInfo(files = depset([bazelrc] + outputs))

    return [default_info]

bazelrc = rule(
    attrs = {
        "deps": attr.label_list(
            providers = [BazelrcInfo],
        ),
        "path": attr.string(),
        "srcs": attr.label_list(
            allow_files = True,
        ),
    },
    implementation = _bazelrc_impl,
    toolchains = COPY_FILE_TOOLCHAINS,
)

def bazelrc_gen(name, path, deps = None, srcs = None, **kwargs):
    generate(
        name = name,
        srcs = native.glob(
            ["%s.bazelrc" % path, "%s/**" % path],
            allow_empty = True,
        ),
        data = ["%s.bazelrc" % name],
        **kwargs
    )

    bazelrc(
        name = "%s.bazelrc" % name,
        deps = deps,
        path = path,
        srcs = srcs,
        **kwargs
    )
