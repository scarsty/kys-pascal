# 苍龙逐日 investigation — 2026-10-29

The C++ rewrite builds with a native MCP frontend. A strict guide-driven
righteous campaign has earned all fourteen books and reached the actual native
ending. The alternate campaign and supplementary branch checks remain in
progress, so overall stability remains unverified. The route uses native
walking, item dispatch, choices, damage, recovery and rewards; no debug grants
or forced wins count as progression.

Shared C++ corrections, MCP frontend work, and mod audit/repair tools are
separate commits. The [source-fix record](CPP_FIXES.md) distinguishes Pascal
parity from deliberate fixes to defects shared by Pascal. The mod has three
malformed item names and the runtime-confirmed misplaced treasure-cave trigger.
Actual wrong-item play also reproduced the paired-saber possession behavior
detailed below; its author intent is unverified and no speculative patch is
applied. Original inputs remain unchanged.

The [campaign ledger](CAMPAIGN_VALIDATION.md) records completed routes and
remaining branches. Static checks missed a valid script in the wrong trigger
field; the earlier completion claim overstated the evidence. No computer use,
graphics inspection or graphical runtime validation was performed. Both
graphical and MCP targets compile.

## Reference inputs

- Repository: `https://github.com/scarsty/kys-pascal`, starting commit `e541bad`.
- Stable behavior reference: `bin-pas/kys_main.pas`, `kys_event.pas`, and
  `kys_battle.pas`, read alongside their C++ equivalents.
- Original supplied archive: `D:\Downloads\kys-pascal-n-in-1.7z`.
- Tested mod: extracted `kys-Dragon`, retained at `tmp/runtime/kys-Dragon`.
- Guide: `D:\Downloads\金庸mod攻略.chm`, article **苍龙逐曰完全攻略**,
  credited to 仙剑飞去来 and described as updated to version 1.2. The extracted
  article is GB18030, while the native game records require CP950.

The original archive and extracted reference mod remain unchanged. The
dependency and MCP setup also consulted `D:\projects\kys-cpp\kys-cpp`.

## Source fixes and parity evidence

| Finding | Before | After / evidence |
| --- | --- | --- |
| Scene entry condition 2 | C++ returned true unconditionally | Matches Pascal `CheckCanEnter`: an active teammate must have `Speed > 70`. Tests cover 70, 71, an empty party and plot locks. |
| Full inventory access | `instruct_32` read `RItemList[i]` before checking `i < MAX_ITEM_AMOUNT` | Bounds checked first; full inventory cannot read beyond the vector. Tests also cover removal, reuse and count saturation. The Pascal source contains the same ordering pattern; this is C++ memory-safety hardening, not evidence of a distinct quest rule. |
| Fixed-width CP950 fields | The C++ decoder ignored its length argument and relied on a later NUL | Length is honored; packed role/item/scene/magic name callers pass their actual byte capacity. Exact-width names cannot bleed into neighboring fields. Existing status-name calls that passed 5 are updated to the full 10-byte field to preserve display behavior. Pascal's decoder also ignores its optional length, so the bounds fix is deliberate hardening. |
| Event bytecode reads | Opcode operands and index-derived byte ranges could be read without validation | Shared interpreter rejects invalid byte ranges, opcodes and truncated operands before access. Native tests cover malformed ranges and truncated instructions. |
| Battle movement | Simplified C++ BFS omitted water, enemy-adjacency stopping and the initial envelope for split moves; path reconstruction could move despite a broken gradient | Restored active Pascal movement rules and preferred backtracking. Nine behavioral assertions fail before the fix and pass after it. Attack/skill mode 1 retains Pascal's Manhattan targeting. |
| Quest handover of equipped gear | Actual 金蛇劍40 handover removed inventory but retained equipment/user links in both versions | Last-unit owned equipment removal now clears matching links. Boundary cases and a native earned-state handover replay pass; partial stacks and practice books are preserved. |
| Hidden-weapon poison at resistance >100 | Actual battle176 produced poison0→−9 against resistance112; active Pascal has the same defect | Shared correction clamps the resistance factor to nonnegative and final poison to0–99. Seven boundary regressions pass; the exact earned-state replay keeps item1→0 and HP956→948 while poison stays0. |

