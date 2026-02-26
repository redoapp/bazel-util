from argparse import ArgumentParser
from sys import stdin

parser = ArgumentParser(prog="deleted-packages")
parser.add_argument("--config")
args = parser.parse_args()

packages = [line.rstrip() for line in stdin]

for command in ["build", "query"]:
    if args.config:
        command = f"{args.config}:{command}"
    for package in packages:
        print(command, f"--deleted_packages={package}")
