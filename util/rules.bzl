load("@bazel_skylib//lib:shell.bzl", "shell")
load("//util:path.bzl", "runfile_path")
load(":providers.bzl", "create_digest")

def _digest_impl(ctx):
    actions = ctx.actions
    encoding = ctx.attr.encoding or None
    hash = ctx.attr._hash[DefaultInfo]
    length = ctx.attr.length or None
    name = ctx.attr.name
    srcs = ctx.files.srcs
    executable_infos = [target[DefaultInfo] for target in ctx.attr.executables]

    digest = actions.declare_file("%s.%s" % (name, "txt" if encoding else "digest"))
    create_digest(
        actions = actions,
        encoding = encoding,
        hash = hash,
        length = length,
        output = digest,
        runfiles = ctx.runfiles(files = srcs).merge_all(
            [default_info.default_runfiles for default_info in executable_infos],
        ),
    )

    default_info = DefaultInfo(files = depset([digest]))

    return [default_info]

digest = rule(
    attrs = {
        "executables": attr.label_list(),
        "length": attr.int(),
        "srcs": attr.label_list(allow_files = True),
        "encoding": attr.string(),
        "_hash": attr.label(
            cfg = "exec",
            default = "//util/hash:bin",
            executable = True,
        ),
    },
    implementation = _digest_impl,
)

def _digest_binary_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    executable_ = ctx.executable.executable
    executable_default = ctx.attr.executable[DefaultInfo]
    data = ctx.files.data
    data_default = [target[DefaultInfo] for target in ctx.attr.data]
    digest = ctx.attr.digest
    deps_default = [target[DefaultInfo] for target in ctx.attr.deps]
    deps_output_group = [target[OutputGroupInfo] for target in ctx.attr.deps]
    hash = ctx.attr._hash[DefaultInfo]
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        substitutions = {
            "%{executable}": shell.quote(runfile_path(workspace, executable_)),
        },
        template = runner,
        output = executable,
    )

    runfiles = ctx.runfiles(transitive_files = depset(data))
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(executable_default.default_runfiles)
    runfiles = runfiles.merge_all([default_info.default_runfiles for default_info in data_default])
    runfiles = runfiles.merge_all([default_info.default_runfiles for default_info in deps_default])
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    digest_runfiles = ctx.runfiles(
        transitive_files = depset(data if "data" in digest else None, transitive = [output_group_info.digest for output_group_info in deps_output_group]),
    )
    if "data" in digest:
        digest_runfiles = digest_runfiles.merge_all([default_info.default_runfiles for default_info in data_default])
    if "executable" in digest:
        digest_runfiles = digest_runfiles.merge(executable_default.default_runfiles)

    digest = actions.declare_file("%s.digest" % name)
    create_digest(
        actions = actions,
        hash = hash,
        output = digest,
        runfiles = digest_runfiles,
    )

    output_group_info = OutputGroupInfo(digest = depset([digest]))

    return [default_info, output_group_info]

digest_binary = rule(
    attrs = {
        "executable": attr.label(cfg = "target", executable = True),
        "digest": attr.string_list(default = ["data", "executable"]),
        "data": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_hash": attr.label(
            cfg = "exec",
            default = "//util/hash:bin",
            executable = True,
        ),
        "_runner": attr.label(allow_single_file = True, default = "digest-binary-runner.sh.tpl"),
    },
    executable = True,
    implementation = _digest_binary_impl,
)