Source locations: `bin-c/kys_main.cpp:CheckCanEnter`,
`bin-c/kys_event.cpp:instruct_32`, `bin-c/kys_engine.cpp:cp950toutf8`, and
`bin-c/kys_script.cpp:CallEvent`. Pascal's strict speed condition is in
`bin-pas/kys_main.pas:2229`. Its inclusive ethics comparison is in
`bin-pas/kys_event.pas:instruct_28`.

The native `CallEvent` VM moved into `kys_script.cpp`, and presentation/input
hooks live in `kys_frontend.h/.cpp`. A null frontend keeps the SDL path.
Graphics calls keep their original behavior when a real screen exists;
headless execution bypasses rendering/audio and supplies input at explicit
decision boundaries. Shared fixes apply to both executables.

## Confirmed mod name defects and repair

| Item ID | Original decoded name | Repaired name | Name-field byte offset in ranger.grp |
| --- | --- | --- | --- |
| 88 | `須彌山神掌\r\n` | `須彌山神掌` | 124756 |
| 89 | `七傷拳\r\n譜` | `七傷拳譜` | 124946 |
| 178 | `大剪刀\r\n刀法` | `大剪刀刀法` | 141856 |

The repair removes embedded control characters and pads the same fixed
20-byte name fields. It retains all other bytes, including IDs and record
offsets. **Only 12 bytes differ** in the complete file. The output is retained
at `tmp/repairs/ranger.grp` and can be regenerated by `tools/dragon_audit.py`.
It has not been installed into the reference mod.

- Original `ranger.grp` SHA-256:
  `272f5d0300a49fe1e08afdc8da1873695998d4c88f79330f66e6874646553aaa`
- Repaired `ranger.grp` SHA-256:
  `ee097b46bd47f56b9fcda67c25a5c8a5250adf05fea9ac9cee18435091febe44`

CP950 extensions matter: 恒山派 contains valid extended 恒 bytes `F9 DA`.
Generic Big5 decoding falsely classified that scene name as corrupt. It is
not repaired. The literal `大剪刀刀法` is retained rather than editorially
renamed; removing CRLF is the supported correction.

## Static scan results

The supplied dataset contains 589 roles, 237 items, 106 scenes, 114 martial
arts, 5 shops, 1,087 scripts, 4,020 dialogue records and 227 battles.
The scan found **zero script-layout/common-reference issues** and **zero
invalid initial scene trigger references** after checking instruction widths,
static branch boundaries, common item/dialogue/battle/recruit operands and
scene talk/item/step script IDs. This does not prove all event conditions,
dynamic opcode-50 references or quest sequencing are correct.

The follow-up semantic scan now also flags talk scripts that begin by checking
the used item while the item-use trigger routes elsewhere. It finds two
candidates: scene 84/slot 8 (the confirmed saber defect below), and scene
10/slot 0 (script 372 checks 玄冰碧火酒 203; not runtime-verified or repaired).
These are valid script IDs in the wrong possible trigger context, so the
initial bounds/reference scan alone could not detect them.

Script 280 demonstrates a legitimate branch past an embedded negative
terminator into another block of the same record. The audit continues
decoding such records; treating the first terminator as the whole record's
end would produce a false positive.

## Guide comparisons exercised through actual MCP calls

