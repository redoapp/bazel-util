from python.runfiles import runfiles
from shutil import copyfileobj
from sys import exit, stdout

r = runfiles.Create()


def main(args):
    print("Differences detected")
    for diff in args.diffs:
        diff = r.Rlocation(diff)
        with open(diff, "r") as f:
            copyfileobj(f, stdout)
            print()
    exit(1)
