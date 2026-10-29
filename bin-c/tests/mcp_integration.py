"""Real stdio MCP regressions against the supplied unmodified kys-Dragon.

Run with --executable and --mod. Assets are external, never part of the tests.
All generated checkpoint files live under the repository's ignored tmp/ root
and are removed even when a test fails. Debug fixtures are explicitly named.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import struct
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from mcp_client import Game


def amount(state, item):
    return sum(i["quantity"] for i in state["inventory"] if i["id"] == item)


def party(state):
    return [r["id"] for r in state["party"]]


class DragonIntegration(unittest.TestCase):
    executable: Path
    mod: Path
    scratch: Path

    def game(self, *, debug=False, save_dir=None, seed=7, mod=None, allow_legacy_checkpoints=False):
        g = Game(self.executable, mod or self.mod, debug=debug, save_dir=save_dir,
                 allow_legacy_checkpoints=allow_legacy_checkpoints)
        self.addCleanup(g.close)
        q = g.call("new_game", seed=seed)
        self.assertIsNone(q["state"]["pending"])
        return g, q

    def rejects_unchanged(self, g, tool, **args):
        before = g.call("state")
        with self.assertRaises(RuntimeError):
            g.call(tool, **args)
        self.assertEqual(before, g.call("state"))

    def training(self, g):
        g.call("navigate", x=31, y=41)
        g.call("travel", scene=36)
        q = g.call("interact", slot=4, item=234)
        self.assertEqual(amount(q["state"], 234), 0)
        self.assertEqual(amount(q["state"], 134), 1)
        g.call("interact", slot=6)
        q = g.call("use_item", item=134)
        self.assertEqual(q["state"]["pending"]["title"], "誰要修煉")
        self.rejects_unchanged(g, "choose")
        return g.call("choose", index=0)

    def test_opening_protocol_and_input_atomicity(self):
        g, q = self.game()
        self.assertGreater(len(q["messages"]), 100)
        self.assertEqual(q["state"]["scene"], 70)
        self.assertEqual(amount(q["state"], 174), 400)
        self.assertEqual(amount(q["state"], 234), 1)
        self.assertEqual(len(g.call("inspect_scene")["events"]), 6)
        tools = g.rpc("tools/list")["tools"]
        choose = next(t for t in tools if t["name"] == "choose")
        self.assertEqual(choose["inputSchema"]["required"], ["index"])
        for name, args in (("navigate", {"x": 99, "y": 0}),
                           ("debug", {"scene": 0}),
                           ("use_item", {"item": 202}),
                           ("navigate", {"x": True, "y": 1})):
            self.rejects_unchanged(g, name, **args)
        q = g.call("navigate", x=31, y=41)
        self.assertFalse(q["action_result"]["reached"])
        self.assertEqual(q["state"]["where"], 0)
        self.rejects_unchanged(g, "travel", scene=2)
        self.rejects_unchanged(g, "travel", scene=0)

    def test_native_training_items_loss_manual_and_replay(self):
        g, _ = self.game()
        self.training(g)
        idle = g.call("state")
        g.call("checkpoint", action="save", label="before_battle")
        g.call("interact", slot=0)
        q = g.call("choose", index=1)
        self.assertEqual(q["state"]["pending"]["kind"], "battle_turn")
        before_inspect = g.call("state")
        observed = g.call("inspect_battle", radius=2)
        self.assertEqual(g.call("state"), before_inspect)
        self.assertEqual(observed, g.call("inspect_battle", radius=2))
        self.assertEqual(observed["actor"], q["state"]["pending"]["actor"])
        self.assertEqual(len(observed["magic"]), len(observed["role"]["magic"]))
        self.assertTrue(observed["reachable"])
        self.assertLessEqual(len(observed["tiles"]), 25)
        for x, y, cost in observed["reachable"]:
            self.assertGreater(cost, 0)
            self.assertLessEqual(cost, observed["battle"]["actors"][observed["actor"]]["step"])
        self.rejects_unchanged(g, "choose", index=-1)
        self.rejects_unchanged(g, "checkpoint", action="save", label="busy")
        self.rejects_unchanged(g, "battle_action", action="move", x=99, y=1)
        medicine = amount(q["state"], 1)
        q = g.call("battle_action", action="consume", item=1)
        self.assertEqual(amount(q["state"], 1), medicine - 1)
        effect = q["effects"][0]
        self.assertGreater(effect["after"]["hp"][0], effect["before"]["hp"][0])
        q = g.call("choose", index=2)
        self.assertEqual(q["state"]["where"], 1)
        self.assertTrue(any("lost" in m["text"] for m in q["messages"]))
        magic = q["state"]["party"][0]["magic"][0]
        self.assertEqual(magic["id"], 27)
        self.assertEqual(magic["slot"], 0)
        detail = g.call("search", kind="magic", id=27)["results"][0]
        self.assertEqual(detail["area_type"], 1)
        self.assertEqual(len(detail["levels"]), 10)
        g.call("interact", slot=0)
        q = g.call("choose", index=1)
        idx = q["state"]["pending"]["actor"]
        observed = g.call("inspect_battle", radius=0)
        self.assertTrue(observed["magic"])
        x, y, cost = min(observed["reachable"], key=lambda t: t[2])
        q = g.call("battle_action", action="move", x=x, y=y)
        self.assertEqual(q["state"]["pending"]["kind"], "battle_turn")
        actor = next(a for a in q["state"]["battle"]["actors"] if a["index"] == idx)
        enemy = next(a for a in q["state"]["battle"]["actors"] if a["team"] == 1 and not a["dead"])
        ax, ay = actor["xy"]; ex, ey = enemy["xy"]
        x, y = (ax, ay+(1 if ey>ay else -1)) if ey!=ay else (ax+(1 if ex>ax else -1), ay)
        q = g.call("battle_action", action="attack", magic_slot=magic["slot"], x=x, y=y)
        self.assertTrue(q["effects"])
        if q["state"]["pending"]:
            q = g.call("choose", index=2)
        self.assertEqual(q["state"]["where"], 1)
        g.call("checkpoint", action="load", label="before_battle")
        self.assertEqual(g.call("state"), idle)

    def test_guide_north_chou_silver_for_shovel(self):
        g, _ = self.game()
        g.call("interact", slot=4)
        q = g.call("interact", slot=4, item=174)
        self.assertEqual(amount(q["state"], 174), 395)
        self.assertEqual(amount(q["state"], 195), 1)
        self.assertEqual({i["id"]:i["delta"] for i in q["changes"]["items"]}, {174:-5, 195:1})

    def test_native_world_approach_and_return_facing(self):
        g, _ = self.game()
        g.call("navigate", x=31, y=41)
        q = g.call("travel", scene=36)
        self.assertTrue(q["action_result"]["reached"])
        self.assertGreater(q["action_result"]["world_steps"], 1)
        self.assertEqual(q["state"]["world_xy"], [370,185])
        self.assertEqual(q["state"]["face"], 0)
        self.assertEqual(q["state"]["world_face"], 3)
        tile = g.call("inspect_world", x=369, y=185, radius=0)["tiles"][0]
        self.assertEqual(tile["entrance_scene"], 36)
        scene = g.call("inspect_scene")
        x,y = scene["exits"][0]
        q = g.call("navigate", x=x, y=y)
        self.assertEqual(q["state"]["where"], 0)
        self.assertEqual(q["state"]["xy"], [370,185])
        self.assertEqual(q["state"]["face"], 3)

    def test_debug_step_event_before_exit_and_keyboard_height(self):
        g, _ = self.game(debug=True)
        g.call("debug", scene=21, x=25, y=56)
        q = g.call("navigate", x=25, y=57)
        self.assertEqual(q["state"]["where"], 0)
        self.assertIn(440, {r[0] for r in q["trace"]})
        self.assertEqual(len(q["changes"]["events"]), 4)
        g.call("debug", scene=25, x=15, y=0)
        self.rejects_unchanged(g, "navigate", x=16, y=0)
        q = g.call("step", direction=3)
        self.assertEqual(q["state"]["xy"], [16,0])
        self.assertEqual(q["action_result"]["moved"], 1)
        self.assertEqual(g.call("inspect_scene", x=16, y=0)["tile"]["layers"][4], 36)

    def test_debug_zero_mp_native_manual_attack(self):
        g, _ = self.game(debug=True)
        g.call("debug", scene=79, field=63, value=1)  # known 羅漢拳
        g.call("debug", field=41, value=0)           # MP=0
        g.call("debug", field=44, value=999)         # act before enemy
        g.call("debug", script=20)
        q = g.call("choose", index=1)
        actor = next(a for a in q["state"]["battle"]["actors"] if a["index"]==q["state"]["pending"]["actor"])
        q = g.call("battle_action", action="attack", magic_slot=0, x=actor["xy"][0], y=actor["xy"][1])
        effect = q["effects"][0]
        self.assertEqual(effect["before"]["mp"][0], 0)
        self.assertEqual(effect["after"]["mp"][0], 0)
        self.assertGreater(effect["after"]["magic"][0]["proficiency"], 0)

    def test_debug_battle_observation_purity_and_line_effects(self):
        g, _ = self.game(debug=True)
        for field, value in ((63, 27), (73, 999), (43, 300), (44, 999),
                             (17, 999), (18, 999), (41, 999)):
            g.call("debug", field=field, value=value)
        g.call("checkpoint", action="save", label="line_fixture")
        outcomes = []
        for observe in (True, False):
            g.call("checkpoint", action="load", label="line_fixture")
            q = g.call("debug", scene=79, script=20)
            if q["state"]["pending"]["kind"] == "party":
                q = g.call("choose", index=1)
            if observe:
                before = g.call("state")
                b = g.call("inspect_battle", radius=0)
                self.assertEqual(before, g.call("state"))
                actor = b["battle"]["actors"][b["actor"]]
                enemy = next(a for a in b["battle"]["actors"] if a["team"] == 1 and not a["dead"])
                ex, ey = enemy["xy"]
                candidates = [[*actor["xy"], 0]] + b["reachable"]
                positions = [p for p in candidates
                             if (p[0] == ex or p[1] == ey)
                             and 1 < abs(p[0]-ex)+abs(p[1]-ey) <= 7]
                x, y, cost = min(positions, key=lambda p: p[2])
                ax = x + (1 if ex > x else -1 if ex < x else 0)
                ay = y + (1 if ey > y else -1 if ey < y else 0)
            if cost:
                g.call("battle_action", action="move", x=x, y=y)
            if observe:
                # Inspect another actor after moving: its first-move envelope
                # must not replace the player's preserved split-move envelope.
                before = g.call("state")
                g.call("inspect_battle", actor=enemy["index"], radius=0)
                g.call("inspect_battle", radius=1)
                self.assertEqual(before, g.call("state"))
            q = g.call("battle_action", action="attack", magic_slot=0, x=ax, y=ay)
            effect = q["effects"][0]
            self.assertIsNone(effect["target_before"])  # direction tile is empty
            damaged = next(a for a in effect["affected"] if a["role"] == enemy["role"])
            self.assertLess(damaged["after"]["hp"][0], damaged["before"]["hp"][0])
            outcomes.append((q["state"], q["effects"]))
            while q["state"]["pending"]:
                p = q["state"]["pending"]
                index = 2 if p["kind"] == "battle_turn" else 1 if p["kind"] == "party" else 0
                q = g.call("choose", index=index)
        self.assertEqual(*outcomes)

    def test_durable_checkpoint_and_corruption(self):
        saves = self.scratch / "saves"
        g, _ = self.game(save_dir=saves)
        g.call("checkpoint", action="save", label="start")
        saved = g.call("state")
        g.close()
        h, _ = self.game(save_dir=saves, seed=99)
        h.call("checkpoint", action="load", label="start")
        self.assertEqual(h.call("state"), saved)
        bad = saves / "bad.kys-save"
        data = bytearray((saves / "start.kys-save").read_bytes())
        data[-16] ^= 1
        bad.write_bytes(data)
        self.rejects_unchanged(h, "checkpoint", action="load", label="bad")
        self.rejects_unchanged(h, "checkpoint", action="save", label="../escape")

    def test_incomplete_gameplay_runtime_rejected_before_start(self):
        mod = self.scratch / "incomplete-runtime"
        shutil.copytree(self.mod, mod)
        files = ("list/leave.bin", "list/levelup.bin", "list/match.bin", "list/effect.bin",
                 "resource/earth.002", "resource/surface.002", "resource/building.002",
                 "resource/buildx.002", "resource/buildy.002")
        for relative in files:
            with self.subTest(missing=relative):
                path = mod / relative
                original = path.read_bytes()
                path.unlink()
                try:
                    with Game(self.executable, mod) as g:
                        with self.assertRaisesRegex(RuntimeError, relative):
                            g.call("new_game", seed=7)
                        path.write_bytes(original)
                        # Correcting the runtime permits a true start in the
                        # same process, with native opening stats rather than
                        # the missing-table jump to level 60.
                        q = g.call("new_game", seed=7)
                        self.assertEqual(q["state"]["party"][0]["level"], 1)
                finally:
                    path.write_bytes(original)
        path = mod / "list/levelup.bin"
        original = path.read_bytes()
        path.write_bytes(original[:2])
        try:
            with Game(self.executable, mod) as g:
                with self.assertRaisesRegex(RuntimeError, "Unexpected gameplay file size"):
                    g.call("new_game", seed=7)
        finally:
            path.write_bytes(original)

    def test_checkpoint_rejects_changed_rules_and_world(self):
        mod = self.scratch / "rules-identity"
        saves = self.scratch / "rules-identity-saves"
        shutil.copytree(self.mod, mod)
        g, _ = self.game(mod=mod, save_dir=saves)
        g.call("checkpoint", action="save", label="original")
        g.close()
        for relative in ("list/leave.bin", "list/levelup.bin", "list/match.bin", "list/effect.bin",
                         "resource/earth.002", "resource/surface.002", "resource/building.002",
                         "resource/buildx.002", "resource/buildy.002"):
            with self.subTest(changed=relative):
                path = mod / relative
                original = path.read_bytes()
                altered = bytearray(original)
                altered[0] ^= 1
                path.write_bytes(altered)
                try:
                    h, _ = self.game(mod=mod, save_dir=saves, allow_legacy_checkpoints=True)
                    self.rejects_unchanged(h, "checkpoint", action="load", label="original")
                    h.close()
                finally:
                    path.write_bytes(original)

    def test_legacy_checkpoint_import_is_explicit_and_lineage_persists(self):
        saves = self.scratch / "legacy-saves"
        g, _ = self.game(save_dir=saves)
        g.call("checkpoint", action="save", label="modern")
        saved = g.call("state")
        g.close()
        data = (saves / "modern.kys-save").read_bytes()
        self.assertEqual(struct.unpack_from("<Q", data, 8)[0], 3)
        # V2 has the same native payload, without V3's final lineage word.
        # A false lineage word XORs zero into the checksum, so stripping it
        # reconstructs the historical format without altering native state.
        legacy = bytearray(data[:-16] + data[-8:])
        identity = 14695981039346656037
        for relative in ("kysmod.ini", "save/ranger.idx", "save/ranger.grp", "save/allsin.grp",
                         "save/alldef.grp", "resource/kdef.idx", "resource/kdef.grp",
                         "resource/talk.idx", "resource/talk.grp", "resource/war.sta",
                         "resource/warfld.idx", "resource/warfld.grp"):
            for value in (self.mod / relative).read_bytes():
                identity = ((identity ^ value) * 1099511628211) & ((1 << 64) - 1)
        struct.pack_into("<QQ", legacy, 8, 2, identity)
        (saves / "legacy.kys-save").write_bytes(legacy)
        h, _ = self.game(save_dir=saves)
        self.rejects_unchanged(h, "checkpoint", action="load", label="legacy")
        h.close()
        h, _ = self.game(save_dir=saves, allow_legacy_checkpoints=True)
        q = h.call("checkpoint", action="load", label="legacy")
        self.assertEqual(q["checkpoint_format"], 2)
        self.assertTrue(q["legacy_checkpoint_lineage"])
        saved["legacy_checkpoint_lineage"] = True
        self.assertEqual(q["state"], saved)
        h.call("checkpoint", action="save", label="migrated")
        h.close()
        h, _ = self.game(save_dir=saves)
        q = h.call("checkpoint", action="load", label="migrated")
        self.assertEqual(q["checkpoint_format"], 3)
        self.assertTrue(q["state"]["legacy_checkpoint_lineage"])
        self.assertEqual(q["state"], saved)

    def test_durable_branch_labels_beyond_memory_cache(self):
        saves = self.scratch / "many_branches"
        g, _ = self.game(debug=True, save_dir=saves)
        for index in range(14):
            g.call("debug", field=56, value=40 + index)
            g.call("checkpoint", action="save", label=f"branch_{index:02}")
        self.assertEqual(len(list(saves.glob("*.kys-save"))), 14)
        for index in (0, 13, 1):
            q = g.call("checkpoint", action="load", label=f"branch_{index:02}")
            self.assertEqual(q["state"]["party"][0]["ethics"], 40 + index)
        g.close()
        h, _ = self.game(save_dir=saves)
        q = h.call("checkpoint", action="load", label="branch_00")
        self.assertEqual(q["state"]["party"][0]["ethics"], 40)

    def test_debug_native_party_medicine_and_detox(self):
        g, _ = self.game(debug=True)
        for field, value in ((18, 200), (17, 50), (19, 40), (20, 60),
                             (46, 80), (48, 30), (21, 73)):
            g.call("debug", field=field, value=value)
        before = g.call("state")
        self.rejects_unchanged(g, "party_action", action="unknown")
        q = g.call("party_action", action="detox")
        self.assertIsNotNone(q["state"]["pending"])
        q = g.call("choose", index=0)  # actor
        self.assertIsNotNone(q["state"]["pending"])
        q = g.call("choose", index=0)  # recipient
        self.assertIsNone(q["state"]["pending"])
        self.assertEqual(q["state"]["party"][0]["poison"], 30)
        self.assertEqual(q["state"]["party"][0]["stamina"], 73)
        g.call("party_action", action="medicine")
        g.call("choose", index=0)
        q = g.call("choose", index=0)
        healed = q["state"]["party"][0]
        self.assertGreater(healed["hp"][0], before["party"][0]["hp"][0])
        self.assertLess(healed["injury"], 40)
        self.assertEqual(healed["stamina"], 73)
        self.assertEqual(q["state"]["inventory"], before["inventory"])
        unchanged = g.call("state")
        g.call("party_action", action="medicine")
        q = g.call("choose", index=-1)
        self.assertEqual(q["state"], unchanged)

    def test_debug_guide_hu_fei_tian_branch_and_party_mask(self):
        g, _ = self.game(debug=True)
        self.rejects_unchanged(g, "debug", scene=0, x=999)
        g.call("debug", scene=0)
        g.call("interact", slot=4)
        q = g.call("choose", index=1)
        self.assertEqual(party(q["state"]), [0, 1])
        self.assertEqual(amount(q["state"], 202), 1)
        g.call("debug", scene=3)
        g.call("checkpoint", action="save", label="branch")
        g.call("interact", slot=17)
        q = g.call("choose", index=1)
        self.assertEqual(party(q["state"]), [0, 72])
        g.call("checkpoint", action="load", label="branch")
        g.call("interact", slot=17)
        q = g.call("choose", index=0)
        self.assertEqual(party(q["state"]), [0, 1])
        q = g.call("debug", scene=79, script=20)
        self.assertEqual(q["state"]["pending"]["available_mask"], 3)
        self.rejects_unchanged(g, "choose", index=4)
        q = g.call("choose", index=3)
        self.assertEqual({a["role"] for a in q["state"]["battle"]["actors"] if a["team"]==0}, {0, 1})

    def test_debug_guide_di_yun_ethics_boundary(self):
        g, _ = self.game(debug=True)
        g.call("checkpoint", action="save", label="start")
        for ethics in (69, 70):
            g.call("checkpoint", action="load", label="start")
            g.call("debug", scene=65, field=56, value=ethics)
            g.call("interact", slot=1)
            q = g.call("choose", index=1)
            self.assertEqual(37 in party(q["state"]), ethics==70)
            self.assertEqual(amount(q["state"], 59), 1 if ethics==70 else 0)

    def test_debug_blocked_entry_candidates_are_escapable(self):
        g, _ = self.game(debug=True)
        for sid, inside in ((94, (42, 24)), (2, (48, 28))):
            g.call("debug", scene=sid)
            q = g.call("navigate", x=inside[0], y=inside[1])
            self.assertTrue(q["action_result"]["reached"])
            scene = g.call("inspect_scene")
            ex, ey = scene["exits"][0]
            q = g.call("navigate", x=ex, y=ey)
            self.assertEqual(q["state"]["where"], 0)

    def test_pristine_data_audit(self):
        g, _ = self.game()
        q = g.call("audit")
        self.assertEqual([v["item"] for v in q["item_name_control_characters"]], [88, 89, 178])
        self.assertEqual(q["invalid_script_references"], [])
        from dragon_audit import audit, repair_names, validate_outputs
        report, _, original = audit(self.mod)
        self.assertEqual(report["script_issues"], [])
        self.assertEqual(report["invalid_triggers"], [])
        # Even diagnostic outputs must not overwrite the reference or each other.
        for output in (self.mod / "save/ranger.grp", self.mod / "new-report.json"):
            with self.assertRaises(ValueError):
                validate_outputs(self.mod, {"report": output})
        with self.assertRaises(ValueError):
            validate_outputs(self.mod, {"report": self.scratch / "same",
                                        "scripts": self.scratch / "same"})
        existing = self.scratch / "existing-repair"
        existing.write_bytes(b"preserve")
        with self.assertRaises(ValueError):
            validate_outputs(self.mod, {"repair_names": existing})
        self.assertEqual(existing.read_bytes(), b"preserve")
        repaired, _ = repair_names(original, report["item_name_defects"])
        self.assertEqual(sum(a!=b for a,b in zip(original, repaired)), 12)
        self.assertEqual((self.mod / "save/ranger.grp").read_bytes(), original)

    def test_debug_lingjiu_picture_counter_original_and_repaired(self):
        from dragon_audit import audit, repair_pictures
        originals = {name: (self.mod / name).read_bytes()
                     for name in ("save/alldef.grp", "resource/kdef.idx", "resource/kdef.grp")}
        files, patch = repair_pictures(*originals.values())
        self.assertEqual((patch["after"], patch["reward_script"]), (1087, 1094))
        self.assertEqual(patch["changed_event_bytes"], 2)
        self.assertEqual(patch["appended_index_bytes"], 32)
        self.assertEqual(patch["appended_script_bytes"], 102)
        for name in ("resource/kdef.idx", "resource/kdef.grp"):
            self.assertTrue(files[name].startswith(originals[name]))
        with self.assertRaises(ValueError):
            repair_pictures(files["save/alldef.grp"], originals["resource/kdef.idx"],
                            originals["resource/kdef.grp"])
        with self.assertRaises(ValueError):
            repair_pictures(originals["save/alldef.grp"], originals["resource/kdef.idx"],
                            originals["resource/kdef.grp"] + b"\0\0")
        repaired_mod = self.scratch / "pictures-repaired-mod"
        shutil.copytree(self.mod, repaired_mod)
        for name, data in files.items():
            (repaired_mod / name).write_bytes(data)
        report, _, _ = audit(repaired_mod)
        self.assertEqual(report["script_issues"], [])
        self.assertEqual(report["invalid_triggers"], [])
        ascending = (15, 16, 17, 18, 20, 21, 22)
        for modified, order in ((False, ascending), (True, ascending),
                                (True, tuple(reversed(ascending)))):
            with self.subTest(repaired=modified, order=order):
                g, _ = self.game(debug=True, mod=repaired_mod if modified else self.mod)
                # Explicit scene/ethics fixture; not campaign progression evidence.
                g.call("debug", scene=60, field=56, value=80)
                g.call("interact", slot=15)
                q = g.call("choose", index=1)
                self.assertIn(49, party(q["state"]))
                aptitude = next(r for r in q["state"]["party"] if r["id"] == 49)["aptitude"]

                def interact_picture(slot):
                    scene = g.call("inspect_scene", scene=12)
                    event = next(e for e in scene["events"] if e["slot"] == slot)
                    x, y = event["xy"]
                    # Place the fixture beside the actual event and still use
                    # normal event dispatch, not arbitrary script invocation.
                    g.call("debug", scene=12, x=x, y=y+1)
                    return g.call("interact", slot=slot)

                q = interact_picture(19)
                self.assertEqual(amount(q["state"], 79), 0)
                for count, slot in enumerate(order, 1):
                    interact_picture(slot)
                    if modified and count < 7:
                        q = interact_picture(19)
                        self.assertEqual(amount(q["state"], 79), 0)
                        self.assertEqual(amount(q["state"], 99), 0)
                q = interact_picture(19)
                monk = next(r for r in q["state"]["party"] if r["id"] == 49)
                self.assertEqual(amount(q["state"], 79), 1 if modified else 0)
                self.assertEqual(amount(q["state"], 99), 0 if modified else 1)
                self.assertEqual(monk["aptitude"], aptitude + (10 if modified else 0))
                self.assertIn(101 if modified else 14, [m["id"] for m in monk["magic"]])
                # The independent chest must retain its original reward.
                q = interact_picture(23)
                self.assertEqual(amount(q["state"], 99), 1 if modified else 2)
                self.rejects_unchanged(g, "interact", slot=23)
                self.rejects_unchanged(g, "interact", slot=19)
                g.close()
        for name, original in originals.items():
            self.assertEqual((self.mod / name).read_bytes(), original)

    def test_debug_chuang_saber_caves_original_and_repaired(self):
        from dragon_audit import audit, repair_saber_event
        report, _, _ = audit(self.mod)
        original = (self.mod / "save/alldef.grp").read_bytes()
        repaired, patch = repair_saber_event(original, report["item_trigger_candidates"])
        self.assertEqual(sum(a!=b for a,b in zip(original, repaired)), 2)
        self.assertEqual(patch["talk"]["offset"], 369780)
        self.assertEqual(patch["item"]["offset"], 369782)
        with self.assertRaises(ValueError):
            repair_saber_event(repaired, report["item_trigger_candidates"])
        with self.assertRaises(ValueError):
            repair_saber_event(original, [])
        # A distinct temporary mod copy proves the saved data repair loads and
        # works in the native interpreter. The reference assets stay untouched.
        repaired_mod = self.scratch / "saber-repaired-mod"
        shutil.copytree(self.mod, repaired_mod)
        (repaired_mod / "save/alldef.grp").write_bytes(repaired)
        for modified, mod in ((False, self.mod), (True, repaired_mod)):
            g, _ = self.game(debug=True, mod=mod)
            g.call("debug", scene=0)
            g.call("interact", slot=4)
            q = g.call("choose", index=1)
            self.assertEqual(amount(q["state"], 202), 1)
            g.call("checkpoint", action="save", label="with_saber")
            for scene in (5, 84, 85):
                with self.subTest(repaired=modified, scene=scene):
                    g.call("checkpoint", action="load", label="with_saber")
                    g.call("debug", scene=scene, x=22, y=20)
                    gate = next(e for e in g.call("inspect_scene")["events"] if e["slot"]==8)
                    broken = scene==84 and not modified
                    self.assertEqual((gate["talk"], gate["item"]), (18,0) if broken else (0,18))
                    self.rejects_unchanged(g, "navigate", x=21, y=21)
                    # A different owned plot item must not unlock the door.
                    g.call("interact", slot=8, item=234)
                    self.rejects_unchanged(g, "navigate", x=21, y=21)
                    q = g.call("interact", slot=8, item=202)
                    self.assertEqual(amount(q["state"], 202), 1)
                    if broken:
                        self.assertEqual({row[0] for row in q["trace"]}, {0})
                        self.assertEqual(q["changes"]["events"], [])
                        self.rejects_unchanged(g, "navigate", x=21, y=21)
                        # Both engines retain CurItem: subsequent ordinary
                        # interaction can accidentally reach the misplaced gate.
                        q = g.call("interact", slot=8)
                        self.assertEqual({row[0] for row in q["trace"]}, {18})
                    else:
                        self.assertEqual({row[0] for row in q["trace"]}, {18})
                    self.assertTrue(g.call("navigate", x=21, y=21)["action_result"]["reached"])
            g.close()
        self.assertEqual((self.mod / "save/alldef.grp").read_bytes(), original)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--mod", required=True, type=Path)
    args, rest = parser.parse_known_args()
    DragonIntegration.executable = args.executable.resolve()
    DragonIntegration.mod = args.mod.resolve()
    temp_root = ROOT / "tmp"
    temp_root.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="integration-", dir=temp_root) as scratch:
        DragonIntegration.scratch = Path(scratch)
        unittest.main(argv=[sys.argv[0], *rest], verbosity=2)