| Guide claim / scenario | Observed native behavior | Evidence scope |
| --- | --- | --- |
| 北丑 asks for 5 silver and gives a shovel | Talk changes his item trigger; giving silver consumes exactly 5 and awards 鐵鏟 195 | Normal scene navigation and native item-use event |
| Introduction letter chooses a weapon school | Giving letter 234 to 青城派 consumes it and awards 松風劍法 134; practice uses a character selector | Normal route from 小村 using explicit world-travel shortcut |
| Training provides real fighting and practice | 青城練功 battle 219 loses naturally and returns through its survivable loss branch; practice teaches magic 27; a later manually directed native attack wins | Native battle data, AI, damage, item use, book learning and event branch |
| 胡斐 joins with 闖王軍刀 | Role 1 joins and item 202 is awarded after the explicit invitation | Debug scene entry fixture; normal house unlock is not established |
| Accepting 田歸農 removes 胡斐 | Accept produces party `[0,72]`; refuse preserves `[0,1]` | Native inn event after debug recruitment fixture, replayed from checkpoint |
| 狄云 requires ethics greater than 70 and gives 烏蠶衣 | Ethics 69 fails, **70 succeeds**, role 37 and item 59 awarded | Debug ethics/scene fixtures; script 39 accepts inclusive 70–100 |
| Multiple battle participants | Native roster prompt accepts party bitmask 3 and includes both protagonist and 胡斐; empty slot 4 rejects | Debug battle fixture; native initialization and selection |

The 狄云 threshold is a small guide discrepancy. The actual mod and Pascal's
inclusive range opcode agree, so no gameplay patch was made. The guide also
spells the armor 乌蝉衣; the item data is 烏蠶衣.

The basic practice book's rapid learning initially looked suspicious. Actual
item 134 has `NeedExp=0`, and Pascal `CheckBook` uses the same formula and
learning loop as C++. This is retained as stable mod behavior.

## Confirmed follow-up: 闖王軍刀 fails in one treasure cave

The user supplied a report that one of two caves had the key event configured
as trigger type 1 instead of type 2. This is reproducible in the supplied
unmodified mod. The numbers refer to **ordinary interaction versus item use**,
not to changing bytecode script ID 1 to script ID 2.

| Scene | Public world coordinate | Slot / native tile | Ordinary interaction script | Item-use script | Native result when using item 202 |
| --- | --- | --- | --- | --- | --- |
| 84 山洞 | `(24,16)` | 8 / `(21,20)` | **18** | **0** | Executes empty script 0; door stays blocked |
| 85 山洞 | `(45,34)` | 8 / `(21,20)` | 0 | **18** | Executes script 18; door opens |
| 5 legacy 山洞 record | `(64,51)` | 8 / `(21,20)` | 0 | **18** | Also opens correctly |

Script 18 checks `CurItem == 202` (闖王軍刀), clears its event record, and sets
the building layer at native `(21,21)` to zero, opening the doorway. Pascal
`UseItem` and C++ `UseItem` both dispatch plot-item use through
`DData[scene][slot][3]`; ordinary interaction dispatches through field 2.
Scene 84 placed script 18 in field 2, while field 3 points to empty script 0.
This is a confirmed **mod event-data defect**, not a C++ dispatch regression.

The separate repair `tmp/repairs/alldef.grp` changes only field 2 from 18→0
and field 3 from 0→18, preserving blocking and every other record field.
Record offset is 369776; the field offsets are **369780** and **369782**.
The two 16-bit field changes alter **only 2 bytes** in the complete file.

- Original `alldef.grp` SHA-256:
  `6ab5976dabc2053ff8039b756710e1446d14b30bb8189ecf303cd9bf10466d50`
- Repaired `alldef.grp` SHA-256:
  `10234b3e3d01f418e4110601542da965f15ab0ee2e92a4dac36f5367519fdbc4`

The regression obtains the saber through native 胡斐 recruitment, then uses
explicit debug fixtures only to reach the locked cave doors without playing
the intervening fights. Before item use, navigating through `(21,21)` fails.
On the pristine scene 84, using the saber leaves it blocked and traces script
0. On scenes 5 and 85, the same action traces script 18 and permits passage.
A separate temporary mod copy with only the two-byte repair makes all three
caves work. A different owned plot item does not open any door, and the saber
is retained. The reference mod is checked unchanged after the test.

There is also an incidental workaround in this C++ build: use the saber at
the broken door, then perform ordinary interaction once. Both native source
versions retain `CurItem` after `UseItem`, so the misplaced ordinary-interact
script can then pass its item test. This sequence was reproduced through MCP;
it does not make the original trigger routing correct.

