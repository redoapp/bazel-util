def _ibazel_http_impl(ctx):
    build = ctx.attr._build
    rules = ctx.attr._rules
    sha256 = ctx.attr.sha256
    url = ctx.attr.url

    ctx.template(
        "BUILD.bazel",
        build,
        substitutions = {
            '"%{rules}"': repr(str(rules)),
        },
    )

    result = ctx.download(
        executable = True,
        output = "ibazel",
        sha256 = sha256,
        url = url,
    )

    return ctx.repo_metadata(
        reproducible = True,
    )

ibazel_http = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "_build": attr.label(default = "ibazel.BUILD.bazel"),
        "_rules": attr.label(default = "rules.bzl"),
    },
    implementation = _ibazel_http_impl,
)
