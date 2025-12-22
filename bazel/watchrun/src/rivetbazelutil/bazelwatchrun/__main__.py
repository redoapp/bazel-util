import argparse
import signal

signal.signal(signal.SIGTERM, signal.default_int_handler)


def alias_type(arg: str):
    try:
        target, name = arg.split("=", 1)
        return (target, name)
    except ValueError:
        raise argparse.ArgumentTypeError("Requires TARGET=NAME format")


parser = argparse.ArgumentParser(
    prog="bazel-watchrun", description="Build and run Bazel executables."
)
parser.add_argument(
    "--alias",
    action="append",
    default=[],
    dest="aliases",
    metavar="TARGET=NAME",
    type=alias_type,
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
    "--ibazel-arg",
    action="append",
    default=[],
    dest="ibazel_args",
    metavar="IBAZEL_ARG",
    help="ibazel argument",
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

from rivetbazelutil.bazelwatchrun import watchrun
from rivetbazelutil.common import run

run.set_cwd()

watchrun.run(
    aliases=dict(args.aliases),
    bazel_args=args.bazel_args,
    ibazel_args=args.ibazel_args,
    targets=args.targets,
    width=args.width,
)
