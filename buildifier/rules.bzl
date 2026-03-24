load("//generate:providers.bzl", "FormatterInfo")

def _buildifier_format(ctx, path, src, out, bin):
    args = ctx.actions.args()
    args.add(bin.executable)
    args.add(src)
    args.add(out)
    ctx.actions.run_shell(
        arguments = [args],
        command = 'cp "$2" "$3" && "$1" "$3"',
        execution_requirements = {
            "supports-path-mapping": "1",
        },
        inputs = [src],
        outputs = [out],
        tools = [bin],
    )

def _buildifier_impl(ctx):
    actions = ctx.actions
    buildifier = ctx.toolchains[":toolchain_type"]
    name = ctx.attr.name

    bin = buildifier.buildifier

    def format(ctx, path, src, out):
        _buildifier_format(ctx, path, src, out, bin.files_to_run)

    format_info = FormatterInfo(
        fn = format,
    )

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

    return [default_info, format_info]

buildifier = rule(
    executable = True,
    implementation = _buildifier_impl,
    toolchains = [":toolchain_type"],
)

def _buildifier_toolchain_impl(ctx):
    buildifier_default = ctx.attr.buildifier[DefaultInfo]

    toolchain_info = platform_common.ToolchainInfo(
        buildifier = buildifier_default,
    )

    return [toolchain_info]

buildifier_toolchain = rule(
    implementation = _buildifier_toolchain_impl,
    attrs = {
        "buildifier": attr.label(cfg = "target", executable = True, mandatory = True),
    },
)
