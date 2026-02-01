def _jsonschema_archive_impl(repository_ctx):
    build = repository_ctx.attr._build
    rules = repository_ctx.attr._rules
    sha256 = repository_ctx.attr.sha256
    url = repository_ctx.attr.url

    repository_ctx.template(
        "BUILD.bazel",
        build,
        substitutions = {
            '"%{rules}"': repr(str(rules)),
        },
    )

    result = repository_ctx.download_and_extract(
        sha256 = sha256,
        url = url,
    )

    return repository_ctx.repo_metadata(
        reproducible = True,
    )

jsonschema_http_archive = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "_build": attr.label(default = "jsonschema.BUILD.bazel"),
        "_rules": attr.label(default = "rules.bzl"),
    },
    implementation = _jsonschema_archive_impl,
)
