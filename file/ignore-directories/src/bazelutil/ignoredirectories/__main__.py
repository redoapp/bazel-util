from argparse import ArgumentParser
from ast import Call, Expr, Name, literal_eval, parse
from pathlib import Path
from sys import exit

parser = ArgumentParser(
    description="Write ignore_directories() of a REPO.bazel file as a manifest.",
    prog="ignore-directories",
)
parser.add_argument("repo", type=Path, help="REPO.bazel file.")
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()


def ignore_directories(path):
    for statement in parse(path.read_text()).body:
        if not isinstance(statement, Expr):
            continue
        call = statement.value
        if (
            not isinstance(call, Call)
            or not isinstance(call.func, Name)
            or call.func.id != "ignore_directories"
        ):
            continue
        if len(call.args) != 1 or call.keywords:
            exit(f"{path}:{call.lineno}: unexpected ignore_directories() arguments")
        try:
            patterns = literal_eval(call.args[0])
        except ValueError:
            exit(f"{path}:{call.lineno}: ignore_directories() argument is not literal")
        yield from patterns


with args.output.open("w") as output:
    print(f"# Generated from {args.repo.name}", file=output)
    for pattern in ignore_directories(args.repo):
        print(pattern, file=output)
