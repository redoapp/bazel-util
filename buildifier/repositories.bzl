def _buildifier_http_impl(ctx):
    build = ctx.attr._build
    rules = ctx.attr._rules
    sh_binary_rules = ctx.attr._sh_binary_rules
    sha256 = ctx.attr.sha256
    url = ctx.attr.url

    ctx.template(
        "BUILD.bazel",
        build,
        substitutions = {
            '"%{rules}"': json.encode(str(rules)),
            '"%{sh_binary_rules}"': json.encode(str(sh_binary_rules)),
        },
    )

    result = ctx.download(
        executable = True,
        output = "buildifier",
        sha256 = sha256,
        url = url,
    )

buildifier_http = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "_build": attr.label(default = "buildifier.BUILD.bazel"),
        "_rules": attr.label(default = "rules.bzl"),
        "_sh_binary_rules": attr.label(default = "@rules_shell//shell:sh_binary.bzl"),
    },
    implementation = _buildifier_http_impl,
)
