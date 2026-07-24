def _buildozer_impl(ctx):
    actions = ctx.actions
    buildozer = ctx.toolchains[":toolchain_type"]
    name = ctx.attr.name

    bin = buildozer.buildozer

    executable = actions.declare_file(name)
    actions.symlink(
        is_executable = True,
        output = executable,
        target_file = bin.files_to_run.executable,
    )

    runfiles = ctx.runfiles(files = [executable])
    default_runfiles = runfiles.merge(bin.default_runfiles)
    data_runfiles = runfiles.merge(bin.data_runfiles)

    default_info = DefaultInfo(
        executable = executable,
        default_runfiles = default_runfiles,
        data_runfiles = data_runfiles,
    )

    return [default_info]

buildozer = rule(
    executable = True,
    implementation = _buildozer_impl,
    toolchains = [":toolchain_type"],
)

def _buildozer_toolchain_impl(ctx):
    buildozer_default = ctx.attr.buildozer[DefaultInfo]

    toolchain_info = platform_common.ToolchainInfo(
        buildozer = buildozer_default,
    )

    return [toolchain_info]

buildozer_toolchain = rule(
    implementation = _buildozer_toolchain_impl,
    attrs = {
        "buildozer": attr.label(cfg = "target", executable = True, mandatory = True),
    },
)
