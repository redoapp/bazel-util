# https://github.com/bazelbuild/bazel/blob/4948ddd514ed5b0ede57d4c2231516bbe8c4fcb4/src/main/java/com/google/devtools/build/lib/skyframe/IgnoredSubdirectoriesFunction.java#L202
def bazelignore_parse(string):
    return [
        ignore
        for ignore in string.splitlines()
        if ignore and not ignore.startswith("#")
    ]

BAZELIGNORE_PATH = ".bazelignore"

BUILD_PATH = "BUILD.bazel"

REPO_PATH = "REPO.bazel"
