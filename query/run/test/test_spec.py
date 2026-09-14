import json
import re
import unittest

from bazelutil.query.spec import (
    MissingExclude,
    derive_query,
    parse_targets,
    render,
    select,
    sort_labels,
    tag_pattern,
    union_query,
)


def rule(name, rule_class, tags=None):
    attribute = []
    if tags is not None:
        attribute.append(
            {"name": "tags", "type": "STRING_LIST", "stringListValue": tags}
        )
    return json.dumps(
        {
            "type": "RULE",
            "rule": {"name": name, "ruleClass": rule_class, "attribute": attribute},
        }
    )


def spec(**kwargs):
    return {"kind": None, "tag": None, "exclude": [], "out": "out.bzl", **kwargs}


class TagPatternTest(unittest.TestCase):
    """The pattern the query uses and the membership test the runner uses have
    to agree, or a spec's own targets would not survive the union."""

    TAGS = [
        "unit",
        "it",
        "e2e-live",
        "congodb-collection=orders",
        "ts_gen",
        "a.b",
        "x:y",
        "A1",
    ]
    LISTS = [
        [],
        ["unit"],
        ["it"],
        ["unit", "it"],
        ["units"],
        ["preunit"],
        ["a", "unit", "b"],
        ["congodb-collection=orders", "unit"],
        ["ts_gen"],
        ["ts_gen_v2"],
        ["a.b"],
        ["axb"],
        ["x:y"],
    ]

    def test_a_present_tag_always_matches(self):
        """The load-bearing direction: the query has to return every target the
        runner will then select, or a spec would lose targets to the union."""
        for tag in self.TAGS:
            pattern = re.compile(tag_pattern(tag))
            for tags in self.LISTS:
                if tag not in tags:
                    continue
                with self.subTest(tag=tag, tags=tags):
                    self.assertTrue(pattern.search("[%s]" % ", ".join(tags)))

    def test_ordinary_tags_match_exactly(self):
        for tag in [t for t in self.TAGS if "." not in t]:
            pattern = re.compile(tag_pattern(tag))
            for tags in self.LISTS:
                rendered = "[%s]" % ", ".join(tags)
                with self.subTest(tag=tag, tags=tags):
                    self.assertEqual(bool(pattern.search(rendered)), tag in tags)

    def test_a_dot_widens_the_query_but_not_the_result(self):
        # "." is the one allowed character that is also a regex operator, so the
        # query returns more than the tag means. select() drops the extra.
        self.assertTrue(re.search(tag_pattern("a.b"), "[axb]"))
        targets = parse_targets([rule("//a:t", "ts_library", ["axb"])])
        self.assertEqual(select(spec(tag="a.b"), targets), [])


class DeriveQueryTest(unittest.TestCase):
    def test_kind_and_tag(self):
        self.assertEqual(
            derive_query(spec(kind=".*_test", tag="unit")),
            "attr('tags', '[\\[ ]unit[,\\]]', kind('.*_test', //...))",
        )

    def test_kind_only(self):
        self.assertEqual(derive_query(spec(kind="cjs_root")), "kind('cjs_root', //...)")

    def test_tag_only(self):
        self.assertEqual(
            derive_query(spec(tag="ts_gen")), "attr('tags', '[\\[ ]ts_gen[,\\]]', //...)"
        )

    def test_exclusions_stay_out_of_the_query(self):
        # They are applied to the result, so the union stays a superset.
        self.assertEqual(
            derive_query(spec(kind="ts_library", exclude=["//a:b"])),
            "kind('ts_library', //...)",
        )

    def test_union_wraps_each_query(self):
        self.assertEqual(
            union_query([spec(kind="a"), spec(tag="b")]),
            "(kind('a', //...)) + (attr('tags', '[\\[ ]b[,\\]]', //...))",
        )


class ParseTargetsTest(unittest.TestCase):
    def test_reads_kind_and_tags(self):
        targets = parse_targets([rule("//a:t", "jest_test", ["unit", "no-sandbox"])])
        self.assertEqual(targets, {"//a:t": ("jest_test rule", ["unit", "no-sandbox"])})

    def test_missing_tags_attribute(self):
        self.assertEqual(
            parse_targets([rule("//a:t", "cjs_root")]), {"//a:t": ("cjs_root rule", [])}
        )

    def test_skips_non_rules(self):
        source = json.dumps({"type": "SOURCE_FILE", "sourceFile": {"name": "//a:f.ts"}})
        self.assertEqual(parse_targets([source, ""]), {})


class SelectTest(unittest.TestCase):
    def setUp(self):
        self.targets = parse_targets(
            [
                rule("//a:unit_test", "jest_test", ["unit"]),
                rule("//b:it_test", "jest_test", ["it"]),
                rule("//c:unit_test", "vitest_test", ["unit", "no-sandbox"]),
                rule("//d:root", "cjs_root"),
                rule("//e:lib", "ts_library", ["units"]),
            ]
        )

    def test_kind_is_unanchored_like_bazel(self):
        self.assertEqual(
            sorted(select(spec(kind=".*_test"), self.targets)),
            ["//a:unit_test", "//b:it_test", "//c:unit_test"],
        )

    def test_kind_matches_the_rule_suffix(self):
        self.assertEqual(select(spec(kind="cjs_root rule"), self.targets), ["//d:root"])

    def test_tag_is_a_whole_tag_not_a_substring(self):
        # //e:lib is tagged "units", which a substring match would wrongly include.
        self.assertEqual(
            sorted(select(spec(tag="unit"), self.targets)),
            ["//a:unit_test", "//c:unit_test"],
        )

    def test_kind_and_tag_are_combined(self):
        self.assertEqual(
            select(spec(kind="^vitest", tag="unit"), self.targets), ["//c:unit_test"]
        )

    def test_exclude_removes_labels(self):
        self.assertEqual(
            select(
                spec(kind=".*_test", exclude=["//a:unit_test", "//b:it_test"]),
                self.targets,
            ),
            ["//c:unit_test"],
        )

    def test_exclude_that_removes_nothing_fails(self):
        # A renamed exclusion would otherwise rejoin the list silently.
        with self.assertRaises(MissingExclude) as caught:
            select(spec(kind=".*_test", exclude=["//a:renamed"]), self.targets)
        self.assertIn("//a:renamed", str(caught.exception))

    def test_exclude_must_match_this_spec_not_just_the_union(self):
        # //d:root is in the result, but not among this spec's own targets.
        with self.assertRaises(MissingExclude):
            select(spec(kind=".*_test", exclude=["//d:root"]), self.targets)


class RenderTest(unittest.TestCase):
    def test_orders_by_package_then_name(self):
        # Bazel sorts on the package first, so //a/b:c follows //a:z.
        self.assertEqual(
            sort_labels(["//a/b:c", "//a:z", "//a:a"]), ["//a:a", "//a:z", "//a/b:c"]
        )

    def test_renders_a_starlark_list(self):
        self.assertEqual(
            render(["//b:t", "//a:t"]), 'TARGETS = [\n    "//a:t",\n    "//b:t",\n]\n'
        )

    def test_renders_an_empty_list(self):
        self.assertEqual(render([]), "TARGETS = [\n]\n")


if __name__ == "__main__":
    unittest.main()
