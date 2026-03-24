load("@bazel_skylib//lib:shell.bzl", "shell")
load("//generate:providers.bzl", "FormatterInfo")

def _jsonschema_toolchain_impl(ctx):
    bin = ctx.file.bin

    toolchain_info = platform_common.ToolchainInfo(
        bin = bin,
    )

    return [toolchain_info]

jsonschema_toolchain = rule(
    attrs = {
        "bin": attr.label(
            allow_single_file = True,
            doc = "Executable",
        ),
    },
    doc = "jsonschema toolchain",
    implementation = _jsonschema_toolchain_impl,
    provides = [platform_common.ToolchainInfo],
)

# https://github.com/sourcemeta/jsonschema/blob/main/docs/validate.markdown
def _jsonschema_format(ctx, src, out, bin, schema, compiled, options):
    args = ctx.actions.args()
    args.add(bin)
    args.add(schema)
    args.add_all([src], expand_directories = False)
    args.add(compiled)
    args.add_all([out], expand_directories = False)
    options_sh = [shell.quote(option) for option in options]
    ctx.actions.run_shell(
        arguments = [args],
        command = '"$1" validate "$2" "$3" --template="$4" %s && cp -r "$3" "$5"' % " ".join(options_sh),
        execution_requirements = {
            "supports-path-mapping": "1",
        },
        inputs = [bin, schema, src, compiled],
        outputs = [out],
    )

def _jsonschema_validator_impl(ctx):
    actions = ctx.actions
    toolchain = ctx.toolchains[":toolchain_type"]
    bin = toolchain.bin
    name = ctx.attr.name
    schema = ctx.file.schema
    options = ctx.attr.options

    compiled = actions.declare_file("%s.template.json" % name)

    args = actions.args()
    args.add(bin)
    args.add(schema)
    args.add(compiled)
    actions.run_shell(
        command = '"$1" compile -m "$2" > "$3"',
        execution_requirements = {
            "supports-path-mapping": "1",
        },
        arguments = [args],
        inputs = [bin, schema],
        outputs = [compiled],
    )

    def format(ctx, path, src, out):
        _jsonschema_format(ctx, src, out, bin, schema, compiled, options)

    format_info = FormatterInfo(fn = format)

    return [format_info]

# This uses FormatterInfo, even though it doesn't actually format.
jsonschema_validator = rule(
    attrs = {
        "options": attr.string_list(
            doc = "Command-line options",
        ),
        "schema": attr.label(
            allow_single_file = [".json", ".yaml", ".yml"],
            doc = "JSON schema",
            mandatory = True,
        ),
    },
    implementation = _jsonschema_validator_impl,
    provides = [FormatterInfo],
    toolchains = [":toolchain_type"],
)
