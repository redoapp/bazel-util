#!/bin/bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

set -e

if [ "${1-}" = check ]; then
    check_args="$(rlocation %{check_args})"
    if [ ! -s "$check_args" ] || "$(rlocation bazel_util/generate/run/bin)" check @"$check_args"; then
      exit
    else
      code="$?"
      echo 'To correct, run bazel run '%{label}
      exit "$code"
    fi
fi

if ! [ -z "${BUILD_WORKSPACE_DIRECTORY-}" ]; then
  cd "$BUILD_WORKSPACE_DIRECTORY"
fi

write_args="$(rlocation %{write_args})"
[ -s "$write_args" ] || exit 0
exec "$(rlocation bazel_util/generate/run/bin)" write --file-mode=%{file_mode} --dir-mode=%{dir_mode} @"$write_args"
