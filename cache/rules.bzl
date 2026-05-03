load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_skylib//lib:shell.bzl", "shell")

def _cache_src_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    content = ctx.executable.content
    content_default = ctx.attr.content[DefaultInfo]
    key = ctx.file.key
    label = ctx.label
    name = ctx.attr.name
    output = ctx.attr.output
    runner = ctx.file._runner
    store = ctx.executable.store
    store_default = ctx.attr.store[DefaultInfo]
    workspace = ctx.workspace_name

    if output.startswith("/"):
        output = output[1:]
    elif label.package:
        output = "%s/%s" % (label.package, output)

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{content}": shell.quote(to_rlocation_path(ctx, content)),
            "%{key}": shell.quote(to_rlocation_path(ctx, key)),
            "%{output}": shell.quote(output),
            "%{store}": shell.quote(to_rlocation_path(ctx, store)),
            "%{target}": shell.quote("%s/%s/%s" % (workspace, label.package or "_", name)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles(files = [key])
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(content_default.default_runfiles)
    runfiles = runfiles.merge(store_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

cache_src = rule(
    attrs = {
        "key": attr.label(allow_single_file = True, doc = "Key file", mandatory = True),
        "output": attr.string(doc = "Output path, relative to workspace root", mandatory = True),
        "content": attr.label(cfg = "target", doc = "Content executable", executable = True, mandatory = True),
        "store": attr.label(cfg = "target", doc = "Store executable", executable = True, mandatory = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(allow_single_file = True, default = "digest-status-runner.sh.tpl"),
    },
    executable = True,
    implementation = _cache_src_impl,
)
