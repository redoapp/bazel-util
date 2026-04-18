def _git_changed_files_impl(ctx):
    ctx.getenv("BUILD_RANDOM")  # trigger re-run

    base_ref = ctx.getenv("GIT_BASE_REF") or "HEAD"

    workspace = ctx.path(ctx.attr.root_file).dirname

    files = set()

    result = ctx.execute(
        ["git", "diff", "--name-only", "--merge-base", base_ref],
        working_directory = str(workspace),
    )
    if result.return_code not in (0, 1):
        fail("git diff failed:\n%s" % result.stderr)
    files.update(result.stdout.strip().split("\n"))

    result = ctx.execute(
        ["git", "ls-files", "--exclude-standard", "--others"],
        working_directory = str(workspace),
    )
    if result.return_code:
        fail("git ls-files failed:\n%s" % result.stderr)
    files.update(result.stdout.strip().split("\n"))

    ctx.template(
        "BUILD.bazel",
        Label("//file:paths_filter.BUILD.bazel.tpl"),
        executable = False,
        substitutions = {
            '"%{file_rules}"': repr(str(Label("//file:rules.bzl"))),
        },
    )
    ctx.template(
        "files.bzl",
        Label("//file:paths_filter.bzl.tpl"),
        executable = False,
        substitutions = {
            "%{files}": json.encode(files),
        },
    )

git_changed_files = repository_rule(
    attrs = {
        "root_file": attr.label(
            doc = "A file in the root of the workspace.",
            mandatory = True,
        ),
    },
    doc = "Git changed files. Must set BUILD_RANDOM to trigger re-run.",
    implementation = _git_changed_files_impl,
)
