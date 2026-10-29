# Campaign validation — in progress, stability unverified

The preceding static scan and focused integration checks were preliminary.
They did not complete the user's requested guide-driven campaign validation.
The scene-84 saber report exposed that gap: a valid script ID was attached to
the wrong trigger, outside the played scenarios. The earlier completed-goal
designation must not be read as a stability finding.

The primary native campaign has completed all fourteen books and the actual
ending. The alternate combined campaign also has all fourteen books; supplementary
branch campaigns continue. All use actual stdio MCP with `--debug` absent
and **苍龙逐曰完全攻略** as the reference.
The original supplied mod remains the reference. A data repair must first be
reproduced on that reference and then validated on a separately identified
repaired version; changing data cannot silently turn a failing original route
into a passing one.

## Required evidence

- All fourteen books and the final 华山/钓鱼岛 sequence through actual game
  progression. Rewards, consumed items, party changes, gate unlocks, fights,
  losses and relevant dialogue must be recorded against guide steps.
- Every mutually exclusive branch explicitly described in the guide, replayed
  from legitimate pre-branch checkpoints or a separate new game. One moral
  route cannot establish the other route's correctness.
- Sidequests, unique item uses, manual combat actions and boundary conditions
  listed by the guide, including failed/wrong-item interactions where relevant.
- Actual world approach, native entry, spawn, scene walking and ordinary/item/
  step dispatch. Debug teleports, arbitrary script calls, stat or item grants,
  and forced wins are not campaign progression evidence.
- Exact build/data identity, RPC evidence, durable checkpoint and an explicit
  passed/failed/blocked/unvisited status for each result. A passing script
  fixture is a regression test; it is not a substitute for reaching it.

Completion would validate the recorded routes on the identified build/data.
It would not prove every possible event order or every graphical behavior.

## Progress ledger

| Guide chapter | Righteous/reference run | Evil/alternate run | Remaining scope / qualifications |
| --- | --- | --- | --- |
| Opening/school | Passed strict opening and 青城 training | Passed strict opening and training | Other starter schools and their hidden arts remain |
| 飞狐外传 | 苗人凤 duel4 won6; book144/map/manual | Evil duel0 manually won9 on0.2.3; book144/map/manual | Both 田归农 choices played |
| 雪山飞狐 | Scene85 guards, saber gate and four rewards | Scene85 passed | All original variants reached; scene84 failed as reported. Fresh repaired84 passed separately |
| 连城诀 | 狄云, ethics81, book146/神照71 | Evil route passed in combined and independent branch campaigns | Important poem wrong-item, consumption and repeat checks passed |
| 天龙八部 | 聚贤庄/少林 fights; book147/降龙86 | Evil formations; book147/慕容/王 | 虚竹/灵鹫/丁春秋/薛 sidequests passed. Original all-seven picture reward is defective; separate fresh repaired progression passed |
| 射雕英雄传 |176 won4;177 manual clean replay won6; book148 | Kill一灯68 and finals187/183/184/185 passed;148/九阴84 | Root spare一灯175 won2/一阳96; final186 still lost, no book |
| 白马啸西风 | Spare route, ruins and weapon-gated door passed | Evil route passed on0.2.2 | Final-build replay92/91 and actual ruins approach passed |
| 鹿鼎记 | Scene91 guards and book150 passed | Scene91 required1076/1075 and book150 passed | Primary1074 confirmed; both wives separately recruited, mutual party exclusion verified |
| 笑傲江湖 | Righteous chain, 东方54 won2 and book151 passed | Evil chain,54 won3; Five Mountains fights and151 passed | Trust/menu variations recorded; branch ledger still needs final reconciliation |
| 书剑恩仇录 |141/142/143; book152 |138/139/144/140; book152/张召重 | Full-party sends her home; actual later join correctly grants132 |
| 神雕侠侣 | Refused金轮; group fights and153 | Accepted金轮;75 won1,153/降魔170 | Both main book routes passed |
| 侠客行 | 石破天 and scholar conversations;154/太玄80 |170 retry won3;154 | Important酒/令 transitions played; guide side branches still need reconciliation |
| 倚天屠龙记 | 成昆/head219→谢逊;155/鹰爪109 | 成昆/head219→玄慈;155 | Battle80 genuinely lost but script progressed. Full6+2 allies 崆峒 waves passed; guide warning not reproduced. Buried九阳 actual wrong-compass/correct-shovel passed |
| 碧血剑 | Physician route passed;156 | Evil corpse route passed;156 | Independent no-doctor high/exact75/74-fight branches passed |
| 鸳鸯刀 | Both blades,157/夫妻140 | Kill route132/137 won1;157 | Wrong compass also places owned blades in both orders; shared script behavior, no repair |
| 华山/钓鱼岛 ending | Completed:18 solo opponents, group133,14 altars,神杖205,128–131 and native terminal ending | Not repeated | Primary has full transcript and final checkpoint; mixed-build lineage explicit |
| Hidden room | 松風→神山 passed independently from earned all14 checkpoint | Not played | 南贤 activation required. Three alternative starter-manual arts unplayed |
| Other guide sidequests | Partially covered | Partially covered | Detailed optional results below; remaining hidden starter alternatives unplayed |

