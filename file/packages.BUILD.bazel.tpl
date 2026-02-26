load(%{rules}, "bazelrc_deleted_packages", "find_packages")

find_packages(
    name = "packages",
    exclude_directories = %{exclude_directories},
    prefix = repository_name() + "//files",
    visibility = ["//visibility:public"],
)

bazelrc_deleted_packages(
    name = "bazelrc",
    output = "/%s" % %{bazelrc},
    packages = [":packages"],
    visibility = ["//visibility:public"],
)
