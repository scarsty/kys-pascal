#include "kys_rules.h"
#include "rules/dragon_dos12.h"
#include "rules/growth_state.h"
#include "rules/rules_internal.h"
#include "kys_event.h"
#include "kys_main.h"
#include "kys_frontend.h"
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
    rules::config.progression = rules::Profile::Remake;
    rules::SelectProfiles();
    LoadR(1);
    SaveR(2);
    std::ifstream remakeSaved(dir / "save/r2.grp", std::ios::binary);
    actual.assign(std::istreambuf_iterator<char>(remakeSaved), std::istreambuf_iterator<char>());
    check(actual == original, "Remake LoadR/SaveR must preserve unrelated role words without interpreting Dragon metadata");
    rules::config.progression = rules::Profile::DragonDos12;
    rules::SelectProfiles();
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
    for (const char* profiles : { "", "profile=remake\n", "profile=legacy\n",
             "profile=remake\ncombat=dragon_dos12\n", "profile=dragon_dos12\nprogression=remake\n" })
        for (const char* options : { "growth_mode=average\ngrowth_max_priority=mp\n",
                 "growth_mode=unrelated\ngrowth_max_priority=unrelated\n" })
        {
            { std::ofstream out(path); out << "[rules]\n" << profiles << options; }
            LoadGameRules(path.string());
            auto info = DescribeGameRules();
            check(!HasConfigurableGrowth() && !info.growthMode && !info.growthMaxPriority,
                "Only Dragon progression may expose configurable growth, including mixed profiles");
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
        TRole hero = Rrole[0];
        decltype(MAX_ADD_PRO) maxAdd = MAX_ADD_PRO;
        int threshold = LevelUpList[0];
        std::array<int, 16> caps;
        Restore() { std::copy(std::begin(MaxProList), std::end(MaxProList), caps.begin()); }
        ~Restore()
        {
            rules::config = config;
            rules::SelectProfiles();
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
    rules::config.progression = rules::Profile::Remake;
    LevelUpList[0] = 50;
    std::fill(std::begin(MaxProList), std::end(MaxProList), 999);
    for (auto combat : { rules::Profile::Remake, rules::Profile::DragonDos12 })
    {
        rules::config.combat = combat;
        rules::SelectProfiles();
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

void legacyDrainBenefits()
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

void legacyDamage()
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
        for (auto [name, test] : { std::pair{ "original DOS batch growth", originalGrowth },
                 { "per-level growth", levelGrowth }, { "average and attainable maximum", averageAndMaximum },
                 { "fixed growth reload/order independence", fixedGrowth }, { "growth metadata storage", growthStorage },
                 { "native R save round trip", saveRoundTrip }, { "growth INI options", configOptions },
                 { "non-Dragon growth isolation", nonDragonIsolation },
                 { "preserved DOS drain benefits", legacyDrainBenefits }, { "per-cast MP costs", magicCosts },
                 { "hidden weapon poison", hiddenPoison }, { "knockout experience", knockoutExperience },
                 { "nonlethal round damage", roundDamage }, { "preserved DOS damage", legacyDamage } })
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
