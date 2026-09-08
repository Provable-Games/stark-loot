#!/usr/bin/env python3
"""Measure complete release classes and caller artifacts; compile each caller CASM twice."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def leaves(value):
    if isinstance(value, int):
        return [value]
    return [leaf for child in value for leaf in leaves(child)]


def measure(sierra_path, casm_path):
    sierra = json.loads(sierra_path.read_text())
    casm = json.loads(casm_path.read_text())
    return {
        "casm_words": len(casm["bytecode"]),
        "sierra_words": len(sierra["sierra_program"]),
        "largest_segment": max(leaves(casm["bytecode_segment_lengths"])),
        "entrypoints": {k: len(v) for k, v in casm["entry_points_by_type"].items()},
        "casm_sha256": sha(casm_path),
        "sierra_sha256": sha(sierra_path),
        "casm_path": str(casm_path.relative_to(ROOT)),
        "sierra_path": str(sierra_path.relative_to(ROOT)),
    }


def main():
    compiler = Path(shutil.which("universal-sierra-compiler"))
    output = ROOT / "target/cache-artifacts"
    output.mkdir(parents=True, exist_ok=True)
    result = {
        "source_revision": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip(),
        "compiler": subprocess.check_output(
            [str(compiler), "--version"], text=True
        ).strip(),
        "compiler_sha256": sha(compiler),
        "classes": {},
        "source_sha256": {
            str(p.relative_to(ROOT)): sha(p)
            for p in sorted(
                [
                    *ROOT.glob("src/*.cairo"),
                    *ROOT.glob("tests/cache*.cairo"),
                    *ROOT.glob("scripts/*cache*.py"),
                    ROOT / "Scarb.toml",
                    ROOT / "Scarb.lock",
                    ROOT / ".tool-versions",
                ]
            )
        },
    }
    for name in ["stark_loot", "stark_loot_cache"]:
        prefix = ROOT / "target/release" / f"stark_loot_{name}"
        result["classes"][name] = measure(
            Path(str(prefix) + ".contract_class.json"),
            Path(str(prefix) + ".compiled_contract_class.json"),
        )
    cases = json.loads((ROOT / "scripts/cache_probe_cases.json").read_text())
    names = sorted(
        {spec["contract"] for spec in cases.values()}
        | {"stark_loot", "stark_loot_cache"}
    )
    for name in names:
        sierra = (
            ROOT
            / "target/release"
            / f"stark_loot_tests_{name}.test.contract_class.json"
        )
        artifacts = []
        for repetition in [1, 2]:
            casm = output / f"{name}.{repetition}.casm.json"
            subprocess.run(
                [
                    str(compiler),
                    "compile-contract",
                    "--sierra-path",
                    str(sierra),
                    "--output-path",
                    str(casm),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            artifacts.append(casm)
        assert artifacts[0].read_bytes() == artifacts[1].read_bytes(), name
        measured = measure(sierra, artifacts[0])
        if name in ["stark_loot", "stark_loot_cache"]:
            # Foundry's benchmark must execute the complete production bytecode.
            production = (
                ROOT
                / "target/release"
                / f"stark_loot_{name}.compiled_contract_class.json"
            )
            prod = json.loads(production.read_text())
            test = json.loads(artifacts[0].read_text())
            for field in [
                "bytecode",
                "bytecode_segment_lengths",
                "entry_points_by_type",
                "hints",
            ]:
                assert prod[field] == test[field], (name, field)
            result["classes"][name]["test_artifact_matches_production"] = True
        else:
            result["classes"][name] = measured
    (output / "sizes.json").write_text(json.dumps(result, indent=2) + "\n")
    for name in [
        "stark_loot",
        "stark_loot_cache",
        "CacheReusePackedProbe",
        "CacheReuseSelectedProbe",
        "CacheReuseExpandedProbe",
    ]:
        print(name, result["classes"][name])


if __name__ == "__main__":
    main()
