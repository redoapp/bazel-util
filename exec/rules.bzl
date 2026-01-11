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
