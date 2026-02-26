def _jsonschema_archive_impl(ctx):
    build = ctx.attr._build
    rules = ctx.attr._rules
    sha256 = ctx.attr.sha256
    strip_prefix = ctx.attr.strip_prefix
    url = ctx.attr.url

    ctx.template(
        "BUILD.bazel",
        build,
        substitutions = {
            '"%{rules}"': repr(str(rules)),
        },
    )

    result = ctx.download_and_extract(
        sha256 = sha256,
        stripPrefix = strip_prefix,
        url = url,
    )

    return ctx.repo_metadata(
        reproducible = True,
    )

jsonschema_http_archive = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(),
        "url": attr.string(mandatory = True),
        "_build": attr.label(default = "jsonschema.BUILD.bazel"),
        "_rules": attr.label(default = "rules.bzl"),
    },
    implementation = _jsonschema_archive_impl,
)
