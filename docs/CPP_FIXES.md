# Shared C++ gameplay and data-access fixes

These corrections are separate from the MCP frontend commit. They apply to
both `kys.exe` and `kys_mcp.exe`; no mod assets are changed. Pascal is the
behavior reference for entry and battle movement. Two bugs reproduced during
actual play also exist in Pascal and are deliberate corrections beyond parity.

| Change | Evidence and resulting behavior |
| --- | --- |
| Scene entry condition 2 | An active teammate must have speed greater than 70, matching Pascal. Tests cover 70, 71, an empty party and plot locks; the MCP opening test checks the locked scene. |
| Battle movement | Restore water blocking, enemy-adjacency stopping, the initial envelope for split moves, dead-actor passability and preferred backtracking. A broken gradient fails without moving. Nine behavioral assertions failed before correction. Attack/skill mode 1 keeps native Manhattan targeting. |
| Inventory capacity | Test the index bound before reading the slot. Regression covers a full inventory, removal, slot reuse and quantity saturation. |
| Fixed-width text | Honor the explicit CP950 byte length and stop at an embedded NUL. Packed name/description callers supply their actual capacities. Status names retain the full field width. |
| Event bytecode | Reject invalid script indices, negative/odd/out-of-file byte ranges, unknown opcodes and truncated operands before access. Tests use malformed byte ranges and truncated instructions. |
| Hidden-weapon poison | A real attack against poison resistance 112 produced poison 0 to -9. Pascal uses the same formula. Clamp the resistance multiplier at zero and final poison to 0–99; seven boundary cases preserve HP damage, item consumption and the native action. |
| Handed-over equipment | Giving the last owned 金蛇劍 to 袁承志 left its equipment and user links active in both implementations. Remove matching weapon/armor links only when a negative removal exhausts a positive owned stack. Tests preserve partial stacks, unrelated gear/base stats, unowned-removal behavior and practice books. Existing save inconsistencies are not migrated. |

Release verification builds the graphical target, MCP target and asset-free
core regression target. Both CTest targets pass, including sixteen real stdio
integration cases in this commit. Data-audit/repair integration cases belong
to the separate mod investigation commit.

Actual earned-state replays under the single ignored `tmp/` root supplement
the automated tests:

- `tmp/campaign/root-condor/`: original negative poison and corrected attack,
  keeping HP 956 to 948 and item quantity 1 to 0 while poison stays zero.
- `tmp/campaign/root-equipment/`: normal equip, travel, fight and quest handover;
  item 40 quantity 1 to 0 now clears the hero equipment slot and item user.
- `tmp/validation/movement-before.log` and
  `tmp/validation/equipment-removal-before.log`: regression failures on the
  preceding behavior.

The campaign includes checkpoints from multiple builds with recorded lineage.
A completed route is not evidence for every branch or graphical runtime
behavior. The historical sanitizer run covered an older eight-case suite;
it does not establish sanitizer coverage for these later corrections.