Subsequent strict campaigns reached **all three original variants** through
ordinary world travel, native guard fights and wealth-dependent map selection.
Script16 chooses map225/scene5 at≥10000silver, map226/scene84 at≥5000, and
map227/scene85 below5000. In scene84, both wrong compass and current-facing
saber dispatched empty0 and left the door blocked; ordinary talk afterwards
opened it through the misplaced18. Failure, workaround and later chest rewards
have distinct transcript entries. Scene5 and85 current-facing saber uses
opened the gate normally and awarded book145, 鴛刀217, 金絲背心60 and1000silver.
These actual progression records are retained under `tmp/campaign/sidequests/`.
A separate fresh repaired-mod campaign has now passed scene84 without imports
or debug actions: map226 at RPC855, guard wins at886/903, wrong compass906
inert, current-facing saber907 opened the doorway, and rewards908–911 gave
145/217/60/+1000. Repeat chest912 gave nothing. That run used complete original
rule/map tables with only the two-byte event repair. Its provenance, transcript
and `fresh84_repaired_looted` checkpoint are under
`tmp/campaign/sidequests/patched/`. The debug fixture remains separate evidence.

The forum's new-game caveat is consistent with the save layout. `alldef.grp`
is the initial event template loaded by `LoadR(0)`. Existing graphical saves
load `d1.grp`, `d2.grp`, etc., so replacing only `alldef.grp` does not update
their already-saved event records. Old save files were not patched. MCP
checkpoints also preserve their own event state and check the mod fingerprint.

## Actual-play finding: wrong selected item places the paired sabers

The guide instructs the player to place 鴛刀217 and 鴦刀218 in their separate
slots in scene79. Both proper-item orders work. With both blades legitimately
owned, using the unrelated compass182 also consumes the corresponding blade
and opens the gate. Independent current-facing input reproduced it; the MCP
does not substitute a blade for the requested compass.

Scripts203/205 and their second-placement counterparts204/206 use opcode18
(inventory possession), while opcode4 tests the selected `CurItem`. C++ and
Pascal implement opcode18 identically. This is a confirmed mod-script behavior
and guide mismatch; author intent is not established. No repair is applied.
A selected-item correction would have to cover all four scripts, both blade
orders, wrong items and final rewards rather than change only the first two.

Evidence: `tmp/campaign/sidequests/paired-saber/` preserves exact imported
earned-checkpoint provenance, transcript and independent review. RPC8–9
placed both knives using compass182. RPC14 used only current-facing compass
at the other initial slot, then15 opened the gate in reverse order. After
restoring the earned pre-item checkpoint, intended blades at19–20 worked.
The source checkpoint was V2, explicitly imported with visible legacy lineage.
The alternate campaign independently reproduced the same wrong-item behavior.

## Coordinate candidates investigated without speculative patches

| Scene | Observation | Runtime check / disposition |
| --- | --- | --- |
| 94 長樂幫 | Entry internal `(43,24)` is on building tile 3084 and fails destination passability | From the exact spawn, native navigation reaches `(42,24)` and `(43,25)`, and exits `(44,24)` / `(44,25)`. It is not a trapped spawn. Its plot gate was bypassed explicitly for this fixture. No coordinate repair. |
| 2 雪山 | Entry `(49,28)` overlaps blocking event slot 1, step script 41 | Moving away to `(48,28)` or `(50,28)` and reaching exits works. Actual `travel` retains its entry step event. This overlap is insufficient evidence of a defect. No coordinate repair. |
| 98 明霞島 | Guide says public world `(390,173)`; data says `(389,173)` | One-tile discrepancy may describe an adjacent approach tile; world walking was not validated. The scene spawn itself has walkable neighbors and an exit. No coordinate repair. |

Coordinates in this table are native internal axes except the explicitly
public world coordinates. The MCP exposes both conventions.

## Independent usability review

