echo 'Refreshing tools/test/tests.bazelrc' >&2
"$(rlocation bazel_util/tools/test/bazelrc)"

echo 'Refreshing tools/file/files.bazelrc' >&2
"$(rlocation files/packages/bazelrc)"
