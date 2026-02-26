def _git_changed_files_impl(ctx):
    ctx.getenv("BUILD_RANDOM")  # trigger re-run

    build = ctx.attr._build
    changed_files = ctx.attr._changed_files
    base_ref = ctx.getenv("GIT_BASE_REF") or "HEAD"
    file_rules = ctx.attr._file_rules

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

    ctx.template("BUILD.bazel", build, executable = False, substitutions = {
        '"%{file_rules}"': repr(str(file_rules)),
    })
    ctx.template(
        "files.bzl",
        changed_files,
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
        "_build": attr.label(
            default = "changed_files.BUILD.bazel",
            doc = "BUILD.bazel template",
        ),
        "_changed_files": attr.label(
            default = "changed_files.bzl.tpl",
            doc = "files.bzl template",
        ),
        "_file_rules": attr.label(default = "//file:rules.bzl"),
    },
    doc = "Git changed files. Must set BUILD_RANDOM to trigger re-run.",
    implementation = _git_changed_files_impl,
)
