load("@bazel_skylib//lib:shell.bzl", "shell")

def _query_bzl_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    query = ctx.attr.query
    out = ctx.attr.out
    if out.startswith("/"):
        out = out[len("/"):]
    elif ctx.label.package:
        out = "%s/%s" % (ctx.label.package, out)
    runner = ctx.file._runner

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        substitutions = {
            "%{query}": shell.quote(query),
            "%{output}": shell.quote(out),
        },
        output = executable,
        template = runner,
    )

    default_info = DefaultInfo(executable = executable)

    return [default_info]

query_bzl = rule(
    attrs = {
        "query": attr.string(mandatory = True),
        "out": attr.string(mandatory = True),
        "_runner": attr.label(
            allow_single_file = True,
            default = "query-targets.sh.tpl",
        ),
    },
    doc = "Query targets and generate Starlark file",
    executable = True,
    implementation = _query_bzl_impl,
)
