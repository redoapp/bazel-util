"""Both halves of what a spec means: the query that finds its targets, and the
test that recognizes them again in a result shared with other specs."""

__package__ = "bazelutil.query"

import json
import re


class MissingExclude(Exception):
    pass


def tag_pattern(tag):
    # attr() matches this against the "[a, b]" rendering of the tags list, so
    # the brackets anchor it to a whole tag rather than a substring of one.
    return "[\\[ ]%s[,\\]]" % tag


def derive_query(spec):
    """The query for a spec's targets, before its exclusions."""
    query = "//..."
    if spec.get("kind"):
        query = "kind('%s', %s)" % (spec["kind"], query)
    if spec.get("tag"):
        query = "attr('tags', '%s', %s)" % (tag_pattern(spec["tag"]), query)
    return query


def union_query(specs):
    return " + ".join(["(%s)" % derive_query(spec) for spec in specs])


def parse_targets(lines):
    """Maps each rule label from `--output=streamed_jsonproto` to its kind and tags."""
    targets = {}
    for line in lines:
        if not line.strip():
            continue
        data = json.loads(line)
        if data.get("type") != "RULE":
            continue
        rule = data["rule"]
        tags = []
        for attr in rule.get("attribute", []):
            if attr["name"] == "tags":
                tags = attr.get("stringListValue", [])
        targets[rule["name"]] = ("%s rule" % rule["ruleClass"], tags)
    return targets


def select(spec, targets):
    """The targets a spec's own query would have returned."""
    kind = re.compile(spec["kind"]) if spec.get("kind") else None
    tag = spec.get("tag")
    matched = [
        label
        for label, (rule_kind, tags) in targets.items()
        if (kind is None or kind.search(rule_kind)) and (tag is None or tag in tags)
    ]

    exclude = spec.get("exclude") or []
    missing = [label for label in exclude if label not in matched]
    if missing:
        raise MissingExclude(
            "%s excludes %s, which %s does not return"
            % (spec["out"], ", ".join(missing), derive_query(spec))
        )
    return [label for label in matched if label not in exclude]


def sort_labels(labels):
    # Bazel orders labels by package, then by name.
    def key(label):
        package, _, name = label[len("//") :].partition(":")
        return package, name

    return sorted(labels, key=key)


def render_verbatim(lines):
    """The escape hatch's result, in the order bazel query returned it."""
    return "TARGETS = [\n" + "".join(['    "%s",\n' % line for line in lines]) + "]\n"


def render(labels):
    return (
        "TARGETS = [\n"
        + "".join(['    "%s",\n' % label for label in sort_labels(labels)])
        + "]\n"
    )
