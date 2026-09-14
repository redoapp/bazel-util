#!/usr/bin/env bash
set -euo pipefail

# The manifest is the whole contract between the rules and the runner.
cd "$TEST_SRCDIR/$TEST_WORKSPACE/query/test"

for name in tests_bzl batch; do
  if ! diff -u "$name.golden.json" "$name.manifest.json"; then
    echo "$name.manifest.json does not match the golden file" >&2
    exit 1
  fi
done
