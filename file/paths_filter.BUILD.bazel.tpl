load("%{file_rules}", "paths_filter")
load(":files.bzl", "FILES")

paths_filter(
    name = "filter",
    paths = FILES,
    visibility = ["//visibility:public"],
)
