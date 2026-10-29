"""Audit legacy mod data and produce minimal, separate name/event repairs.

The supplied archive remains the reference. Repairs go to NEW output files;
the input is never edited. No commercial game assets are checked into Git.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def words(data):
    return struct.unpack(f"<{len(data) // 2}h", data)


def text(data):
    return data.split(b"\0", 1)[0].decode("cp950")


def audit(mod: Path):
    grp = (mod / "save/ranger.grp").read_bytes()
    idx = struct.unpack("<6i", (mod / "save/ranger.idx").read_bytes())
    counts = dict(zip(("roles", "items", "scenes", "magic", "shops"),
                      ((idx[i+1] - idx[i]) // stride for i, stride in enumerate((182, 190, 52, 136, 30)))))
    item_names = [text(grp[idx[1]+i*190+2:idx[1]+i*190+22]) for i in range(counts["items"])]
    name_defects = [{"item": i, "name": n, "replacement": n.replace("\r", "").replace("\n", "").replace("\t", ""),
                     "offset": idx[1]+i*190+2, "original_hex": grp[idx[1]+i*190+2:idx[1]+i*190+22].hex()}
                    for i, n in enumerate(item_names) if any(c in n for c in "\r\n\t")]
    widths = list(map(int, re.search(r"EventWidths\s*=\s*\{([^}]+)",
                      (Path(__file__).resolve().parents[1] / "bin-c/kys_script.h").read_text()).group(1).split(",")))
    kidx_data = (mod / "resource/kdef.idx").read_bytes()
    kidx = struct.unpack(f"<{len(kidx_data)//4}i", kidx_data)
    kdef = (mod / "resource/kdef.grp").read_bytes()
    talk_count = (mod / "resource/talk.idx").stat().st_size // 4
    battle_count = (mod / "resource/war.sta").stat().st_size // 186
    issues, branches, references, scripts = [], [], [], []
    opcode_counts = Counter()
    jumps = {4:(2,3),5:(1,2),6:(2,3),9:(1,2),11:(1,2),16:(2,3),18:(2,3),20:(1,2),
             28:(4,5),29:(4,5),31:(2,3),36:(2,3),42:(1,2),43:(2,3),55:(3,4),60:(4,5),61:(1,2)}
    previous = 0
    for script, end in enumerate(kidx):
        if not previous <= end <= len(kdef) or (end-previous) % 2:
            issues.append({"script": script, "reason": "invalid byte range"})
            previous = end
            continue
        data = words(kdef[previous:end]); previous = end
        instructions = []; boundaries = set(); pc = 0
        while pc < len(data):
            opcode = data[pc]
            boundaries.add(pc)
            if opcode < 0:
                # A branch can jump over a terminator into another block in the
                # same record (Dragon event 280 does this for a full party).
                instructions.append({"pc": pc, "opcode": opcode, "args": ()})
                pc += 1
                continue
            if opcode >= len(widths) or pc+widths[opcode] > len(data):
                issues.append({"script": script, "pc": pc, "opcode": opcode, "reason": "unknown/truncated opcode"})
                break
            width = widths[opcode]; args = data[pc+1:pc+width]
            instructions.append({"pc": pc, "opcode": opcode, "args": args})
            opcode_counts[opcode] += 1
            kind, value = None, None
            if opcode in (2,4,18,32,43): kind, value = "item", args[0]
            elif opcode == 41: kind, value = "item", args[1]
            elif opcode == 1: kind, value = "talk", args[0]
            elif opcode == 6: kind, value = "battle", args[0]
            elif opcode == 10: kind, value = "role", args[0]
            if kind:
                ref = {"script": script, "pc": pc, "kind": kind, "id": value, "opcode": opcode}
                if kind == "item" and 0 <= value < len(item_names):
                    ref["name"] = item_names[value]
                references.append(ref)
                limit = {"item": counts["items"], "role": counts["roles"], "talk": talk_count, "battle": battle_count}[kind]
                if not 0 <= value < limit:
                    issues.append({**ref, "reason": "reference out of bounds"})
            for arg in jumps.get(opcode, ()):
                branches.append({"script": script, "pc": pc, "target": pc+width+data[pc+arg]})
            pc += width
        boundaries.add(len(data))
        for branch in (b for b in branches if b["script"] == script):
            if branch["target"] not in boundaries:
                issues.append({**branch, "reason": "branch target is not an instruction boundary"})
        scripts.append({"id": script, "instructions": instructions})
    ddata = (mod / "save/alldef.grp").read_bytes()
    bad_triggers, item_trigger_candidates = [], []
    first_instructions = {s["id"]: next((r for r in s["instructions"] if r["opcode"] != 0), None)
                          for s in scripts}
    for scene in range(counts["scenes"]):
        for slot in range(200):
            d = words(ddata[(scene*200+slot)*22:(scene*200+slot+1)*22])
            for trigger in (2,3,4):
                if d[trigger] >= len(kidx):
                    bad_triggers.append({"scene": scene, "slot": slot, "trigger": trigger, "script": d[trigger]})
            first = first_instructions.get(d[2])
            if first and first["opcode"] == 4 and d[3] != d[2]:
                required = first["args"][0]
                item_trigger_candidates.append({"scene": scene, "slot": slot, "xy": [d[10], d[9]],
                    "talk_script": d[2], "item_script": d[3], "required_item": required,
                    "item_name": item_names[required] if 0 <= required < len(item_names) else None,
                    "reason": "Talk script begins by testing the used item, but item-use routes elsewhere; investigate"})
    report = {"mod": str(mod.resolve()), "ranger_sha256": sha256(grp), "counts": {**counts, "scripts": len(kidx), "talks": talk_count, "battles": battle_count},
              "item_name_defects": name_defects, "script_issues": issues, "invalid_triggers": bad_triggers,
              "item_trigger_candidates": item_trigger_candidates,
              "opcode_counts": dict(opcode_counts), "references": references}
    return report, scripts, grp


def repair_names(original: bytes, defects: list[dict]):
    repaired = bytearray(original)
    patches = []
    for defect in defects:
        replacement = defect["replacement"].encode("cp950")
        if len(replacement) > 20:
            raise ValueError("Replacement exceeds fixed name field")
        offset = defect["offset"]
        after = replacement.ljust(20, b"\0")
        repaired[offset:offset+20] = after
        patches.append({**defect, "replacement_hex": after.hex()})
    return bytes(repaired), patches


def repair_saber_event(original: bytes, candidates: list[dict]):
    """Repair ONLY the runtime-confirmed Dragon scene-84 saber trigger.

    Do not automatically repair other item-gate candidates or progressed saves.
    Ordinary interaction (field 2) and item use (field 3) are different trigger
    types; both must point to the intended scripts, not change script 1 to 2.
    """
    expected = (1, 0, 18, 0, 0, 0, 0, 0, 0, 20, 21)
    offset = (84 * 200 + 8) * 22
    if not any(c["scene"] == 84 and c["slot"] == 8 and c["talk_script"] == 18
               and c["item_script"] == 0 and c["required_item"] == 202 for c in candidates):
        raise ValueError("The confirmed scene-84 saber defect is not present")
    if len(original) < offset + 22 or words(original[offset:offset+22]) != expected:
        raise ValueError("Scene-84 event record differs; refusing an unverified repair")
    repaired = bytearray(original)
    struct.pack_into("<hh", repaired, offset+4, 0, 18)
    patch = {"scene": 84, "slot": 8, "record_offset": offset, "xy": [21, 20],
             "talk": {"offset": offset+4, "before": 18, "after": 0},
             "item": {"offset": offset+6, "before": 0, "after": 18},
             "original_hex": original[offset:offset+22].hex(),
             "replacement_hex": repaired[offset:offset+22].hex()}
    return bytes(repaired), patch


def validate_outputs(mod: Path, outputs: dict[str, Path | None]):
    """Keep all generated files outside the reference and mutually distinct."""
    seen = set()
    for kind, output in outputs.items():
        if output is None:
            continue
        target = output.resolve()
        if target.is_relative_to(mod.resolve()):
            raise ValueError("All outputs must be outside the reference mod directory")
        if target in seen:
            raise ValueError("Report, script dump and repair outputs must be distinct")
        if kind.startswith("repair") and target.exists():
            raise ValueError("Repair output already exists; choose a new path")
        seen.add(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mod", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--scripts", type=Path, help="Optional full decoded bytecode, for guide investigations")
    parser.add_argument("--repair-output", type=Path, help="NEW ranger.grp; never overwrite the input")
    parser.add_argument("--repair-event-output", type=Path, help="NEW alldef.grp; fix only confirmed scene-84 saber trigger")
    args = parser.parse_args()
    try:
        validate_outputs(args.mod, {"report": args.report, "scripts": args.scripts,
                                    "repair_names": args.repair_output,
                                    "repair_event": args.repair_event_output})
    except ValueError as error:
        parser.error(str(error))
    report, scripts, original = audit(args.mod)
    if args.repair_output:
        repaired, patches = repair_names(original, report["item_name_defects"])
        args.repair_output.parent.mkdir(parents=True, exist_ok=True)
        args.repair_output.write_bytes(repaired)
        report["repair"] = {"output": str(args.repair_output.resolve()), "sha256": sha256(repaired), "patches": patches,
                            "changed_byte_count": sum(a != b for a, b in zip(original, repaired))}
    if args.repair_event_output:
        original_events = (args.mod / "save/alldef.grp").read_bytes()
        repaired, patch = repair_saber_event(original_events, report["item_trigger_candidates"])
        args.repair_event_output.parent.mkdir(parents=True, exist_ok=True)
        args.repair_event_output.write_bytes(repaired)
        report["event_repair"] = {"output": str(args.repair_event_output.resolve()), "sha256": sha256(repaired),
                                  "original_sha256": sha256(original_events), "patch": patch,
                                  "changed_byte_count": sum(a != b for a, b in zip(original_events, repaired))}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.scripts:
        args.scripts.parent.mkdir(parents=True, exist_ok=True)
        args.scripts.write_text(json.dumps(scripts, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"counts": report["counts"], "name_defects": len(report["item_name_defects"]),
                      "script_issues": len(report["script_issues"]), "invalid_triggers": len(report["invalid_triggers"]),
                      "item_trigger_candidates": len(report["item_trigger_candidates"])}, indent=2))


if __name__ == "__main__":
    main()
