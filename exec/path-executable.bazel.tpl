load("@bazel_util//exec:rules.bzl", "executable_path", "executable_toolchain")

package(default_visibility = ["//visibility:public"])

executable_path(
    name = "executable",
    # compatible_with = [":exists"],
    path = %{path},
)

executable_toolchain(
    name = "executable_toolchain",
    executable = ":executable",
)

constraint_setting(
  name = "existance",
  default_constraint_value = %{existance},
)

constraint_value(
  name = "exists",
  constraint_setting = ":existance",
)

constraint_value(
  name = "not_exists",
  constraint_setting = ":existance",
)
