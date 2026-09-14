__package__ = "bazelutil.query"

import json
import os
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path

from .spec import (
    MissingExclude,
    parse_targets,
    render,
    render_verbatim,
    select,
    union_query,
)

parser = ArgumentParser()
parser.add_argument("--manifest", required=True)


def write_if_changed(path, content):
    if path.exists() and path.read_text() == content:
        return
    tmp = path.with_name("%s.tmp~" % path.name)
    try:
        tmp.write_text(content)
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


def query_command(specs):
    # One query for every list. Each spec then selects its own targets out of
    # the union, which gives the same answer as running its query alone.
    return [
        "bazel",
        "query",
        union_query(specs),
        "--output=streamed_jsonproto",
        "--noproto:rule_inputs_and_outputs",
        "--proto:output_rule_attrs=tags",
    ]


def run_query(specs, workspace):
    result = subprocess.run(
        query_command(specs), cwd=workspace, stdout=subprocess.PIPE, text=True
    )
    if result.returncode:
        sys.exit(result.returncode)
    return result.stdout.splitlines()


def run_raw_query(query, workspace):
    # The escape hatch runs the query as written, so its result is whatever
    # bazel query printed, in the order it printed it.
    result = subprocess.run(
        ["bazel", "query", query],
        cwd=workspace,
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode:
        sys.exit(result.returncode)
    return [line for line in result.stdout.splitlines() if line.strip()]


def main(args):
    specs = json.loads(Path(args.manifest).read_text())
    workspace = Path(os.environ.get("BUILD_WORKSPACE_DIRECTORY", os.getcwd()))

    raw = [spec for spec in specs if spec.get("query")]
    structured = [spec for spec in specs if not spec.get("query")]

    written = [
        (spec["out"], render_verbatim(run_raw_query(spec["query"], workspace)))
        for spec in raw
    ]

    if structured:
        targets = parse_targets(run_query(structured, workspace))
        try:
            written += [
                (spec["out"], render(select(spec, targets))) for spec in structured
            ]
        except MissingExclude as error:
            sys.exit("error: %s" % error)

    for out, content in written:
        write_if_changed(workspace / out, content)


if __name__ == "__main__":
    main(parser.parse_args())
