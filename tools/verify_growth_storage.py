"""Read-only DOS machine-code round trip of the C++ v1 growth metadata.

Requires unicorn. Supply the original, SHA-pinned Z.dat, ranger.idx and an R
file with that index. Only isolated memory and an optional JSON report change.
"""

import argparse
import hashlib
import json
import struct
from pathlib import Path

from unicorn.x86_const import UC_X86_REG_ESI, UC_X86_REG_ESP
from verify_dragon_dos12 import BASELINE_SHA256, Probe, ROLE, STACK


# These exact v1 encodings are also pinned by the native regression tests.
ENCODINGS = {
    0: (0, 0, 21852, 9128),
    1: (1, 0, 19124, 9128),
    0x12345678: (22136, 9320, 21896, 9128),
    0xFFFFFFFF: (32767, 32767, 24795, 9128),
}


class FileProbe(Probe):
    def __init__(self, executable, data, offsets):
        self.file = bytearray(data)
        self.pos = 0
        super().__init__(executable)
        for i, value in enumerate((0, *offsets)):
            self.write(0xB5070 + 4 * i, value, "I")
        self.cpu.reg_write(UC_X86_REG_ESI, 37)

    def hook(self, cpu, address, size, user_data):
        if address not in (0x1DB07, 0x1DABF, 0x1DAE3, 0x1DB2B):
            return super().hook(cpu, address, size, user_data)
        sp = cpu.reg_read(UC_X86_REG_ESP)
        assert self.read(sp + 4, "I") == 37  # synthetic file handle
        if address == 0x1DB07:  # seek
            self.pos = self.read(sp + 8, "I")
            assert self.read(sp + 12, "I") == 0
            self.ret(self.pos)
        elif address in (0x1DABF, 0x1DAE3):  # read / write
            buf, count = self.read(sp + 8, "I"), self.read(sp + 12, "I")
            assert self.pos + count <= len(self.file)
            if address == 0x1DABF:
                cpu.mem_write(buf, bytes(self.file[self.pos:self.pos + count]))
            else:
                self.file[self.pos:self.pos + count] = cpu.mem_read(buf, count)
            self.pos += count
            self.ret(count)
        else:
            self.ret(0)


def verify(executable, idx, original):
    assert hashlib.sha256(executable).hexdigest() == BASELINE_SHA256, "Wrong DOS executable"
    assert len(idx) == 24, "Expected six section offsets"
    offsets = struct.unpack("<6I", idx)
    assert offsets[-1] == len(original)
    assert list(offsets) == sorted(offsets)
    assert (offsets[1] - offsets[0]) % 182 == 0
    roles = (offsets[1] - offsets[0]) // 182
    assert roles > 0
    assert struct.unpack_from("<4h", original, offsets[0] + 166) == (-1,) * 4
    # The unrelocated DOS static scene array begins where role 320 would be.
    # Expanded remake data already overlaps that address without our metadata.
    # Check the role-section format separately, then compare full loading with
    # its own baseline rather than attributing that old aliasing to this change.
    safe_roles = min(roles, (0x7E4CC - ROLE) // 182)
    def save_roles(p):
        p.cpu.reg_write(UC_X86_REG_ESP, STACK)
        p.cpu.reg_write(UC_X86_REG_ESI, 37)
        p.run(0x68AD, 0x68DD)
        return p.file

    baseline = FileProbe(executable, original, offsets)
    baseline.run(0x644A, 0x657F)
    baseline_file = save_roles(baseline)
    baseline_changes = sum(a != b for a, b in zip(original, baseline_file))
    results = []
    for seed, words in ENCODINGS.items():
        fixture = bytearray(original)
        struct.pack_into("<4h", fixture, offsets[0] + 174, *words)
        for role in range(roles):
            struct.pack_into("<h", fixture, offsets[0] + role * 182 + 6, 0x5000 | (role % 2))
        p = FileProbe(executable, fixture, offsets)
        p.run(0x647C, 0x64AE)  # original role-section loader
        assert p.cpu.mem_read(ROLE, roles * 182) == fixture[offsets[0]:offsets[1]]
        assert save_roles(p) == fixture, "DOS role-section I/O changed a byte or the file length"
        full = FileProbe(executable, fixture, offsets)
        full.run(0x644A, 0x657F)
        expected = bytearray(baseline_file)
        struct.pack_into("<4h", expected, offsets[0] + 174, *words)
        for role in range(safe_roles):
            struct.pack_into("<h", expected, offsets[0] + role * 182 + 6, 0x5000 | (role % 2))
        assert save_roles(full) == expected, "Full DOS loading introduced changes beyond the baseline and reserved metadata"
        results.append({"seed": seed, "quantity_words": words, "role_section_every_byte_preserved": True,
                        "full_load_seed_and_first_roles_carry_preserved": safe_roles})
    return {"dos_sha256": BASELINE_SHA256, "R_bytes": len(original), "role_count": roles,
            "added_bytes": 0, "section_offsets": offsets, "cases": results,
            "full_load_baseline_changed_bytes_due_to_static_array_aliasing": baseline_changes,
            "method": "Isolated original DOS x86 role I/O and six-section loader in Unicorn; no full DOSBox session"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("index", type=Path)
    parser.add_argument("save", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    original = args.save.read_bytes()
    result = verify(args.executable.read_bytes(), args.index.read_bytes(), original)
    assert args.save.read_bytes() == original, "Source save was modified"
    report = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        # A report may never overwrite any supplied game file.
        assert args.output.resolve() not in {p.resolve() for p in (args.executable, args.index, args.save)}
        args.output.write_text(report + "\n", encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()
