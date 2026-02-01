load("@better_rules_javascript//rules:workspace.bzl", "repositories")
load("@better_rules_javascript//commonjs:workspace.bzl", "cjs_directory_npm_plugin")
load("@better_rules_javascript//npm:workspace.bzl", "npm")
load("@better_rules_javascript//typescript:workspace.bzl", "ts_directory_npm_plugin")
load("//tools:npm_data.bzl", "PACKAGES", "ROOTS")

def javascript_repositories():
    repositories()

    npm(
        "npm",
        PACKAGES,
        ROOTS,
        [
            cjs_directory_npm_plugin(),
            ts_directory_npm_plugin(),
        ],
    )
