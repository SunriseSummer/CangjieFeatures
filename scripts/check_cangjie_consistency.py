from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

try:
    import yaml
except ModuleNotFoundError:
    print(
        "Missing dependency: PyYAML. Install with `python -m pip install -r requirements.txt`.",
        file=sys.stderr,
    )
    raise SystemExit(2)


@dataclass(frozen=True)
class Finding:
    severity: str
    file: str
    path: str
    message: str

    def render(self) -> str:
        return f"{self.severity.upper():7} {self.file}:{self.path} - {self.message}"


class ConsistencyChecker:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.docs: dict[str, Any] = {}
        self.findings: list[Finding] = []

    def run(self) -> int:
        self._load_documents()
        if self.error_count:
            self._print_findings()
            return 1

        self._check_index()
        self._check_types_language_alignment()
        self._check_constructs()
        self._check_learning()
        self._check_rules()
        self._check_coverage()

        self._print_findings()
        return 1 if self.error_count else 0

    @property
    def error_count(self) -> int:
        return sum(1 for finding in self.findings if finding.severity == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for finding in self.findings if finding.severity == "warning")

    def _add(self, severity: str, file: str, path: str, message: str) -> None:
        self.findings.append(Finding(severity, file, path, message))

    def _error(self, file: str, path: str, message: str) -> None:
        self._add("error", file, path, message)

    def _warning(self, file: str, path: str, message: str) -> None:
        self._add("warning", file, path, message)

    def _info(self, file: str, path: str, message: str) -> None:
        self._add("info", file, path, message)

    def _load_documents(self) -> None:
        expected = {
            "index.yaml",
            "language.yaml",
            "lexer.yaml",
            "types.yaml",
            "constructs.yaml",
            "rules.yaml",
            "learning.yaml",
        }
        found = {path.name for path in self.root.glob("*.yaml")}
        missing = sorted(expected - found)
        extra = sorted(found - expected)
        for name in missing:
            self._error("<workspace>", str(self.root), f"Missing expected YAML file: {name}")
        for name in extra:
            self._warning("<workspace>", str(self.root), f"Unexpected YAML file not referenced by checker: {name}")

        for name in sorted(found):
            file_path = self.root / name
            try:
                self.docs[name] = yaml.safe_load(file_path.read_text(encoding="utf-8"))
            except yaml.YAMLError as exc:
                self._error(name, "$", f"YAML parse error: {exc}")

    def _doc(self, file_name: str) -> Any:
        return self.docs[file_name]

    def _require_mapping(self, value: Any, file: str, path: str) -> dict[str, Any]:
        if not isinstance(value, dict):
            self._error(file, path, f"Expected mapping, got {type(value).__name__}")
            return {}
        return value

    def _require_list(self, value: Any, file: str, path: str) -> list[Any]:
        if not isinstance(value, list):
            self._error(file, path, f"Expected list, got {type(value).__name__}")
            return []
        return value

    def _collect_id_map(
        self,
        items: Iterable[Any],
        file: str,
        path: str,
        *,
        id_key: str = "id",
    ) -> dict[str, dict[str, Any]]:
        result: dict[str, dict[str, Any]] = {}
        for index, item in enumerate(items):
            current_path = f"{path}[{index}]"
            if not isinstance(item, dict):
                self._error(file, current_path, f"Expected mapping item, got {type(item).__name__}")
                continue
            raw_id = item.get(id_key)
            if not isinstance(raw_id, str) or not raw_id:
                self._error(file, current_path, f"Missing or invalid `{id_key}`")
                continue
            if raw_id in result:
                self._error(file, current_path, f"Duplicate id `{raw_id}`")
                continue
            result[raw_id] = item
        return result

    def _check_same_set(
        self,
        *,
        file: str,
        path: str,
        actual: Iterable[str],
        expected: Iterable[str],
        noun: str,
    ) -> None:
        actual_set = set(actual)
        expected_set = set(expected)
        missing = sorted(expected_set - actual_set)
        extra = sorted(actual_set - expected_set)
        if missing:
            self._error(file, path, f"Missing {noun}: {', '.join(missing)}")
        if extra:
            self._error(file, path, f"Unknown {noun}: {', '.join(extra)}")

    def _resolve_pointer(self, file_name: str, pointer: str) -> Any:
        current = self.docs.get(file_name)
        if current is None:
            raise KeyError(file_name)
        if not pointer.startswith("#/"):
            raise KeyError(pointer)
        parts = [part.replace("~1", "/").replace("~0", "~") for part in pointer[2:].split("/")]
        for part in parts:
            if isinstance(current, dict):
                current = current[part]
            elif isinstance(current, list):
                current = current[int(part)]
            else:
                raise KeyError(pointer)
        return current

    def _extract_base_name(self, value: Any) -> str | None:
        if not isinstance(value, str) or not value:
            return None
        base = value.split("<", 1)[0].strip()
        return base or None

    def _check_index(self) -> None:
        index = self._require_mapping(self._doc("index.yaml"), "index.yaml", "$")
        language = self._require_mapping(self._doc("language.yaml"), "language.yaml", "$")
        language_root = self._require_mapping(language.get("language"), "language.yaml", "language")

        index_language = self._require_mapping(index.get("language"), "index.yaml", "language")
        if index_language.get("version") != language_root.get("version"):
            self._error(
                "index.yaml",
                "language.version",
                "Version does not match language.yaml language.version",
            )

        schema = self._require_mapping(index.get("schema"), "index.yaml", "schema")
        if schema.get("version") != language_root.get("spec_version"):
            self._error(
                "index.yaml",
                "schema.version",
                "Schema version does not match language.yaml spec_version",
            )

        imports = self._require_list(index.get("imports"), "index.yaml", "imports")
        import_names = [item for item in imports if isinstance(item, str)]
        self._check_same_set(
            file="index.yaml",
            path="imports",
            actual=import_names,
            expected=[name for name in self.docs if name != "index.yaml"],
            noun="imported YAML files",
        )

        loading_order = self._require_list(index.get("loading_order"), "index.yaml", "loading_order")
        expected_loading_order = [Path(name).stem for name in import_names]
        if loading_order != expected_loading_order:
            self._error(
                "index.yaml",
                "loading_order",
                f"Expected loading_order {expected_loading_order}, got {loading_order}",
            )

        resolution = self._require_mapping(index.get("resolution"), "index.yaml", "resolution")
        for key, value in resolution.items():
            if not isinstance(value, str) or "#" not in value:
                self._error("index.yaml", f"resolution.{key}", "Resolution value must be file#/json/pointer")
                continue
            file_name, pointer = value.split("#", 1)
            file_name = file_name.strip()
            pointer = f"#{pointer}"
            if file_name not in self.docs:
                self._error("index.yaml", f"resolution.{key}", f"Unknown resolution file `{file_name}`")
                continue
            try:
                self._resolve_pointer(file_name, pointer)
            except Exception:
                self._error(
                    "index.yaml",
                    f"resolution.{key}",
                    f"Could not resolve pointer `{file_name}{pointer}`",
                )

    def _check_types_language_alignment(self) -> None:
        language_doc = self._require_mapping(self._doc("language.yaml"), "language.yaml", "$")
        language = self._require_mapping(language_doc.get("language"), "language.yaml", "language")
        symbol_catalog = self._require_mapping(language_doc.get("symbol_catalog"), "language.yaml", "symbol_catalog")
        types_doc = self._require_mapping(self._doc("types.yaml"), "types.yaml", "$")
        types = self._require_list(types_doc.get("types"), "types.yaml", "types")
        rules_doc = self._require_mapping(self._doc("rules.yaml"), "rules.yaml", "$")
        diagnostics = self._require_list(rules_doc.get("diagnostics"), "rules.yaml", "diagnostics")
        constructs_doc = self._require_mapping(self._doc("constructs.yaml"), "constructs.yaml", "$")
        constructs = self._require_list(constructs_doc.get("constructs"), "constructs.yaml", "constructs")

        type_map = self._collect_id_map(types, "types.yaml", "types")
        diagnostic_map = self._collect_id_map(diagnostics, "rules.yaml", "diagnostics")
        construct_map = self._collect_id_map(constructs, "constructs.yaml", "constructs")
        interface_ids = sorted(type_id for type_id, item in type_map.items() if item.get("kind") == "interface")
        concrete_type_ids = sorted(
            type_id
            for type_id, item in type_map.items()
            if item.get("kind") != "interface" or type_id == "Any"
        )

        catalog_types = self._require_list(symbol_catalog.get("types"), "language.yaml", "symbol_catalog.types")
        catalog_interfaces = self._require_list(symbol_catalog.get("interfaces"), "language.yaml", "symbol_catalog.interfaces")
        catalog_constructs = self._require_list(symbol_catalog.get("constructs"), "language.yaml", "symbol_catalog.constructs")
        catalog_diagnostics = self._require_list(symbol_catalog.get("diagnostics"), "language.yaml", "symbol_catalog.diagnostics")
        nonterminals = self._require_list(symbol_catalog.get("nonterminals"), "language.yaml", "symbol_catalog.nonterminals")
        learning_order = self._require_list(language_doc.get("learning_order"), "language.yaml", "learning_order")

        self._check_same_set(
            file="language.yaml",
            path="symbol_catalog.types",
            actual=[item for item in catalog_types if isinstance(item, str)],
            expected=concrete_type_ids,
            noun="type ids",
        )
        self._check_same_set(
            file="language.yaml",
            path="symbol_catalog.interfaces",
            actual=[item for item in catalog_interfaces if isinstance(item, str)],
            expected=interface_ids,
            noun="interface ids",
        )
        self._check_same_set(
            file="language.yaml",
            path="symbol_catalog.constructs",
            actual=[item for item in catalog_constructs if isinstance(item, str)],
            expected=construct_map.keys(),
            noun="construct ids",
        )
        self._check_same_set(
            file="language.yaml",
            path="symbol_catalog.diagnostics",
            actual=[item for item in catalog_diagnostics if isinstance(item, str)],
            expected=diagnostic_map.keys(),
            noun="diagnostic ids",
        )
        self._check_same_set(
            file="language.yaml",
            path="learning_order",
            actual=[item for item in learning_order if isinstance(item, str)],
            expected=construct_map.keys(),
            noun="construct ids in learning order",
        )

        nonterminal_set = {item for item in nonterminals if isinstance(item, str)}
        known_ref_bases = set(type_map) | set(interface_ids) | nonterminal_set | set(construct_map) | {"none"}
        for type_id, item in type_map.items():
            implements = self._require_list(item.get("implements", []), "types.yaml", f"types.{type_id}.implements")
            for index, entry in enumerate(implements):
                base_name = self._extract_base_name(entry)
                if base_name and base_name not in known_ref_bases:
                    self._error(
                        "types.yaml",
                        f"types.{type_id}.implements[{index}]",
                        f"Unknown implemented interface or type `{base_name}`",
                    )
            for param_index, param in enumerate(self._require_list(item.get("parameters", []), "types.yaml", f"types.{type_id}.parameters")):
                if not isinstance(param, dict):
                    continue
                constraints = self._require_list(
                    param.get("constraints", []),
                    "types.yaml",
                    f"types.{type_id}.parameters[{param_index}].constraints",
                )
                for constraint_index, constraint in enumerate(constraints):
                    base_name = self._extract_base_name(constraint)
                    if base_name and base_name not in known_ref_bases:
                        self._error(
                            "types.yaml",
                            f"types.{type_id}.parameters[{param_index}].constraints[{constraint_index}]",
                            f"Unknown constraint base `{base_name}`",
                        )

    def _check_constructs(self) -> None:
        constructs_doc = self._require_mapping(self._doc("constructs.yaml"), "constructs.yaml", "$")
        constructs = self._require_list(constructs_doc.get("constructs"), "constructs.yaml", "constructs")
        language_doc = self._require_mapping(self._doc("language.yaml"), "language.yaml", "$")
        symbol_catalog = self._require_mapping(language_doc.get("symbol_catalog"), "language.yaml", "symbol_catalog")
        diagnostics_doc = self._require_mapping(self._doc("rules.yaml"), "rules.yaml", "$")
        diagnostics = self._require_list(diagnostics_doc.get("diagnostics"), "rules.yaml", "diagnostics")

        construct_map = self._collect_id_map(constructs, "constructs.yaml", "constructs")
        construct_ids = set(construct_map)
        nonterminal_ids = {
            item for item in self._require_list(symbol_catalog.get("nonterminals"), "language.yaml", "symbol_catalog.nonterminals")
            if isinstance(item, str)
        }
        diagnostic_ids = set(self._collect_id_map(diagnostics, "rules.yaml", "diagnostics"))

        for construct_id, construct in construct_map.items():
            prerequisites = self._require_list(
                construct.get("prerequisites", []),
                "constructs.yaml",
                f"constructs.{construct_id}.prerequisites",
            )
            for index, ref in enumerate(prerequisites):
                if not isinstance(ref, str):
                    self._error(
                        "constructs.yaml",
                        f"constructs.{construct_id}.prerequisites[{index}]",
                        "Prerequisite must be a string",
                    )
                    continue
                if ref not in construct_ids and ref not in nonterminal_ids:
                    self._error(
                        "constructs.yaml",
                        f"constructs.{construct_id}.prerequisites[{index}]",
                        f"Unknown prerequisite reference `{ref}`",
                    )

            syntax = self._require_mapping(
                construct.get("syntax", {}),
                "constructs.yaml",
                f"constructs.{construct_id}.syntax",
            )
            slots = self._require_list(
                syntax.get("slots", []),
                "constructs.yaml",
                f"constructs.{construct_id}.syntax.slots",
            )
            for index, slot in enumerate(slots):
                if not isinstance(slot, dict):
                    self._error(
                        "constructs.yaml",
                        f"constructs.{construct_id}.syntax.slots[{index}]",
                        "Slot must be a mapping",
                    )
                    continue
                ref = slot.get("ref")
                if isinstance(ref, str) and ref not in nonterminal_ids:
                    self._error(
                        "constructs.yaml",
                        f"constructs.{construct_id}.syntax.slots[{index}].ref",
                        f"Unknown nonterminal reference `{ref}`",
                    )

            semantic_rules = self._require_list(
                construct.get("semantic_rules", []),
                "constructs.yaml",
                f"constructs.{construct_id}.semantic_rules",
            )
            rule_map = self._collect_id_map(
                semantic_rules,
                "constructs.yaml",
                f"constructs.{construct_id}.semantic_rules",
            )
            for rule_id, rule in rule_map.items():
                diagnostic = rule.get("diagnostic")
                if isinstance(diagnostic, str) and diagnostic not in diagnostic_ids:
                    self._error(
                        "constructs.yaml",
                        f"constructs.{construct_id}.semantic_rules.{rule_id}.diagnostic",
                        f"Unknown diagnostic `{diagnostic}`",
                    )

    def _check_learning(self) -> None:
        learning_doc = self._require_mapping(self._doc("learning.yaml"), "learning.yaml", "$")
        learning = self._require_mapping(learning_doc.get("learning"), "learning.yaml", "learning")
        constructs_doc = self._require_mapping(self._doc("constructs.yaml"), "constructs.yaml", "$")
        rules_doc = self._require_mapping(self._doc("rules.yaml"), "rules.yaml", "$")
        construct_map = self._collect_id_map(
            self._require_list(constructs_doc.get("constructs"), "constructs.yaml", "constructs"),
            "constructs.yaml",
            "constructs",
        )
        diagnostic_map = self._collect_id_map(
            self._require_list(rules_doc.get("diagnostics"), "rules.yaml", "diagnostics"),
            "rules.yaml",
            "diagnostics",
        )
        construct_ids = set(construct_map)
        diagnostic_ids = set(diagnostic_map)

        curriculum = self._require_list(learning.get("curriculum"), "learning.yaml", "learning.curriculum")
        curriculum_topics: list[str] = []
        for index, step in enumerate(curriculum):
            if not isinstance(step, dict):
                self._error("learning.yaml", f"learning.curriculum[{index}]", "Curriculum step must be a mapping")
                continue
            topic = step.get("topic")
            if not isinstance(topic, str):
                self._error("learning.yaml", f"learning.curriculum[{index}].topic", "Curriculum topic must be a string")
                continue
            curriculum_topics.append(topic)
        self._check_same_set(
            file="learning.yaml",
            path="learning.curriculum[*].topic",
            actual=curriculum_topics,
            expected=construct_ids,
            noun="construct topics",
        )

        example_collections = [
            ("canonical_examples", "construct", None),
            ("counterexamples", "construct", "expected_diagnostic"),
            ("idioms", None, None),
        ]
        all_example_constructs: set[str] = set()
        for section_name, construct_key, diagnostic_key in example_collections:
            items = self._require_list(learning.get(section_name), "learning.yaml", f"learning.{section_name}")
            item_map = self._collect_id_map(items, "learning.yaml", f"learning.{section_name}")
            for item_id, item in item_map.items():
                if construct_key is not None:
                    construct_id = item.get(construct_key)
                    if not isinstance(construct_id, str) or construct_id not in construct_ids:
                        self._error(
                            "learning.yaml",
                            f"learning.{section_name}.{item_id}.{construct_key}",
                            f"Unknown construct `{construct_id}`",
                        )
                    else:
                        all_example_constructs.add(construct_id)
                if diagnostic_key is not None:
                    diagnostic_id = item.get(diagnostic_key)
                    if not isinstance(diagnostic_id, str) or diagnostic_id not in diagnostic_ids:
                        self._error(
                            "learning.yaml",
                            f"learning.{section_name}.{item_id}.{diagnostic_key}",
                            f"Unknown diagnostic `{diagnostic_id}`",
                        )
                requires = self._require_list(
                    item.get("requires", []),
                    "learning.yaml",
                    f"learning.{section_name}.{item_id}.requires",
                )
                for index, ref in enumerate(requires):
                    if isinstance(ref, str) and ref not in construct_ids:
                        self._error(
                            "learning.yaml",
                            f"learning.{section_name}.{item_id}.requires[{index}]",
                            f"Unknown required construct `{ref}`",
                        )

        uncovered = sorted(construct_ids - all_example_constructs)
        if uncovered:
            self._info(
                "learning.yaml",
                "learning.coverage",
                f"No canonical/counterexample coverage for constructs: {', '.join(uncovered)}",
            )

    def _check_rules(self) -> None:
        rules_doc = self._require_mapping(self._doc("rules.yaml"), "rules.yaml", "$")
        semantic_rules = self._require_mapping(rules_doc.get("semantic_rules"), "rules.yaml", "semantic_rules")
        global_rules = self._require_list(semantic_rules.get("global"), "rules.yaml", "semantic_rules.global")
        diagnostics = self._require_list(rules_doc.get("diagnostics"), "rules.yaml", "diagnostics")
        diagnostic_ids = set(self._collect_id_map(diagnostics, "rules.yaml", "diagnostics"))
        global_map = self._collect_id_map(global_rules, "rules.yaml", "semantic_rules.global")
        self._collect_id_map(
            self._require_list(rules_doc.get("lint_rules"), "rules.yaml", "lint_rules"),
            "rules.yaml",
            "lint_rules",
        )

        for rule_id, rule in global_map.items():
            diagnostic = rule.get("diagnostic")
            if isinstance(diagnostic, str) and diagnostic not in diagnostic_ids:
                self._error(
                    "rules.yaml",
                    f"semantic_rules.global.{rule_id}.diagnostic",
                    f"Unknown diagnostic `{diagnostic}`",
                )

    def _check_coverage(self) -> None:
        learning_doc = self._require_mapping(self._doc("learning.yaml"), "learning.yaml", "$")
        learning = self._require_mapping(learning_doc.get("learning"), "learning.yaml", "learning")
        rules_doc = self._require_mapping(self._doc("rules.yaml"), "rules.yaml", "$")
        diagnostics = self._require_list(rules_doc.get("diagnostics"), "rules.yaml", "diagnostics")
        diagnostic_ids = set(self._collect_id_map(diagnostics, "rules.yaml", "diagnostics"))
        counterexamples = self._require_list(learning.get("counterexamples"), "learning.yaml", "learning.counterexamples")
        covered = {
            item.get("expected_diagnostic")
            for item in counterexamples
            if isinstance(item, dict) and isinstance(item.get("expected_diagnostic"), str)
        }
        uncovered = sorted(diagnostic_ids - covered)
        if uncovered:
            self._info(
                "rules.yaml",
                "diagnostics",
                f"Diagnostics without learning counterexamples: {', '.join(uncovered)}",
            )

    def _print_findings(self) -> None:
        ordered = sorted(
            self.findings,
            key=lambda finding: (
                {"error": 0, "warning": 1, "info": 2}.get(finding.severity, 3),
                finding.file,
                finding.path,
                finding.message,
            ),
        )
        for finding in ordered:
            print(finding.render())
        print(
            f"Summary: {self.error_count} error(s), {self.warning_count} warning(s), {len(self.findings) - self.error_count - self.warning_count} info message(s)."
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check cross-file consistency of the cangjie YAML spec.")
    parser.add_argument(
        "root",
        nargs="?",
        default="cangjie",
        help="Directory containing index.yaml, language.yaml, lexer.yaml, types.yaml, constructs.yaml, rules.yaml, and learning.yaml.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    if not root.exists() or not root.is_dir():
        print(f"Invalid root directory: {root}", file=sys.stderr)
        return 2
    checker = ConsistencyChecker(root)
    return checker.run()


if __name__ == "__main__":
    raise SystemExit(main())