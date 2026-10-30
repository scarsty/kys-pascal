"""Apply all confirmed Dragon data repairs to a new patch directory.

Copy the generated save/ and resource/ folders into the mod, then start a new
game. The original mod and existing save slots are never modified.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import struct


SOURCE_HASHES = {
    "save/ranger.grp": "272f5d0300a49fe1e08afdc8da1873695998d4c88f79330f66e6874646553aaa",
    "save/alldef.grp": "6ab5976dabc2053ff8039b756710e1446d14b30bb8189ecf303cd9bf10466d50",
    "resource/kdef.idx": "c123ade12d6554fb1539a7a0ad27dfff8f64a1446e3a2b350c4479f29910086b",
    "resource/kdef.grp": "d03c428d470db54f557f2c4a2a6081aea955ab32e8a623d607d045b155823c67",
}


def repaired_files(mod: Path) -> dict[str, bytes]:
    files = {}
    for name, expected in SOURCE_HASHES.items():
        data = (mod / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError("Expected the unmodified Dragon reference; input is different or already repaired")
        files[name] = data

    # Remove only the confirmed control characters from the three item names.
    ranger = bytearray(files["save/ranger.grp"])
    for offset in (124756, 124946, 141856):
        name = ranger[offset:offset + 20].split(b"\0", 1)[0]
        name = name.replace(b"\r", b"").replace(b"\n", b"").replace(b"\t", b"")
        ranger[offset:offset + 20] = name.ljust(20, b"\0")

    # Route item use, rather than ordinary interaction, to the saber gate.
    events = bytearray(files["save/alldef.grp"])
    struct.pack_into("<hh", events, (84 * 200 + 8) * 22 + 4, 0, 18)

    # Give the seven paintings their own counter, preserving the chest script.
    index = struct.unpack(f"<{len(files['resource/kdef.idx']) // 4}i", files["resource/kdef.idx"])
    original_scripts = files["resource/kdef.grp"]
    empty = original_scripts[index[623]:index[624]]
    reward = original_scripts[index[629]:index[630]]
    new_index = bytearray(files["resource/kdef.idx"])
    scripts = bytearray(original_scripts)
    for payload in [empty] * 7 + [reward]:
        scripts.extend(payload)
        new_index.extend(struct.pack("<i", len(scripts)))
    struct.pack_into("<h", events, (12 * 200 + 19) * 22 + 4, len(index))

    return {"save/ranger.grp": bytes(ranger), "save/alldef.grp": bytes(events),
            "resource/kdef.idx": bytes(new_index), "resource/kdef.grp": bytes(scripts)}


def repair(mod: Path, output: Path) -> None:
    mod, output = mod.resolve(strict=True), output.resolve()
    if output.is_relative_to(mod) or mod.is_relative_to(output):
        raise ValueError("Output must be outside the original mod directory")
    if output.exists():
        raise ValueError("Output already exists; choose a new directory")
    # Validate every source before creating any output.
    files = repaired_files(mod)
    output.mkdir(parents=True, exist_ok=False)
    for name, data in files.items():
        target = output / name
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("xb") as stream:
            stream.write(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mod", type=Path, help="Original unmodified Dragon mod directory")
    parser.add_argument("output", type=Path, help="New directory for all repaired files")
    args = parser.parse_args()
    try:
        repair(args.mod, args.output)
    except (ValueError, OSError) as error:
        parser.error(str(error))
    print("All repairs applied: item names, saber gate and seven-painting reward.")
    print("Copy save/ and resource/ into the mod, then start a new game.")


if __name__ == "__main__":
    main()
