load("//util:providers.bzl", _create_digest = "create_digest")

# deprecated
def create_digest(name, actions, runfiles, hash):
    output = actions.declare_file("%s.digest" % name)

    _create_digest(
        actions = actions,
        output = output,
        runfiles = runfiles,
        hash = hash,
    )

    return output
