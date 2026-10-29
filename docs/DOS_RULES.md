# Recovered 苍龙逐日 v1.2 DOS progression and combat rules

The shared C++ engine has an opt-in `dragon_dos12` rules profile. It applies to
both the graphical executable and the MCP executable. Rendering, animation and
input stay in their existing frontends. An absent `[rules]` section selects
`legacy`, preserving the supplied remake's balancing and Pascal formulas.

This is a recovered **progression and combat-effects profile**, not a claim
that the entire remake is now the DOS engine. AI, movement, item/book/event
logic, starting data and overall battle reward distribution retain remake
behavior. The completed guide campaign used legacy rules; it has not been
repeated under DOS balance. The new profile has targeted real gameplay and
native-machine-code differential tests described below.

## Original package and extraction

Reference supplied by the user:

```text
D:\Downloads\22-2.《苍龙逐日》【v1.2DOS原版；2006-08】\《苍龙逐日》【v1.2原版；2006-08】\2009-03 金庸群侠传苍龙逐日 v1.2.exe
```

The installer is an NSIS archive. It was extracted with 7-Zip into the ignored
`tmp/reverse/dragon-dos12/base/`; the installer was never executed. No computer
use, DOS desktop, game graphics or original package modification was involved.

| Reference | Bytes | SHA-256 |
| --- | ---: | --- |
| Original `Z.dat` | 343217 | `60ff7e91d7be7a848242e2ddc2ef105b906e160e19f3086bf13ff55d8e951928` |
| Original launcher `Z.com` | 413 | `9de4c8002f92759bd2771a4984ff02599121e6c66fed1eb0d7e905a327e2dac1` |
| Adjacent enhancement-patch `z.dat` | 389120 | `884903b604709029e2fe093775fa09169665490a42861619ab11dbc316e0f520` |

