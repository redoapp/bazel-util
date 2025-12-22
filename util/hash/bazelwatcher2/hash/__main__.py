import argparse
import codecs
import hashlib
from bazelwatcher2 import worker


def _worker(args, inputs):
    if inputs is None:
        raise RuntimeError("Must be run as worker")

    parser = argparse.ArgumentParser()
    parser.add_argument("--encoding", default="none")
    parser.add_argument("--length", default=32, type=int)
    parser.add_argument("output")
    args = parser.parse_args(args)

    hash = hashlib.sha256()
    for input in inputs:
        hash.update(input.path)
        hash.update(b"\0")
        if input.digest:
            hash.update(input.digest)
        hash.update(b"\0")
    digest = hash.digest()[: args.length]
    with open(args.output, "wb") as f:
        f.write(
            digest
            if args.encoding == "none"
            else codecs.encode(digest, encoding=args.encoding)
        )
    return worker.WorkResult(exit_code=0, output=b"")


def _worker_factory(_):
    return _worker


worker.main(_worker_factory)
