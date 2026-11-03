"""Package a local Dragon data tree into compressed bundles for demand loading."""
from __future__ import annotations

import argparse
from collections import defaultdict
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import struct

from PIL import Image
from fontTools import subset
from fontTools.ttLib import TTFont
from soundfont import convert_sf2


def web_font(data: bytes, source: Path) -> bytes:
    # Subset from actual dialogue, record names and compiled UI text, then
    # close the alphabet over SimpleCC's conversions as in KYS-CPP.
    font = TTFont(io.BytesIO(data), recalcTimestamp=False)
    points = {point for point in font.getBestCmap()
              if not (0x3400 <= point <= 0x9FFF or 0x20000 <= point <= 0x323AF)}
    # FreeType's CJK auto-hinter measures these reference glyphs even when
    # rendering other characters. Preserve the same small-size font metrics.
    points.update(map(ord, "个为主事些人他以们你來例個們军別别到制前动動即同吗吧听呢和品响嗎囗因地增大她學它对将將對就已师師席年得情想意愿我或指收政断斯新斷既时明星是時景最會有朝期来构样樣民沒没為然照物特现現球理生用田當看眼着确种第經置者能自舰著裡要說調说谁调費费起軍过还这进這通進過道還那都配里開間间际陈限除陳随際隨雷露面顾齊"))
    dialogue = (source / "resource/talk.grp").read_bytes()
    points.update(map(ord, bytes(byte ^ 0xFF if byte else 0 for byte in dialogue).decode("cp950", errors="ignore")))
    records = (source / "save/ranger.grp").read_bytes()
    offsets = struct.unpack("<6I", (source / "save/ranger.idx").read_bytes()[:24])
    for start, end, size, field, length in (
        (offsets[0], offsets[1], 182, 8, 20),
        (offsets[1], offsets[2], 190, 2, 70),
        (offsets[2], offsets[3], 52, 2, 10),
        (offsets[3], offsets[4], 136, 2, 10),
    ):
        for position in range(start, end, size):
            points.update(map(ord, records[position + field:position + field + length].decode("cp950", errors="ignore")))
    code = Path(__file__).resolve().parents[1] / "bin-c"
    for path in [*code.glob("*.cpp"), *code.glob("*.h")]:
        points.update(map(ord, path.read_text(encoding="utf-8")))
    for path in [*(source / "resource").glob("*.txt"), *(source / "list").glob("*.txt")]:
        data = path.read_bytes()
        try:
            text = data.decode("utf-8-sig")
        except UnicodeDecodeError:
            text = data.decode("cp950", errors="ignore")
        points.update(map(ord, text))
    mappings = {}
    for direction in ("ST", "TS"):
        for suffix in ("Phrases", "Characters"):
            for line in (source / "cc" / f"{direction}{suffix}.txt").read_text(encoding="utf-8").splitlines():
                if "\t" in line:
                    key, value = line.split("\t", 1)
                    mappings[direction, key] = value.split(" ", 1)[0]
    previous = -1
    while previous != len(points):
        previous = len(points)
        for (_, key), value in mappings.items():
            if set(map(ord, key)) <= points:
                points.update(map(ord, value))
    selected = subset.Subsetter()
    selected.populate(unicodes=points)
    selected.subset(font)
    stream = io.BytesIO()
    font.save(stream)
    return stream.getvalue()


