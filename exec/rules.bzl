load("@bazel_skylib//lib:shell.bzl", "shell")
load("//util:path.bzl", "runfile_path")

def _command_impl(ctx):
    actions = ctx.actions
    args = ctx.attr.args
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    data = ctx.files.data
    data_default = [target[DefaultInfo] for target in ctx.attr.data]
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        substitutions = {
            "%{bin}": shell.quote(runfile_path(workspace, bin)),
            "%{args}": " ".join([shell.quote(ctx.expand_location(arg)) for arg in args]),
        },
        is_executable = True,
        output = executable,
        template = runner,
    )

    runfiles = ctx.runfiles(files = data)
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge_all([default_info.default_runfiles for default_info in data_default])
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

command = rule(
    implementation = _command_impl,
    attrs = {
        "bin": attr.label(
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "data": attr.label_list(allow_files = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "command-runner.sh.tpl",
        ),
    },
    executable = True,
)

def _executable_path_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    path = ctx.attr.path

    symlink = actions.declare_symlink(name)
    actions.symlink(output = symlink, target_path = path)

    default_info = DefaultInfo(executable = symlink)

    return [default_info]

executable_path = rule(
    attrs = {
        "path": attr.string(mandatory = True),
    },
    executable = True,
    implementation = _executable_path_impl,
)

def _executable_symlink_impl(ctx):
    name = ctx.attr.name
    target = ctx.executable.target
    target_default = ctx.attr.target[DefaultInfo]

    symlink = ctx.actions.declare_file(name)
    ctx.actions.symlink(output = symlink, target_file = target)

    default_info = DefaultInfo(executable = symlink, runfiles = target_default.default_runfiles)

    return [default_info]

executable_symlink = rule(
    attrs = {
        "target": attr.label(cfg = "target", executable = True, mandatory = True),
    },
    doc = "Symlink to an executable. Similar to alias, but with a known runfile location.",
    executable = True,
    implementation = _executable_symlink_impl,
)

def _executable_toolchain_impl(ctx):
    executable_default = ctx.attr.executable[DefaultInfo]

    toolchain_info = platform_common.ToolchainInfo(
        executable = executable_default,
    )

    return [toolchain_info]

executable_toolchain = rule(
    attrs = {
        "executable": attr.label(
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
    },
    provides = [platform_common.ToolchainInfo],
    implementation = _executable_toolchain_impl,
)
