def _http_gz_impl(ctx):
    sha256 = ctx.attr.sha256
    url = ctx.attr.url

    ctx.download(
        output = "file.gz",
        sha256 = sha256,
        url = url,
    )
    ctx.template(
        "BUILD.bazel",
        Label(":http-gz.BUILD.bazel"),
    )

    return ctx.repo_metadata(
        reproducible = True,
    )

http_gz = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
    implementation = _http_gz_impl,
)
