QueryBzlInfo = provider(
    doc = "Specification of a generated Starlark target list",
    fields = {
        "exclude": "Absolute labels to subtract from the result",
        "kind": "Rule kind pattern, or None",
        "out": "Workspace-relative output path",
        "query": "Raw query string, or None. Set only by the escape hatch; cannot be batched.",
        "tag": "Required tag, or None",
    },
)
