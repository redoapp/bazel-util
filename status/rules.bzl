def status(name, key, stamp = None):
    """
    Status file
    """

    _status_inner(
        name = name,
        key = key,
        stamp = stamp,
        stamp_setting = select({
            Label(":stamp"): True,
            "//conditions:default": False,
        }),
    )

def _stamp_inner_impl(ctx):
    actions = ctx.actions
    key = ctx.attr.key
    info_file = ctx.info_file
    name = ctx.attr.name
    stamp = ctx.attr.stamp
    stamp_setting = ctx.attr.stamp_setting
    version_file = ctx.version_file

    output = actions.declare_file("%s.txt" % name)

    if stamp == 1 or stamp == -1 and stamp_setting:
        args = actions.args()
        args.add(key)
        args.add(info_file)
        args.add(version_file)
        args.add(output)
        actions.run_shell(
            arguments = [args],
            command = 'sed -n "s/^$1 //p" "$2" "$3" | tr -d "\\n" > "$4"',
            execution_requirements = {
                "supports-path-mapping": "1",
            },
            inputs = [ctx.info_file, ctx.version_file],
            outputs = [output],
        )
    else:
        actions.write(content = "", output = output)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

_status_inner = rule(
    attrs = {
        "key": attr.string(mandatory = True),
        "stamp": attr.int(default = -1),
        "stamp_setting": attr.bool(mandatory = True),
    },
    implementation = _stamp_inner_impl,
)