Detailed live journals, coverage records, native RPC transcripts and saves are
under `tmp/campaign/reference/` and `tmp/campaign/alternate/`. These are gameplay
evidence and recovery state, retained under the single ignored temporary root.
The initial runs used the older world-travel shortcut; that portion of access
coverage must be revalidated with the strict frontend rather than assumed.
Both main campaigns restarted from a fresh strict `new_game(seed=7)` after
the world-travel fix. A third strict run under `tmp/campaign/sidequests/`
is exercising the duplicate caves and sidequests, including both Western
village shovel rewards and the refusal branch. The righteous combined run earned all fourteen books and completed the native
ending. The alternate combined run also has all fourteen books after native final185. The primary pre-ending `all14books` checkpoint is preserved for
independent branches. The alternate native ruins map names coordinates `(80,212)` and opens
scene 87; the route includes fights 92 and 91, linked ruin scene 89, the owned
玄鐵劍 stone-door check, and a book chest that gives no duplicate reward.
See `alternate/strict/coverage.json` for physical transcript lines and build
identities; historical shortcut-run coverage is explicitly superseded.

Root independently played 连城诀's evil branch on corrected 0.2.3 from a copy
of the earned alternate `book_baima` checkpoint. Native fights 16, 42, 7 and 93
won in 3/5/3/5 rounds; 神照經, 唐詩選集, 中平槍法, 血刀經, 血刀 and book
146 were acquired. Wrong compass use did nothing at the water bowl; correct
poem use consumed item 206 and unlocked 天宁寺. The book event removes itself.
`tmp/campaign/root-liancheng/` retains provenance, transcript, highlights and
the `book_liancheng_evil` checkpoint. The alternate campaign has also replayed
this route in its own combined state, as recorded in its strict ledger.

Root subsequently completed the evil 书剑 route on 0.2.4: 回族部落's native
step event and refusal, battle 138 (3 rounds), prison guard conversation and
3,000 silver, battle 139 (4 rounds), 恒山's native step event, solo battle 144
(2 rounds), and battle 140 (3 rounds). Book 152 was awarded and 张召重 went to
home slot 52 because the party was full. The checkpoint is
`root-liancheng/saves/book_shujian_evil.kys-save`. This is supplementary branch
evidence; it does not merge progress into either main campaign.

The treasure-map choice is **wealth-dependent**, as script 16's native money
checks show: at least 10,000 silver selects map 225 / scene 5; at least 5,000
selects map 226 / scene 84; otherwise map 227 / scene 85. Both main runs had
1,795 silver at the map award and legitimately selected scene 85. The fidelity
run earned money before map delivery and actually exercised the other entrances.
For scene84 it collected four native cellar rewards to reach5795 silver,
earned map226, walked378 world steps, and won guard fights5/6. Wrong compass
and current-facing saber both dispatched empty script0 and left the gate
blocked. The subsequent ordinary-talk workaround and all four rewards are
recorded separately from the failure. For scene5 it earned10295 silver,
received map225, walked305 world steps, won both guard fights and opened the
gate with the saber; wrong compass remained inert. A fresh new game against
the separate two-byte-repaired mod has now completed scene84, without imports,
debug progression or forced results. Wrong compass906 did nothing; exact
current-facing saber907 opened the gate;908–911 awarded145/217/60/+1000,
repeat912 gave nothing. Complete rule/map provenance and `fresh84_repaired_looted`
are retained under `tmp/campaign/sidequests/patched/`.
This is distinct from the randomized 白马 ruins.

