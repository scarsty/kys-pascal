"""Permanent CLI and native-game regressions for the Dragon repair package.

Requires the external unmodified mod and a built MCP executable. Generated
patches, mod copies and checkpoints are removed under the ignored tmp/ root.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
from mcp_client import Game

ROOT = Path(__file__).resolve().parents[2]
FILES = ("save/ranger.grp", "save/alldef.grp", "resource/kdef.idx", "resource/kdef.grp")


def run_repair(mod, output):
    return subprocess.run([sys.executable, "-B", str(ROOT / "tools/repair_dragon.py"),
                           str(mod), str(output)], capture_output=True, text=True,
                          encoding="utf-8", timeout=30)


def amount(state, item):
    return sum(i["quantity"] for i in state["inventory"] if i["id"] == item)


class DragonRepairTests(unittest.TestCase):
    executable: Path
    mod: Path
    scratch: Path

    @classmethod
    def setUpClass(cls):
        cls.originals = {name: (cls.mod / name).read_bytes() for name in FILES}
        cls.package = cls.scratch / "patch"
        result = run_repair(cls.mod, cls.package)
        if result.returncode != 0:
            raise RuntimeError(result.stderr)
        cls.repaired_mod = cls.scratch / "repaired-mod"
        shutil.copytree(cls.mod, cls.repaired_mod)
        shutil.copytree(cls.package, cls.repaired_mod, dirs_exist_ok=True)

    def game(self, mod):
        g = Game(self.executable, mod, debug=True)
        self.addCleanup(g.close)
        g.call("new_game", seed=7)
        return g

    def rejects_unchanged(self, g, tool, **args):
        before = g.call("state")
        with self.assertRaises(RuntimeError):
            g.call(tool, **args)
        self.assertEqual(before, g.call("state"))

    def test_all_repairs_and_exact_scope(self):
        self.assertEqual({p.relative_to(self.package).as_posix()
                          for p in self.package.rglob("*") if p.is_file()}, set(FILES))
        files = {name: (self.package / name).read_bytes() for name in FILES}
        for name, before in self.originals.items():
            self.assertEqual((self.mod / name).read_bytes(), before)
        self.assertEqual([sum(a != b for a, b in zip(self.originals[n], files[n]))
                          for n in FILES], [12, 4, 0, 0])
        self.assertEqual([len(files[n]) - len(self.originals[n]) for n in FILES], [0, 0, 32, 102])

        before, after = self.originals[FILES[0]], files[FILES[0]]
        name_offsets = (124756, 124946, 141856)
        allowed = {i for offset in name_offsets for i in range(offset, offset + 20)}
        self.assertTrue(all(i in allowed for i, (a, b) in enumerate(zip(before, after)) if a != b))
        for offset in name_offsets:
            old_name = before[offset:offset + 20].split(b"\0", 1)[0].decode("cp950")
            new_name = after[offset:offset + 20].split(b"\0", 1)[0].decode("cp950")
            self.assertEqual(new_name, old_name.replace("\r", "").replace("\n", "").replace("\t", ""))

        before, after = self.originals[FILES[1]], files[FILES[1]]
        gate = (84 * 200 + 8) * 22 + 4
        painting = (12 * 200 + 19) * 22 + 4
        allowed = {*range(gate, gate + 4), *range(painting, painting + 2)}
        self.assertTrue(all(i in allowed for i, (a, b) in enumerate(zip(before, after)) if a != b))
        self.assertEqual(struct.unpack_from("<hh", after, gate), (0, 18))
        first = len(self.originals[FILES[2]]) // 4
        self.assertEqual(struct.unpack_from("<h", after, painting)[0], first)
        # All existing scripts stay intact; the appended counter ends in the
        # original reward and leaves the independent chest untouched.
        for name in FILES[2:]:
            self.assertTrue(files[name].startswith(self.originals[name]))
        ends = struct.unpack(f"<{len(files[FILES[2]]) // 4}i", files[FILES[2]])
        scripts = files[FILES[3]]
        appended = [scripts[ends[i - 1]:ends[i]] for i in range(first, first + 8)]
        self.assertEqual(appended, [scripts[ends[623]:ends[624]]] * 7
                         + [scripts[ends[629]:ends[630]]])

    def test_invalid_inputs_do_not_write_or_overwrite(self):
        occupied = self.scratch / "occupied"
        occupied.write_bytes(b"preserve")
        empty = self.scratch / "empty"
        empty.mkdir()
        nested = self.mod / "must-not-create"
        for output in (self.package, occupied, empty, nested, self.mod):
            with self.subTest(output=output):
                self.assertEqual(run_repair(self.mod, output).returncode, 2)
        self.assertEqual(occupied.read_bytes(), b"preserve")
        self.assertEqual(list(empty.iterdir()), [])
        self.assertFalse(nested.exists())
        for name in FILES:
            self.assertEqual((self.package / name).read_bytes(), (self.repaired_mod / name).read_bytes())

        changed = self.scratch / "changed-input"
        for name, data in self.originals.items():
            target = changed / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        for i, (name, data) in enumerate(self.originals.items()):
            with self.subTest(changed=name):
                target = changed / name
                target.write_bytes(bytes([data[0] ^ 1]) + data[1:])
                output = self.scratch / f"rejected-{i}"
                result = run_repair(changed, output)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("unmodified Dragon", result.stderr)
                self.assertFalse(output.exists())
                target.write_bytes(data)
        output = self.scratch / "already-repaired"
        self.assertEqual(run_repair(self.repaired_mod, output).returncode, 2)
        self.assertFalse(output.exists())
        for name, data in self.originals.items():
            self.assertEqual((self.mod / name).read_bytes(), data)

    def test_native_saber_caves_original_and_repaired(self):
        for modified, mod in ((False, self.mod), (True, self.repaired_mod)):
            g = self.game(mod)
            if modified:
                observed = g.call("audit")
                self.assertEqual(observed["item_name_control_characters"], [])
                self.assertEqual(observed["invalid_script_references"], [])
            g.call("debug", scene=0)
            g.call("interact", slot=4)
            q = g.call("choose", index=1)
            self.assertEqual(amount(q["state"], 202), 1)
            g.call("checkpoint", action="save", label="with_saber")
            for scene in (5, 84, 85):
                with self.subTest(repaired=modified, scene=scene):
                    g.call("checkpoint", action="load", label="with_saber")
                    g.call("debug", scene=scene, x=22, y=20)
                    self.rejects_unchanged(g, "navigate", x=21, y=21)
                    g.call("interact", slot=8, item=234)
                    self.rejects_unchanged(g, "navigate", x=21, y=21)
                    q = g.call("interact", slot=8, item=202)
                    self.assertEqual(amount(q["state"], 202), 1)
                    if scene == 84 and not modified:
                        self.assertEqual(q["changes"]["events"], [])
                        self.rejects_unchanged(g, "navigate", x=21, y=21)
                    else:
                        self.assertTrue(g.call("navigate", x=21, y=21)["action_result"]["reached"])
            g.close()

    def test_native_picture_rewards_original_and_repaired(self):
        order = (15, 16, 17, 18, 20, 21, 22)
        for modified, slots in ((False, order), (True, order), (True, tuple(reversed(order)))):
            with self.subTest(repaired=modified, order=slots):
                g = self.game(self.repaired_mod if modified else self.mod)
                # Position/ethics fixtures reach the event without granting its
                # rewards. Recruitment and picture interactions still run natively.
                g.call("debug", scene=60, field=56, value=80)
                g.call("interact", slot=15)
                q = g.call("choose", index=1)
                monk = next(r for r in q["state"]["party"] if r["id"] == 49)
                aptitude = monk["aptitude"]

                def picture(slot):
                    event = next(e for e in g.call("inspect_scene", scene=12)["events"] if e["slot"] == slot)
                    x, y = event["xy"]
                    g.call("debug", scene=12, x=x, y=y + 1)
                    return g.call("interact", slot=slot)

                q = picture(19)
                self.assertEqual(amount(q["state"], 79), 0)
                for count, slot in enumerate(slots, 1):
                    picture(slot)
                    self.rejects_unchanged(g, "interact")
                    if modified and count < 7:
                        q = picture(19)
                        self.assertEqual(amount(q["state"], 79), 0)
                        self.assertEqual(amount(q["state"], 99), 0)
                q = picture(19)
                monk = next(r for r in q["state"]["party"] if r["id"] == 49)
                self.assertEqual(amount(q["state"], 79), int(modified))
                self.assertEqual(amount(q["state"], 99), int(not modified))
                self.assertEqual(monk["aptitude"], aptitude + (10 if modified else 0))
                self.assertIn(101 if modified else 14, [m["id"] for m in monk["magic"]])
                self.rejects_unchanged(g, "interact", slot=19)
                q = picture(23)
                self.assertEqual(amount(q["state"], 99), 1 if modified else 2)
                monk = next(r for r in q["state"]["party"] if r["id"] == 49)
                self.assertIn(14, [m["id"] for m in monk["magic"]])
                self.rejects_unchanged(g, "interact", slot=23)
                g.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--mod", required=True, type=Path)
    args, rest = parser.parse_known_args()
    DragonRepairTests.executable = args.executable.resolve()
    DragonRepairTests.mod = args.mod.resolve()
    temp_root = ROOT / "tmp"
    temp_root.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="repairs-", dir=temp_root) as scratch:
        DragonRepairTests.scratch = Path(scratch)
        unittest.main(argv=[sys.argv[0], *rest], verbosity=2)
