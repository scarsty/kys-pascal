"""Package the fixed Dragon data into compressed bundles for demand loading."""
from __future__ import annotations

import argparse
from collections import defaultdict
import gzip
import hashlib
import io
import json
from pathlib import Path
import shutil

from PIL import Image
from fontTools import subset
from fontTools.ttLib import TTFont


def web_font(data: bytes, source: Path) -> bytes:
    # Saves and dialogue use Big5; SimpleCC supplies the simplified forms.
    # Retain both Chinese repertoires and every non-CJK glyph in the font.
    font = TTFont(io.BytesIO(data), recalcTimestamp=False)
    points = {point for point in font.getBestCmap()
              if not (0x3400 <= point <= 0x9FFF or 0x20000 <= point <= 0x323AF)}
    for encoding in ("cp950", "gb2312"):
        for first in range(0x81, 0xFF):
            for second in range(0x40, 0xFF):
                try:
                    points.update(map(ord, bytes((first, second)).decode(encoding)))
                except UnicodeError:
                    pass
    for dictionary in (source / "cc").glob("*.txt"):
        points.update(map(ord, dictionary.read_text(encoding="utf-8")))
    selected = subset.Subsetter()
    selected.populate(unicodes=points)
    selected.subset(font)
    stream = io.BytesIO()
    font.save(stream)
    return stream.getvalue()


def group(path: str) -> str:
    folder, _, name = path.partition("/")
    if folder == "fight":
        return "fight-" + str(int(Path(name).stem[5:]) // 32)
    if folder == "head":
        return "heads-" + str(int(Path(name).stem) // 64)
    if folder == "music":
        return "soundfont" if name.endswith(".sf2") else "music-" + str(int(Path(name).stem) // 8)
    if folder == "resource":
        if name.endswith(".ttf"):
            return "fonts"
        if name in ("mmap.grp", "mmap.idx"):
            return "world"
        if name in ("smp", "sdx"):
            return "scenes"
        if name in ("wmp", "wdx", "warfld.grp", "warfld.idx"):
            return "battle"
        if name.endswith(".png"):
            return Path(name).stem
    return folder if folder in ("save", "sound") else "core"


def package(source: Path, output: Path) -> None:
    if not (source / "kysmod.ini").is_file():
        raise ValueError("Golden game data is missing")
    assets = output / "assets"
    assets.mkdir(parents=True, exist_ok=True)
    groups = defaultdict(list)
    original_bytes = 0
    webp_bytes_saved = 0
    font_bytes_saved = 0
    for path in sorted(source.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(source).as_posix()
        data = path.read_bytes()
        original_bytes += len(data)
        if relative == "resource/chinese.ttf":
            selected = web_font(data, source)
            font_bytes_saved += len(data) - len(selected)
            data = selected
        if path.suffix.lower() == ".png":
            stream = io.BytesIO()
            with Image.open(path) as image:
                image.save(stream, "WEBP", lossless=True, method=6)
            if stream.tell() < len(data):
                webp_bytes_saved += len(data) - stream.tell()
                data = stream.getvalue()
        groups[group(relative)].append(("/game/" + relative, data))
    manifest = {"files": {}, "bundles": {}}
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
        for path, offset, size in members:
            manifest["files"][path] = [filename, size]
        total += len(compressed)
    (assets / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False,
                                                     separators=(",", ":")), encoding="utf-8")
    for old in assets.glob("*.pack.gz"):
        if old.name not in manifest["bundles"]:
            old.unlink()
    for name in ("index.html", "_headers"):
        shutil.copyfile(Path(__file__).with_name(name), output / name)
    wasm = output / "kys-dragon.wasm"
    wasm.with_suffix(".wasm.gz").write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
    print(f"{len(manifest['files'])} files -> {len(groups)} compressed bundles")
    print(f"Game data: {original_bytes:,} -> {total:,} bytes; lossless WebP saves {webp_bytes_saved:,} bytes")
    print(f"Chinese font subsetting saves {font_bytes_saved:,} uncompressed bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    package(args.source.resolve(), args.output.resolve())