Both main runs independently found a shared legacy equipment inconsistency:
quest handover removes inventory 金蛇劍40 but leaves it equipped. Pascal and
C++ inventory-removal routines both omit unequipping. This shared legacy bug is fixed in0.2.7: actual removal of the last positive
owned weapon/armor stack clears all matching equipment slots and item.User.
Partial stacks, unrelated gear/base stats and practice books are preserved;
old inconsistent saves are not migrated. Boundary tests and the independent
design review passed. `tmp/campaign/root-equipment/` replays the normal equip,
fight, travel and 袁承志 handover from an earned checkpoint and verifies the
last-unit links clear. Earlier campaigns retain their original caveat.

## MCP fidelity findings requiring correction

| Finding | Implication | Status |
| --- | --- | --- |
| Scene exit/jump checked before step event | 黑龍潭 exit `(25,57)` skipped native script 440 | Fixed; independent retest and permanent regression pass |
| `travel` directly assigned world/scene coordinates | Could not test reachability, boats/terrain, actual entrance approach or facing | Fixed with native path/entrance execution; independent retest and permanent regression pass |
| Manual attack required base MP | Rejected native weak attacks with low/zero MP; relevant to guide 阎基 fight | Fixed; MP0 native attack regression passes |
| Only automatic event approach exposed | Difficult to compare an exact position/facing with player input | `step`, `face`, current-facing `interact`, per-tile inspection added and retested |
| Out-of-battle recovery skills unavailable | Poisoned/injured roles could not use the native treatment menus | Native `party_action` medicine/detox added; real actor/recipient menu and effects regression passes |

Build 0.2.7 passes the asset-free core checks and nineteen MCP integration cases.
Actual manual play identified another observation gap: line/area attacks aimed
at empty direction tiles did not expose affected enemies before later turns
or battle-end restoration. `affected` now captures every changed target's
immediate native state. `inspect_battle` exposes native reachable tiles,
movement costs, cropped terrain/occupancy, skills and magic ranges without
changing turns, scratch layers or RNG; replay tests verify this.

The battle path review also found shared C++ regressions against Pascal:
water tiles did not block movement, enemy adjacency did not stop route
propagation, split movement lost its initial reachability envelope, and broken
path reconstruction could move despite failure. Nine behavioral assertions
failed before the fix (`tmp/validation/movement-before.log`); all now pass.
The native shared movement is corrected for both frontends. Pre-fix combat
results retain their build identity and require relevant final-build replay;
later campaign completion must use the corrected code. Native attack/skill
targeting mode 1 deliberately remains Pascal's Manhattan diamond.

Current campaigns use V3 checkpoints. Older legitimate strict saves were
imported only with explicit `--allow-legacy-checkpoints`, verified original
world/list provenance and persistent visible legacy lineage. A fresh repaired
mod attempt omitted the list tables, causing zero level-up thresholds; that
attempt is retained as excluded evidence, and the repaired run restarted
from a true fresh game with complete files. MCP preflight now rejects each
missing rule/map file before native loading, and V3 identity includes all
nine files. Regression tests cover missing-file recovery in the same process,
changed-file rejection, legacy opt-in and lineage persistence.

Actual manual battle176 exposed a shared legacy hidden-weapon bug. 袁承志
used owned 黑血神针35 against 欧阳锋 with naturally grown poison resistance112:
item1→0, HP956→948 and poison0→−9. Active Pascal has the same formula, so
this is a deliberate shared bug correction rather than a rewrite-only parity
claim. Resistance now cannot make added poison negative, and poison is clamped
to0–99. Seven asset-free boundary cases cover ordinary resistance,99,100,112,
existing poison and the cap; the exact earned-state replay on0.2.6 preserves
HP956→948 and item consumption while poison stays0. Original and corrected
RPCs and hashes are in `tmp/campaign/root-condor/`.