def group(path: str) -> str:
    folder, _, name = path.partition("/")
    if folder == "cc":
        return "text-conversion"
    if folder == "fight":
        return "fight-" + str(int(Path(name).stem[5:]) // 32)
    if folder == "head":
        return "heads-" + str(int(Path(name).stem) // 64)
    if folder == "music":
        return "soundfont" if name.endswith(".sf2") else "music-" + str(int(Path(name).stem) // 8)
    if folder == "resource":
        if name == "talkutf8.txt":
            return "extras"
        for prefix, bundle in (("eft.", "effects"), ("hdgrp.", "portraits"),
                               ("talk.", "dialogue"), ("kdef.", "events"),
                               ("name.", "extras"), ("war", "battle")):
            if name.startswith(prefix):
                return bundle
        if name.endswith(".ttf"):
            return "fonts"
        if name in ("mmap.grp", "cloud.grp"):
            return "world"
        if name == "smp":
            return "scenes"
        if name in ("wmp", "warfld.grp", "warfld.idx"):
            return "battle"
        if name.endswith((".png", ".webp")):
            return Path(name).stem
    return folder if folder in ("save", "sound") else "core"


def package(source: Path, output: Path) -> None:
    if not (source / "kysmod.ini").is_file():
        raise ValueError(f"Game data is missing: {source / 'kysmod.ini'}")
    assets = output / "assets"
    # Running tabs still request bundles from their original manifest.
    # Keep prior content-hashed bundles available across deployments.
    assets.mkdir(parents=True, exist_ok=True)
    groups = defaultdict(list)
    original_bytes = 0
    webp_bytes_saved = 0
    font_bytes_saved = 0
    for path in sorted(source.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(source).as_posix()
        if re.fullmatch(r"save/[rsd]\d+\.grp", relative, re.IGNORECASE):
            continue
        data = path.read_bytes()
        original_bytes += len(data)
        if relative == "resource/chinese.ttf":
            groups["font-fallback"].append(("/game/resource/chinese-full.ttf", data))
            selected = web_font(data, source)
            font_bytes_saved += len(data) - len(selected)
            data = selected
        if relative == "music/mid.sf2":
            data = convert_sf2(data)
        if path.suffix.lower() == ".png":
            stream = io.BytesIO()
            with Image.open(path) as image:
                image.save(stream, "WEBP", quality=80, method=6)
            if stream.tell() < len(data):
                webp_bytes_saved += len(data) - stream.tell()
                data = stream.getvalue()
        groups[group(relative)].append(("/game/" + relative, data))
    manifest = {"files": {}, "bundles": {}, "sizes": {}}
    total = 0
    for name, entries in sorted(groups.items()):
        raw = bytearray()
        members = []
        for path, data in entries:
            members.append([path, len(raw), len(data)])
            raw.extend(data)
        compressed = gzip.compress(raw, compresslevel=9, mtime=0)
        digest = hashlib.sha256(compressed).hexdigest()[:16]
        filename = f"{name}-{digest}.pack.gz"
        (assets / filename).write_bytes(compressed)
        manifest["bundles"][filename] = members
        manifest["sizes"][filename] = len(compressed)
        for path, offset, size in members:
            manifest["files"][path] = [filename, size]
        total += len(compressed)
    startup = ["kysmod.ini", "resource/title.grp", "resource/open.png"]
    if "/game/resource/title-menu.webp" in manifest["files"]:
        startup.append("resource/title-menu.webp")
    manifest["startup"] = sorted({manifest["files"]["/game/" + name][0] for name in startup})
    (assets / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False,
                                                     separators=(",", ":")), encoding="utf-8")
    wasm = output / "kys-dragon.wasm"
    wasm.with_suffix(".wasm.gz").write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
    # Pair the script and Wasm with this build even when a local server permits
    # caching unversioned files. Player saves remain on the same origin.
    version = hashlib.sha256((output / "kys-dragon.js").read_bytes() + wasm.read_bytes()).hexdigest()[:16]
    html = Path(__file__).with_name("index.html").read_text(encoding="utf-8")
    for name in ("kys-dragon.js", "kys-dragon.wasm.gz"):
        html = html.replace("'" + name + "'", "'" + name + "?v=" + version + "'")
    (output / "index.html").write_text(html, encoding="utf-8")
    shutil.copyfile(Path(__file__).with_name("_headers"), output / "_headers")
    fallback = sum(size for name, size in manifest["sizes"].items() if name.startswith("font-fallback-"))
    print(f"{len(manifest['files'])} files -> {len(groups)} compressed bundles")
    print(f"Game data: {original_bytes:,} source bytes -> {total - fallback:,} compressed bytes + {fallback:,} optional font bytes")
    print(f"Title data: {sum(manifest['sizes'][name] for name in manifest['startup']):,} compressed bytes; WebP q80 saves {webp_bytes_saved:,} bytes")
    print(f"Chinese font subsetting saves {font_bytes_saved:,} uncompressed bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    package(args.source.resolve(), args.output.resolve())
