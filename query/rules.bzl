load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_skylib//lib:shell.bzl", "shell")
load(":providers.bzl", "QueryBzlInfo")

# A tag becomes part of a regex in the query, and is compared literally when the
# result is split up. Only characters that mean themselves in both places keep
# those two agreeing.
_TAG_CHARACTERS = "-.0123456789:=ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"

def _check_tag(tag):
    for character in tag.elems():
        if character not in _TAG_CHARACTERS:
            fail("tag %s contains %s, which does not mean itself in a regex" % (tag, character))

def _check_kind(kind):
    # kind is a regex, evaluated by Bazel to build the result and by the runner
    # to split it up. Only the syntax common to both is safe.
    if "'" in kind:
        fail("kind %s contains a quote, which would end the query's string" % kind)

def _exclude(ctx):
    labels = []
    for value in ctx.attr.exclude:
        label = ctx.label.relative(value)
        if label.workspace_name:
            fail("exclude %s is outside this repository, which the query does not cover" % value)
        labels.append("//%s:%s" % (label.package, label.name))
    return labels

def _out(ctx):
    out = ctx.attr.out
    if out.startswith("/"):
        return out[len("/"):]
    if ctx.label.package:
        return "%s/%s" % (ctx.label.package, out)
    return out

def _runner(ctx, specs):
    actions = ctx.actions
    name = ctx.attr.name

    manifest = actions.declare_file("%s.manifest.json" % name)
    actions.write(manifest, json.encode(specs))

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{manifest}": shell.quote(to_rlocation_path(ctx, manifest)),
            "%{run}": shell.quote(to_rlocation_path(ctx, ctx.executable._run)),
        },
        template = ctx.file._runner,
    )

    runfiles = ctx.runfiles(files = [manifest, ctx.executable._run])
    runfiles = runfiles.merge(ctx.attr._run[DefaultInfo].default_runfiles)
    return DefaultInfo(executable = executable, runfiles = runfiles)

def _query_bzl_impl(ctx):
    if ctx.attr.query:
        # The escape hatch runs its own query verbatim, so it cannot be batched
        # and none of the structured attributes apply to it.
        for attribute in ["exclude", "kind", "tag"]:
            if getattr(ctx.attr, attribute):
                fail("query cannot be combined with %s" % attribute)
        spec = {
            "exclude": [],
            "kind": None,
            "out": _out(ctx),
            "query": ctx.attr.query,
            "tag": None,
        }
        return [_runner(ctx, [spec]), QueryBzlInfo(**spec)]

    if not ctx.attr.kind and not ctx.attr.tag:
        fail("one of query, kind or tag is required")
    if ctx.attr.kind:
        _check_kind(ctx.attr.kind)
    if ctx.attr.tag:
        _check_tag(ctx.attr.tag)

    spec = {
        "exclude": _exclude(ctx),
        "kind": ctx.attr.kind or None,
        "out": _out(ctx),
        "query": None,
        "tag": ctx.attr.tag or None,
    }

    return [_runner(ctx, [spec]), QueryBzlInfo(**spec)]

def _query_bzls_impl(ctx):
    specs = []
    labels = {}
    for dep in ctx.attr.deps:
        info = dep[QueryBzlInfo]
        if info.out in labels:
            fail("%s and %s both generate %s" % (labels[info.out], dep.label, info.out))
        labels[info.out] = dep.label
        if info.query:
            fail("%s sets query, which runs its own query and cannot be batched" % dep.label)
        specs.append({
            "exclude": info.exclude,
            "kind": info.kind,
            "out": info.out,
            "query": None,
            "tag": info.tag,
        })

    return [_runner(ctx, specs)]

_RUNNER_ATTRS = {
    "_run": attr.label(
        cfg = "exec",
        default = "//query/run:bin",
        executable = True,
    ),
    "_runner": attr.label(
        allow_single_file = True,
        default = "runner.sh.tpl",
    ),
}

query_bzl = rule(
    attrs = dict(
        {
            # Strings, not labels: these are subtracted from a query's result,
            # and depending on them would pull testonly targets into a
            # non-testonly rule.
            "exclude": attr.string_list(
                doc = "Labels to subtract from the result. Each must match a target the query returns.",
            ),
            "kind": attr.string(
                doc = "Rule kind pattern, as in the query language's kind()",
            ),
            "out": attr.string(mandatory = True),
            # Escape hatch for queries the structured attributes cannot express,
            # such as subtracting a package pattern. Runs its own bazel query and
            # writes its result verbatim, so it is not batchable.
            "query": attr.string(
                doc = "Raw query, run on its own. Cannot be combined with kind, tag or exclude, and cannot be batched by query_bzls.",
            ),
            "tag": attr.string(
                doc = "Tag the target must carry. A \".\" in it matches any character in the query, which only widens what the runner then filters.",
            ),
        },
        **_RUNNER_ATTRS
    ),
    doc = "Query targets and generate Starlark file",
    executable = True,
    implementation = _query_bzl_impl,
    provides = [QueryBzlInfo],
)

query_bzls = rule(
    attrs = dict(
        {
            "deps": attr.label_list(
                allow_empty = False,
                doc = "query_bzl targets to generate together",
                mandatory = True,
                providers = [QueryBzlInfo],
            ),
        },
        **_RUNNER_ATTRS
    ),
    doc = "Generate several query_bzl files with a single query",
    executable = True,
    implementation = _query_bzls_impl,
)
