from argparse import ArgumentParser
from pathlib import Path
from shutil import copy, copytree

parser = ArgumentParser(fromfile_prefix_chars="@", prog="directory")
parser.add_argument("files", type=Path, nargs="*")
args = parser.parse_args()

for i in range(0, len(args.files), 2):
    input = args.files[i]
    output = args.files[i + 1]
    output.parent.mkdir(parents=True, exist_ok=True)
    if input.is_dir():
        copytree(input, output, copy_function=copy)
    else:
        copy(input, output)
