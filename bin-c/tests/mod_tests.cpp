#include "mods/mod.h"
#include "kys_event.h"
#include "kys_frontend.h"
#include "kys_main.h"
#include <algorithm>
#include <array>
#include <chrono>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

namespace
{
void check(bool condition, const char* message)
{
    if (!condition) throw std::runtime_error(message);
}

constexpr std::array versions{ 0, 11, 12, 21, 22, 23, 31, 41, 51, 71, 72, 81, 91, 100 };
const RulesRandom zero = [](int) { return 0; };

struct TestFrontend final : GameFrontend
{
    void text(const std::string&, int) override { }
    int choose(const std::string&, const std::vector<std::string>&, bool) override { return 0; }
    int number(int, int, int initial) override { return initial; }
    bool battle(int, int) override { return false; }
    bool aim(int, int, int, int) override { return false; }
    void instruction(int, int, int) override { }
};

struct ModSelection
{
    std::filesystem::path path = std::filesystem::temp_directory_path() /
        ("kys-mod-tests-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()) + ".ini");
    ~ModSelection() { std::filesystem::remove(path); }
    void select(int version) const
    {
        { std::ofstream out(path); out << "[system]\nMODVersion=" << version << '\n'; }
        mods::LoadDefinition(path.string());
    }
};

void resetCharacters()
{
    std::fill(std::begin(Rrole), std::end(Rrole), TRole{ });
    std::fill(std::begin(Rmagic), std::end(Rmagic), TMagic{ });
    std::fill(std::begin(Ritem), std::end(Ritem), TItem{ });
    for (auto& role : Rrole)
    {
        role.Level = 1;
        role.CurrentHP = role.MaxHP = 100;
        role.CurrentMP = role.MaxMP = 100;
        role.Attack = role.Speed = role.Defence = 30;
        role.DefPoi = 73;
        role.Aptitude = 70;
        role.Ethics = 77;
        role.Magic[0] = 9;
        std::fill(std::begin(role.TakingItem), std::end(role.TakingItem), -1);
    }
    RItemList.assign(200, TItemList{ -1, 0 });
    for (int i = 0; i < 100; ++i) LeaveList[i] = i + 1;
    MAX_ITEM_AMOUNT = 200;
}

void registryAndPresentation()
{
    struct Expected
    {
        int version;
        const char* name;
        const char* title;
        int x, y, height, music, items, musicSlots;
    };
    const Expected expected[]{
        { 0, "原版", "Replicated Edition", 275, 125, 220, 16, 200, 200 },
        { 11, "小猪闯江湖", "A Pig", 275, 270, 240, 16, 200, 200 },
        { 12, "苍龙逐日", "We Are Dragons", 200, 250, 220, 16, 200, 200 },
        { 21, "天书奇侠", "Books", 275, 285, 220, 16, 200, 200 },
        { 22, "菠萝三国", "Why I have to go after a pineapple", 275, 125, 240, 37, 456, 200 },
        { 23, "笑梦游记", "Four Dreams", 275, 165, 240, 24, 200, 200 },
        { 31, "再战江湖", "Wider Rivers and Deeper Lakes", 275, 125, 220, 16, 200, 200 },
        { 41, "PTT", "Here is PTT", 275, 255, 240, 16, 200, 200 },
        { 51, "魏征", "An Prime Minister of Tang", 275, 125, 220, 16, 200, 200 },
        { 71, "天书劫", "Books from Heaven", 60, 270, 220, 16, 400, 200 },
        { 72, "Shake the World", "Shake the World", 275, 125, 220, 16, 400, 200 },
        { 81, "真龙觉醒", "Awaking of Dragons", 200, 250, 220, 16, 200, 999 },
        { 91, "问情", "What's Loving", 275, 125, 220, 16, 200, 200 },
        { 100, "其他", "Replicated Edition", 275, 270, 220, 16, 200, 200 }
    };
    ModSelection config;
    for (const auto& entry : expected)
    {
        config.select(entry.version);
        const auto& mod = mods::Active();
        check(mod.version() == entry.version && std::string(mod.name()) == entry.name && &mod == &mods::Find(entry.version),
            "Every known MOD must resolve its own stable definition");
        CENTER_X = 320; CENTER_Y = 220; MAX_ITEM_AMOUNT = 200;
        SetMODVersion();
        check(TitleString.find(entry.title) != std::string::npos && TitlePosition.x == entry.x && TitlePosition.y == entry.y && CENTER_Y == entry.height,
            "Presentation extraction must preserve each MOD's title and layout");
        check(StartMusic == entry.music && MAX_ITEM_AMOUNT == entry.items && Music.size() == entry.musicSlots,
            "Presentation extraction must preserve music and item limits");
        check(mod.renameHomeScene() == (entry.version != 11 && entry.version != 12 && entry.version != 22 && entry.version != 91),
            "Home scene naming must follow each MOD's data compatibility");
        check(HasConfigurableGrowth() == (entry.version == 12), "Only Canglong owns DOS growth customization");
    }
    const auto& first = mods::Find(777);
    const auto& second = mods::Find(778);
    check(first.version() == 777 && second.version() == 778 && &first != &second && mods::Find(100).version() == 100,
        "Unspecified MOD numbers must preserve their IDs without changing known definitions");
}

void startingRolls()
{
    for (int version : versions)
    {
        if (version == 12) continue; // DOS draw bounds are covered by dragon_rules_tests.
        for (bool high : { false, true })
        {
            resetCharacters();
            int draws = 0;
            std::vector<int> bounds;
            const auto& mod = mods::Find(version);
            auto result = mod.createStartingStats(Rrole[0], "ordinary", [&](int bound)
                { ++draws; bounds.push_back(bound); return high ? bound - 1 : 0; });
            auto& hero = Rrole[0];
            check(!result.fixed && hero.Aptitude == (high ? 100 : 1) && hero.DefPoi == 73,
                "Shared starting rolls must preserve aptitude bounds and leave poison resistance untouched");
            if (version == 21)
            {
                check(draws == 1 && bounds[0] == 100 && hero.MaxHP == 100 && hero.MaxMP == 100 && hero.Attack == 30,
                    "Tianshu Qixia must reroll only aptitude and preserve its template attributes");
            }
            else
            {
                check(hero.MaxHP == (high ? 50 : 25) && hero.MaxMP == (high ? 50 : 25) && hero.Attack == (high ? 30 : 25),
                    "Other MODs must preserve remake attribute ranges");
                check(bounds[0] == 26 && bounds[1] == 26 && bounds[2] == 2 && bounds[3] == 10 && bounds[15] == 100,
                    "Shared attribute draws must retain their order and bounds");
                int expectedDraws = version == 0 ? (high ? 17 : 18) : version == 31 ? 18 : 16;
                check(draws == expectedDraws, "MOD-specific initialization must preserve RNG consumption");
            }
            check(hero.Magic[0] == (version == 0 ? (high ? 1 : 0) : version == 41 ? 0 : 9),
                "Only the base game and PTT alter the starting martial art");
            check(hero.Ethics == (version == 31 ? (high ? 98 : 0) : 77), "Only Zaizhan randomizes starting ethics");
        }
    }
}

void namePresets()
{
    ModSelection config;
    struct Preset { int version; const char* name; int hp, attack; };
    const Preset presets[]{
        { 0, "TXDX尊使", 50, 30 }, { 100, "TXDX尊使", 50, 30 },
        { 11, "小小豬", 50, 30 }, { 11, "晴空飛雪", 50, 30 },
        { 21, "古天奇", 100, 30 }, { 21, "青狼火花", 100, 30 },
        { 22, "k小邪", 50, 150 }, { 22, "龍吟星落", 150, 130 }, { 22, "小隨", 150, 130 },
        { 22, "破大俠", 1150, 230 }, { 22, "鳳凰", 250, 25 },
        { 23, "小小豬", 10, 10 }, { 23, "k小邪", 150, 30 }, { 23, "南宮夢", 500, 70 },
        { 23, "游客", 50, 30 }, { 23, "飛蟲王", 50, 30 }, { 23, "破劍式", 499, 90 },
        { 23, "9523", 25, 10 }, { 23, "鳳凰ice", 25, 25 },
        { 31, "南宮夢", 50, 300 }, { 41, "leo", 50, 30 }
    };
    for (const auto& preset : presets)
    {
        config.select(preset.version);
        resetCharacters();
        const auto& mod = mods::Find(preset.version);
        mod.createStartingStats(Rrole[0], preset.name, zero);
        const std::vector<TRole> beforeOthers(std::begin(Rrole) + 1, std::end(Rrole));
        const std::vector<TMagic> beforeMagic(std::begin(Rmagic), std::end(Rmagic));
        const std::vector<TItem> beforeItems(std::begin(Ritem), std::end(Ritem));
        const auto beforeInventory = RItemList;
        check(mod.applySpecialStartingStats(Rrole[0], preset.name), "Every special name must lock its preview");
        check(Rrole[0].MaxHP == preset.hp && Rrole[0].Attack == preset.attack && Rrole[0].Aptitude == 100,
            "The preview must show the final non-Dragon special-name preset");
        check(std::memcmp(Rrole + 1, beforeOthers.data(), beforeOthers.size() * sizeof(TRole)) == 0 &&
                std::memcmp(Rmagic, beforeMagic.data(), beforeMagic.size() * sizeof(TMagic)) == 0 &&
                std::memcmp(Ritem, beforeItems.data(), beforeItems.size() * sizeof(TItem)) == 0 &&
                RItemList.size() == beforeInventory.size() &&
                std::memcmp(RItemList.data(), beforeInventory.data(), beforeInventory.size() * sizeof(TItemList)) == 0,
            "Previewing a special name must not change other roles, magic, items or inventory");
        auto preview = Rrole[0];
        mod.finishCharacterCreation(preset.name);
        check(std::memcmp(&Rrole[0], &preview, sizeof(TRole)) == 0,
            "Confirmation must not change the displayed protagonist stats");
        if (preset.version == 0 || preset.version == 100)
            check(Rrole[13].Magic[1] == 91 && Rrole[0].Magic[0] == 62 && Rmagic[62].Attack[9] == 2000 && Ritem[66].OnlyPracRole == -1,
                "Base name bonuses must retain changes to other roles, magic and items");
        if (preset.version == 23)
            check(Rrole[401].Attack == Rrole[0].Attack && Rrole[404].MaxHP == Rrole[0].MaxHP,
                "Xiaomeng must copy the finalized hero into all four alternate roles");
        if (std::string(preset.name) == "鳳凰")
            check(Rrole[1].Attack == 300 && Rrole[14].IncLife == 30, "Boluo's Phoenix preset must retain party bonuses");
        if (std::string(preset.name) == "鳳凰ice")
            check(Rrole[1].Aptitude == 95 && Rrole[100].Attack == 90, "Xiaomeng's Phoenix preset must retain leave-list bonuses");
    }
    resetCharacters();
    config.select(777);
    mods::Find(777).finishCharacterCreation("TXDX尊使");
    check(Rrole[0].Magic[0] == 9 && Rrole[13].Magic[1] == 0, "Unspecified MODs must not inherit MODVersion=100 bonuses");
}

void movementAndEvents()
{
    ModSelection config;
    for (int version : versions)
    {
        config.select(version);
        const auto& mod = mods::Active();
        Earth[100][100] = 358; BuildX[100][100] = 0;
        check(CanWalk(100, 100) == (version != 22) && InShip == (version == 22 ? 0 : 1),
            "World movement must preserve Boluo's water restriction and ship state");
        CurScene = 1;
        SData[1][0][1][1] = 522;
        SData[1][1][1][1] = 1358 * 2;
        SData[1][3][1][1] = -1;
        check(CanWalkInScene(1, 1) == (version == 23), "Xiaomeng must retain its explicit scene tile override");
        for (bool ship : { false, true })
        {
            check(mod.worldPathTilePassable(5, ship) == (version != 22 || ship), "Boluo pathfinding must distinguish water from land");
            check(mod.worldPathTilePassable(0, ship) == (version != 22 || !ship), "Boluo ships must not pathfind across land");
            check(mod.worldPathTilePassable(7, ship) == (version != 22), "Only the shared pathfinder accepts terrain seven");
        }
        Rrole[0].Attack = 100;
        check(instruct_29(0, 50, 60, 123, 456) == (version == 41 ? 123 : 456), "PTT attack checks must ignore the upper bound");
        check(mod.instruction50UsesItemCheck(0) == (version == 11) && mod.instruction50UsesItemCheck(129),
            "Xiaozhu must retain its item-check instruction format");
        check(mod.eventUsesWorldPictures(1, -1) == (version == 22) && !mod.eventUsesWorldPictures(1, 5) && mod.eventUsesWorldPictures(0, 5),
            "Boluo event pictures must keep their no-active-event exception");
        check(mod.eventRequestsNumber(176) == (version == 22) && !mod.eventRequestsNumber(175),
            "Only Boluo event 176 requests number input");
        check(mod.statusMenuEvent() == (version == 51 ? 1092 : -1) && mod.battleSpecialEvent() == (version == 51 ? 1077 : -1),
            "Weizheng must own its two distinct menu events");
        std::array<std::string, 22> labels;
        labels.fill("original");
        mod.customizeStatusLabels(labels);
        check(labels[0] == "original" && labels[2] == (version == 22 ? "靈力" : "original") && labels[19] == (version == 22 ? "所會法術" : "original"),
            "Only Boluo customizes status terminology");
    }
}
}    //namespace

int main()
{
    TestFrontend frontend;
    Frontend = &frontend;
    try
    {
        registryAndPresentation();
        startingRolls();
        namePresets();
        movementAndEvents();
        Frontend = nullptr;
        std::cout << "PASS all 14 MOD definitions, presentation, starting RNG, names, movement and events\n";
    }
    catch (const std::exception& error)
    {
        Frontend = nullptr;
        std::cerr << "FAIL " << error.what() << '\n';
        return 1;
    }
}
