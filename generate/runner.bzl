load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_skylib//lib:shell.bzl", "shell")

def create_runner(args_bin, runfiles_fn, name, bash_runfiles, actions, bin, diff_bin, dir_mode, file_mode, label, run_bin, runner_template, file_defs, ctx):
    check_args = []
    write_args = []
    diffs = []
    for path, file_def in file_defs.items():
        diff = actions.declare_file("%s.diff/%s.patch" % (name, path))
        args = actions.args()
        args.add_all([file_def.src if file_def.src else ""], expand_directories = False)
        args.add_all([file_def.generated if file_def.generated else ""], expand_directories = False)
        args.add(diff)
        actions.run(
            arguments = [args],
            executable = diff_bin.files_to_run.executable,
            execution_requirements = {
                "supports-path-mapping": "1",
            },
            inputs = ([file_def.src] if file_def.src else []) + ([file_def.generated] if file_def.generated else []),
            mnemonic = "Diff",
            outputs = [diff],
            progress_message = "Diffing %{output}",
            tools = [diff_bin.files_to_run],
        )
        diffs.append(diff)

        check_args.append(
            struct(
                diff = diff,
                args = [to_rlocation_path(ctx, diff)],
            ),
        )
        write_args.append(
            struct(
                diff = diff,
                args = [
                    "--file",
                    path,
                    to_rlocation_path(ctx, file_def.generated) if file_def.generated else "",
                    to_rlocation_path(ctx, diff),
                ],
            ),
        )

    check_args_file = actions.declare_file("%s.check.args" % name)
    _args(
        actions = actions,
        args_bin = args_bin,
        defs = check_args,
        output = check_args_file,
        prefix = "%s.check-" % name,
    )

    write_args_file = actions.declare_file("%s.write.args" % name)
    _args(
        actions = actions,
        args_bin = args_bin,
        defs = write_args,
        output = write_args_file,
        prefix = "%s.write-" % name,
    )

    bin = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        template = runner_template,
        output = bin,
        substitutions = {
            "%{check_args}": shell.quote(to_rlocation_path(ctx, check_args_file)),
            "%{dir_mode}": shell.quote(dir_mode),
            "%{label}": shell.quote(str(label)),
            "%{file_mode}": shell.quote(file_mode),
            "%{write_args}": shell.quote(to_rlocation_path(ctx, write_args_file)),
        },
    )

    generated = [file_def.generated for file_def in file_defs.values() if file_def.generated]

    runfiles = runfiles_fn(files = [check_args_file, write_args_file] + diffs + generated)
    runfiles = runfiles.merge(bash_runfiles)
    runfiles = runfiles.merge(diff_bin.default_runfiles)

    # It seems that Python executable requires data_runfiles.
    # Otherwise, fails with error: Cannot find .runfiles directory
    runfiles = runfiles.merge(run_bin.data_runfiles)

    default_info = DefaultInfo(
        executable = bin,
        runfiles = runfiles,
    )

    return default_info

_BATCH = 100

def _args(actions, args_bin, prefix, defs, output):
    parts = []
    for i in range(0, len(defs), _BATCH):
        part = actions.declare_file("%s%x" % (prefix, i // _BATCH))
        diffs = []
        args = actions.args()
        args.add("--output", part)
        for def_ in defs[i:i + _BATCH]:
            diffs.append(def_.diff)
            args.add("=".join([def_.diff.path] + def_.args))
        actions.run(
            arguments = [args],
            executable = args_bin.files_to_run.executable,
            execution_requirements = {"no-remote-cache": "1"},
            inputs = diffs,
            mnemonic = "Args",
            outputs = [part],
            progress_message = "Writing args for %{input}",
            tools = [args_bin.files_to_run],
        )
        parts.append(part)
    files = parts

    args = actions.args()
    args.add(output)
    for file in files:
        args.add(file)
    actions.run_shell(
        arguments = [args],
        command = 'out="$1" && shift && cat "$@" > "$out"',
        execution_requirements = {"no-remote-cache": "1"},
        inputs = files,
        mnemonic = "Concat",
        outputs = [output],
        progress_message = "Concatenating %{output}",
    )