Root's separate no-doctor 碧血 branches dismiss both physicians normally,
win 玉真子161, and then exercise 袁承志 at high ethics, exactly75 and74.
Exactly75 still gives book156, 金蛇121 and recruitment; the guide's `>75`
is an inclusive75 boundary in the actual data. At74 the first talk refuses,
the next offers battle, cancellation changes nothing, and victory101 gives
the book without recruiting 袁. The event removes itself and cannot duplicate
the reward. The74 state was earned through ordinary 功德箱 theft choices;
the75 boundary used one native donation. `tmp/campaign/root-bixue-no-doctor/`
retains the distinct legitimate checkpoints, transcript and provenance.

Root also took the evil 射雕 spare一灯 choice from the alternate campaign's
earned pre-choice checkpoint. Native guardians179–182 each won in1round,
spare choice led battle175 (won2) and 一阳指96. Final186's cancel branch
awarded nothing; acceptance led a real7round loss and no book. Further legitimate 天龙 recruitment, owned food, spider fights and party
reordering were followed by real AI/manual losses. The latest saved
`spare186_reformed_ready` still has no 射雕 book. This branch needs further
normal growth/tactics before a retry. It is not merged into
either combined campaign.

These regressions and supplementary branch saves support fidelity, not campaign
completion. Native AI can stall after learning an MP-draining art: primary177
was allowed to repeat to3012rounds, then manually finished in an excluded
tactical trial. The campaign restored the earned pre-fight state and won
manually in6rounds without retaining that MP growth. Clients should inspect
each100round pause and switch tactics when needed, rather than blindly loop.

Static checks remain useful for malformed records and references. They are
supplementary checks throughout this work, not the campaign acceptance test.

## Completed primary ending and additional actual-play results

Primary RPC2730 saved all14books before 南贤. Tournament RPC2778–2924 won
**18 solo fights**, not the guide's15; group133 won2 at2931. Correct placement
of all14books consumed each one and awarded 神杖205 at2952. 钓鱼岛 battles
128/129/130/131 won4/8/7/3 rounds at3028/3092/3135/3170. The first130 attempt
actually lost at3112 with injury66; a restored earned checkpoint, native
medicine/rest and a real replay won. The final fight manually killed the
guide's priority support enemy, then native ending dialogue ran and `Where=3`
was observed at3171. Final checkpoint3173 is `diaoyu_stage4_won`. The island
requires a rotating companion roster: each companion fights once, a rule the
guide omits. See `reference/strict/completion.md`.

Final two island fights used0.2.7 SHA-256
`372DC2F44B4EFBC9DE8206233A77B0049AD002432BE70F974F9C9EAAFA415AB2`.
Earlier progression used preceding builds and imported earned saves with
explicit legacy lineage. This establishes a completed native route, not a
fresh final-build campaign or every branch. Graphical behavior is untested.

The hidden branch under `sidequests/hidden/` used the earned all14books source
with exact provenance. Western shovel teaching clears the event flag; normal
南贤 conversations692→693 additionally clear building4414. Before those
conversations the passage was legitimately blocked, not a confirmed data bug.
After activation, actual keyboard corridor steps reached the stone and
script882 replaced the first martial slot with 神山110, retaining manual134.
Repeat stepping gave no further reward. The other starter-manual alternatives
remain unplayed.

Independent `sidequests/paired-saber/` play placed both earned knives using
the wrong compass182 in both orders. Current-facing RPC14 confirmed no slot
helper substitution. Correct knives19–20 also worked. Scripts203–206 use
inventory opcode18 rather than selected-item opcode4 in both native versions.
This shared mod behavior disagrees with the guide's explicit blade selection;
author intent is unverified and no speculative repair is applied.

## Outstanding acceptance work

- Finish the separate spare一灯 final186; kill一灯 final185 has passed.
- Reconcile any remaining pre-fix fight-specific obligations. The requested
  older 白马92/91 replay on the corrected build has passed.
- Validate the remaining exclusive starter-manual hidden arts with naturally
  obtained manuals; existing 松風→神山 evidence covers only one alternative.
- Keep the scene10 wine candidate scoped to the recorded runtime plus
  reachability/source analysis below. No pre-clear item-use failure was
  reproduced and no repair is justified by the heuristic alone.
- Preserve failed attempts, build/data provenance and unvisited statuses.

The goal remains active. A primary ending plus selected opposite branches
does not establish every branch, every approach or all-game stability.

## Reconciled optional guide coverage

