#!/bin/sh -e
IFS=:; set -- $PATH; shift 2; PATH="$*" # Bazel adds junk
cd file/test/bazel
unset RUNFILES_DIR
unset TEST_TMPDIR
bazel info output_path
bazel build directory:example