`Z.dat` is executable code: an MZ stub followed by an uncompressed 32-bit
Watcom LE image. Its LE header is at file offset `0x2c80`, physical pages start
at `0x18a00`, and object 2's initialized bytes start at `0x19a00`. The page map
uses three-byte big-endian physical page numbers and 4096-byte pages. The
[Open Watcom LE header definition](https://raw.githubusercontent.com/open-watcom/open-watcom-v2/master/bld/watcom/h/exeflat.h)
was used to interpret the format. Preferred object addresses must not be
confused with object-relative offsets or file offsets.

The adjacent `sysEnhance_clzr` ZIP was extracted separately. Its level routine
deducts XP, gains a single level, and uses different stat increments. It is
**not** included in this original profile. For the same synthetic input that
gains two levels in the original, the patch gains one; mixing these references
would yield the wrong rules.

## Activating and configuring the profile

Append [the preset](../bin-c/presets/dragon_dos12.ini) to a **copy** of a remake
mod's `kysmod.ini`, then launch either executable with that mod. The original
DOS package is a code reference, not a drop-in replacement for remake assets.

```ini
[rules]
profile=dragon_dos12
```

This overrides inherited `[constant]` values for level/HP/MP/stamina and the
combat divisors with the recovered defaults. In particular, an old
`MAX_LEVEL=60` does not silently defeat the original cap of 30. Original mod
files and existing campaign saves were not overwritten.

Optional `[rules]` keys:

| Key | DOS default | Meaning |
| --- | --- | --- |
| `progression`, `combat` | profile name | Select `legacy` or `dragon_dos12` independently. |
| `max_level` | 30 | 1–100. DOS caps above 30 require a complete custom XP table. |
| `max_hp`, `max_mp` | 999, 9999 | 1–32767; used by growth and existing shared cap paths. |
| `max_stamina` | 100 | Stamina refill/rest ceiling. |
| `min_knowledge` | 80 | Knowledge must be strictly greater than this to contribute. |
| `life_hurt` | 10 | HP hit damage divided by this becomes injury. Must be positive. |
| `poison_hurt` | 1 | Poison loss divisor at round end. Zero disables poison loss. |
| `hp_growth_factor` | 3 | DOS batch HP gain coefficient. |
| `mp_growth_factor` | 4 | DOS batch MP gain coefficient. |
| `attack_growth_factor`, `speed_growth_factor`, `defence_growth_factor` | 1 each | Multiply the DOS `Δ×g` gain separately for each attribute. Zero disables that attribute's level growth. |
| `xp_thresholds` | authentic built-in table | Comma-separated cumulative thresholds, first for level 1→2. Positive, strictly increasing, ≤65535, enough entries for the selected cap. |

Unknown modes, invalid numbers, non-increasing thresholds and an incomplete
XP table fail before character generation. Original DOS random aptitude growth
does not use the legacy `MAX_ADD_PRO` toggle. Existing `MaxProList43..58`
continues to govern the legacy growth/item/book paths; DOS leveling has its
own recovered selective caps. This distinction prevents an inherited remake
cap from changing DOS growth accidentally.

All settings live in `kysmod.ini`, already covered by the MCP mod fingerprint.
Changing the profile or a coefficient rejects checkpoints from the previous
configuration. Start a new campaign lineage when changing XP semantics; old
role XP is not automatically converted.

## Level limits, XP and stat gains

Original routine: object 2 `0x1b6be`; XP table: `0x3458e`.

Normal level cap: **30**. XP is unsigned 16-bit, cumulative, and is **not
deducted** on leveling. Total XP required to attain levels 1 through 30:

```text
0,50,150,300,500,750,1050,1400,1800,2250,
2750,3850,5050,6350,7750,9250,10850,12550,14350,16750,
18250,21400,24700,28150,31750,35500,39400,43450,47650,52000
```

If a character gains `Δ` levels at one settlement, the original rolls **once
for the whole batch**. Let `R(n)` be a draw in `[0,n-1]` and `g=1+R(tier)`:

| Aptitude | tier | Attack/speed/defence gain per level |
| --- | ---: | --- |
| below 30 | 2 | 1–2 |
| 30–49 | 3 | 1–3 |
| 50–69 | 4 | 1–4 |
| 70–89 | 5 | 1–5 |
| 90 and above | 6 | 1–6 |

- HP maximum increases by `Δ × 3 × (IncLife + R(3))`, capped at 999.
- MP maximum increases by `Δ × 4 × (9-g)`, capped at 9999.
- Attack, speed and defence each increase by `Δ × g`.
- Medicine, poison use, detox, fist, sword and knife each gain `R(3)` only if
  their prior value is **greater than 20**. This happens once per batch.
- Hidden weapon gains `R(3)` once per batch, including when it starts at zero.
- Poison resistance and unusual weapons do not grow through leveling.
- Medicine, poison use and detox cap at 100. The original binary deliberately
  jumps over the old 100 clamps for attack/speed/defence/fist/sword/knife/hidden
  weapon. Their stored values remain signed 16-bit; this is not a universal
  statement about caps in item or event code.
- HP/MP refill, injury/poison clear and stamina refills to 100.

Example verified by executing the original instructions: level 1 with XP 150,
IncLife 3, aptitude 56, HP 100 and MP 200, using `g=3` and HP random 1, becomes
level 3 with XP **still 150**, HP 124, MP 248 and +6 attack/speed/defence. The
remake's old per-level XP deduction and fixed maximum aptitude gains cannot
reproduce this by changing only `MAX_LEVEL`.

## HP damage

Routine: `0x19188`. All divisions truncate toward zero, and the code contains
signed 16-bit intermediates. The implementation preserves these stores rather
than rearranging the arithmetic into superficially equivalent expressions.

`trained = proficiency/100+1`. Starting at this tier, step down until MP covers
`NeedMP × floor(effective/2)`. Tier 1 is free, so zero MP can still produce a
tier-1 attack. Damage power uses the effective tier; targeting remains based
on the trained tier.

Every living, non-dead actor with knowledge >80 contributes `2×knowledge` to
its team's subtotal. An actor at zero HP contributes nothing even before its
dead flag is updated. With `power=Attack[effective-1]`:

```text
A = (3 × attacker.attack + power) / 2
    + weapon.AddAttack + armor.AddAttack + weapon/magic match bonus
    + attacking team's knowledge subtotal
D = defender.defence + weapon.AddDefence + armor.AddDefence
    + defending team's knowledge subtotal
damage = 2 × (A - 3 × D) / 3 + R(20) - R(20)
if damage <= 0: damage = A/10 + R(4) - R(4)
if damage < 0: damage = 0
else:
    damage += attacker.stamina/15 + defender.injury/20
    if Manhattan distance <= 10:
        damage = damage × (100 - (distance-1) × 3) / 100
    else:
        damage = damage × 2 / 3
damage = max(damage, 1)
```

There is no fist/sword/knife proficiency bonus in this formula, no attacker's
injury discount, and no unconditional `max(raw, fallback)` floor. Both pieces
of equipment contribute before the damage calculation. Knowledge, integer
rounding and distances above 10 therefore differ materially from the remake.

HP loss adds injury `damage/10`, capped at 99. Hit XP is `damage/5`; the
original adds the victim's `level×10` only when HP becomes **negative** before
clamping, so an exact-zero kill misses that bonus. The attack caller adds 2 XP
per strike. An attack costs 3 stamina after the action, including a double
strike; proficiency increases 1–2 **after** each strike, capped at 999.

HP-hit poison uses **trained**, not effective, tier:
`attackPoison = attacker.AttPoi + trained×magic.Poison`. If this exceeds
resistance and resistance <90, poison increases by
`(attackPoison-resistance)/15`. The native upper check is `>100 → 99`, leaving
exactly 100 possible. This quirk is retained in the original profile.

## MP drain and its cached-cost quirk

Effect routine: `0x195ec`. Using the trained tier:

- Attacker current MP gains `magic.AddMP[tier-1] + R(3)-R(3)`.
- Attacker max MP gains `R(magic.AddMP[tier-1]/2)`, capped at 9999; current MP
  then clamps to the new maximum.
- Target MP loses `magic.HurtMP[tier-1] + R(3)-R(3)`, using separate noise;
  it clamps at zero. The displayed result is actual before-minus-after MP.
- Zero target MP does **not** prevent recovery or max-MP growth.

The original HP routine writes global `0xc6ec2`, while the MP routine does
not. The caller at `0x184ed..0x18551` charges
`NeedMP × floor(cachedHPLevel/2)` after either kind of attack. Thus the first
MP attack can be free, and a later one can inherit the tier of a previous HP
attack by another actor. The profile retains that behavior explicitly as
`DosLastEffectiveLevel`; it is not silently replaced by a tidier formula.

MCP checkpoint V4 persists and checksums this cache. V3 remains readable in
legacy mode; DOS combat rejects pre-V4 checkpoints because the missing cache
can change the next action. V1/V2 still require explicit legacy import. Both
in-memory restoration and process-restart restoration preserve cache and RNG.

## Other recovered battle effects

| Effect | Native offset | Recovered behavior |
| --- | --- | --- |
| Use poison | `0x19a45` | Add `(UsePoi-DefPoi)/4`, clamp contribution to 0–99 and total to 99. |
| Detox | `0x19da3` | Remove `MedPoi/3 + R(10)-R(10)`, clamp 0–99 and to current poison; no removal if poison > MedPoi+20. |
| Medicine | `0x1a10c` | Requires stamina ≥50, costs 2. Base healing is medicine×2 for injury ≤25; ×3/4 for 26–50; ×2/3 for 51–75; ×1/2 above 75; then +R(5). If injury > medicine+20, healing and injury reduction are zero. Otherwise injury drops by the medicine stat even when HP was almost full. |
| Hidden weapon | effect slice `0x1a537..0x1a839` | With divisor 4 at injury 0, 3 at 1–33, 2 at 34–66, 1 above 66: signed HP change is `(item.AddCurrentHP/divisor - R(5) - 2×attacker.HidWeapon)/3`. Apply HP change and subtract change/4 from injury, clamping HP and injury. Defender hidden-weapon skill is not used. |
| Hidden-weapon poison | same slice | For positive item poison, contribution is `max((item.AddPoi-attacker.HidWeapon)/2 - target.DefPoi,0)/2`; resistance ≥100 gives zero. For zero/negative item poison, use `item.AddPoi/2+R(5)-R(5)`, which can add or remove a little poison. Total clamps to 0–99. |
| Rest | `0x1a8a4` | Recover `3+R(3)` stamina if remaining steps equal speed/10, otherwise `2+R(3)`, cap 100. If resulting stamina ≥30, separately recover `3+R(stamina/10-2)` HP and MP, capped at maxima. |
| Round status | `0x1c563` | Lose injury/20 plus poison/1. The native short-circuit condition lets injury bypass the usual alive/stamina checks. Negative resulting HP becomes 1, but exactly zero stays zero. This runs at round end, not as a substitute for an attack. |

Poison/detox battle actions cost 2 stamina and give the acting character 1 XP.
The same medicine/detox effect functions serve the existing out-of-battle
menus, with their normal graphical feedback retained. Default legacy behavior
and its existing regression expectations are unchanged.

## Differential and gameplay validation

[The oracle tool](../tools/dragon_dos_oracle.py) parses the original LE object
and runs isolated native routines in Unicorn. It refuses every binary hash
except the original above. RNG and synthetic role/magic/item records are
controlled inputs; the original instructions produce expected outputs. Stack
probes and the game RNG wrapper are intercepted; no DOS I/O or graphics runs.
Hidden-weapon and MP-cost slices stop before presentation, with their local
stack/register inputs explicitly constructed in the tool.

```powershell
python -B tools/dragon_dos_oracle.py `
  --binary tmp/reverse/dragon-dos12/base/Z.dat `
  --vectors tmp/reverse/dragon-dos12/regenerated.json
python -B tools/dragon_dos_oracle.py `
  --binary tmp/reverse/dragon-dos12/base/Z.dat --disasm 19188 195ec
```

Analysis-only dependencies are `unicorn` and, for disassembly, `capstone`.
They are not game/build/runtime dependencies. The checked-in JSON contains
inputs, outputs, bounded RNG calls and the original binary hash; no original
executable or game assets are committed. CTest uses those fixtures directly
without requiring either analysis dependency.

Validation on this workspace:

- **274 native vectors**, covering aptitude thresholds, cumulative XP edges,
  batch growth and caps, low-MP tier selection, distance, fallback noise,
  equipment, knowledge/alive checks, exact-zero kills, poison boundaries,
  independent MP tables, stale cached cost, healing, detox, hidden weapons,
  rest and round damage. All 91 role words and RNG bounds/order are compared.
- Seeded adapters additionally exercise actual shared `CheckLevelUp` and
  `CalHurtRole`, rather than only calling arithmetic helpers.
- A real stdio MCP test starts a fresh DOS-profile character, visits the
  normal training route, practices the book, completes sparring attempts and
  wins a fight. It verifies the cumulative XP/level relationship, reported
  cost, and cache/RNG/state equality after saving, closing, restarting and
  loading. It uses no debug mutations or imported campaign saves.
- Configuration validation, changed-INI rejection, legacy V2/V3 compatibility
  and DOS rejection of missing-cache checkpoints are covered by stdio tests.
- The graphical executable, MCP executable and test executables build through
  the existing vcpkg setup. No graphics inspection was performed.

Remaining fidelity work would be a separate expansion: recover and port DOS
AI, movement/initiative, full item/book/event cap paths, starting generation,
overall XP settlement and its RNG implementation; then play a new full guide
campaign under that balance. Native vectors establish the listed effects,
not whole-game equivalence. The optional enhancement patch also needs its own
profile if it is selected as a future reference.
