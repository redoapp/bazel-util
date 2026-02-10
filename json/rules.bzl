def _jq_impl(ctx):
    jq_toolchain = ctx.toolchains["@jq.bzl//jq/toolchain:type"]
    name = ctx.attr.name

    bin = ctx.actions.declare_file(name)
    ctx.actions.symlink(
        output = bin,
        target_file = jq_toolchain.jqinfo.bin
    )

    default_info = DefaultInfo(executable = bin)

    return [default_info]

jq = rule(
    executable = True,
    implementation = _jq_impl,
    toolchains = ["@jq.bzl//jq/toolchain:type"],
)
