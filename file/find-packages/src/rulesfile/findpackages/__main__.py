__package__ = "rulesfile.findpackages"

from argparse import ArgumentParser
from pathlib import Path

parser = ArgumentParser(prog="find-packages")
parser.add_argument("root", type=Path)
parser.add_argument("roots", nargs="*")
parser.add_argument("--prefix", default="")
parser.add_argument("--exclude", action="append", default=[])
args = parser.parse_args()

from .find_packages import find_packages

find_packages(root=args.root, roots=args.roots, prefix=args.prefix, excludes=args.exclude)
