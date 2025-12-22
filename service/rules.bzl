load("@bazel_skylib//lib:shell.bzl", "shell")
load("//util:path.bzl", "runfile_path")

def _services_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bazel_args = ctx.attr.bazel_args
    ibazel_args = ctx.attr.ibazel_args
    manifest = ctx.file.manifest
    name = ctx.attr.name
    runner = ctx.file._runner
    services = ctx.executable._services
    services_default = ctx.attr._services[DefaultInfo]
    workspace = ctx.workspace_name

    args = []
    for arg in bazel_args:
        args.append("--bazel-arg")
        args.append(arg)
    for arg in ibazel_args:
        args.append("--ibazel-args")
        args.append(arg)

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        substitutions = {
            "%{args}": " ".join([shell.quote(arg) for arg in args]),
            "%{manifest}": shell.quote(runfile_path(workspace, manifest)),
            "%{services}": shell.quote(runfile_path(workspace, services)),
        },
        template = runner,
        output = executable,
    )

    runfiles = ctx.runfiles(files = [manifest])
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(services_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

services = rule(
    attrs = {
        "bazel_args": attr.string_list(),
        "manifest": attr.label(allow_single_file = [".json"], mandatory = True),
        "ibazel_args": attr.string_list(),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(allow_single_file = True, default = "services-runner.sh.tpl"),
        "_services": attr.label(cfg = "target", default = "//service/services:bin", executable = True),
    },
    executable = True,
    implementation = _services_impl,
)
