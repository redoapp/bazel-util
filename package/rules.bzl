load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@rules_pkg//pkg:providers.bzl", "PackageFilegroupInfo", "PackageFilesInfo", "PackageSymlinkInfo")

def _runfiles_pkg_files(ctx, runfiles):
    files = {}
    for file in runfiles.files.to_list():
        files[to_rlocation_path(ctx, file)] = file
    for file in runfiles.symlinks.to_list():
        files[file.path] = "%s/%s" % (ctx.workspace_name, file.target_file)
    for file in runfiles.root_symlinks.to_list():
        files[file.path] = file.target_file

    return PackageFilesInfo(
        dest_src_map = files,
        attributes = {"mode": "0755"},
    )

def _pkg_runfiles_impl(ctx):
    runfiles = ctx.attr.runfiles[DefaultInfo]
    label = ctx.label

    runfiles_files = _runfiles_pkg_files(ctx, runfiles.default_runfiles)

    pkg_filegroup_info = PackageFilegroupInfo(
        pkg_dirs = [],
        pkg_files = [(runfiles_files, label)],
        pkg_symlinks = [],
    )

    default_info = DefaultInfo(files = depset(runfiles_files.dest_src_map.values()))

    return [default_info, pkg_filegroup_info]

pkg_runfiles = rule(
    implementation = _pkg_runfiles_impl,
    attrs = {
        "runfiles": attr.label(
            doc = "Runfiles.",
            mandatory = True,
        ),
    },
    provides = [PackageFilegroupInfo],
)

def _pkg_executable_impl(ctx):
    bin = ctx.attr.bin[DefaultInfo]
    bin_executable = ctx.executable.bin
    path = ctx.attr.path
    label = ctx.label

    runfiles_files = _runfiles_pkg_files(ctx, bin.default_runfiles)
    runfiles_files = PackageFilesInfo(
        dest_src_map = {"%s.runfiles/%s" % (path, p): file for p, file in runfiles_files.dest_src_map.items()},
        attributes = runfiles_files.attributes,
    )

    executable_symlink = PackageSymlinkInfo(
        attributes = {"mode": "0755"},
        destination = path,
        target = "%s.runfiles/%s" % (path, to_rlocation_path(ctx, bin_executable)),
    )

    pkg_filegroup_info = PackageFilegroupInfo(
        pkg_dirs = [],
        pkg_files = [(runfiles_files, label)],
        pkg_symlinks = [(executable_symlink, label)],
    )

    default_info = DefaultInfo(files = depset(runfiles_files.dest_src_map.values()))

    return [default_info, pkg_filegroup_info]

pkg_executable = rule(
    implementation = _pkg_executable_impl,
    attrs = {
        "bin": attr.label(
            doc = "Executable.",
            executable = True,
            cfg = "target",
            mandatory = True,
        ),
        "path": attr.string(
            doc = "Executable path. (Runfiles tree with be adjacent.)",
            mandatory = True,
        ),
    },
    provides = [PackageFilegroupInfo],
)
