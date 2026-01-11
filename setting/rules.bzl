load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":transitions.bzl", "mode_transition")

def _mode_target_impl(ctx):
    actions = ctx.actions
    dep_default = ctx.attr.dep[0][DefaultInfo]
    dep_output_group = ctx.attr.dep[0][OutputGroupInfo] if OutputGroupInfo in ctx.attr.dep[0] else None
    dep_toolchain = ctx.attr.dep[0][platform_common.ToolchainInfo] if platform_common.ToolchainInfo in ctx.attr.dep[0] else None
    name = ctx.attr.name

    if dep_default.files_to_run.executable:
        # Bazel requires executable to come this target.
        # Create symlink to original executable.
        executable = actions.declare_file(name)
        actions.symlink(
            output = executable,
            target_file = dep_default.files_to_run.executable,
        )
        runfiles = ctx.runfiles(files = [executable])
        default_info = DefaultInfo(
            executable = executable,
            data_runfiles = runfiles.merge(dep_default.data_runfiles),
            default_runfiles = runfiles.merge(dep_default.default_runfiles),
        )
    else:
        default_info = dep_default

    return [default_info] + ([dep_output_group] if dep_output_group else []) + ([dep_toolchain] if dep_toolchain else [])

mode_bin = rule(
    attrs = {
        "dep": attr.label(cfg = mode_transition, doc = "Dependency", mandatory = True),
        "compilation_mode": attr.string(doc = "--compilation_mode, or empty to use existing value"),
        "platforms": attr.string(doc = "--platforms, or empty to use existing value"),
        "stamp": attr.int(default = -1, doc = "--stamp, or -1 to use existing value"),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
    implementation = _mode_target_impl,
)

mode_target = rule(
    attrs = {
        "dep": attr.label(cfg = mode_transition, doc = "Dependency", mandatory = True),
        "compilation_mode": attr.string(doc = "--compilation_mode, or empty to use existing value"),
        "platforms": attr.string(doc = "--platforms, or empty to use existing value"),
        "stamp": attr.int(default = -1, doc = "--stamp, or -1 to use existing value"),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    implementation = _mode_target_impl,
)

def _setting_file_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    setting_setting_info = ctx.attr.setting[BuildSettingInfo]

    output = actions.declare_file("%s.txt" % name)
    actions.write(content = setting_setting_info.value, output = output)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

setting_file = rule(
    attrs = {
        "setting": attr.label(mandatory = True, providers = [BuildSettingInfo]),
    },
    doc = "File whose contents are the build setting",
    implementation = _setting_file_impl,
)
