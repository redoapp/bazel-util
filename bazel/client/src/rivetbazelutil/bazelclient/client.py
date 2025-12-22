import subprocess
import typing


def build(targets, options=[]):
    args = ["bazel", "build"] + options + targets
    process = subprocess.run(args, stdin=subprocess.DEVNULL, check=True)
    return process.stdout


def cquery(query, options=[]) -> str:
    args = ["bazel", "cquery"] + options + [query]
    process = subprocess.run(
        args,
        encoding="utf-8",
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        check=True,
    )
    return process.stdout


def info(keys=None, options=[]) -> typing.Dict[str, str]:
    if keys is not None and not keys:
        return {}
    args = ["bazel", "info"] + options
    if keys is not None:
        args += keys
    process = subprocess.run(
        args,
        encoding="utf-8",
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        check=True,
    )
    lines = process.stdout.rstrip("\n").split("\n")
    if keys is not None and len(keys) == 1:
        return {keys[0]: lines[0]}
    return dict(line.split(": ", 1) for line in lines)
