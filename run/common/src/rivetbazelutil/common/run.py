import os
import pathlib
from rivetbazelutil.common import prefix


def _create_pg():
    os.setpgid(0, 0)


def set_cwd():
    try:
        wd = os.environ["BUILD_WORKING_DIRECTORY"]
    except KeyError:
        pass
    else:
        del os.environ["BUILD_WORKING_DIRECTORY"]
        os.chdir(wd)


def run_executable(
    workspace,
    execution_root,
    executable,
    name,
    width,
    create_pg=False,
    display_code=False,
    stdin=None,
):
    env = dict(os.environ)
    env.pop("RUNFILES_DIR", None)
    env.pop("RUNFILES_MANIFEST_FILE", None)
    env["BUILD_WORKING_DIRECTORY"] = str(pathlib.Path.cwd())
    env["BUILD_WORKSPACE_DIRECTORY"] = str(workspace)
    executable = execution_root / executable
    options = {
        "cwd": f"{executable}.runfiles/{execution_root.name}",
        "env": env,
        "stdin": stdin,
    }
    if create_pg:
        options["preexec_fn"] = _create_pg
    return prefix.run_process(
        args=[str(executable)],
        display_code=display_code,
        name=name,
        width=width,
        process_options=options,
    )
