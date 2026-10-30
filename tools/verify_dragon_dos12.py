"""Probe the original Dragon DOS 1.2 Z.dat machine code (requires unicorn).

No game executable is patched. Relevant x86 routines/blocks run in isolated
memory with deterministic random draws. This checks historical behavior, not
the corrected C++ rules. Addresses are offsets within LE object 2.
"""

import argparse
import hashlib
import json
import struct
from pathlib import Path

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_EIP,
)


BASELINE_SHA256 = "60ff7e91d7be7a848242e2ddc2ef105b906e160e19f3086bf13ff55d8e951928"
OBJECT_FILE_OFFSET = 0x19A00
ROLE = 0x7014C
ROLE_SIZE = 0xB6
BATTLE = 0xBC72C
MAGIC = 0x7F5DC
STACK = 0x4F0000
RETURN = 0x4FF000


class Probe:
    def __init__(self, blob, draws=()):
        self.cpu = Uc(UC_ARCH_X86, UC_MODE_32)
        self.cpu.mem_map(0, 0x500000)
        self.cpu.mem_write(0, blob[OBJECT_FILE_OFFSET:])
        self.draws = iter(draws)
        self.random_bounds = []
        self.cpu.reg_write(UC_X86_REG_ESP, STACK)
        self.cpu.hook_add(UC_HOOK_CODE, self.hook)

    def read(self, address, fmt="h"):
        return struct.unpack(fmt, self.cpu.mem_read(address, struct.calcsize(fmt)))[0]

    def write(self, address, value, fmt="h"):
        self.cpu.mem_write(address, struct.pack(fmt, value))

    def role(self, role, field, value=None):
        address = ROLE + role * ROLE_SIZE + field
        if value is None:
            return self.read(address)
        self.write(address, value)

    def ret(self, value=None, extra=0):
        if value is not None:
            self.cpu.reg_write(UC_X86_REG_EAX, value & 0xFFFFFFFF)
        sp = self.cpu.reg_read(UC_X86_REG_ESP)
        self.cpu.reg_write(UC_X86_REG_EIP, self.read(sp, "I"))
        self.cpu.reg_write(UC_X86_REG_ESP, sp + 4 + extra)

    def hook(self, cpu, address, size, user_data):
        if address == 0x1ED1E:  # Watcom stack check, consumes its size argument
            self.ret(extra=4)
        elif address == 0x1D612:  # random(bound), caller cleans up argument
            bound = self.read(cpu.reg_read(UC_X86_REG_ESP) + 4, "i")
            self.random_bounds.append(bound)
            value = next(self.draws, 0)
            assert 0 <= value < max(bound, 1), (bound, value)
            self.ret(value)

    def run(self, start, stop=RETURN, args=()):
        if args:
            for i, value in enumerate((RETURN, *args)):
                self.write(STACK + i * 4, value, "I")
        self.cpu.emu_start(start, stop, count=100000)
        assert self.cpu.reg_read(UC_X86_REG_EIP) == stop, "Instruction limit reached"


