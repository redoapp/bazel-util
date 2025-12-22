from dataclasses import dataclass
import base64
import json
import sys
import traceback
import typing


@dataclass
class WorkResult:
    exit_code: str
    output: bytes


@dataclass
class Input:
    path: bytes
    digest: typing.Optional[bytes]


def _run_once(worker, args):
    result = worker(args, None)
    sys.stderr.write(result.output)
    sys.exit(result.exit_code)


def _run_worker(worker):
    for line in sys.stdin:
        request = json.loads(line)

        arguments = request["arguments"]
        inputs = [
            Input(
                path=input["path"].encode("utf-8"),
                digest=base64.b64decode(input["digest"]) if "digest" in input else None,
            )
            for input in request["inputs"]
        ]

        try:
            result = worker(arguments, inputs)
        except Exception as e:
            result = WorkResult(
                exit_code=1, output=traceback.format_exc().encode("utf-8")
            )

        response = {
            "exit_code": result.exit_code,
            "output": result.output.decode("utf-8"),
        }
        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()


def main(worker_factory):
    last = sys.argv[-1]
    if last == "--persistent_worker":
        worker = worker_factory(sys.argv[1:-1])
        _run_worker(worker)
    elif last.startswith("@"):
        worker = worker_factory(sys.argv[1:-1])
        with open(last, "r") as f:
            args = f.read().strip().split("\n")
        _run_once(worker, args)
    else:
        worker = worker_factory(sys.argv[1])
        _run_once(worker, sys.argv[1:])
