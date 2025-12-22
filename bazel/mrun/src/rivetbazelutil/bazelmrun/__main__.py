import argparse
import signal

signal.signal(signal.SIGINT, signal.SIG_DFL)


def alias_type(arg: str):
    try:
        target, alias = arg.split("=", 1)
        return (target, alias)
    except ValueError:
        raise argparse.ArgumentTypeError("Requires TARGET=ALIAS format")


parser = argparse.ArgumentParser(
    prog="bazel-mrun", description="Build and run Bazel executables."
)
parser.add_argument(
    "--alias",
    action="append",
    default=[],
    type=alias_type,
    dest="aliases",
    metavar="TARGET=ALIAS",
    help="aliases",
)
parser.add_argument(
    "--bazel-arg",
    action="append",
    default=[],
    dest="bazel_args",
    metavar="BAZEL_ARG",
    help="bazel argument",
)
parser.add_argument(
    "--parallelism",
    type=int,
    help="maximum concurrent processes",
)
parser.add_argument(
    "--width",
    type=int,
)
parser.add_argument(
    "targets",
    nargs="*",
    help="Targets to run",
    metavar="target",
)

args = parser.parse_args()

from rivetbazelutil.bazelmrun import mrun
from rivetbazelutil.common import run

run.set_cwd()

mrun.run(
    aliases=dict(args.aliases),
    bazel_args=args.bazel_args,
    parallelism=args.parallelism,
    targets=args.targets,
    width=args.width,
)
