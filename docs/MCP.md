# Native MCP frontend for kys-pascal-c

`kys_mcp.exe` runs the C++ game through newline-delimited JSON-RPC on stdio.
It shares event execution, inventory, equipment, practice, scene passability,
entry gates and combat calculations with `kys.exe`. It creates no SDL window,
renderer, audio device or substitute screen. SDL libraries are still linked
because the shared native source uses SDL types and utility functions.

## Build on this Windows workspace

The tested checkout started at `e541bad`. The following uses the installed
vcpkg packages and mlcc checkout from the separate kys-cpp project:

```powershell
cmake -S bin-c -B bin-c/build -G 'Visual Studio 18 2026' -A x64 `
  '-DCMAKE_TOOLCHAIN_FILE=D:/projects/vcpkg/scripts/buildsystems/vcpkg.cmake' `
  '-DVCPKG_MANIFEST_MODE=OFF' `
  '-DVCPKG_INSTALLED_DIR=D:/projects/kys-cpp/kys-cpp/vcpkg_installed' `
  '-DMLCC_DIR=D:/projects/kys-cpp/kys-cpp/mlcc' `
  '-DKYS_TEST_MOD=D:/projects/kys-pascal/tmp/runtime/kys-Dragon'
cmake --build bin-c/build --config Release --parallel 6
ctest --test-dir bin-c/build -C Release --output-on-failure
```

MSVC 19.51 successfully builds the graphical game, MCP server, and core tests.
Use your installed generator and paths on another machine. For a fresh vcpkg
installation, omit `VCPKG_MANIFEST_MODE=OFF` and the reused installed directory;
`bin-c/vcpkg.json` declares SDL3, SDL3_ttf, SDL3_mixer with fluidsynth/mpg123,
libiconv, and Glaze at a pinned baseline. mlcc remains a separate dependency.
The fresh manifest dependency installation was not rerun here. Set
`KYS_BUILD_MCP=OFF` to build the original graphical target without Glaze.

The existing Visual Studio project includes the extracted shared sources;
CMake is the tested route for the new MCP executable and tests.

`KYS_TEST_MOD` is optional. With no mod supplied, CTest runs only the asset-free
core checks. When provided, it also runs `tests/mcp_integration.py` against the
**unmodified** supplied Dragon mod. The integration suite expects that dataset,
including its three malformed names. It does not run against the repaired copy.

## Launch and client configuration

```powershell
bin-c/build/Release/kys_mcp.exe --mod tmp/runtime/kys-Dragon --save-dir tmp/saves
```

Use an MCP client with a stdio server configuration such as:

```json
{
  "mcpServers": {
    "kys_pascal": {
      "command": "D:\\projects\\kys-pascal\\bin-c\\build\\Release\\kys_mcp.exe",
      "args": [
        "--mod", "D:\\projects\\kys-pascal\\tmp\\runtime\\kys-Dragon",
        "--save-dir", "D:\\projects\\kys-pascal\\tmp\\saves"
      ]
    }
  }
}
```

All protocol output is UTF-8 JSON. No Python package is needed by the server.
`tools/mcp_client.py` is a small Python standard-library client used by the
regressions, including an actual initialize/initialized handshake. The server
advertises MCP protocol version `2024-11-05`.

Call `new_game(seed=7)` once. It uses native random character generation,
accepts the mod's default protagonist name and first attribute roll, and runs
the actual opening event. Seeds are reproducible within this frontend; its
stored LCG random sequence differs from the graphical frontend's `std::rand`.

## Tool surface

| Tools | Purpose |
| --- | --- |
| `state` | Party, inventory quantities, scene/coordinates, pending choice, RNG, battle roster |
| `search(kind, query/id, offset, limit)` | Item, role, scene or magic IDs; explicit IDs expand details |
| `inspect_scene(scene, x?, y?)` | Sparse active event slots, map locations, scripts, entries/exits/gates/jumps; optional six-layer tile detail |
| `inspect_world(x?,y?,radius?)` | Native world terrain, building anchors, entrance IDs and passability, without moving |
| `inspect_script(id, offset, limit, include_text)` | Paginated native bytecode and optional decoded dialogue |
| `navigate(x,y)` | Find and walk a path using native passability and height rules |
| `step(direction,count?)`, `face(direction)` | Direct native keyboard movement and facing |
| `interact(slot?, item?)` | With a slot, walk adjacent and face the object; without it, dispatch from current position/facing |
| `travel(scene)` | Walk through native world passability to the actual entrance; retain gates, spawn, facing and entry step trigger |
| `choose(index)` | Resume a native choice, number input, party selection or battle turn |
| `battle_action(action, ...)` | Native movement, attack, healing, detox, poison, medicine/food and hidden weapons |
| `inspect_battle(actor?,x?,y?,radius?)` | Legal native moves/costs, cropped terrain/occupancy, actor skills and current magic ranges |
| `use_item(item)`, `dismiss(role)` | Native ownership, equipment/practice/item flow and leave event |
| `party_action(action)` | Native out-of-battle medicine/detox, with actor and recipient choices |
| `checkpoint(action,label)` | Save/load idle state and RNG, optionally across processes |
| `audit` | Malformed item names, blocked/out-of-range spawn candidates and bad script references |
| `debug(...)` | Explicit opt-in fixture entry/stat changes/script invocation, enabled by `--debug` |

`search(kind="item",id=...)` exposes description, raw name bytes, quantity,
requirements, equipment eligibility, effects, book experience requirements,
craft products and materials, plus the original record. `search(kind="magic",
id=...)` includes area type, target convention, base and per-level MP cost,
minimum stamina, attack/range arrays and raw fields. Party magic entries expose
their actual `slot` for manual combat; slot numbers may have gaps.

The scene's **slot** is an object index; its `talk`, `item` and `step` values
are **script IDs**. Use the slot in `interact`. `tiles` are the actual event-map
locations, which can differ from a record's stored `xy`. Pass
`include_inactive=1` when investigating raw/inactive objects.

Coordinates are zero-based native internal `(x,y)`. The legacy data/editor
axes are reversed; `state.data_xy` and `world_data_xy` use the guide/editor
convention. Check `action_result.reached`: walking stops on intervening events,
exits or scene jumps, even if the destination lies farther along the path.
`interact` also reports an interruption if its approach hits one of these.
Scene `navigate` uses the native mouse-path height restriction. Native keyboard
movement only checks destination passability; use `step` to exercise that input
path, including a height change the mouse path rejects. Directions are
`0=x-1`, `1=y+1`, `2=y-1`, `3=x+1`; `count` is 1–100. Step scripts execute
before exit/jump checks, including scripts on exit tiles.

World `travel` plans around unselected entrances, but each executed step calls
the actual native entrance check. World `navigate` can also target internal
coordinates 0–479. State includes world position/facing and boat state, so
approaches and returns can be checked against the guide's swapped axes.

Actions return full dialogue since the previous mutation, item/role/event
changes, immediate manual combat effects, a compact state and the last 160
`[script, word_offset, opcode]` trace entries. This makes an item decrement,
reward, party branch or changed trigger directly inspectable. Role changes
report only the raw fields that changed; explicit role search returns the
full record. Data strings use **CP950**, including its extended characters.

## Decisions and battles

The native event worker suspends its C++ stack at an input boundary. Read-only
inspection remains available; a new mutation is rejected until the input is
answered. Options are zero-based. Use `-1` only when `cancel_allowed` is true.
Numeric prompts expose their bounds. A `party` prompt uses a **bitmask**:
slots 0 and 1 together are `choose(index=3)`, slots 0 and 2 are `5`.

At a `battle_turn` prompt, `choose(0)` runs the native AI for that turn,
`choose(1)` rests and `choose(2)` runs the native AI for the battle, pausing
again every 100 rounds. A loss follows the real loss branch. Native movement,
damage, poison, rewards, level-up, practice and restoration still apply.
The headless scheduler uses ordinary turn rounds; semi-real-time graphical
initiative is not simulated. No forced-win command is exposed.

For manual control use `battle_action`:

```text
action="move", x=..., y=...                  # retains remaining turn
action="attack", magic_slot=0, x=..., y=...
action="consume", item=1                    # owned type-3 medicine/food
action="medicine" or "detox", x=..., y=...   # living friendly target
action="poison", x=..., y=...                # living enemy target
action="hidden_weapon", item=..., x=..., y=...
```

For a line attack (`area_type=1`), aim at an **adjacent cardinal direction
tile**, with the line extending in that direction. Supplying a distant
enemy tile is rejected. A self-cross attack (`area_type=2`) extends along the
four cardinal arms and excludes diagonals; omit x/y. Point attacks
(`area_type=0`) aim within Manhattan `move_distance`. A target-square attack
(`area_type=3`) aims within that same Manhattan range and affects a square
of radius `attack_distance` around the aim. The 0.2.4 observations include
named `shape` and explicit `targeting` descriptions. Native
skill ranges, stamina, ownership and target teams are validated. Native weak
attacks with insufficient or zero MP remain available; the native damage
calculation adjusts their effective level. An
`effects` record captures the immediate actor/target state before following
enemy actions can conceal the effect in the net state.
The `affected` array records all other actors whose native role state changed
immediately after the action, including line/area targets away from the aimed
tile. This remains observable even if following enemy turns or end-of-battle
restoration would hide their damage in the final state.

`inspect_battle` defaults to the pending actor and a radius-five map crop;
radius is 0–10 and x/y can center the crop elsewhere. `reachable` rows are
`[x,y,movement_cost]`; `tiles` rows are
`[x,y,ground,building,occupant_actor]`. It calls native movement calculation
while preserving all scratch layers and RNG. The returned `role` and `magic`
describe skills and current targeting ranges. Battle actors also expose face,
poison and injury, so manual tactics need no
graphical inspection or guessed legal moves.

For recovery outside battle call `party_action(action="medicine")` or
`party_action(action="detox")`, then answer the actor and recipient menus.
These call the same native menus/effects as the graphical game. Outside battle
they consume no stamina or items, as in Pascal. Sleep skips poisoned roles and
roles with injury above 33, so treatment may be necessary before resting.
Named skill values are available in each party member's `skills` object.

## Checkpoints, shortcuts and boundaries

Checkpoints are **idle-only**. Save before an interaction whose choices or
battle you want to replay. A suspended battle cannot be rolled back directly;
finish its action or restart the process and load a durable checkpoint.
The memory cache holds at most 12 labels. With `--save-dir`, durable labels
are unlimited and an evicted label is loaded from disk on demand. Without a
save directory, the session is limited to 12 labels. Labels accept ASCII letters, digits,
underscore and hyphen. `--save-dir` creates binary `.kys-save` files with
version, gameplay-data fingerprint and checksum checks. V3 fingerprints the
five world maps and four `list/*.bin` gameplay tables as well as the original
mod/script/battle data. It includes the scene jump guard and a checksummed
legacy-lineage flag. V1/V2 import requires the explicit command-line option
`--allow-legacy-checkpoints` and a matching old mod fingerprint. Imported state
reports `legacy_checkpoint_lineage: true`, including after V3 resave/reload;
import cannot retroactively verify files omitted by the old fingerprint.
Checkpoint responses expose the source `checkpoint_format`. A failed load leaves
the live game unchanged. These are private MCP checkpoints for this build,
not interchangeable with the original graphical save format.

Before loading a new game, the MCP checks that all five world maps have their
native dimensions and that `leave.bin`, `levelup.bin`, `match.bin` and
`effect.bin` are present with usable lengths. `MAX_WEAPON_MATCH` is bounded
before its fixed native array is loaded. Missing tables previously could
silently become zero-filled rules: an incomplete test mirror caused a level
1 protagonist to jump to level 60 after one fight. That attempt is excluded
from campaign evidence. The supplied mod's `effect.bin` intentionally has 128
bytes; validation accepts its complete 16-bit entries. The graphical loader
is unchanged by this MCP preflight.

`travel` requires the world map, an actual world entrance and native entry
eligibility. It now executes terrain walking and native ship/entrance checks;
older shortcut-travel transcripts do not establish world-access coverage. Scripted
walks/animations advance to their native final logical state without showing
frames. A presentation-only acknowledgement accepts Enter. Native branch
menus, number inputs and script key choices still suspend explicitly.

`--debug` enables labeled fixture teleports, raw role-field mutation and
direct script invocation. It is useful for testing boundary values or
isolating a quest, but such results do not prove that the normal route unlocks
that state. Do not treat a debug recruitment as a complete campaign playthrough.

The native script VM has a 250,000-instruction budget per top-level action.
Malformed opcodes/operand lengths or byte ranges are rejected. Native action
exceptions restore the snapshot taken before that top-level action. This is
an investigation frontend for trusted legacy mod files; it is not a sandbox
for arbitrary hostile bytecode, and it does not replace every graphical menu.

## Reproducible data audit and repair

```powershell
python tools/dragon_audit.py tmp/runtime/kys-Dragon `
  --report tmp/dragon-audit.json `
  --repair-output tmp/repairs/ranger.grp
```

All outputs, including reports and decoded scripts, must be outside the
reference mod directory and have distinct paths. Repairs must be new files;
the tool refuses an existing repair. Copy the repaired file into a separate mod copy's `save/`
directory if you want to play with cleaned names.

The user-reported 闖王軍刀 cave defect is a separate `alldef.grp` repair:

```powershell
python tools/dragon_audit.py tmp/runtime/kys-Dragon `
  --report tmp/validation/dragon-audit.json `
  --repair-event-output tmp/repairs/alldef.grp
```

This narrowly repairs scene 84/slot 8, moving script 18 from ordinary
interaction to item use. It verifies the exact original record and refuses
unverified/progressed data. It changes two bytes and leaves other semantic
trigger candidates alone. This file is a **new-game event template**; existing
graphical save `dN.grp` files contain separate event state. The regression
tests the original failure and repaired success through actual MCP calls.

The independently reproduced 灵鹫宫 seven-picture counter needs a three-file
new-game repair package:

```powershell
python tools/dragon_audit.py tmp/runtime/kys-Dragon `
  --report tmp/validation/lingjiu-repair.json `
  --repair-pictures-output tmp/repairs/lingjiu
```

The output directory must be new. Copy its `save/alldef.grp` and both
`resource/kdef.*` files together into a separate complete runtime. This package
contains only the picture repair; it is an alternative event template to the
standalone saber repair, so blindly copying both templates would overwrite one
repair with the other.

To install all three confirmed repairs together, generate one combined package:

```powershell
python tools/dragon_audit.py tmp/runtime/kys-Dragon `
  --report tmp/validation/combined-repair.json `
  --repair-combined-output tmp/repairs/dragon-confirmed
```

The destination must be a new directory, including when an existing directory
is empty. Combined output cannot be mixed with the individual repair flags;
those remain available for isolated investigations. The tool validates the
exact original name/event files and the verified script-file hashes, composes
both event edits in memory, and creates each package file exclusively. It
rejects changed inputs, output collisions and paths inside the reference mod.
All guards run before the package is created.

Copy all four generated files into a separate complete runtime:
`save/ranger.grp`, `save/alldef.grp`, `resource/kdef.idx` and
`resource/kdef.grp`. The combined event template retains both the scene84
saber repair and scene12 picture repair. Names change 12 bytes; the combined
event template changes four bytes; script data and indices preserve their
existing prefixes and append 102 and 32 bytes respectively. The JSON report's
`combined_repair` records per-file original/output hashes, byte changes and
the individual repair details. Unconfirmed candidates are unchanged.

This is a **new-game package**. Existing graphical saves are not migrated, and
original-data MCP checkpoints cannot be imported into a changed-data run
without violating their identity checks. Exact composition and native debug
fixtures check the cleaned names, wrong/correct saber use, both picture
orders, early clicks, repeats and the separate chest together. Those fixtures
are regression evidence; a full fresh campaign using all four combined files
has not been completed. The separate fresh saber and picture campaigns retain
their own asset identities and coverage limits.

No game assets are tracked
by this change. Temporary extraction, reports, checkpoints and diagnostic
material belong under the single ignored `tmp/` root. Integration tests clean
up their own scratch directory on exit.

See [the investigation report](DRAGON_FINDINGS.md) for source fixes, exact
data defects, guide coverage, hashes and independent review results.
See [the campaign ledger](CAMPAIGN_VALIDATION.md) for the completed primary
ending and remaining alternate-branch acceptance work.
