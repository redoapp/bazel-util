from argparse import ArgumentParser
from fnmatch import fnmatch
from tarfile import open as tarfile_open

parser = ArgumentParser(prog="tar-filter")
parser.add_argument("--compression", choices=["gz"])
parser.add_argument("--exclude", action="append", default=[])
parser.add_argument("src")
parser.add_argument("dst")
args = parser.parse_args()

with tarfile_open(args.src, f"r:{args.compression}") as tar_in, tarfile_open(
    args.dst, f"w:{args.compression}"
) as tar_out:
    for member in tar_in.getmembers():
        if any(fnmatch(member.name, exclude) for exclude in args.exclude):
            continue
        tar_out.addfile(tarinfo=member, fileobj=tar_in.extractfile(member))