The alternate combined campaign now has all14 books:187/183/184/185 won
1/1/4/4 rounds, final185 manually and without a forced result. Natural shovel
九阳, prior earned book experience and ordinary fights developed the needed
art; 王 survived with owned armor/medicine and legal retreat. Exact lines2254–
2257 establish148/84 and fourteen owned books. The original low-level 白马
checkpoint was replayed on0.2.7:92 won5,91 won4, native approach/jump, owned
玄铁 gate and one-time149 reward. Lin revenge, both Huo alternatives and the
pre一灯 Mei quest also passed. Starting 一灯 removes Mei's cave event before
the moral choice; the guide omits that deadline. See alternate/strict/handoff.md.

The primary supplementary run used four hashed earned checkpoints and current
binary47A1. Native results include delayed 霍132; separate 苏荃/阿珂 recruitment
and their mutual party exclusion; 虚竹 inheritance, 灵鹫202, 丁86, 苏回报 and
薛188; all six wooden/copper solo fights and168/85; 瑛姑/周235 and speed+20;
小龙女/读172; early 蓝凤凰 healing and later173 recruitment; football win/loss;
and merit-box donation/withdrawal. The actual guide timing/threshold differences
are recorded without speculative patches in reference-sidequests/findings.md.

The 灵鹫 all-seven picture sequence fails as a mod-data defect:624+7 routes
to unrelated631 instead of630. Two independent actual replays, the clean
pre-picture checkpoint and native original/repaired fixture are retained. The
guarded separate repair appends dedicated counter states and retains all
existing scripts. Separate fresh repaired progression has now passed; see
DRAGON_FINDINGS.md and the evidence below. The original-data defect remains
a failing original route, not a silently converted pass.

The new armored root186 attempt killed four enemies with a real manual玄鐵
opening but 王 still died before her first turn; remaining native AI lost6.
`spare186_armored_loss` records it. The earned pre-fight state was restored
without retaining loss growth. Further normal preparation remains necessary.

## Fresh repaired 灵鹫宫 campaign

The independent repaired-data campaign started from `new_game(seed=7)` on
0.2.7 SHA-256 `47A1C01338C1C8005D2079D9CF7EEF60195068E9DA2A5510D10C5831A29EB522`.
Its complete 21-file runtime manifest matches at completion, with only the
three guarded picture-package files differing from the original. All 497 RPCs
used native progression; there were no debug calls, imported checkpoints,
grants, forced wins, direct scripts, save edits or identity bypass. Every
observed state has clean lineage. All three checkpoint loads refer to saves
earned earlier by this same fresh process.

Ordinary fighting, loot, donations and Western-village teaching/refusal earned
ethics75. Native recruitment291 accepted 虚竹 at exactly75, a small inclusive
boundary difference from the guide's `>75`. 苏星河296, actual `(24,23)` step297
and rejoining299 earned the transformation, manuals and ring. The first
palace202 attempt genuinely lost5rounds at342. Its earned pre-entry checkpoint
was restored; owned-book practice, 21 total native224 wins, medicine and home
rest prepared the next attempt. Palace202 won8rounds at428, and the normal
inheritance dialogue granted palace ownership.

From the earned pre-picture checkpoint, descending slots22/21/20/18/17/16/15
at433–453 and ascending15/16/17/18/20/21/22 at465–492 both advanced1087→1094
only once per distinct picture. Central clicks after0–6 pictures gave nothing;
after7 they awarded79 exactly once, taught 虚竹 magic101 at proficiency0 and
raised aptitude55→65. In the ascending replay, every picture was immediately
repeated from the same actual position/facing; no repeat had a trigger or
advanced the counter. The separate chest gave99 once and magic14 at
proficiency0; both central and chest repeat interactions were empty. Failed
slot-targeted/guessed-coordinate repeat approaches are retained separately
and are not used as evidence of successful navigation.

`tmp/campaign/fidelity-pictures/repaired/` retains `report.md`, all 497 RPCs,
`validation.json`, exact provenance and the final earned save. All 19 scoped
assertions passed. The original executable was used directly, no private
binary copies were made, and the process closed with exit0. This is a fresh
validation of the repaired prerequisite/reward chain and two reading orders,
not a fresh final-build whole-game run or exhaustive order/tactics coverage.
Graphical behavior and the later 星宿/薛 quests were not replayed by this
fresh repaired run; their original-data evidence remains separately labeled.
