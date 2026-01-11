def _mode_transition_impl(settings, attr):
    return {
        "//command_line_option:compilation_mode": attr.compilation_mode or settings["//command_line_option:compilation_mode"],
        "//command_line_option:platforms": attr.platforms or settings["//command_line_option:platforms"],
        "//command_line_option:stamp": bool(attr.stamp) if attr.stamp != -1 else settings["//command_line_option:stamp"],
    }

mode_transition = transition(
    implementation = _mode_transition_impl,
    inputs = ["//command_line_option:compilation_mode", "//command_line_option:platforms", "//command_line_option:stamp"],
    outputs = ["//command_line_option:compilation_mode", "//command_line_option:platforms", "//command_line_option:stamp"],
)
