from argparse import ArgumentParser
from json import load
from os import execv
from pathlib import Path
from python.runfiles import runfiles
from sys import exit, stderr

parser = ArgumentParser(prog="service")
parser.add_argument("--manifest", type=Path)
parser.add_argument(
    "--local-manifest",
    type=Path,
    action="append",
    dest="local_manifests",
    default=[],
)
parser.add_argument("--bazel-arg", action="append", dest="bazel_args", default=[])
parser.add_argument("--ibazel-arg", action="append", dest="ibazel_args", default=[])
parser.add_argument("--width", type=int)
parser.add_argument("services", nargs="*")
args = parser.parse_args()

RUNFILES = runfiles.Create()

with args.manifest.open() as manifest_file:
    manifest = load(manifest_file)

# Shallow-merge each local manifest on top of the base. Local wins on any key,
# whether the value is a group (array) or a service target (string), and new
# keys in the local manifest extend the base.
for local_path in args.local_manifests:
    with local_path.open() as local_file:
        local_manifest = load(local_file)
    manifest.update(local_manifest)

services = {}
visited = set()


def collect_services(s):
    for service in s:
        if service in visited:
            continue
        visited.add(service)
        try:
            result = manifest[service]
        except KeyError:
            exit(f"No service {service}")
        if type(result) == str:
            services[service] = result
        elif type(result) == list:
            collect_services(result)


collect_services(args.services or ["default"])

print("Services", *services, file=stderr)

watchrun_cmd = (
    ["bazel-watchrun"]
    + [f"--bazel={arg}" for arg in args.bazel_args]
    + [f"--ibazel-arg={arg}" for arg in args.ibazel_args]
    + [f"--alias={target}={name}" for name, target in services.items()]
    + list(sorted(services.values()))
)

execv(RUNFILES.Rlocation("bazel_util/bazel/watchrun/bin"), watchrun_cmd)
