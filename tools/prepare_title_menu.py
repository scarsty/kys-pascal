"""Split a generated three-row lettering sheet into an 8x WebP menu atlas."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def prepare(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGBA")
    atlas = Image.new("RGBA", (672, 480))
    # The selected brush sheet has transparent gutters at these row boundaries.
    boundaries = (0, 377, 686, image.height)
    for row, (top, bottom) in enumerate(zip(boundaries, boundaries[1:])):
        label = image.crop((0, top, image.width, bottom))
        bounds = label.getchannel("A").point(lambda value: 255 if value >= 128 else 0).getbbox()
        if bounds is None:
            raise ValueError(f"Empty label in row {row}")
        left, upper, right, lower = bounds
        label = label.crop((max(0, left - 3), max(0, upper - 3), min(label.width, right + 3), min(label.height, lower + 3)))
        label.thumbnail((656, 148), Image.Resampling.LANCZOS)
        atlas.alpha_composite(label, ((672 - label.width) // 2, row * 160 + (160 - label.height) // 2))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, "WEBP", quality=80, method=6)
    print(f"{output.resolve()} ({output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    prepare(args.source, args.output)
