load(%{generate_rules}, "generate_test")
load(%{rules}, "ignore_directories_manifest")

ignore_directories_manifest(
    name = "gen",
    manifest = %{ignore_directories_manifest},
    repo = %{repo},
    visibility = ["//visibility:public"],
)

generate_test(
    name = "gen_test",
    generate = ":ignore_directories",
    visibility = ["//visibility:public"],
)