def verify(blob):
    results = {}

    p = Probe(blob, [0, 0] + [1] * 7)
    p.role(0, 30, 1)  # level
    p.write(ROLE + 32, 750, "H")  # enough cumulative XP for level 6
    for field, value in [(4, 3), (36, 100), (84, 100), (120, 50)]:
        p.role(0, field, value)
    for field in (92, 94, 96, 100, 102, 104, 108):
        p.role(0, field, 30)
    p.run(0x1B6BE, args=(0, 1))  # silent level-up
    results["batch_growth"] = {"level": p.role(0, 30), "medicine_gain": p.role(0, 92) - 30,
                               "hidden_weapon_gain": p.role(0, 108) - 30}
    assert results["batch_growth"] == {"level": 6, "medicine_gain": 1, "hidden_weapon_gain": 1}

    costs = []
    for cached_tier in (0, 2, 10):
        p = Probe(blob)
        p.role(0, 82, 100)
        p.write(0xC6EC2, cached_tier)
        p.cpu.reg_write(UC_X86_REG_EBX, 0)
        p.cpu.reg_write(UC_X86_REG_ESI, 10)  # current magic NeedMP
        p.run(0x18520, 0x18551)
        costs.append(100 - p.role(0, 82))
    assert costs == [0, 10, 50]
    results["cached_mp_cost"] = {"previous_hp_tiers": [0, 2, 10], "costs": costs}

    p = Probe(blob, [0, 0, 4, 0, 0])
    p.role(0, 82, 50)
    p.role(0, 84, 100)
    p.write(MAGIC + 96, 20)  # magic 0 AddMP[0]
    p.write(MAGIC + 116, 30)  # HurtMP[0]
    p.run(0x195EC, args=(0, 1, 0, 1, 0))
    results["empty_target_mp"] = {"target_mp": p.role(1, 82), "recovered": p.role(0, 82) - 50,
                                  "max_mp_gain": p.role(0, 84) - 100}
    assert results["empty_target_mp"] == {"target_mp": 0, "recovered": 20, "max_mp_gain": 4}

    poison = []
    for hidden_skill in (20, 80):
        p = Probe(blob)
        p.role(0, 108, hidden_skill)
        p.write(STACK + 12, 0, "I")  # local attacker role ID
        p.write(STACK + 16, 0, "I")  # local item ID
        p.write(0x827A2, 100)  # item 0 AddPoi
        p.cpu.reg_write(UC_X86_REG_EBX, 1)  # defender role ID
        p.run(0x1A73B, 0x1A839)
        poison.append(p.role(1, 40))
    assert poison == [20, 5]
    results["poison_vs_hidden_skill"] = {"skills": [20, 80], "poison": poison}

    changes = []
    for draws in ([4, 0], [0, 4]):
        p = Probe(blob, draws)
        p.role(1, 40, 10)
        p.write(STACK + 16, 0, "I")
        p.cpu.reg_write(UC_X86_REG_EBX, 1)
        p.run(0x1A73B, 0x1A839)
        changes.append(p.role(1, 40) - 10)
    assert changes == [4, -4]
    results["unpoisoned_weapon_changes"] = changes

    experience = []
    for hp in (10, 9):
        p = Probe(blob)
        p.role(1, 34, hp)
        p.role(1, 30, 5)
        p.write(STACK + 0x18, 0, "I")  # attacker battle index
        p.write(STACK + 0x24, 1, "I")  # defender role ID
        p.cpu.reg_write(UC_X86_REG_EBX, 10)  # fixed damage
        p.run(0x19493, 0x194EE)
        experience.append(p.read(BATTLE + 26))
    assert experience == [2, 52]
    results["knockout_experience"] = {"starting_hp": [10, 9], "damage": 10, "experience": experience}

    remaining = []
    for poison in (10, 11):
        p = Probe(blob)
        p.write(0x356D2, 1)  # one battle actor, role 0
        p.role(0, 34, 10)
        p.role(0, 40, poison)
        p.role(0, 42, 100)
        p.write(STACK, RETURN, "I")
        p.run(0x1C56D)
        remaining.append(p.role(0, 34))
    assert remaining == [0, 1]
    results["round_damage_hp"] = {"starting_hp": 10, "poison": [10, 11], "remaining_hp": remaining}

    damages = []
    for defence in (99, 100):
        p = Probe(blob)
        p.role(0, 42, 90)
        for offset, value in [(0x20, 0), (0x24, 1), (0x2C, 1)]:
            p.write(STACK + offset, value, "I")
        p.cpu.reg_write(UC_X86_REG_EBX, 300)  # total attack
        p.cpu.reg_write(UC_X86_REG_EDX, defence)
        p.run(0x1938E, 0x19493)
        damages.append(p.cpu.reg_read(UC_X86_REG_EBX))
    assert damages == [8, 36]
    results["preserved_damage_formula"] = {"defence": [99, 100], "damage": damages}
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("z_dat", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    blob = args.z_dat.read_bytes()
    digest = hashlib.sha256(blob).hexdigest()
    if digest != BASELINE_SHA256:
        parser.error(f"Expected the original installer Z.dat ({BASELINE_SHA256}), got {digest}")
    report = {"source": str(args.z_dat.resolve()), "sha256": digest,
              "method": "Unicorn x86 execution of original routines/blocks; RNG and stack-check hooks only",
              "results": verify(blob)}
    output = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output, encoding="utf-8")
    print(output, end="")


if __name__ == "__main__":
    main()
