def _buildozer_http_impl(ctx):
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

    ctx.download(
        executable = True,
        output = "buildozer",
        sha256 = sha256,
        url = url,
    )

    return ctx.repo_metadata(
        reproducible = True,
    )

buildozer_http = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "_build": attr.label(default = "buildozer.BUILD.bazel"),
        "_rules": attr.label(default = "rules.bzl"),
        "_sh_binary_rules": attr.label(default = "@rules_shell//shell:sh_binary.bzl"),
    },
    implementation = _buildozer_http_impl,
)
