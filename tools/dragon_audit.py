"""Audit legacy mod data and produce minimal standalone or combined repairs.

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


def repair_pictures(original_events: bytes, original_index: bytes, original_scripts: bytes):
    """Give Dragon's seven paintings a dedicated counter-script range.

    Reuse the exact native no-op and reward payloads. Existing scripts,
    including the folding-hand chest, are unchanged. The old 624-based counter
    reaches the reward at six pictures and an unrelated script at seven.
    """
    expected_hashes = (
        "c123ade12d6554fb1539a7a0ad27dfff8f64a1446e3a2b350c4479f29910086b",
        "d03c428d470db54f557f2c4a2a6081aea955ab32e8a623d607d045b155823c67",
    )
    if (sha256(original_index), sha256(original_scripts)) != expected_hashes:
        raise ValueError("Script files differ from the verified Dragon reference")
    offset = (12 * 200 + 19) * 22
    expected = (0, 19, 624, 0, 0, 0, 0, 0, 0, 20, 10)
    if words(original_events[offset:offset+22]) != expected:
        raise ValueError("Scene-12 central painting differs; refusing an unverified repair")
    for slot, script in ((15, 617), (16, 618), (17, 620), (18, 619),
                         (20, 623), (21, 622), (22, 621)):
        if struct.unpack_from("<h", original_events, (12 * 200 + slot) * 22 + 4)[0] != script:
            raise ValueError("Scene-12 painting sequence differs from the reference")
    index = struct.unpack(f"<{len(original_index)//4}i", original_index)

    def script_bytes(number):
        return original_scripts[index[number-1] if number else 0:index[number]]

    first = len(index)
    appended = [script_bytes(624)] * 7 + [script_bytes(630)]
    new_index = bytearray(original_index)
    new_scripts = bytearray(original_scripts)
    for payload in appended:
        new_scripts.extend(payload)
        new_index.extend(struct.pack("<i", len(new_scripts)))
    events = bytearray(original_events)
    struct.pack_into("<h", events, offset + 4, first)
    files = {"save/alldef.grp": bytes(events),
             "resource/kdef.idx": bytes(new_index),
             "resource/kdef.grp": bytes(new_scripts)}
    patch = {"scene": 12, "slot": 19, "talk_offset": offset + 4,
             "before": 624, "after": first, "reward_script": first + 7,
             "appended_scripts": len(appended),
             "appended_index_bytes": len(new_index) - len(original_index),
             "appended_script_bytes": len(new_scripts) - len(original_scripts),
             "changed_event_bytes": sum(a != b for a, b in zip(original_events, events)),
             "files": {name: {"sha256": sha256(data), "bytes": len(data)}
                       for name, data in files.items()},
             "original_hashes": {"events": sha256(original_events),
                                 "index": sha256(original_index),
                                 "scripts": sha256(original_scripts)}}
    return files, patch


def repair_combined(original_ranger: bytes, original_events: bytes,
                    original_index: bytes, original_scripts: bytes, report: dict):
    """Compose all confirmed Dragon fixes from the exact original reference.

    Apply the saber edit before the picture edit so there is a single event
    template containing both. Each existing repair still enforces its own
    guards; the combined package additionally requires pristine names/events.
    """
    expected = (
        "272f5d0300a49fe1e08afdc8da1873695998d4c88f79330f66e6874646553aaa",
        "6ab5976dabc2053ff8039b756710e1446d14b30bb8189ecf303cd9bf10466d50",
    )
    if (sha256(original_ranger), sha256(original_events)) != expected:
        raise ValueError("Combined repair requires the unmodified Dragon names/event reference")
    names = report["item_name_defects"]
    if [(d["item"], d["offset"]) for d in names] != [(88, 124756), (89, 124946), (178, 141856)]:
        raise ValueError("The three confirmed Dragon name defects are not present")
    for defect in names:
        field = original_ranger[defect["offset"]:defect["offset"]+20]
        replacement = text(field).replace("\r", "").replace("\n", "").replace("\t", "")
        if defect["original_hex"] != field.hex() or defect["replacement"] != replacement:
            raise ValueError("Name repair differs from the confirmed control-character cleanup")
    ranger, names = repair_names(original_ranger, report["item_name_defects"])
    events, saber = repair_saber_event(original_events, report["item_trigger_candidates"])
    files, pictures = repair_pictures(events, original_index, original_scripts)
    files = {"save/ranger.grp": ranger, **files}
    originals = {"save/ranger.grp": original_ranger, "save/alldef.grp": original_events,
                 "resource/kdef.idx": original_index, "resource/kdef.grp": original_scripts}
    patch = {
        "new_game_only": True,
        "repairs": {"names": names, "saber": saber, "pictures": pictures},
        "files": {name: {"original_sha256": sha256(originals[name]),
                         "sha256": sha256(data), "bytes": len(data),
                         "changed_existing_bytes": sum(a != b for a, b in zip(originals[name], data)),
                         "appended_bytes": len(data) - len(originals[name])}
                  for name, data in files.items()},
    }
    return files, patch


def validate_outputs(mod: Path, outputs: dict[str, Path | None]):
    """Keep all generated files outside the reference and mutually distinct."""
    seen = {}
    directory_outputs = {"repair_pictures", "repair_combined"}
    for kind, output in outputs.items():
        if output is None:
            continue
        target = output.resolve()
        if target.is_relative_to(mod.resolve()):
            raise ValueError("All outputs must be outside the reference mod directory")
        if target in seen:
            raise ValueError("Report, script dump and repair outputs must be distinct")
        for previous, previous_kind in seen.items():
            if ((target.is_relative_to(previous) and previous_kind not in directory_outputs)
                    or (previous.is_relative_to(target) and kind not in directory_outputs)):
                raise ValueError("A file output cannot contain another output path")
        if kind.startswith("repair") and target.exists():
            raise ValueError("Repair output already exists; choose a new path")
        seen[target] = kind


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mod", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--scripts", type=Path, help="Optional full decoded bytecode, for guide investigations")
    parser.add_argument("--repair-output", type=Path, help="NEW ranger.grp; never overwrite the input")
    parser.add_argument("--repair-event-output", type=Path, help="NEW alldef.grp; fix only confirmed scene-84 saber trigger")
    parser.add_argument("--repair-pictures-output", type=Path,
                        help="NEW directory with save/alldef.grp and resource/kdef.*; fix seven-picture counter")
    parser.add_argument("--repair-combined-output", type=Path,
                        help="NEW directory combining all confirmed name, saber and picture repairs")
    args = parser.parse_args()
    try:
        if args.repair_combined_output and any((args.repair_output, args.repair_event_output,
                                               args.repair_pictures_output)):
            raise ValueError("Use the combined output or individual repair outputs, not both")
        outputs = {"report": args.report, "scripts": args.scripts,
                   "repair_names": args.repair_output, "repair_event": args.repair_event_output,
                   "repair_pictures": args.repair_pictures_output,
                   "repair_combined": args.repair_combined_output}
        if args.repair_pictures_output:
            outputs.update({"repair_picture_" + name: args.repair_pictures_output / name
                            for name in ("save/alldef.grp", "resource/kdef.idx", "resource/kdef.grp")})
        if args.repair_combined_output:
            outputs.update({"repair_combined_" + name: args.repair_combined_output / name
                            for name in ("save/ranger.grp", "save/alldef.grp",
                                         "resource/kdef.idx", "resource/kdef.grp")})
        validate_outputs(args.mod, outputs)
    except ValueError as error:
        parser.error(str(error))
    report, scripts, original = audit(args.mod)
    if args.repair_combined_output:
        try:
            files, patch = repair_combined(original, (args.mod / "save/alldef.grp").read_bytes(),
                                          (args.mod / "resource/kdef.idx").read_bytes(),
                                          (args.mod / "resource/kdef.grp").read_bytes(), report)
            # Validate and compose everything before creating the package.
            # Exclusive creation also rejects a destination created after the
            # preflight check, without overwriting any of its contents.
            args.repair_combined_output.mkdir(parents=True, exist_ok=False)
            for name, data in files.items():
                output = args.repair_combined_output / name
                output.parent.mkdir(parents=True, exist_ok=True)
                with output.open("xb") as stream:
                    stream.write(data)
        except (ValueError, OSError) as error:
            parser.error(str(error))
        report["combined_repair"] = {"output": str(args.repair_combined_output.resolve()), **patch}
    if args.repair_pictures_output:
        files, patch = repair_pictures((args.mod / "save/alldef.grp").read_bytes(),
                                      (args.mod / "resource/kdef.idx").read_bytes(),
                                      (args.mod / "resource/kdef.grp").read_bytes())
        for name, data in files.items():
            output = args.repair_pictures_output / name
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
        report["pictures_repair"] = {"output": str(args.repair_pictures_output.resolve()), **patch}
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
