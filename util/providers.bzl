def _runfiles_files(runfiles):
    return (
        [entry.target_file for entry in runfiles.symlinks.to_list()] +
        [entry.target_file for entry in runfiles.root_symlinks.to_list()] +
        runfiles.files.to_list()
    )

def _create_one_digest(actions, output, files, hash, encoding, length = None):
    args = actions.args()
    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)
    if encoding != None:
        args.add("--encoding", encoding)
    if length:
        args.add("--length", length)
    args.add(output)

    actions.run(
        arguments = [args],
        executable = hash.files_to_run.executable,
        execution_requirements = {
            "requires-worker-protocol": "json",
            "supports-workers": "1",
        },
        inputs = files,
        mnemonic = "Hash",
        outputs = [output],
        progress_message = "Creating digest %{output}",
        tools = [hash.files_to_run],
    )

    return output

def create_digest(actions, output, runfiles, hash, encoding = None, length = None):
    files = _runfiles_files(runfiles)

    if 200 <= len(files):
        package_path = "/".join([part for part in [output.root.path, output.owner.workspace_name, output.owner.package] if part])
        output_name = output.path[len("%s/" % package_path):]
        new_files = []
        for i in range(0, len(files), 100):
            one_output = actions.declare_file("%s%s" % (output_name, i))
            _create_one_digest(
                actions = actions,
                encoding = None,
                files = files[i:i + 100],
                hash = hash,
                output = one_output,
            )
            new_files.append(one_output)
        files = new_files

    return _create_one_digest(
        actions = actions,
        encoding = encoding,
        files = files,
        hash = hash,
        length = length,
        output = output,
    )
