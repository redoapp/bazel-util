load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_skylib//lib:shell.bzl", "shell")

def _ibazel_sock_activate_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    name = ctx.attr.name
    addrs = ctx.attr.addrs
    ports = ctx.attr.ports
    server = ctx.executable._server
    server_default = ctx.attr._server[DefaultInfo]
    runner = ctx.file._runner

    # Build args from either addrs (quoted) or ports (with env var expansion)
    if ports and addrs:
        fail("Cannot specify both 'ports' and 'addrs'")
    if ports:
        args = " ".join(['--addr="tcp:${LISTEN_HOST:-localhost}:%s"' % port for port in ports])
    elif addrs:
        args = " ".join([shell.quote("--addr=%s" % addr) for addr in addrs])
    else:
        fail("Must specify either 'ports' or 'addrs'")

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{args}": args,
            "%{bin}": shell.quote(to_rlocation_path(ctx, bin)),
            "%{sock_activate}": shell.quote(to_rlocation_path(ctx, server)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(server_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

ibazel_sock_activate = rule(
    attrs = {
        "addrs": attr.string_list(default = []),
        "ports": attr.int_list(default = []),
        "bin": attr.label(cfg = "target", executable = True, mandatory = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "sock-activate-runner.sh.tpl",
        ),
        "_server": attr.label(
            cfg = "target",
            default = "//net/ibazel-sock-activate:bin",
            executable = True,
        ),
    },
    executable = True,
    implementation = _ibazel_sock_activate_impl,
)

def _sock_activate_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    name = ctx.attr.name
    addrs = ctx.attr.addrs
    ports = ctx.attr.ports
    server = ctx.executable._server
    server_default = ctx.attr._server[DefaultInfo]
    runner = ctx.file._runner

    # Build args from either addrs (quoted) or ports (with env var expansion)
    if ports and addrs:
        fail("Cannot specify both 'ports' and 'addrs'")
    if ports:
        args = " ".join(['--addr="tcp:${LISTEN_HOST:-localhost}:%s"' % port for port in ports])
    elif addrs:
        args = " ".join([shell.quote("--addr=%s" % addr) for addr in addrs])
    else:
        fail("Must specify either 'ports' or 'addrs'")

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{args}": args,
            "%{bin}": shell.quote(to_rlocation_path(ctx, bin)),
            "%{sock_activate}": shell.quote(to_rlocation_path(ctx, server)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(server_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

sock_activate = rule(
    attrs = {
        "addrs": attr.string_list(default = []),
        "ports": attr.int_list(default = []),
        "bin": attr.label(cfg = "target", executable = True, mandatory = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "sock-activate-runner.sh.tpl",
        ),
        "_server": attr.label(
            cfg = "target",
            default = "//net/sock-activate:bin",
            executable = True,
        ),
    },
    executable = True,
    implementation = _sock_activate_impl,
)

def _sock_activate_proxy_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    forwards = ctx.attr.forwards
    listens = ctx.attr.listens
    name = ctx.attr.name
    runner = ctx.file._runner
    server = ctx.executable._server
    server_default = ctx.attr._server[DefaultInfo]

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{args}": " ".join(
                [shell.quote("--forward=%s") % addr for addr in forwards] + [shell.quote("--listen=%s") % addr for addr in listens],
            ),
            "%{bin}": shell.quote(to_rlocation_path(ctx, bin)),
            "%{sock_activate}": shell.quote(to_rlocation_path(ctx, server)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(server_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

sock_activate_proxy = rule(
    attrs = {
        "bin": attr.label(cfg = "target", executable = True, mandatory = True),
        "forwards": attr.string_list(mandatory = True),
        "listens": attr.string_list(mandatory = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "sock-activate-proxy-runner.sh.tpl",
        ),
        "_server": attr.label(
            cfg = "target",
            default = "//net/sock-activate-proxy:bin",
            executable = True,
        ),
    },
    executable = True,
    implementation = _sock_activate_proxy_impl,
)
