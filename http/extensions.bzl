load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("//bzlmod:facts.bzl", "create_versioned_facts", "get_versioned_facts")
load(":repositories.bzl", "http_gz")

_archive_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "strip_prefix": attr.string(),
        "url": attr.string(mandatory = True),
    },
)

_file_tag = tag_class(
    attrs = {
        "downloaded_file_path": attr.string(),
        "name": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
)

_file_gz_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
)

def _http_impl(ctx):
    facts = get_versioned_facts(ctx.facts, _FACTS_VERSION)

    urls = {}
    for module in ctx.modules:
        for archive in module.tags.archive:
            integrity = facts and facts["urls"].get(archive.url)
            if integrity == None:
                ctx.report_progress("Fetching %s" % archive.url)
                result = ctx.download(
                    output = "file",
                    url = archive.url,
                )
                integrity = result.integrity
            urls[archive.url] = integrity
            http_archive(
                name = archive.name,
                integrity = integrity,
                strip_prefix = archive.strip_prefix,
                url = archive.url,
            )

    for module in ctx.modules:
        for file in module.tags.file:
            integrity = facts and facts["urls"].get(file.url)
            if integrity == None:
                ctx.report_progress("Fetching %s" % file.url)
                result = ctx.download(
                    output = "file",
                    url = file.url,
                )
                integrity = result.integrity
            urls[file.url] = integrity
            http_file(
                name = file.name,
                downloaded_file_path = file.downloaded_file_path,
                integrity = integrity,
                url = file.url,
            )

    for module in ctx.modules:
        for file_gz in module.tags.file_gz:
            integrity = facts and facts["urls"].get(file_gz.url)
            if integrity == None:
                ctx.report_progress("Fetching %s" % file_gz.url)
                result = ctx.download(
                    output = "file.gz",
                    url = file_gz.url,
                )
                integrity = result.integrity
            urls[file_gz.url] = integrity
            http_gz(
                name = file_gz.name,
                integrity = integrity,
                url = file_gz.url,
            )

    return ctx.extension_metadata(
        facts = create_versioned_facts(_FACTS_VERSION, {"urls": urls}),
        reproducible = True,
    )

# Memorizes digests
http = module_extension(
    implementation = _http_impl,
    tag_classes = {
        "archive": _archive_tag,
        "file": _file_tag,
        "file_gz": _file_gz_tag,
    },
)

_FACTS_VERSION = "1"
