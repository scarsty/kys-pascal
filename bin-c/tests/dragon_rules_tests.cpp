#include "kys_rules.h"
#include "rules/dragon_dos12.h"
#include "rules/growth_state.h"
#include "rules/rules_internal.h"
#include "kys_event.h"
#include "kys_main.h"
#include "kys_frontend.h"
#include "mods/mod.h"
#include <array>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include <utility>
#include <tuple>

namespace dos = rules::dragon_dos12;

namespace
{
void check(bool condition, const char* message)
{
    if (!condition)
    {
        throw std::runtime_error(message);
    }
}

const RulesRandom zero = [](int) { return 0; };
const RulesRandom maximum = [](int bound) { return bound - 1; };

TRole role()
{
    TRole r{ };
    r.Level = 1;
    r.IncLife = 3;
    r.Aptitude = 70;
    r.CurrentHP = r.MaxHP = 100;
    r.CurrentMP = r.MaxMP = 100;
    r.Attack = r.Speed = r.Defence = 30;
    r.PhyPower = 100;
    r.Equip[0] = r.Equip[1] = -1;
    for (int index : { 46, 47, 48, 50, 51, 52, 54 })
    {
        r.Data[index] = 30;
    }
    return r;
}

RulesRandom sequence(unsigned& state)
{
    return [&state](int bound)
    {
        state = state * 1664525u + 1013904223u;
        return static_cast<int>((state >> 1) % bound);
    };
}

struct TemporaryIni
{
    std::filesystem::path path = std::filesystem::temp_directory_path() /
        ("kys-mod-config-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()) + ".ini");
    ~TemporaryIni() { std::filesystem::remove(path); }
    void write(const std::string& text) const { std::ofstream out(path); out << text; }
    void load(const std::string& text) const { write(text); LoadGameRules(path.string()); }
};

void selectMod(int version)
{
    TemporaryIni ini;
    ini.write("[system]\nMODVersion=" + std::to_string(version) + "\n");
    mods::LoadDefinition(ini.path.string());
}

void specialStartingStats()
{
    selectMod(12);
    for (auto random : { zero, maximum })
    {
        auto ordinary = role();
        auto expected = ordinary;
        dos::RollStartingStats(expected, random);
        auto result = mods::Active().createStartingStats(ordinary, "ordinary", random);
        check(!result.fixed && std::memcmp(&ordinary, &expected, sizeof(ordinary)) == 0,
            "Ordinary names must use the complete DOS starting roll and allow rerolls");
        for (auto [name, attack, aptitude] : { std::tuple{ "\xe5\xb0\x8f\xe5\xb0\x8f\xe8\xb1\xac", 30, 100 }, { "\xe8\xa6\x8b\xe8\xb3\xa2\xe6\x80\x9d\xe9\xbd\x8a", 60, 45 } })
        {
            auto hero = role();
            hero.DefPoi = 99;
            int draws = 0;
            result = mods::Active().createStartingStats(hero, name, [&](int bound) { ++draws; return random(bound); });
            check(!result.fixed && draws == 17 && mods::Active().applySpecialStartingStats(hero, name),
                "Special names must initialize DOS stats exactly once before selecting fixed stats");
            check(hero.CurrentHP == 50 && hero.MaxHP == 50 && hero.CurrentMP == 50 && hero.MaxMP == 50 && hero.MPType == 2 && hero.IncLife == 10,
                "Special names must set the original preset HP and MP");
            check(hero.Attack == attack && hero.Defence == attack && hero.Speed == 30 && hero.Aptitude == aptitude,
                "Special name preset must use the expected attributes");
            check(hero.Medicine == 30 && hero.UsePoi == 30 && hero.MedPoi == 30 && hero.Fist == 30 && hero.Sword == 30 && hero.Knife == 30 && hero.Unusual == 30 && hero.HidWeapon == 30 && hero.DefPoi == expected.DefPoi,
                "Special names must retain DOS initialization for attributes outside their presets");
        }
    }
    selectMod(11);
    auto hero = role();
    auto result = mods::Active().createStartingStats(hero, "\xe5\xb0\x8f\xe5\xb0\x8f\xe8\xb1\xac", zero);
    check(!result.fixed && hero.MaxHP == 25 && hero.MaxMP == 25 && hero.Aptitude == 1,
        "Other mods must retain their own character creation");
    selectMod(23);
    for (const char* name : { "遊客", "游客" })
    {
        hero = role();
        check(mods::Active().applySpecialStartingStats(hero, name), "Xiaomeng must recognize both visitor spellings");
        check(hero.MaxHP == 50 && hero.MaxMP == 50 && hero.Aptitude == 100
                && hero.Magic[0] == 94 && hero.MagLevel[0] == 850 && hero.AttTwice == 1,
            "The visitor preset must include its starting stats, magic and double attacks");
    }
    selectMod(12);
}

void startingStats()
{
    const std::array<int, 17> bounds = { 2, 20, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5, 10, 35 };
    for (int tier : { 0, 1, 2, 7, 8, 9 })
    {
        for (bool high : { false, true })
        {
            auto r = role();
            r.Ethics = 77;
            int drawIndex = 0;
            dos::RollStartingStats(r, [&](int bound)
            {
                check(drawIndex < static_cast<int>(bounds.size()), "Starting rolls must not draw extra values");
                int expected = drawIndex == 16 && tier >= 2 ? 20 : bounds[drawIndex];
                check(bound == expected, "Starting roll order and bounds must match DOS");
                int value = drawIndex == 15 ? tier : high ? bound - 1 : 0;
                ++drawIndex;
                return value;
            });
            check(drawIndex == 17, "Starting rolls must consume every DOS draw");
            int aptitudeBase = tier < 2 ? 30 : tier < 8 ? 60 : 75;
            int aptitudeSpread = tier < 2 ? 35 : 20;
            check(r.Aptitude == aptitudeBase + (high ? aptitudeSpread - 1 : 0), "Aptitude bands must match DOS");
            check(r.MPType == int(high) && r.MaxMP == (high ? 40 : 21) && r.CurrentMP == r.MaxMP,
                "Starting MP must match DOS and be full");
            for (int i = 43; i <= 54; ++i)
                check(r.Data[i] == (high ? 30 : 21), "All twelve DOS starting stats, including poison resistance, must be rolled");
            check(r.IncLife == (high ? 7 : 3) && r.MaxHP == (high ? 50 : 38) && r.CurrentHP == r.MaxHP,
                "Starting HP must be tied to the DOS growth base");
            check(r.Ethics == 77 && r.Level == 1, "Starting rolls must preserve unrelated role data");
        }
    }
    auto r = role();
    r.Level = 2;
    dos::RollStartingStats(r, zero);
    check(r.MaxHP == 47, "Starting HP must account for the template's level");
    mods::Active().createStartingStats(r, "ordinary", zero);
    check(r.MaxHP == 47 && r.MaxMP == 21, "Dragon must select DOS starting rolls");
}

void levelGrowth()
{
    SetGrowthMode(GrowthMode::FixedRandom);
    Rrole[0] = role();
    std::fill(std::begin(Rrole[0].TakingItem), std::end(Rrole[0].TakingItem), -1);
    rules::growth::WriteSeed(Rrole[0], 0x12345678);
    for (int aptitude : { 0, 29, 30, 49, 50, 69, 70, 89, 90, 100 })
    {
        auto batch = role(), separate = batch;
        batch.Aptitude = separate.Aptitude = aptitude;
        unsigned batchSeed = 12345, separateSeed = batchSeed;
        auto batchRandom = sequence(batchSeed), separateRandom = sequence(separateSeed);
        batch.Exp = 750;
        check(dos::LevelUp(batch, batchRandom, 15) == 5, "Batch must gain five levels");
        for (int xp : { 50, 150, 300, 500, 750 })
        {
            separate.Exp = xp;
            check(dos::LevelUp(separate, separateRandom, 15) == 1, "Separate settlement must gain one level");
        }
        check(std::memcmp(&batch, &separate, sizeof(batch)) == 0,
            "Batch and separate growth must match for the same random sequence");
        check(batchSeed == 12345 && separateSeed == 12345, "Fixed growth must not consume the supplied ordinary RNG");
    }
    SetGrowthMode(GrowthMode::Average);
    auto r = role();
    r.Exp = 750;
    dos::LevelUp(r, [](int bound) { return std::min(1, bound - 1); });
    check(r.Medicine == 35 && r.UsePoi == 35 && r.MedPoi == 35 && r.Fist == 35
            && r.Sword == 35 && r.Knife == 35 && r.HidWeapon == 35,
        "All seven eligible abilities must grow five times");
    r = role();
    r.Exp = 750;
    r.Medicine = r.UsePoi = r.MedPoi = 99;
    r.Fist = 20;
    r.Sword = 21;
    r.HidWeapon = 0;
    r.Hurt = r.Poison = 50;
    SetGrowthMode(GrowthMode::Maximum);
    dos::LevelUp(r, maximum);
    check(r.Medicine == 100 && r.UsePoi == 100 && r.MedPoi == 100, "Medical caps must apply per level");
    check(r.Fist == 20 && r.Sword == 31 && r.HidWeapon == 10, "Growth eligibility must remain intact");
    check(r.CurrentHP == r.MaxHP && r.CurrentMP == r.MaxMP && r.PhyPower == 100
            && r.Hurt == 0 && r.Poison == 0,
        "Level-up must restore resources and clear status");
    r.Exp = 52000;
    check(dos::LevelUp(r, maximum) == 24 && r.Level == 30, "Cumulative XP must reach level 30");
    check(dos::LevelUp(r, maximum) == 0, "Level cap must prevent further growth");
    check(!DescribeGameRules().batchGrowth, "Rule metadata must describe per-level rolls");
    SetGrowthMode(GrowthMode::Original);
}

template<class F> void rejects(F fn, const char* message)
{
    bool rejected = false;
    try { fn(); } catch (const std::runtime_error&) { rejected = true; }
    check(rejected, message);
}

void scriptMutationBounds()
{
    struct ScriptFrontend : GameFrontend
    {
        int lastOpcode = -1;
        void text(const std::string&, int) override { }
        int choose(const std::string&, const std::vector<std::string>&, bool) override { return 0; }
        int number(int minimum, int, int) override { return minimum; }
        bool battle(int, int) override { return false; }
        bool aim(int, int, int, int) override { return false; }
        void instruction(int, int, int opcode) override { lastOpcode = opcode; }
    } frontend;
    struct Restore
    {
        decltype(KIdx) idx = std::move(KIdx);
        decltype(KDef) def = std::move(KDef);
        GameFrontend* frontend = Frontend;
        int16_t value = x50[0];
        ~Restore() { KIdx = std::move(idx); KDef = std::move(def); Frontend = frontend; x50[0] = value; }
    } restore;
    Frontend = &frontend;
    x50[0] = 7;
    auto run = [](int16_t target)
    {
        const std::array<int16_t, 9> script = { 50, 32, 0, 0, target, 0, 0, 0, 99 };
        KIdx = { sizeof(script) };
        KDef.resize(sizeof(script));
        std::memcpy(KDef.data(), script.data(), sizeof(script));
        CallEvent(0);
    };
    rejects([&] { run(100); }, "Script mutation must reject targets beyond the script");
    rejects([&] { run(1); }, "Script mutation must not write into the synthetic terminator");
    run(0);
    check(frontend.lastOpcode == 7, "A valid mutation must replace and execute the next opcode");
}

void originalGrowth()
{
    SetGrowthMode(GrowthMode::Original);
    for (int roll : { 0, 5 })
    {
        auto r = role();
        r.Aptitude = 90;
        r.Exp = 750;
        int calls = 0;
        dos::LevelUp(r, [&](int bound)
        {
            check(bound == (calls == 0 ? 6 : 3), "DOS batch random bounds must match Z.dat");
            return calls++ == 0 ? roll : calls == 2 ? (roll ? 2 : 0) : 1;
        });
        check(calls == 9 && r.Level == 6, "Original mode must roll once per batch, including abilities");
        check(r.Attack == (roll ? 60 : 35) && r.Speed == r.Attack && r.Defence == r.Attack,
            "Original linked stat extremes must match Z.dat");
        check(r.MaxHP == (roll ? 175 : 145) && r.MaxMP == (roll ? 160 : 260),
            "Original HP and inverse MP batch growth must match Z.dat");
        check(r.Medicine == 31 && r.HidWeapon == 31, "Original batch must preserve one ability settlement");
        check(r.UnUse == 0, "Original mode must not touch fractional carry");
    }
    check(DescribeGameRules().batchGrowth && DescribeGameRules().growthMode == "original", "Original metadata must describe batch rolls");
}

void averageAndMaximum()
{
    SetGrowthMode(GrowthMode::Average);
    for (auto [aptitude, twice] : { std::pair{ 0, 3 }, { 30, 4 }, { 50, 5 }, { 70, 6 }, { 90, 7 } })
    {
        auto r = role();
        r.Aptitude = aptitude;
        r.Exp = 150;
        dos::LevelUp(r, [](int) -> int { throw std::runtime_error("Average must not draw randomness"); });
        check(r.Attack == 30 + twice && r.Speed == r.Attack && r.Defence == r.Attack, "Two average levels must equal the exact stat mean");
        check(r.MaxMP == 100 + 4 * (18 - twice) && r.MaxHP == 124, "Average HP and MP must use their own mathematical means");
        check(r.Sword == 32 && !rules::growth::HasHalf(r), "Average weapon growth must be +1 per eligible level");
    }
    auto r = role();
    r.Aptitude = 90;
    r.Exp = 50;
    dos::LevelUp(r);
    check(r.Attack == 33 && r.MaxMP == 122 && rules::growth::HasHalf(r), "First 3.5 growth must carry a half");
    auto carry = r.UnUse;
    auto seed = rules::growth::ReadSeed(Rrole[0]);
    SetGrowthMode(GrowthMode::Maximum);
    SetGrowthMaxPriority(GrowthMaxPriority::Stats);
    r.Exp = 150;
    dos::LevelUp(r);
    check(r.Attack == 39 && r.MaxMP == 134 && r.UnUse == carry, "Maximum must preserve average carry and honor linked stats");
    SetGrowthMode(GrowthMode::Average);
    r.Aptitude = 70;  // integer mean must not discard the old half
    r.Exp = 300;
    dos::LevelUp(r);
    check(r.Attack == 42 && r.UnUse == carry, "Integer mean at another aptitude must preserve carry");
    r.Aptitude = 50;  // another fractional tier consumes the same carry
    r.Exp = 500;
    dos::LevelUp(r);
    check(r.Attack == 45 && !rules::growth::HasHalf(r), "Aptitude changes must share the same half-bit");
    check(seed == rules::growth::ReadSeed(Rrole[0]), "Switching modes must never reseed growth");
    SetGrowthMode(GrowthMode::Maximum);
    for (auto priority : { GrowthMaxPriority::Stats, GrowthMaxPriority::Mp })
    {
        SetGrowthMaxPriority(priority);
        auto m = role();
        m.Aptitude = 90;
        m.Exp = 750;
        m.Fist = 20;
        m.Unusual = 40;
        dos::LevelUp(m, [](int) -> int { throw std::runtime_error("Maximum must not draw randomness"); });
        check(m.Attack == (priority == GrowthMaxPriority::Stats ? 60 : 35) && m.Speed == m.Attack && m.Defence == m.Attack,
            "Maximum preference must choose a single attainable joint roll");
        check(m.MaxMP == (priority == GrowthMaxPriority::Stats ? 160 : 260) && m.MaxHP == 175,
            "Maximum independent HP must coexist with the chosen MP/stat tradeoff");
        check(m.Sword == 40 && m.Fist == 20 && m.Unusual == 40 && m.HidWeapon == 40,
            "Maximum must grow only eligible DOS abilities every level");
    }
    // Multiplication precedes rounding for custom factors (3.5*2=7).
    auto factors = rules::config.growth;
    rules::config.growth = { 3, 1, 2, 3, 0 };
    SetGrowthMode(GrowthMode::Average);
    r = role(); r.Aptitude = 90; r.Exp = 50;
    dos::LevelUp(r);
    check(r.Attack == 37 && r.Speed == 40 && r.Defence == 30 && r.MaxMP == 106, "Custom average factors must round after multiplication with complementary MP rounding");
    r.Exp = 150;
    dos::LevelUp(r);
    check(r.Attack == 44 && r.Speed == 51 && r.MaxMP == 111, "Two average levels must exactly preserve custom-factor means");
    rules::config.growth = factors;
    SetGrowthMaxPriority(GrowthMaxPriority::Stats);
    SetGrowthMode(GrowthMode::Original);
}

void fixedGrowth()
{
    SetGrowthMode(GrowthMode::FixedRandom);
    auto savedHero = Rrole[0];
    auto initial = role();
    initial.Aptitude = 90; initial.Exp = 750;
    Rrole[17] = Rrole[18] = initial;
    AdvanceRoleLevels(Rrole[17]);
    auto result17 = Rrole[17];
    AdvanceRoleLevels(Rrole[18]);
    auto result18 = Rrole[18];
    Rrole[0] = savedHero;
    Rrole[17] = Rrole[18] = initial;
    for (int i = 0; i < 100; ++i) GameRandom();
    AdvanceRoleLevels(Rrole[18]);
    AdvanceRoleLevels(Rrole[17]);
    check(std::memcmp(&result17, &Rrole[17], sizeof(TRole)) == 0 && std::memcmp(&result18, &Rrole[18], sizeof(TRole)) == 0,
        "Reload, battle RNG consumption and other characters' leveling order must not reroll fixed growth");
    check(std::memcmp(&savedHero, &Rrole[0], sizeof(TRole)) == 0, "Fixed draws must leave the persisted seed unchanged");
    auto changed = initial;
    changed.Medicine = 0;
    dos::LevelUp(changed, zero, 17);
    check(changed.Attack == result17.Attack && changed.MaxHP == result17.MaxHP && changed.Sword == result17.Sword,
        "Changing one ability's eligibility must not shift other fixed draws");
    unsigned seen = 0;
    check(rules::growth::FixedDraw(0x12345678, 17, 2, 0, 6) == 2
            && rules::growth::FixedDraw(0x12345678, 17, 2, 1, 3) == 0
            && rules::growth::FixedDraw(0x12345678, 18, 2, 0, 6) == 0
            && rules::growth::FixedDraw(0x12345678, 17, 3, 0, 6) == 3
            && rules::growth::FixedDraw(0x12345678, 17, 2, 50, 3) == 1,
        "V1 fixed draws must remain stable for existing campaigns");
    for (uint32_t seed = 0; seed < 300; ++seed)
        for (int group : { 0, 1, 46, 47, 48, 50, 51, 52, 54 })
        {
            int bound = group == 0 ? 6 : 3;
            int draw = rules::growth::FixedDraw(seed, 17, 2, group, bound);
            check(draw >= 0 && draw < bound, "Fixed growth draws must stay in original ranges");
            if (group == 0) seen |= 1u << draw;
        }
    check(seen == 63, "Fixed growth must allow every original stat outcome");
    SetGrowthMode(GrowthMode::Original);
}

void growthStorage()
{
    namespace g = rules::growth;
    std::array<TRole, 3> old{ role(), role(), role() };
    std::fill(std::begin(old[0].TakingItem), std::end(old[0].TakingItem), -1);
    std::fill(std::begin(old[0].TakingItemAmount), std::end(old[0].TakingItemAmount), 3);
    std::memcpy(old[0].Nick, "nickname", 9);
    old[0].UnUse = 1;
    old[1].UnUse = 80;
    auto migrated = old, again = old;
    g::PrepareLoadedRoles(migrated);
    for (int i = 0; i < 50; ++i) GameRandom();
    g::PrepareLoadedRoles(again);
    check(std::memcmp(migrated.data(), again.data(), sizeof(old)) == 0, "Importing the same old save must deterministically reproduce the seed");
    check(g::HasSeed(migrated[0]) && !g::HasHalf(migrated[0]) && !g::HasHalf(migrated[1]), "Unmarked legacy fields must not be mistaken for metadata");
    auto once = migrated;
    g::PrepareLoadedRoles(migrated);
    check(std::memcmp(migrated.data(), once.data(), sizeof(old)) == 0, "Loading recognized metadata must be idempotent");
    for (uint32_t seed : { 0u, 1u, 0x12345678u, 0xffffffffu })
    {
        auto hero = old[0];
        g::WriteSeed(hero, seed);
        check(g::ReadSeed(hero) == seed, "All 32 seed bits must survive packing");
        std::array<int16_t, 4> expected = seed == 0 ? std::array<int16_t, 4>{ 0, 0, 21852, 9128 } :
            seed == 1 ? std::array<int16_t, 4>{ 1, 0, 19124, 9128 } :
            seed == 0x12345678 ? std::array<int16_t, 4>{ 22136, 9320, 21896, 9128 } :
            std::array<int16_t, 4>{ 32767, 32767, 24795, 9128 };
        check(std::equal(expected.begin(), expected.end(), hero.TakingItemAmount), "V1 seed storage must match DOS round-trip fixtures exactly");
        for (int i = 0; i < 4; ++i) check(hero.TakingItem[i] == -1 && hero.TakingItemAmount[i] >= 0, "Editor-facing item IDs and signed quantity ranges must remain valid");
        for (int i = 0; i < 174; ++i)
            check(reinterpret_cast<unsigned char*>(&hero)[i] == reinterpret_cast<unsigned char*>(&old[0])[i], "Seed writes must not touch nickname or any preceding role field");
        hero.TakingItemAmount[0] ^= 1;
        check(!g::HasSeed(hero), "A changed seed word must fail checksum validation");
        rejects([&] { g::ReadSeed(hero); }, "A damaged seed must never be silently accepted");
        auto damaged = migrated;
        damaged[0] = hero;
        rejects([&] { g::PrepareLoadedRoles(damaged); }, "Recognizable damaged metadata must not silently reseed");
    }
    auto conflict = old;
    conflict[0].TakingItem[2] = 10;
    SetGrowthMode(GrowthMode::FixedRandom);
    rejects([&] { g::PrepareLoadedRoles(conflict); }, "Occupied hero personal items must reject fixed RNG storage");
    check(conflict[0].TakingItem[2] == 10 && conflict[0].TakingItemAmount[2] == 3, "A storage conflict must preserve real personal items");
    Rrole[0] = migrated[0];
    auto reserved = Rrole[0];
    rejects([&] { instruct_41(0, 5, 1); }, "Instruction 41 must reject conflicting metadata writes before mutation");
    check(std::memcmp(&reserved, &Rrole[0], sizeof(TRole)) == 0, "Rejected event writes must preserve the seed");
    g::StoreHalf(migrated[1], true);
    g::StartCampaign(migrated, 123);
    check(g::ReadSeed(migrated[0]) == 123 && !g::HasHalf(migrated[1]), "A new campaign must get its seed and reset recognized carry");
    SetGrowthMode(GrowthMode::Original);
}

void saveRoundTrip()
{
    namespace fs = std::filesystem;
    auto dir = fs::temp_directory_path() / ("kys-growth-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    check(fs::create_directory(dir), "Create isolated save fixture directory");
    fs::create_directory(dir / "save");
    struct Cleanup
    {
        fs::path dir;
        std::string appPath = AppPath;
        ~Cleanup()
        {
            AppPath = appPath;
            for (const char* file : { "ranger.idx", "r1.grp", "r2.grp", "s2.grp", "d2.grp" }) fs::remove(dir / "save" / file);
            fs::remove(dir / "save"); fs::remove(dir);
        }
    } cleanup{ dir };
    AppPath = dir.generic_string() + "/";
    std::array<uint32_t, 6> ends;
    ends[0] = 36 + MAX_ITEM_AMOUNT * sizeof(TItemList);
    ends[1] = ends[0] + 3 * sizeof(TRole);
    ends[2] = ends[1] + sizeof(TItem);
    ends[3] = ends[2] + sizeof(TScene);
    ends[4] = ends[3] + sizeof(TMagic);
    ends[5] = ends[4] + sizeof(TShop);
    std::vector<char> original(ends[5]);
    std::array<TRole, 3> roles{ role(), role(), role() };
    std::fill(std::begin(roles[0].TakingItem), std::end(roles[0].TakingItem), -1);
    std::memcpy(roles[0].Nick, "nickname", 9);
    rules::growth::WriteSeed(roles[0], 0xffffffffu);
    rules::growth::StoreHalf(roles[1], true);
    std::memcpy(original.data() + ends[0], roles.data(), sizeof(roles));
    {
        std::ofstream idx(dir / "save/ranger.idx", std::ios::binary);
        idx.write(reinterpret_cast<const char*>(ends.data()), sizeof(ends));
        std::ofstream grp(dir / "save/r1.grp", std::ios::binary);
        grp.write(original.data(), original.size());
    }
    LoadR(1);
    check(rules::growth::ReadSeed(Rrole[0]) == 0xffffffffu && rules::growth::HasHalf(Rrole[1]), "Native LoadR must restore seed and character carry");
    SaveR(2);
    std::ifstream saved(dir / "save/r2.grp", std::ios::binary);
    std::vector<char> actual{ std::istreambuf_iterator<char>(saved), std::istreambuf_iterator<char>() };
    check(actual == original, "Native LoadR/SaveR must preserve every R byte, file length and existing section offset");
    saved.close();
    auto halfRole = Rrole[1];
    SetGrowthMode(GrowthMode::Average);
    Rrole[1].Aptitude = 90; Rrole[1].Exp = 50;
    AdvanceRoleLevels(Rrole[1]);
    check(Rrole[1].Attack == halfRole.Attack + 4 && !rules::growth::HasHalf(Rrole[1]), "A reloaded character must resume its saved fractional carry");
    SetGrowthMode(GrowthMode::Original);

    // Other mods may use the same words for unrelated data, including values
    // that resemble damaged Dragon metadata. Load/save must leave them alone.
    roles[0].TakingItemAmount[0] ^= 1;
    std::memcpy(original.data() + ends[0], roles.data(), sizeof(roles));
    {
        std::ofstream grp(dir / "save/r1.grp", std::ios::binary);
        grp.write(original.data(), original.size());
    }
    selectMod(0);
    LoadR(1);
    SaveR(2);
    std::ifstream remakeSaved(dir / "save/r2.grp", std::ios::binary);
    actual.assign(std::istreambuf_iterator<char>(remakeSaved), std::istreambuf_iterator<char>());
    check(actual == original, "Remake LoadR/SaveR must preserve unrelated role words without interpreting Dragon metadata");
    selectMod(12);
}

template<class F> void rejectsWith(F fn, const std::string& expected)
{
    try { fn(); }
    catch (const std::runtime_error& error)
    {
        check(std::string(error.what()).find(expected) != std::string::npos, "Configuration error must explain the conflicting setting");
        return;
    }
    throw std::runtime_error("Expected invalid mod configuration to be rejected");
}

void modConfiguration()
{
    TemporaryIni ini;
    for (const char* text : { "[system]\nMODVersion=12\n", "[system]\nMODVersion=0x0c\n", "[system]\nMODVersion=014\n", "[system]\nMODVersion=+12\n", "[rules]\nprofile=dragon_dos12\n",
             "[system]\nMODVersion=12\n[rules]\nprofile=dragon_dos12\nprogression=dragon_dos12\ncombat=dragon_dos12\n",
             "[rules]\nprogression=dragon_dos12\n", "[rules]\ncombat=dragon_dos12\n" })
    {
        ini.load(text);
        auto info = DescribeGameRules();
        check(MODVersion == 12 && mods::Active().version() == 12 && HasConfigurableGrowth(), "Every Dragon selector must resolve one complete mod");
        check(info.profile == "dragon_dos12" && info.progression == info.profile && info.combat == info.profile,
            "Dragon must always report DOS combat and progression together");
        check(MAX_LEVEL == 30 && MAX_HP == 999 && MAX_MP == 9999 && MAX_PHYSICAL_POWER == 100,
            "MODVersion alone must select all DOS defaults");
    }
    for (const char* key : { "profile", "progression", "combat" })
        for (const char* value : { "remake", "legacy" })
            rejectsWith([&] { ini.load(std::string("[system]\nMODVersion=12\n[rules]\n") + key + "=" + value + "\n"); }, "DOS 1.2 rules only");
    for (int version : { 0, 11, 31 })
        rejectsWith([&] { ini.load("[system]\nMODVersion=" + std::to_string(version) + "\n[rules]\nprofile=dragon_dos12\n"); }, "conflicting MODVersion");
    rejectsWith([&] { ini.load("[rules]\nprofile=dragon_dos12\ncombat=remake\n"); }, "combat=remake");
    rejectsWith([&] { ini.load("[rules]\nprofile=remake\nprogression=dragon_dos12\n"); }, "profile=remake");
    for (const char* key : { "profile", "progression", "combat" })
        rejectsWith([&] { ini.load(std::string("[rules]\n") + key + "=typo\n"); }, "Unknown [rules]");
    for (const char* value : { "", "typo", "12oops", "-1" })
        rejectsWith([&] { ini.load(std::string("[system]\nMODVersion=") + value + "\n"); }, "Invalid [system] MODVersion");
    for (const char* text : { "", "[rules]\nprofile=remake\n", "[rules]\nprofile=legacy\n",
             "[system]\nMODVersion=31\n[rules]\nprofile=remake\nprogression=legacy\ncombat=remake\n" })
    {
        ini.load(text);
        auto info = DescribeGameRules();
        check(info.profile == "remake" && info.progression == info.profile && info.combat == info.profile && !HasConfigurableGrowth(),
            "Other mods must retain remake rules and clear previous Dragon selection");
    }
    ini.load("[system]\nMODVersion=12\n");
}

void modCompatibility()
{
    selectMod(12);
    SetMODVersion();
    check(TitleString == "All Heros in Kam Yung's Stories - We Are Dragons" && TitlePosition.x == 200 && TitlePosition.y == 250,
        "Dragon definition must own its presentation defaults");
    check(mods::Active().defaultPlayerName("\xe8\xb3\x87") == "\xe5\xb0\x8f\xe8\x99\xbe\xe7\xb1\xb3" && mods::Active().defaultPlayerName("custom") == "custom" && !mods::Active().renameHomeScene(),
        "Dragon must repair only the known broken default name and preserve its starting scene name");
    int previousScene = CurScene;
    for (int version : { 0, 12, 31 })
    {
        selectMod(version);
        for (bool current : { false, true })
        {
            CurScene = current ? 4 : 3;
            DData[4][0][9] = DData[4][0][10] = 1;
            SData[4][3][1][1] = 77;
            std::vector<int> event(13, -2);
            event[0] = 4; event[1] = 0; event[11] = event[12] = 2;
            instruct_3(event);
            check(SData[4][3][1][1] == (current || version == 0 ? -1 : 77) && SData[4][3][2][2] == 0,
                "Event compatibility must preserve remote tiles for Dragon and mod 31 while updating the new event position");
        }
    }
    CurScene = previousScene;
    selectMod(12);
}

void configOptions()
{
    namespace fs = std::filesystem;
    auto path = fs::temp_directory_path() / ("kys-growth-config-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()) + ".ini");
    struct Cleanup { fs::path path; ~Cleanup() { fs::remove(path); } } cleanup{ path };
    auto load = [&](const std::string& options)
    {
        { std::ofstream out(path); out << "[rules]\nprofile=dragon_dos12\n" << options; }
        LoadGameRules(path.string());
    };
    for (auto [text, mode] : { std::pair{ "original", GrowthMode::Original }, { "fixed_random", GrowthMode::FixedRandom },
             { "average", GrowthMode::Average }, { "maximum", GrowthMode::Maximum } })
    {
        load(std::string("growth_mode=") + text + "\ngrowth_max_priority=mp\n");
        check(GetGrowthMode() == mode && GetGrowthMaxPriority() == GrowthMaxPriority::Mp && HasConfigurableGrowth(), "INI must select each mode and priority");
        check(DescribeGameRules().growthMode == text && DescribeGameRules().growthMaxPriority == "mp", "Rule metadata must expose selected growth configuration");
    }
    rejects([&] { load("growth_mode=typo\n"); }, "Unknown growth mode must not silently select a default");
    rejects([&] { load("growth_max_priority=typo\n"); }, "Unknown maximum priority must be rejected");
    for (const char* profiles : { "", "profile=remake\n", "profile=legacy\n" })
        for (const char* options : { "growth_mode=average\ngrowth_max_priority=mp\n",
                 "growth_mode=unrelated\ngrowth_max_priority=unrelated\n" })
        {
            { std::ofstream out(path); out << "[rules]\n" << profiles << options; }
            LoadGameRules(path.string());
            auto info = DescribeGameRules();
            check(!HasConfigurableGrowth() && !info.growthMode && !info.growthMaxPriority,
                "Only the Dragon mod may expose configurable growth");
            check(GetGrowthMode() == GrowthMode::Original && GetGrowthMaxPriority() == GrowthMaxPriority::Stats,
                "Other profiles must ignore Dragon-only options, including unrelated values");
        }
    load("");
    check(GetGrowthMode() == GrowthMode::Original && GetGrowthMaxPriority() == GrowthMaxPriority::Stats, "Default mode and tradeoff must be explicit and stable");
}

void nonDragonIsolation()
{
    namespace g = rules::growth;
    struct Restore
    {
        rules::Configuration config = rules::config;
        int version = MODVersion;
        TRole hero = Rrole[0];
        decltype(MAX_ADD_PRO) maxAdd = MAX_ADD_PRO;
        int threshold = LevelUpList[0];
        std::array<int, 16> caps;
        Restore() { std::copy(std::begin(MaxProList), std::end(MaxProList), caps.begin()); }
        ~Restore()
        {
            rules::config = config;
            selectMod(version);
            Rrole[0] = hero;
            MAX_ADD_PRO = maxAdd;
            LevelUpList[0] = threshold;
            std::copy(caps.begin(), caps.end(), std::begin(MaxProList));
        }
    } restore;
    auto hero = role();
    std::fill(std::begin(hero.TakingItem), std::end(hero.TakingItem), -1);
    g::WriteSeed(hero, 123);
    std::array<TRole, 4> fixtures{ role(), hero, hero, role() };
    std::fill(std::begin(fixtures[0].TakingItem), std::end(fixtures[0].TakingItem), -1);
    fixtures[2].TakingItemAmount[0] ^= 1;
    fixtures[3].TakingItem[0] = 5;
    fixtures[3].TakingItemAmount[0] = 9;
    LevelUpList[0] = 50;
    std::fill(std::begin(MaxProList), std::end(MaxProList), 999);
    for (int version : { 0, 11, 22, 31, 41 })
    {
        selectMod(version);
        auto starting = role();
        auto result = mods::Active().createStartingStats(starting, "ordinary", zero);
        check(!result.fixed && starting.MaxHP == 25 && starting.MaxMP == 25 && starting.Aptitude == 1,
            "Other mods must retain their own starting rolls");
        for (auto mode : { GrowthMode::Original, GrowthMode::FixedRandom, GrowthMode::Average, GrowthMode::Maximum })
        {
            SetGrowthMode(mode);
            for (const auto& fixture : fixtures)
            {
                std::array<TRole, 2> saved{ fixture, role() };
                g::StoreHalf(saved[1], true);
                auto unchanged = saved;
                g::PrepareLoadedRoles(unchanged);
                g::StartCampaign(unchanged, 999);
                check(std::memcmp(unchanged.data(), saved.data(), sizeof(saved)) == 0,
                    "Other profiles must never initialize, validate or reset Dragon growth metadata");
            }
            Rrole[0] = hero;
            instruct_41(0, 5, 9);
            check(Rrole[0].TakingItem[0] == 5 && Rrole[0].TakingItemAmount[0] == 9,
                "Other profiles must retain role 0 personal item events even with Dragon-like quantities");
        }
        for (int fixed : { 0, 1 })
        {
            MAX_ADD_PRO = fixed;
            TRole expected{ };
            int expectedRandom = 0;
            for (auto mode : { GrowthMode::Original, GrowthMode::FixedRandom, GrowthMode::Average, GrowthMode::Maximum })
            {
                SetGrowthMode(mode);
                auto r = role();
                r.Exp = 750;
                g::StoreHalf(r, true);
                std::srand(12345);
                check(AdvanceRoleLevels(r) == 1 && r.Exp == 700 && g::HasHalf(r),
                    "Remake progression must retain one-level XP deduction and leave reserved words unchanged");
                check(!fixed || r.Attack == 35, "Remake MAX_ADD_PRO must retain its aptitude-based stat increase");
                int nextRandom = std::rand();
                if (mode == GrowthMode::Original) { expected = r; expectedRandom = nextRandom; }
                check(std::memcmp(&r, &expected, sizeof(r)) == 0 && nextRandom == expectedRandom,
                    "Dragon modes must not change remake growth or RNG consumption with either MAX_ADD_PRO setting");
            }
        }
    }
}

void dosDrainBenefits()
{
    TMagic magic{ };
    magic.AddMP[0] = 20;
    magic.HurtMP[0] = 30;
    for (int targetMp : { 0, 1, 3, 10, 30, 100 })
    {
        auto a = role(), d = role();
        a.CurrentMP = 10;
        d.CurrentMP = targetMp;
        int actual = dos::ApplyMpHit(a, d, magic, 1, maximum);
        check(actual == std::min(targetMp, 30) && d.CurrentMP == std::max(targetMp - 30, 0),
            "Reported absorption must retain the original target MP calculation");
        check(a.CurrentMP == 30 && a.MaxMP == 109,
            "Preserve original recovery and growth even for empty or low-MP targets");
    }
    auto a = role(), d = role();
    a.CurrentMP = 50;
    d.CurrentMP = 0;
    int draw = 0;
    int actual = dos::ApplyMpHit(a, d, magic, 1, [&draw](int) { return draw++ == 2 ? 4 : 0; });
    check(actual == 0 && d.CurrentMP == 0 && a.CurrentMP == 70 && a.MaxMP == 104,
        "Match the original Z.dat empty-target recovery and permanent growth fixture");
    a = role();
    a.CurrentMP = 9998;
    a.MaxMP = 9999;
    dos::ApplyMpHit(a, d, magic, 1, maximum);
    check(a.CurrentMP == 9999 && a.MaxMP == 9999, "Drain must respect MP caps");

}

void setupBattle()
{
    std::memset(BField, 0, sizeof(BField));
    BRoleAmount = 3;
    for (int i = 0; i < BRoleAmount; ++i)
    {
        Brole[i] = { };
        Brole[i].rnum = i;
        Brole[i].Team = i == 1 ? 1 : 0;
        Brole[i].X = i + 1;
        Brole[i].Y = 1;
        Rrole[i] = role();
        Rrole[i].MaxMP = 1000;
    }
    Rrole[0].CurrentMP = 80;
    BField[4][2][1] = 1;
    Rmagic[0] = { };
    Rmagic[0].HurtType = 1;
    Rmagic[0].NeedMP = 10;
    for (int i = 0; i < 10; ++i)
    {
        Rmagic[0].AddMP[i] = 30;
        Rmagic[0].HurtMP[i] = 20;
    }
    std::srand(123);
}

void magicCosts()
{
    for (int cache : { 0, 2, 10 })
    {
        setupBattle();
        RestoreRuleState({ cache });
        auto info = BattleRules().inspectMagic(&Rrole[0], Rmagic[0], 8);
        check(info.mpCost == 40 && !info.usesCachedTier, "Inspection must ignore historical MP-cost cache");
        BattleRules().resolveMagic(0, 0, 8);
        check(Rrole[0].CurrentMP >= 68 && Rrole[0].CurrentMP <= 72,
            "Drain must pay this cast's cost while preserving original 28..32 MP recovery");

        setupBattle();
        BField[4][2][1] = 0;
        BattleRules().resolveMagic(0, 0, 8);
        check(Rrole[0].CurrentMP == 40, "A cast with no targets must still pay its own cost");
    }
    setupBattle();
    Rrole[0].CurrentMP = 25;
    auto info = BattleRules().inspectMagic(&Rrole[0], Rmagic[0], 8);
    check(info.mpCost == 20, "Cost must account for the current caster's MP");
    BattleRules().resolveMagic(0, 0, 8);
    check(Rrole[0].CurrentMP >= 33 && Rrole[0].CurrentMP <= 37,
        "Recovery must not change a cost already determined for this cast");

    setupBattle();
    Rrole[1].CurrentMP = 0;
    BattleRules().resolveMagic(0, 0, 8);
    check(Rrole[0].CurrentMP >= 68 && Rrole[0].CurrentMP <= 72,
        "An empty target must still provide original recovery, with the corrected cast cost");

    setupBattle();
    Brole[2].Team = 1;
    BField[4][3][1] = 1;
    BattleRules().resolveMagic(0, 0, 8);
    check(Rrole[0].CurrentMP >= 96 && Rrole[0].CurrentMP <= 104,
        "Area attacks must charge exactly once");

    setupBattle();
    Rmagic[0].HurtType = 0;
    Rrole[0].CurrentMP = 25;
    BField[4][2][1] = 0;
    BattleRules().resolveMagic(0, 0, 8);
    check(Rrole[0].CurrentMP == 5, "HP attacks must also pay their own cost when missing");
}

void resourceBounds()
{
    TemporaryIni ini;
    ini.load("[system]\nMODVersion=12\n[rules]\nmax_hp=32767\nmax_mp=32767\nmax_stamina=32767\n");
    for (auto mode : { GrowthMode::Original, GrowthMode::Average, GrowthMode::Maximum })
    {
        SetGrowthMode(mode);
        auto r = role();
        r.MaxHP = r.CurrentHP = r.MaxMP = r.CurrentMP = 32760;
        r.Exp = 50;
        check(dos::LevelUp(r, maximum) == 1 && r.MaxHP == 32767 && r.CurrentHP == 32767
                && r.MaxMP == 32767 && r.CurrentMP == 32767,
            "DOS growth must clamp resources before narrowing to signed words");
    }
    auto a = role(), d = role();
    a.MaxMP = a.CurrentMP = 32760;
    TMagic magic{ };
    magic.AddMP[0] = 20;
    magic.HurtMP[0] = 30;
    dos::ApplyMpHit(a, d, magic, 1, maximum);
    check(a.MaxMP == 32767 && a.CurrentMP == 32767, "DOS absorption must clamp MP before narrowing");
    a.MaxHP = a.MaxMP = 32767;
    a.CurrentHP = a.CurrentMP = a.PhyPower = 32766;
    dos::Rest(a, a.Speed / 10, maximum);
    check(a.CurrentHP == 32767 && a.CurrentMP == 32767 && a.PhyPower == 32767,
        "DOS rest must clamp HP, MP and stamina before narrowing");

    ini.load("[system]\nMODVersion=0\n[rules]\nmax_hp=32767\nmax_mp=32767\n");
    auto r = role();
    r.MaxHP = r.CurrentHP = r.MaxMP = r.CurrentMP = 32760;
    r.IncLife = 10;
    r.Exp = 65535;
    check(AdvanceRoleLevels(r) == 1 && r.MaxHP == 32767 && r.MaxMP == 32767,
        "Remake growth must also clamp resources before narrowing");
    for (int mp : { 0, 9 })
    {
        setupBattle();
        Rrole[0].CurrentMP = mp;
        BattleRules().resolveMagic(0, 0, 8);
        check(Rrole[0].CurrentMP == mp && Rrole[0].MaxMP == 1000
                && Rrole[1].CurrentMP == 100 && Brole[0].ExpGot == 0,
            "Zero-tier absorption must leave MP and experience unchanged");
    }
    setupBattle();
    Rmagic[0].NeedMP = 0;
    Rrole[0].CurrentMP = Rrole[0].MaxMP = 32767;
    BattleRules().resolveMagic(0, 0, 1);
    check(Rrole[0].CurrentMP == 32767 && Rrole[0].MaxMP == 32767,
        "Remake absorption must clamp MP before narrowing");
    ini.load("[system]\nMODVersion=12\n");
}

void hiddenPoison()
{
    TItem item{ };
    item.AddCurrentHP = -100;
    item.AddPoi = 100;
    for (int resistance : { 0, 20, 99, 100, 120 })
    {
        int lastPoison = -1, lastDamage = -1;
        for (int skill = 0; skill <= 200; ++skill)
        {
            auto a = role(), d = role();
            a.HidWeapon = skill;
            d.DefPoi = resistance;
            d.Poison = 10;
            d.CurrentHP = d.MaxHP = 999;
            int damage = dos::HiddenWeapon(a, d, item, zero);
            check(d.Poison >= lastPoison && damage >= lastDamage, "Improving hidden weapons must not weaken damage or poison");
            check(d.Poison >= 10 && d.Poison <= 99, "Poisoned weapons must neither cleanse nor exceed the cap");
            if (resistance >= 100)
            {
                check(d.Poison == 10, "Poison immunity must remain effective");
            }
            lastPoison = d.Poison;
            lastDamage = damage;
        }
    }
    item.AddPoi = 0;
    for (int poison : { 0, 10, 99 })
    {
        for (auto random : { zero, maximum })
        {
            auto a = role(), d = role();
            d.Poison = poison;
            dos::HiddenWeapon(a, d, item, random);
            check(d.Poison == poison, "An unpoisoned weapon must leave poison unchanged");
        }
    }
}

void knockoutExperience()
{
    auto a = role();
    a.Attack = 6;
    a.PhyPower = 0;
    TMagic magic{ };
    magic.Attack[0] = 12;  // total attack 15, defence 0 -> damage 10
    for (int hp : { 9, 10, 11 })
    {
        auto d = role();
        d.Level = 5;
        d.Defence = 0;
        d.CurrentHP = hp;
        int16_t experience = 0;
        check(dos::ApplyHpHit(a, d, magic, 1, { }, experience, zero) == 10, "Fixture must deal ten damage");
        check(experience == (hp <= 10 ? 52 : 2), "Exact-zero and overkill must award the same knockout bonus");
        check(d.CurrentHP == std::max(hp - 10, 0), "Knockout must clamp HP to zero");
    }
}

void roundDamage()
{
    for (int poison : { 9, 10, 11, 99 })
    {
        auto r = role();
        r.CurrentHP = 10;
        r.Poison = poison;
        dos::RoundStatus(r, false);
        check(r.CurrentHP == 1, "Poison must leave one HP at and beyond the lethal boundary");
    }
    auto r = role();
    r.CurrentHP = 1;
    r.Hurt = 99;
    r.Poison = 99;
    dos::RoundStatus(r, false);
    check(r.CurrentHP == 1, "Combined injury and poison must remain nonlethal");
    r.CurrentHP = 10;
    dos::RoundStatus(r, true);
    check(r.CurrentHP == 10, "Dead actors must not receive status processing");
    r.CurrentHP = 0;
    dos::RoundStatus(r, false);
    check(r.CurrentHP == 0, "Status damage must not revive a zero-HP actor");
    int divisor = POISON_HURT;
    POISON_HURT = 0;
    r = role();
    r.Poison = 99;
    dos::RoundStatus(r, false);
    check(r.CurrentHP == 100, "Disabling poison damage must remain supported");
    POISON_HURT = divisor;
}

void dosDamage()
{
    auto a = role(), d = role();
    a.Attack = 100;
    a.PhyPower = 90;
    TMagic magic{ };
    magic.Attack[0] = 300;
    d.Defence = 99;
    check(dos::HpDamage(a, d, magic, 1, { }, zero) == 8, "Preserve original damage just before the fallback");
    d.Defence = 100;
    check(dos::HpDamage(a, d, magic, 1, { }, zero) == 36, "Preserve the requested DOS fallback discontinuity");
}
}    //namespace

int main(int argc, char** argv)
{
    try
    {
        check(argc == 2, "Pass a dragon_dos12 INI path");
        LoadGameRules(argv[1]);
        for (auto [name, test] : { std::pair{ "mod configuration", modConfiguration }, { "mod compatibility", modCompatibility },
                 { "special starting stats", specialStartingStats }, { "DOS starting stats", startingStats }, { "original DOS batch growth", originalGrowth },
                 { "per-level growth", levelGrowth }, { "average and attainable maximum", averageAndMaximum },
                 { "fixed growth reload/order independence", fixedGrowth }, { "growth metadata storage", growthStorage },
                 { "native R save round trip", saveRoundTrip }, { "growth INI options", configOptions },
                 { "non-Dragon growth isolation", nonDragonIsolation },
                 { "preserved DOS drain benefits", dosDrainBenefits }, { "per-cast MP costs", magicCosts },
                 { "resource bounds and zero-tier absorption", resourceBounds }, { "script mutation bounds", scriptMutationBounds },
                 { "hidden weapon poison", hiddenPoison }, { "knockout experience", knockoutExperience },
                 { "nonlethal round damage", roundDamage }, { "preserved DOS damage", dosDamage } })
        {
            test();
            std::cout << "PASS " << name << '\n';
        }
    }
    catch (const std::exception& e)
    {
        std::cerr << "FAIL " << e.what() << '\n';
        return 1;
    }
}
