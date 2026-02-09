def _http_gz_impl(ctx):
    url = ctx.attr.url
    sha256 = ctx.attr.sha256

    ctx.download(
        output = "file.gz",
        sha256 = sha256,
        url = url,
    )
    ctx.template(
        "BUILD.bazel",
        Label(":http-gz.BUILD.bazel"),
    )

http_gz = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
    implementation = _http_gz_impl,
)