The requested independent subagent used the actual Release executable and
unmodified mod through stdio JSON-RPC, with no computer use. Its final trial
passed **22 checks**, with no remaining blocker in the tested surface. It
found the interface compact and usable for items, branches, scenes and native
combat. 小村 inspection returns six active objects, about 989 wire bytes in
the reviewed build, instead of a large inactive-object dump.

Issues found during that independent review were corrected: ambiguous gate
errors, inactive clutter, lost practice-menu context, mutation before debug
validation, unsupported cancellation/missing choice indices, Glaze boolean
access, manual-to-AI mode restoration and healing hidden by later enemy damage.
The immediate medicine effect now exposes HP 44→46 even when the next enemy
hit returns it to 44. The review's suggested named magic costs/ranges/target
conventions and actual slot IDs have also been added.

The independent reviewer did not exercise every combat action: poison,
detox, hidden weapons and teammate healing remain outside its trial. It also
did not complete the campaign. Idle-only checkpoints and explicit debug
fixtures are documented limits, not claims of normal quest progression.

A subsequent independent fidelity review actually played all original cave
variants and the fresh repaired scene84 route, then the hidden-room and
paired-saber branches. It found the strict MCP sufficient for those gates,
including current-facing wrong-item tests and manual combat. Full map knowledge
in travel validates only the executed approach; mouse navigation and keyboard
steps differ in native height rules. Ordinary round scheduling does not cover
graphical semi-real-time initiative. The final assessment is retained at
`tmp/campaign/fidelity/final-usability.md`.

## Validation and retained material

The repeatable asset-free core tests and eighteen-case Dragon integration suite
live under `bin-c/tests/`. Integration uses a real MCP handshake and checks
opening, invalid-input atomicity, native item exchanges/training combat,
checkpoint/RNG replay, fresh-process restore, corrupted-save rejection,
guide branch/ethics fixtures, escapable entry candidates, static audit /
12-byte name-repair invariants, the original/repaired saber-door behavior,
strict world approach/return, step-event-before-exit order, keyboard versus
mouse height rules, MP0 attacks, native out-of-battle treatment, and durable
branch labels beyond the memory cache, pure battle inspection versus replay,
and immediate line-attack target effects beyond an empty aim tile.
The latest cases also reject incomplete world/list tables before loading,
fingerprint all nine rule/map files, and enforce explicit legacy checkpoint
import with persistent lineage. An incomplete repaired-mod mirror previously
omitted level-up tables and silently produced a1→60 level jump; that attempt
is excluded, preserved separately, and restarted with the complete runtime.
It cleans up checkpoint files and the temporary repaired mod under `tmp/`.

Both CTest targets pass with eighteen real stdio integration cases. The
primary ending completed on campaign build0.2.7, SHA-256
`372DC2F44B4EFBC9DE8206233A77B0049AD002432BE70F974F9C9EAAFA415AB2`.
Earlier progress retains its own build identity and explicit checkpoint
lineage. The current validation rebuild also includes bounded scene-name
reads; SHA-256 is
`47A1C01338C1C8005D2079D9CF7EEF60195068E9DA2A5510D10C5831A29EB522`,
also recorded in `tmp/validation/build.json`.
The earlier eight-case
suite also passed in a separate MSVC AddressSanitizer build
(`/fsanitize=address /EHsc /O1 /Z7`), with no sanitizer findings in that
exercised surface. Subsequent native movement/input/recovery changes have
Release regression coverage; the historical sanitizer run does not cover
those later changes. The sanitizer runtime needed the MSVC
Hostx64/x64 directory on PATH. The diagnostic build is removed after its test
log is retained; this does not claim exhaustive memory-safety coverage.

Final test outputs and the audit report are retained under `tmp/validation/`.
The original extracted runtime/guide, separate repairs, campaign transcripts,
durable checkpoints and validation evidence are retained under the single
temporary root. One-off edit/probe scripts and diagnostic build outputs are
removed when no longer needed.
`tmp/` and Python caches are ignored. No game assets, guide content or build
outputs are added to Git. See [MCP.md](MCP.md) for the build, launch, tool
semantics, shortcuts and reproducible audit command.
