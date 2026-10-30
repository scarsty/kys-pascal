// Native stdio MCP frontend. No SDL initialization, window, audio, or fake screen.
#include "INIReader.h"
#include "kys_battle.h"
#include "kys_engine.h"
#include "kys_event.h"
#include "kys_frontend.h"
#include "kys_main.h"
#include "kys_rules.h"
#include "kys_script.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <condition_variable>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <glaze/glaze.hpp>
#include <iostream>
#include <mutex>
#include <queue>
#include <stdexcept>
#include <thread>

namespace fs = std::filesystem;
using J = glz::generic;
using A = J::array_t;

J obj(std::initializer_list<std::pair<const std::string, J>> values) { return J::object_t(values); }

J arr(std::initializer_list<J> values) { return A(values); }

struct JsonOptions : glz::opts
{
    bool escape_control_characters = true;
};

std::string dump(const J& value) { return glz::write<JsonOptions{ }>(value).value(); }

int integer(const J& args, const std::string& key, int fallback = -1)
{
    if (!args.contains(key))
    {
        return fallback;
    }
    if (!args[key].is_number())
    {
        throw std::runtime_error(key + " must be an integer");
    }
    double n = args[key].as<double>();
    if (!std::isfinite(n) || n != std::floor(n) || n < -2147483647.0 || n > 2147483647.0)
    {
        throw std::runtime_error(key + " must be an integer in int32 range");
    }
    return static_cast<int>(n);
}

std::string string(const J& args, const std::string& key, std::string fallback = { })
{
    if (!args.contains(key))
    {
        return fallback;
    }
    if (!args[key].is_string())
    {
        throw std::runtime_error(key + " must be a string");
    }
    return args[key].as<std::string>();
}

void require(bool condition, const std::string& reason)
{
    if (!condition)
    {
        throw std::runtime_error(reason);
    }
}

template <size_t N>
std::string name(const char (&field)[N])
{
    auto end = std::find(field, field + N, '\0');
    return cp950toutf8(field, static_cast<int>(end - field));
}

template <class T>
J numbers(const T& values)
{
    A out;
    for (auto v : values)
    {
        out.emplace_back(v);
    }
    return out;
}

int quantity(int id)
{
    for (const auto& v : RItemList)
    {
        if (v.Number == id)
        {
            return v.Amount;
        }
    }
    return 0;
}

const char* attackShape(int area)
{
    switch (area)
    {
    case 0: return "point";
    case 1: return "cardinal_line";
    case 2: return "self_cross";
    case 3: return "target_square";
    default: return "unknown";
    }
}

const char* attackTargeting(int area)
{
    switch (area)
    {
    case 0: return "Point: aim a tile within Manhattan move_distance.";
    case 1: return "Cardinal line: aim an adjacent direction tile; line length is move_distance.";
    case 2: return "Self-centered cross: four cardinal arms of length move_distance; diagonal tiles excluded. Omit x/y.";
    case 3: return "Square: aim within Manhattan move_distance; square radius is attack_distance around the aim tile.";
    default: return "Unknown native attack area.";
    }
}

struct Snapshot
{
    bool legacyLineage{ };
    uint64_t sourceVersion = 4;
    std::vector<TRole> roles{ std::begin(Rrole), std::end(Rrole) };
    std::vector<TItem> items{ std::begin(Ritem), std::end(Ritem) };
    std::vector<TScene> scenes{ std::begin(Rscene), std::end(Rscene) };
    std::vector<TMagic> magics{ std::begin(Rmagic), std::end(Rmagic) };
    std::vector<TShop> shops{ std::begin(RShop), std::end(RShop) };
    std::vector<TItemList> inventory = RItemList;
    std::vector<int16_t> terrain, events, variables;
    std::array<int16_t, 6> team;
    std::array<int, 20> location;
    std::array<int, 2> jumpGuard{ HeadlessJumpGuardX, HeadlessJumpGuardY };
    unsigned rng = HeadlessRandomState;
    int32_t ruleCostTier = CaptureRuleState().magicCostTier;

    Snapshot()
    {
        auto copy = [](auto& to, auto& from)
        {
            to.resize(sizeof(from) / sizeof(int16_t));
            std::memcpy(to.data(), &from, sizeof(from));
        };
        copy(terrain, SData);
        copy(events, DData);
        copy(variables, x50);
        std::copy(std::begin(TeamList), std::end(TeamList), team.begin());
        location = { Where, CurScene, Sx, Sy, SFace, Mx, My, MFace, InShip, ShipX, ShipY, ShipX1, ShipY1, ShipFace, CurEvent, CurItem, Cx, Cy, SavedSceneIndex, SceneRolePic };
    }

    void restore() const
    {
        std::copy(roles.begin(), roles.end(), Rrole);
        std::copy(items.begin(), items.end(), Ritem);
        std::copy(scenes.begin(), scenes.end(), Rscene);
        std::copy(magics.begin(), magics.end(), Rmagic);
        std::copy(shops.begin(), shops.end(), RShop);
        RItemList = inventory;
        std::memcpy(SData, terrain.data(), sizeof(SData));
        std::memcpy(DData, events.data(), sizeof(DData));
        std::memcpy(x50, variables.data(), sizeof(x50));
        std::copy(team.begin(), team.end(), TeamList);
        HeadlessRandomState = rng;
        Where = location[0];
        CurScene = location[1];
        Sx = location[2];
        Sy = location[3];
        SFace = location[4];
        Mx = location[5];
        My = location[6];
        MFace = location[7];
        InShip = location[8];
        ShipX = location[9];
        ShipY = location[10];
        ShipX1 = location[11];
        ShipY1 = location[12];
        ShipFace = location[13];
        CurEvent = location[14];
        CurItem = location[15];
        Cx = location[16];
        Cy = location[17];
        SavedSceneIndex = location[18];
        SceneRolePic = location[19];
        HeadlessJumpGuardX = jumpGuard[0];
        HeadlessJumpGuardY = jumpGuard[1];
        RestoreRuleState({ ruleCostTier });
    }

    void file(const fs::path& path, uint64_t identity, bool load, uint64_t legacyIdentity = 0, bool allowLegacy = false)
    {
        std::fstream stream(path, std::ios::binary | (load ? std::ios::in : std::ios::out | std::ios::trunc));
        require(stream.is_open(), "Cannot open checkpoint file");
        std::array<uint64_t, 3> header{ 0x3150414e5353594bull, 4, identity }, expected = header;
        auto bytes = [&](void* data, size_t length)
        {
            if (load)
            {
                stream.read(static_cast<char*>(data), length);
            }
            else
            {
                stream.write(static_cast<const char*>(data), length);
            }
            require(stream.good(), "Checkpoint read/write failed");
        };
        bytes(header.data(), sizeof(header));
        require(header[0] == expected[0] && header[1] >= 1 && header[1] <= 4, "Checkpoint format differs");
        sourceVersion = header[1];
        require(sourceVersion >= static_cast<uint64_t>(BattleRules().minimumCheckpointVersion()), "Selected combat rules require a newer checkpoint with complete runtime state");
        if (load && sourceVersion < 3)
        {
            require(allowLegacy, "Legacy checkpoint omits world/list fingerprints; verify its source files and restart with --allow-legacy-checkpoints to import explicitly");
            require(header[2] == legacyIdentity, "Legacy checkpoint mod fingerprint differs");
            legacyLineage = true;
        }
        else
        {
            require(header[2] == identity, "Checkpoint mod fingerprint differs");
        }
        uint64_t checksum = 14695981039346656037ull;
        auto block = [&](auto& values)
        {
            uint64_t size = values.size(), expectedSize = size;
            bytes(&size, sizeof(size));
            require(size == expectedSize, "Checkpoint section size mismatch");
            auto length = values.size() * sizeof(typename std::decay_t<decltype(values)>::value_type);
            bytes(values.data(), length);
            auto p = reinterpret_cast<const unsigned char*>(values.data());
            for (size_t i = 0; i < length; ++i)
            {
                checksum ^= p[i];
                checksum *= 1099511628211ull;
            }
        };
        block(roles);
        block(items);
        block(scenes);
        block(magics);
        block(shops);
        block(inventory);
        block(terrain);
        block(events);
        block(variables);
        block(team);
        block(location);
        bytes(&rng, sizeof(rng));
        checksum ^= rng;
        if (header[1] >= 2)
        {
            block(jumpGuard);
        }
        else
        {
            jumpGuard = { -1, -1 };
        }
        if (header[1] >= 3)
        {
            uint64_t lineage = legacyLineage ? 1 : 0;
            bytes(&lineage, sizeof(lineage));
            require(lineage <= 1, "Invalid checkpoint lineage");
            legacyLineage = lineage != 0;
            checksum ^= lineage;
        }
        if (header[1] >= 4)
        {
            bytes(&ruleCostTier, sizeof(ruleCostTier));
            require(ruleCostTier >= 0 && ruleCostTier <= 10, "Invalid rule runtime state");
            checksum ^= static_cast<uint32_t>(ruleCostTier);
        }
        else
        {
            ruleCostTier = 0;
        }
        uint64_t stored = checksum;
        bytes(&stored, sizeof(stored));
        require(checksum == stored, "Checkpoint checksum mismatch");
        if (load)
        {
            require(stream.peek() == std::char_traits<char>::eof(), "Checkpoint has trailing bytes");
        }
    }
};

class Session final : public GameFrontend
{
    std::mutex mutex;
    std::condition_variable changed;
    std::thread worker;
    bool paused{ }, done = true, stopping{ }, answering{ };
    int answer{ };
    J prompt, result, trace = A{ }, messages = A{ };
    J actionEffects = A{ };
    std::string error;
    std::string menuContext;
    J manualCommand;
    bool manualReady{ };
    int instructions{ }, roleCount{ }, itemCount{ }, magicCount{ };
    bool loaded{ }, debug{ }, allowLegacyCheckpoints{ }, legacyCheckpointLineage{ };
    fs::path saveDirectory;
    uint64_t contentIdentity{ }, legacyContentIdentity{ };
    std::map<std::string, std::shared_ptr<Snapshot>> checkpoints;
    std::unique_ptr<Snapshot> before;
    std::vector<int> currentTrace;

public:
    explicit Session(bool allowDebug, fs::path saves, bool allowLegacy = false) : debug(allowDebug), allowLegacyCheckpoints(allowLegacy), saveDirectory(std::move(saves)) { Frontend = this; }

    ~Session()
    {
        {
            std::lock_guard lock(mutex);
            stopping = true;
            answering = true;
            changed.notify_all();
        }
        if (worker.joinable())
        {
            worker.join();
        }
        Frontend = nullptr;
    }

    void text(const std::string& value, int head = -1) override
    {
        // Keep full dialogue; the protocol returns it once per mutating call.
        messages.get_array().push_back(obj({ { "head", head }, { "text", value } }));
    }

    void context(const std::string& value) override { menuContext = value; }

    void instruction(int script, int pc, int opcode) override
    {
        if (++instructions > 250000)
        {
            throw std::runtime_error("Event instruction budget exceeded: script=" + std::to_string(script) + " pc=" + std::to_string(pc));
        }
        if (trace.get_array().size() >= 160)
        {
            trace.get_array().erase(trace.get_array().begin());
        }
        trace.get_array().push_back(arr({ script, pc, opcode }));
    }

    int waitPrompt(J value)
    {
        std::unique_lock lock(mutex);
        prompt = std::move(value);
        paused = true;
        answering = false;
        changed.notify_all();
        changed.wait(lock, [&]
            {
                return answering || stopping;
            });
        if (stopping)
        {
            throw std::runtime_error("Session stopped");
        }
        paused = false;
        prompt = J{ };
        return answer;
    }

    int choose(const std::string& title, const std::vector<std::string>& options, bool cancel = true) override
    {
        return waitPrompt(obj({ { "kind", "choice" }, { "title", title == "menu" ? menuContext : title }, { "options", numbers(options) }, { "cancel_allowed", cancel } }));
    }

    int number(int minimum, int maximum, int initial) override
    {
        return waitPrompt(obj({ { "kind", "number" }, { "minimum", minimum }, { "maximum", maximum }, { "initial", initial } }));
    }

    bool aim(int actor, int step, int area, int range) override
    {
        if (!manualReady)
        {
            throw std::runtime_error("Headless target input requires battle_action");
        }
        Ax = integer(manualCommand, "x");
        Ay = integer(manualCommand, "y");
        require(Ax >= 0 && Ax < 64 && Ay >= 0 && Ay < 64 && BField[3][Ax][Ay] >= 0, "Invalid native aim target");
        SetAnimationPosition(area, step, range);
        return true;
    }

    J prepareManual(const J& a)
    {
        require(paused && string(prompt, "kind") == "battle_turn", "Wait for a player battle turn");
        int b = integer(prompt, "actor"), r = Brole[b].rnum;
        auto action = string(a, "action");
        int x = integer(a, "x", Brole[b].X), y = integer(a, "y", Brole[b].Y);
        require(x >= 0 && x < 64 && y >= 0 && y < 64, "Battle coordinates must be 0..63");
        J command = a;
        command["x"] = x;
        command["y"] = y;
        int distance = std::abs(x - Brole[b].X) + std::abs(y - Brole[b].Y);
        if (action == "move")
        {
            require(Brole[b].Step > 0 && distance > 0, "No movement available");
            CalCanSelect(b, 0, Brole[b].Step);
            require(BField[3][x][y] > 0 && BField[2][x][y] < 0, "Unreachable/occupied battle destination");
        }
        else if (action == "attack")
        {
            int slot = integer(a, "magic_slot");
            require(slot >= 0 && slot < 10, "magic_slot must be 0..9");
            int m = Rrole[r].Magic[slot];
            require(m > 0 && m < magicCount && Rrole[r].PhyPower >= 10, "Magic is unavailable or stamina below 10");
            int lv = Rrole[r].MagLevel[slot] / 100;
            int area = Rmagic[m].AttAreaType, range = Rmagic[m].MoveDistance[lv];
            if (area == 0 || area == 3)
            {
                require(distance <= range, "Target outside native magic range");
            }
            if (area == 1)
            {
                require(distance == 1, "Line attack: choose adjacent cardinal direction");
            }
            require(area >= 0 && area <= 3, "Unknown native attack area");
        }
        else if (action == "consume")
        {
            int id = integer(a, "item");
            require(id >= 0 && id < itemCount && quantity(id) > 0 && Ritem[id].ItemType == 3, "Choose an owned medicine/food item (type 3)");
        }
        else if (action == "hidden_weapon" || action == "poison" || action == "medicine" || action == "detox")
        {
            int target = BField[2][x][y];
            require(target >= 0 && !Brole[target].Dead, "Target must be a living actor");
            bool friendly = action == "medicine" || action == "detox";
            require((Brole[target].Team == Brole[b].Team) == friendly, "Target on wrong team");
            int stat{ }, cap = 15;
            if (action == "hidden_weapon")
            {
                int id = integer(a, "item");
                require(id >= 0 && id < itemCount && quantity(id) > 0 && Ritem[id].ItemType == 4, "Choose an owned hidden weapon (type 4)");
                stat = Rrole[r].HidWeapon;
                cap = 100;
            }
            if (action == "poison")
            {
                stat = Rrole[r].UsePoi;
                require(stat > 0 && Rrole[r].PhyPower >= 30, "Poison needs skill > 0 and stamina >= 30");
            }
            if (action == "medicine")
            {
                stat = Rrole[r].Medicine;
                require(stat > 0 && Rrole[r].PhyPower >= 50, "Medicine needs skill > 0 and stamina >= 50");
            }
            if (action == "detox")
            {
                stat = Rrole[r].MedPoi;
                require(stat > 0 && Rrole[r].PhyPower >= 50, "Detox needs skill > 0 and stamina >= 50");
            }
            require(distance <= std::min(stat / 15 + 1, cap), "Target outside native skill range");
        }
        else
        {
            throw std::runtime_error("Unknown battle action");
        }
        manualCommand = command;
        manualReady = true;
        return resume(3, true);
    }

    void performManual(int actor)
    {
        auto action = string(manualCommand, "action");
        int r = Brole[actor].rnum;
        std::vector<TRole> beforeRoles;
        for (int i = 0; i < BRoleAmount; ++i)
        {
            beforeRoles.push_back(Rrole[Brole[i].rnum]);
        }
        A beforeStates;
        for (int i = 0; i < BRoleAmount; ++i)
        {
            beforeStates.push_back(role(Brole[i].rnum));
        }
        J beforeActor = role(r);
        int target = integer(manualCommand, "x", Brole[actor].X) * 64 + integer(manualCommand, "y", Brole[actor].Y);
        int targetActor = BField[2][target / 64][target % 64];
        J beforeTarget = targetActor >= 0 ? role(Brole[targetActor].rnum) : J{ };
        Ax = integer(manualCommand, "x");
        Ay = integer(manualCommand, "y");
        Brole[actor].Auto = 0;
        if (action == "move")
        {
            CalCanSelect(actor, 0, Brole[actor].Step);
            MoveAnimation(actor);
        }
        else if (action == "attack")
        {
            int slot = integer(manualCommand, "magic_slot"), m = Rrole[r].Magic[slot], lv = Rrole[r].MagLevel[slot] / 100 + 1;
            SetAnimationPosition(Rmagic[m].AttAreaType, Rmagic[m].MoveDistance[lv - 1], Rmagic[m].AttDistance[lv - 1]);
            Brole[actor].Acted = 1;
            AttackAction(actor, slot, m, lv);
        }
        else if (action == "consume")
        {
            int item = integer(manualCommand, "item");
            EatOneItem(r, item);
            instruct_32(item, -1);
            Brole[actor].Acted = 1;
        }
        else if (action == "hidden_weapon")
        {
            UseHiddenWeapon(actor, integer(manualCommand, "item"));
        }
        else if (action == "poison")
        {
            UsePoison(actor);
        }
        else if (action == "medicine")
        {
            Medicine(actor);
        }
        else if (action == "detox")
        {
            MedPoison(actor);
        }
        A affected;
        for (int i = 0; i < BRoleAmount; ++i)
        {
            if (i != actor && std::memcmp(&beforeRoles[i], &Rrole[Brole[i].rnum], sizeof(TRole)))
            {
                affected.push_back(obj({ { "actor_index", i }, { "role", Brole[i].rnum }, { "before", beforeStates[i] }, { "after", role(Brole[i].rnum) } }));
            }
        }
        actionEffects.get_array().push_back(obj({ { "action", action }, { "item", integer(manualCommand, "item") }, { "actor", r }, { "before", beforeActor }, { "after", role(r) }, { "target_before", beforeTarget }, { "target_after", targetActor >= 0 ? role(Brole[targetActor].rnum) : J{ } }, { "affected", affected } }));
        manualReady = false;
        text("Manual native battle action: " + action);
    }

    bool battle(int number, int getexp) override
    {
        auto staSize = fs::file_size(fs::path(AppPath) / "resource/war.sta");
        require(number >= 0 && (number + 1) * sizeof(TWarData) <= staSize, "Invalid battle record");
        CurrentBattle = number;
        BattleResult = 0;
        BattleRound = 1;
        bool select = InitialBField();
        if (select)
        {
            A choices;
            int mask = 0;
            for (int i = 0; i < 6; ++i)
            {
                if (TeamList[i] >= 0)
                {
                    mask |= 1 << i;
                    choices.push_back(obj({ { "slot", i }, { "bit", 1 << i }, { "role", TeamList[i] }, { "name", name(Rrole[TeamList[i]].Name) } }));
                }
            }
            int selection = waitPrompt(obj({ { "kind", "party" }, { "title", "Select battle roster: choose index is a bitmask (sum of slot bits)" }, { "available", choices }, { "available_mask", mask }, { "minimum", 1 }, { "maximum", mask } }));
            for (int i = 0; i < 6; ++i)
            {
                if (TeamList[i] >= 0 && (selection & (1 << i)))
                {
                    InitialBRole(BRoleAmount++, TeamList[i], 0, WarSta.TeamX[i], WarSta.TeamY[i]);
                }
            }
            for (int i = 0; i < 6; ++i)
            {
                if (WarSta.TeamMate[i] > 0 && instruct_16(WarSta.TeamMate[i], 1, 0) == 0)
                {
                    InitialBRole(BRoleAmount++, WarSta.TeamMate[i], 0, WarSta.TeamX[i], WarSta.TeamY[i] + 1);
                }
            }
        }
        require(BRoleAmount > 0, "Battle has no participants");
        Where = 2;
        for (int i = 0; i < BRoleAmount; ++i)
        {
            Brole[i].AutoMode = 1;
        }
        bool automatic = false;
        while (!BattleResult)
        {
            CalMoveAbility();
            ReArrangeBRole();
            ClearDeadRolePic();
            for (int i = 0; i < BRoleAmount; ++i)
            {
                Brole[i].Acted = 0;
            }
            for (int i = 0; i < BRoleAmount && !BattleResult; ++i)
            {
                if (Brole[i].Dead)
                {
                    continue;
                }
                Bx = Brole[i].X;
                By = Brole[i].Y;
                x50[28005] = i;
                if (Brole[i].Team == 0 && (!automatic || BattleRound % 100 == 0))
                {
                    int action = waitPrompt(obj({ { "kind", "battle_turn" }, { "title", "Battle " + std::to_string(number) + " " + name(WarSta.Name) + " round " + std::to_string(BattleRound) + " actor " + name(Rrole[Brole[i].rnum].Name) }, { "actor", i }, { "options", arr({ "Native AI: this turn", "Rest", "Native AI: battle (pause every 100 rounds)" }) }, { "cancel_allowed", false }, { "manual", "battle_action supports native move/attack/medicine/detox/poison/consume/hidden_weapon" } }));
                    automatic = action == 2;
                    if (action == 3)
                    {
                        performManual(i);
                    }
                    else if (action == 1)
                    {
                        Rest(i);
                    }
                    else
                    {
                        Brole[i].Auto = 1;
                        AutoBattle(i);
                        Brole[i].Acted = 1;
                    }
                    if (Brole[i].Acted != 1)
                    {
                        --i;
                        continue;
                    }
                }
                else
                {
                    Brole[i].Auto = 1;
                    AutoBattle(i);
                    Brole[i].Acted = 1;
                }
                ClearDeadRolePic();
                BattleResult = BattleStatus();
            }
            ++BattleRound;
            CalPoiHurtLife();
        }
        text("Battle " + std::to_string(number) + (BattleResult == 1 ? " won" : " lost") + " in " + std::to_string(BattleRound - 1) + " rounds");
        RestoreRoleStatus();
        if (BattleResult == 1 || (BattleResult == 2 && getexp))
        {
            AddExp();
            CheckLevelUp();
            CheckBook();
        }
        Where = 1;
        return BattleResult == 1;
    }

    J role(int id)
    {
        require(id >= 0 && id < roleCount, "Invalid role ID");
        auto& r = Rrole[id];
        A magic;
        for (int i = 0; i < 10; ++i)
        {
            if (r.Magic[i] > 0 && r.Magic[i] < magicCount)
            {
                magic.push_back(obj({ { "slot", i }, { "id", r.Magic[i] }, { "name", name(Rmagic[r.Magic[i]].Name) }, { "level", r.MagLevel[i] / 100 + 1 }, { "proficiency", r.MagLevel[i] } }));
            }
        }
        return obj({ { "id", id }, { "name", name(r.Name) }, { "level", r.Level }, { "hp", arr({ r.CurrentHP, r.MaxHP }) }, { "mp", arr({ r.CurrentMP, r.MaxMP }) }, { "mp_type", r.MPType }, { "stamina", r.PhyPower }, { "injury", r.Hurt }, { "poison", r.Poison }, { "attack", r.Attack }, { "defence", r.Defence }, { "speed", r.Speed }, { "ethics", r.Ethics }, { "repute", r.Repute }, { "aptitude", r.Aptitude }, { "exp", r.Exp }, { "equipment", numbers(r.Equip) }, { "practice_book", r.PracticeBook }, { "book_exp", r.ExpForBook }, { "skills", obj({ { "medicine", r.Medicine }, { "detox", r.MedPoi }, { "use_poison", r.UsePoi }, { "poison_resistance", r.DefPoi }, { "fist", r.Fist }, { "sword", r.Sword }, { "knife", r.Knife }, { "unusual", r.Unusual }, { "hidden_weapon", r.HidWeapon }, { "knowledge", r.Knowledge } }) }, { "magic", magic } });
    }

    J rules()
    {
        auto info = DescribeGameRules();
        J out = obj({ { "profile", info.profile }, { "progression", info.progression },
            { "combat", info.combat }, { "revision", 1 }, { "max_level", MAX_LEVEL },
            { "max_hp", MAX_HP }, { "max_mp", MAX_MP }, { "max_stamina", MAX_PHYSICAL_POWER },
            { "xp_mode", info.cumulativeExperience ? "cumulative" : "deduct_per_level" },
            { "growth_roll", info.batchGrowth ? "once_per_level_batch" : "once_per_level" },
            { "min_knowledge", MIN_KNOWLEDGE }, { "life_hurt", LIFE_HURT }, { "poison_hurt", POISON_HURT },
            { "dos_mp_cost_cache", CaptureRuleState().magicCostTier } });
        if (info.growth)
        {
            out["xp_thresholds"] = numbers(info.xpThresholds);
            out["hp_growth_factor"] = info.growth->hp;
            out["mp_growth_factor"] = info.growth->mp;
            out["attack_growth_factor"] = info.growth->attack;
            out["speed_growth_factor"] = info.growth->speed;
            out["defence_growth_factor"] = info.growth->defence;
        }
        if (info.levelStatCaps)
        {
            out["level_stat_caps"] = *info.levelStatCaps;
        }
        else
        {
            out["level_stat_caps"] = numbers(MaxProList);
        }
        out["scope"] = "Progression, HP/MP damage, poison, hidden weapons, medicine, detox and rest. AI, movement, item/book/event rules and starting data retain remake behavior.";
        return out;
    }

    J inventory()
    {
        A out;
        for (auto v : RItemList)
        {
            if (v.Number >= 0 && v.Amount > 0)
            {
                out.push_back(obj({ { "id", v.Number }, { "name", name(Ritem[v.Number].Name) }, { "quantity", v.Amount } }));
            }
        }
        return out;
    }

    J battleState()
    {
        A out;
        for (int i = 0; i < BRoleAmount; ++i)
        {
            auto& b = Brole[i];
            out.push_back(obj({ { "index", i }, { "role", b.rnum }, { "name", name(Rrole[b.rnum].Name) }, { "team", b.Team }, { "xy", arr({ b.X, b.Y }) }, { "face", b.Face }, { "dead", b.Dead }, { "hp", Rrole[b.rnum].CurrentHP }, { "mp", Rrole[b.rnum].CurrentMP }, { "stamina", Rrole[b.rnum].PhyPower }, { "injury", Rrole[b.rnum].Hurt }, { "poison", Rrole[b.rnum].Poison }, { "step", b.Step } }));
        }
        return obj({ { "id", CurrentBattle }, { "name", name(WarSta.Name) }, { "round", BattleRound }, { "result", BattleResult }, { "exp_pool", WarSta.ExpGot }, { "actors", out } });
    }

    J inspectBattle(const J& a)
    {
        require(Where == 2, "Battle inspection requires an active battle");
        int actor = integer(a, "actor", integer(prompt, "actor", 0));
        require(actor >= 0 && actor < BRoleAmount && !Brole[actor].Dead, "Choose a living battle actor index");
        int x = integer(a, "x", Brole[actor].X), y = integer(a, "y", Brole[actor].Y), radius = integer(a, "radius", 5);
        require(x >= 0 && x < 64 && y >= 0 && y < 64 && radius >= 0 && radius <= 10, "Battle x/y must be 0..63 and radius 0..10");
        // CalCanSelect uses a scratch layer. Preserve it so observation never
        // changes a suspended targeting/movement operation or its RNG sequence.
        std::array<int16_t, 3 * 64 * 64> savedScratch;
        constexpr int scratchLayers[] = { 3, 6, 7 };
        for (int layer = 0; layer < 3; ++layer)
        {
            std::memcpy(savedScratch.data() + layer * 64 * 64, BField[scratchLayers[layer]], sizeof(BField[3]));
        }
        CalCanSelect(actor, 0, Brole[actor].Step);
        A reachable;
        for (int nx = 0; nx < 64; ++nx)
        {
            for (int ny = 0; ny < 64; ++ny)
            {
                if (BField[3][nx][ny] > 0 && BField[2][nx][ny] < 0)
                {
                    reachable.push_back(arr({ nx, ny, BField[3][nx][ny] }));
                }
            }
        }
        for (int layer = 0; layer < 3; ++layer)
        {
            std::memcpy(BField[scratchLayers[layer]], savedScratch.data() + layer * 64 * 64, sizeof(BField[3]));
        }
        A tiles, magic;
        for (int nx = std::max(0, x - radius); nx <= std::min(63, x + radius); ++nx)
        {
            for (int ny = std::max(0, y - radius); ny <= std::min(63, y + radius); ++ny)
            {
                tiles.push_back(arr({ nx, ny, BField[0][nx][ny], BField[1][nx][ny], BField[2][nx][ny] }));
            }
        }
        auto& r = Rrole[Brole[actor].rnum];
        for (int slot = 0; slot < 10; ++slot)
        {
            if (r.Magic[slot] > 0 && r.Magic[slot] < magicCount)
            {
                auto& m = Rmagic[r.Magic[slot]];
                int lv = r.MagLevel[slot] / 100;
                auto info = BattleRules().inspectMagic(&r, m, lv + 1);
                magic.push_back(obj({ { "slot", slot }, { "id", r.Magic[slot] }, { "name", name(m.Name) }, { "level", lv + 1 }, { "area_type", m.AttAreaType }, { "move_distance", m.MoveDistance[lv] }, { "attack_distance", m.AttDistance[lv] }, { "mp_cost", info.mpCost }, { "minimum_stamina", 10 } }));
                if (info.reportsEffectiveLevel)
                {
                    magic.back()["effective_level"] = info.effectiveLevel;
                    magic.back()["mp_cost_uses_cached_hp_tier"] = info.usesCachedTier;
                }
                magic.back()["shape"] = attackShape(m.AttAreaType);
                magic.back()["targeting"] = attackTargeting(m.AttAreaType);
            }
        }
        return obj({ { "battle", battleState() }, { "actor", actor }, { "role", role(Brole[actor].rnum) }, { "magic", magic }, { "reachable_columns", arr({ "x", "y", "movement_cost" }) }, { "reachable", reachable }, { "tile_columns", arr({ "x", "y", "ground", "building", "occupant_actor" }) }, { "tiles", tiles }, { "center", arr({ x, y }) }, { "radius", radius }, { "rules", "Movement/terrain from native CalCanSelect. Building>0 blocks movement; occupant -1 is empty. Low MP permits native weak attacks. Targeting uses native x/y." } });
    }

    J state()
    {
        A party;
        for (int i = 0; i < 6; ++i)
        {
            if (TeamList[i] >= 0)
            {
                party.push_back(role(TeamList[i]));
            }
        }
        J out = obj({ { "loaded", loaded }, { "where", Where }, { "scene", CurScene }, { "scene_name", CurScene >= 0 ? name(Rscene[CurScene].Name) : "" }, { "xy", Where == 0 ? arr({ Mx, My }) : arr({ Sx, Sy }) }, { "data_xy", Where == 0 ? arr({ My, Mx }) : arr({ Sy, Sx }) }, { "face", Where == 0 ? MFace : SFace }, { "world_xy", arr({ Mx, My }) }, { "world_face", MFace }, { "in_ship", InShip }, { "ship_xy", arr({ ShipY, ShipX }) }, { "party", party }, { "inventory", inventory() }, { "pending", prompt }, { "rng_state", HeadlessRandomState }, { "debug_enabled", debug }, { "legacy_checkpoint_lineage", legacyCheckpointLineage } });
        auto info = DescribeGameRules();
        out["active_rules"] = obj({ { "profile", info.profile }, { "progression", info.progression }, { "combat", info.combat }, { "dos_mp_cost_cache", CaptureRuleState().magicCostTier } });
        for (auto& member : out["party"].get_array())
        {
            member["next_level_exp"] = NextLevelExperience(Rrole[integer(member, "id")]);
        }
        if (Where == 2)
        {
            out["battle"] = battleState();
        }
        return out;
    }

    J changes()
    {
        A items, events, roles;
        if (before)
        {
            std::vector<int> old(itemCount);
            for (auto v : before->inventory)
            {
                if (v.Number >= 0 && v.Number < itemCount)
                {
                    old[v.Number] += v.Amount;
                }
            }
            for (int i = 0; i < itemCount; ++i)
            {
                if (quantity(i) != old[i])
                {
                    items.push_back(obj({ { "id", i }, { "name", name(Ritem[i].Name) }, { "before", old[i] }, { "after", quantity(i) }, { "delta", quantity(i) - old[i] } }));
                }
            }
            for (int i = 0; i < roleCount; ++i)
            {
                if (std::memcmp(&Rrole[i], &before->roles[i], sizeof(TRole)))
                {
                    A fields;
                    for (int f = 0; f < 91; ++f)
                    {
                        if (Rrole[i].Data[f] != before->roles[i].Data[f])
                        {
                            fields.push_back(obj({ { "field", f }, { "before", before->roles[i].Data[f] }, { "after", Rrole[i].Data[f] } }));
                        }
                    }
                    roles.push_back(obj({ { "id", i }, { "name", name(Rrole[i].Name) }, { "fields", fields } }));
                }
            }
            for (int s = 0; s < SceneAmount; ++s)
            {
                for (int e = 0; e < 200; ++e)
                {
                    if (std::memcmp(DData[s][e], before->events.data() + (s * 200 + e) * 11, 22))
                    {
                        events.push_back(obj({ { "scene", s }, { "slot", e }, { "after", numbers(DData[s][e]) } }));
                    }
                }
            }
        }
        return obj({ { "items", items }, { "roles", roles }, { "events", events } });
    }

    J response()
    {
        J visibleState = loaded ? state() : obj({ { "loaded", false }, { "debug_enabled", debug }, { "legacy_checkpoint_lineage", legacyCheckpointLineage } });
        J out = obj({ { "state", visibleState }, { "messages", messages }, { "effects", actionEffects }, { "changes", changes() }, { "trace", trace }, { "trace_format", "[script, word_offset, opcode]; last 160 instructions" }, { "action_result", result } });
        if (!error.empty())
        {
            out["error"] = error;
        }
        messages = A{ };
        trace = A{ };
        actionEffects = A{ };
        before = std::make_unique<Snapshot>();
        return out;
    }

    J run(std::function<J()> action)
    {
        require(done, "A native event is waiting. Call choose before another action.");
        if (worker.joinable())
        {
            worker.join();
        }
        before = std::make_unique<Snapshot>();
        instructions = 0;
        messages = A{ };
        trace = A{ };
        error.clear();
        result = J{ };
        {
            std::lock_guard lock(mutex);
            done = false;
            paused = false;
        }
        auto origin = std::make_shared<Snapshot>();
        bool originallyLoaded = loaded;
        worker = std::thread([&, action, origin, originallyLoaded]
            {
                try
                {
                    result = action();
                } catch (const std::exception& e)
                {
                    error = e.what();
                    origin->restore();
                    loaded = originallyLoaded;
                    manualReady = false;
                }
                std::lock_guard lock(mutex);
                done = true;
                paused = false;
                prompt = J{ };
                changed.notify_all();
            });
        std::unique_lock lock(mutex);
        changed.wait(lock, [&]
            {
                return done || paused;
            });
        return response();
    }

    J resume(int selection, bool manual = false)
    {
        std::unique_lock lock(mutex);
        require(paused, "No pending choice");
        auto kind = string(prompt, "kind");
        if (manual)
        {
            require(kind == "battle_turn" && manualReady, "No prepared manual battle action");
        }
        else if (kind == "number" || kind == "party")
        {
            require(selection >= integer(prompt, "minimum") && selection <= integer(prompt, "maximum"), "Number outside allowed range");
            if (kind == "party")
            {
                require((selection & integer(prompt, "available_mask")) == selection, "Selected empty party slots");
            }
        }
        else
        {
            auto size = prompt["options"].get_array().size();
            bool cancel = prompt.contains("cancel_allowed") && prompt["cancel_allowed"].get<bool>();
            require(selection >= (cancel ? -1 : 0) && selection < static_cast<int>(size), "Invalid option index");
        }
        answer = selection;
        answering = true;
        paused = false;
        changed.notify_all();
        changed.wait(lock, [&]
            {
                return paused || done;
            });
        return response();
    }

    void validateGameplayFiles()
    {
        // ReadFiles historically accepts absent/short files, leaving zeroed
        // thresholds and map layers. Reject an incomplete investigation runtime
        // before loading it; do not change the graphical loader's behavior.
        auto check = [&](const char* file, uintmax_t minimum, bool exact = false)
        {
            auto path = fs::path(AppPath) / file;
            require(fs::is_regular_file(path), std::string("Missing gameplay file: ") + file);
            auto size = fs::file_size(path);
            require(size >= minimum && (!exact || size == minimum), std::string("Unexpected gameplay file size: ") + file);
        };
        INIReaderNormal ini;
        ini.loadFile(AppPath + "kysmod.ini");
        int matches = ini.getInt("constant", "MAX_WEAPON_MATCH", 7);
        require(matches >= 0 && matches <= 100, "MAX_WEAPON_MATCH must be 0..100");
        check("list/leave.bin", sizeof(LeaveList));
        check("list/levelup.bin", sizeof(LevelUpList));
        // The supplied mod deliberately has only 64 effect entries (128 bytes).
        check("list/effect.bin", 2);
        require(fs::file_size(fs::path(AppPath) / "list/effect.bin") % 2 == 0, "Effect list has an incomplete entry");
        check("list/match.bin", static_cast<uintmax_t>(matches) * 6);
        for (const char* file : { "resource/earth.002", "resource/surface.002", "resource/building.002", "resource/buildx.002", "resource/buildy.002" })
        {
            check(file, 480 * 480 * 2, true);
        }
    }

    void loadCounts()
    {
        std::ifstream f(fs::path(AppPath) / "save/ranger.idx", std::ios::binary);
        int offsets[6];
        f.read(reinterpret_cast<char*>(offsets), 24);
        require(f.good(), "Cannot read ranger.idx");
        require(offsets[0] == 36 + MAX_ITEM_AMOUNT * 4, "Inventory header does not match MAX_ITEM_AMOUNT");
        const int strides[] = { 182, 190, 52, 136, 30 };
        const int capacities[] = { 2032, 725, 201, 999, 11 };
        for (int i = 0; i < 5; ++i)
        {
            require(offsets[i + 1] >= offsets[i] && (offsets[i + 1] - offsets[i]) % strides[i] == 0 && (offsets[i + 1] - offsets[i]) / strides[i] <= capacities[i], "Invalid ranger.idx section sizes");
        }
        roleCount = (offsets[1] - offsets[0]) / 182;
        itemCount = (offsets[2] - offsets[1]) / 190;
        magicCount = (offsets[4] - offsets[3]) / 136;
        int scenes = (offsets[3] - offsets[2]) / 52;
        for (auto [file, expected] : std::initializer_list<std::pair<const char*, uintmax_t>>{ { "save/ranger.grp", static_cast<uintmax_t>(offsets[5]) }, { "save/allsin.grp", static_cast<uintmax_t>(scenes) * 49152 }, { "save/alldef.grp", static_cast<uintmax_t>(scenes) * 4400 } })
        {
            require(fs::file_size(fs::path(AppPath) / file) == expected, std::string("Unexpected size: ") + file);
        }
        contentIdentity = 14695981039346656037ull;
        for (const char* file : { "kysmod.ini", "save/ranger.idx", "save/ranger.grp", "save/allsin.grp", "save/alldef.grp", "resource/kdef.idx", "resource/kdef.grp", "resource/talk.idx", "resource/talk.grp", "resource/war.sta", "resource/warfld.idx", "resource/warfld.grp" })
        {
            std::ifstream input(fs::path(AppPath) / file, std::ios::binary);
            require(input.good(), "Cannot fingerprint mod files");
            char buffer[16384];
            while (input.read(buffer, sizeof(buffer)) || input.gcount())
            {
                for (int i = 0; i < input.gcount(); ++i)
                {
                    contentIdentity ^= static_cast<unsigned char>(buffer[i]);
                    contentIdentity *= 1099511628211ull;
                }
            }
        }
        legacyContentIdentity = contentIdentity;
        for (const char* file : { "list/leave.bin", "list/effect.bin", "list/levelup.bin", "list/match.bin", "resource/earth.002", "resource/surface.002", "resource/building.002", "resource/buildx.002", "resource/buildy.002" })
        {
            for (const char* p = file; *p; ++p)
            {
                contentIdentity ^= static_cast<unsigned char>(*p);
                contentIdentity *= 1099511628211ull;
            }
            contentIdentity ^= fs::file_size(fs::path(AppPath) / file);
            contentIdentity *= 1099511628211ull;
            std::ifstream input(fs::path(AppPath) / file, std::ios::binary);
            require(input.good(), std::string("Cannot fingerprint gameplay file: ") + file);
            char buffer[16384];
            while (input.read(buffer, sizeof(buffer)) || input.gcount())
            {
                for (int i = 0; i < input.gcount(); ++i)
                {
                    contentIdentity ^= static_cast<unsigned char>(buffer[i]);
                    contentIdentity *= 1099511628211ull;
                }
            }
        }
    }

    J scene(int id, bool all = true, bool inactive = false)
    {
        require(id >= 0 && id < SceneAmount, "Invalid scene ID");
        auto& s = Rscene[id];
        A points, exits;
        for (int i = 0; i < 3; ++i)
        {
            exits.push_back(arr({ s.ExitX[i], s.ExitY[i] }));
        }
        if (all)
        {
            for (int e = 0; e < 200; ++e)
            {
                auto& d = DData[id][e];
                A tiles;
                for (int x = 0; x < 64; ++x)
                {
                    for (int y = 0; y < 64; ++y)
                    {
                        if (SData[id][3][x][y] == e)
                        {
                            tiles.push_back(arr({ x, y }));
                        }
                    }
                }
                if (!inactive && d[2] <= 0 && d[3] <= 0 && d[4] <= 0 && d[5] <= 0)
                {
                    continue;
                }
                J point = obj({ { "slot", e }, { "xy", arr({ d[10], d[9] }) }, { "tiles", tiles }, { "blocking", d[0] }, { "talk", d[2] }, { "item", d[3] }, { "step", d[4] }, { "sprite", d[5] } });
                if (inactive)
                {
                    point["raw"] = numbers(d);
                }
                points.push_back(point);
            }
        }
        return obj({ { "id", id }, { "name", name(s.Name) }, { "entry_condition", s.EnCondition }, { "can_enter", CheckCanEnter(id) }, { "entry_xy", arr({ s.EntranceX, s.EntranceY }) }, { "world_data_xy", arr({ s.MainEntranceY1, s.MainEntranceX1 }) }, { "exits", exits }, { "jump_scene", s.JumpScene }, { "jump_xy", arr({ s.JumpX1, s.JumpY1 }) }, { "jump_landing_xy", arr({ s.JumpX2, s.JumpY2 }) }, { "events", points } });
    }

    bool transition()
    {
        if (Where != 1)
        {
            return false;
        }
        auto& s = Rscene[CurScene];
        for (int i = 0; i < 3; ++i)
        {
            if (Sx == s.ExitX[i] && Sy == s.ExitY[i])
            {
                Where = 0;
                return true;
            }
        }
        if (Sx != HeadlessJumpGuardX || Sy != HeadlessJumpGuardY)
        {
            HeadlessJumpGuardX = HeadlessJumpGuardY = -1;
        }
        if (HeadlessJumpGuardX < 0 && Sx == s.JumpX1 && Sy == s.JumpY1 && s.JumpScene >= 0)
        {
            int old = CurScene;
            CurScene = s.JumpScene;
            require(CurScene < SceneAmount, "Invalid jump scene");
            auto& to = Rscene[CurScene];
            Sx = Rscene[old].MainEntranceX1 != 0 ? to.EntranceX : to.JumpX2;
            Sy = Rscene[old].MainEntranceX1 != 0 ? to.EntranceY : to.JumpY2;
            HeadlessJumpGuardX = Sx;
            HeadlessJumpGuardY = Sy;
            Cx = Sx;
            Cy = Sy;
            CheckEvent3();
            return true;
        }
        return false;
    }

    bool walk(int tx, int ty)
    {
        require(Where == 1, "Scene navigation requires a scene");
        require(tx >= 0 && tx < 64 && ty >= 0 && ty < 64, "Coordinates must be 0..63");
        int previous[4096];
        std::fill(std::begin(previous), std::end(previous), -1);
        int start = Sx * 64 + Sy, goal = tx * 64 + ty;
        std::queue<int> q;
        q.push(start);
        previous[start] = start;
        constexpr int dx[] = { -1, 0, 0, 1 }, dy[] = { 0, 1, -1, 0 };
        while (!q.empty() && previous[goal] < 0)
        {
            int v = q.front();
            q.pop();
            int x = v / 64, y = v % 64;
            for (int d = 0; d < 4; ++d)
            {
                int nx = x + dx[d], ny = y + dy[d];
                if (nx < 0 || nx >= 64 || ny < 0 || ny >= 64)
                {
                    continue;
                }
                int n = nx * 64 + ny;
                if (previous[n] < 0 && CanWalkInScene(x, y, nx, ny))
                {
                    previous[n] = v;
                    q.push(n);
                }
            }
        }
        require(previous[goal] >= 0, "Destination unreachable through native mouse-path/height rules; inspect_scene and step can test a native keyboard approach");
        std::vector<int> path;
        for (int v = goal; v != start; v = previous[v])
        {
            path.push_back(v);
        }
        std::reverse(path.begin(), path.end());
        for (int v : path)
        {
            int nx = v / 64, ny = v % 64;
            require(CanWalkInScene(Sx, Sy, nx, ny), "Path became blocked");
            SFace = nx < Sx ? 0 : ny > Sy ? 1 :
                ny < Sy                   ? 2 :
                                            3;
            Sx = nx;
            Sy = ny;
            Cx = Sx;
            Cy = Sy;
            int e = SData[CurScene][3][Sx][Sy];
            bool triggered = e >= 0 && DData[CurScene][e][4] > 0;
            // Native keyboard loop runs the step script immediately after
            // movement, then checks exits/jumps on its next iteration.
            CheckEvent3();
            if (transition() || triggered)
            {
                return false;
            }
        }
        return true;
    }

    bool worldPassable(int x, int y)
    {
        int ship = InShip;
        bool result = CanWalk(x, y);
        InShip = ship;
        return result;
    }

    bool worldStep(int direction)
    {
        constexpr int dx[] = { -1, 0, 0, 1 }, dy[] = { 0, 1, -1, 0 };
        MFace = direction;
        int x = Mx + dx[direction], y = My + dy[direction];
        if (CanWalk(x, y))
        {
            Mx = x;
            My = y;
        }
        // This is the same dispatch used by graphical world keyboard steps.
        // The headless branch skips only rendering and native autosave I/O.
        return CheckEntrance();
    }

    J worldWalk(int tx, int ty, int destinationScene = -1)
    {
        require(Where == 0, "World navigation requires the world map");
        require(tx >= 0 && tx < 480 && ty >= 0 && ty < 480, "World coordinates must be 0..479");
        constexpr int dx[] = { -1, 0, 0, 1 }, dy[] = { 0, 1, -1, 0 };
        std::vector<int> previous(480 * 480, -1);
        std::queue<int> q;
        int start = Mx * 480 + My, goal = -1, entryFace = -1;
        previous[start] = start;
        q.push(start);
        while (!q.empty())
        {
            int v = q.front();
            q.pop();
            int x = v / 480, y = v % 480;
            if (destinationScene < 0 && x == tx && y == ty)
            {
                goal = v;
                break;
            }
            if (destinationScene >= 0)
            {
                for (int d = 0; d < 4; ++d)
                {
                    int ex = x + dx[d], ey = y + dy[d];
                    if (ex >= 0 && ex < 480 && ey >= 0 && ey < 480 && Entrance[ex][ey] == destinationScene)
                    {
                        goal = v;
                        entryFace = d;
                        break;
                    }
                }
            }
            if (goal >= 0)
            {
                break;
            }
            for (int d = 0; d < 4; ++d)
            {
                int nx = x + dx[d], ny = y + dy[d];
                if (nx < 0 || nx >= 480 || ny < 0 || ny >= 480)
                {
                    continue;
                }
                int n = nx * 480 + ny;
                // Plan around known unselected entrances, just as a player
                // chooses a route around them. Execution still calls the
                // native entry check after every actual keyboard step.
                int ex = nx + dx[d], ey = ny + dy[d];
                int other = ex >= 0 && ex < 480 && ey >= 0 && ey < 480 ? Entrance[ex][ey] : -1;
                if (other >= 0 && other != destinationScene && CheckCanEnter(other))
                {
                    continue;
                }
                if (previous[n] < 0 && worldPassable(nx, ny))
                {
                    previous[n] = v;
                    q.push(n);
                }
            }
        }
        require(goal >= 0, "No reachable native world approach; inspect map coordinates/terrain instead of bypassing entry");
        std::vector<int> path;
        for (int v = goal; v != start; v = previous[v])
        {
            path.push_back(v);
        }
        std::reverse(path.begin(), path.end());
        int steps = 0;
        for (int v : path)
        {
            int x = v / 480, y = v % 480, d = x < Mx ? 0 : y > My ? 1 :
                y < My                                            ? 2 :
                                                                    3;
            ++steps;
            if (worldStep(d))
            {
                return obj({ { "reached", destinationScene >= 0 && CurScene == destinationScene }, { "entered_scene", CurScene }, { "world_steps", steps }, { "mode", "native world approach" } });
            }
            require(Mx == x && My == y, "Native world path became blocked");
        }
        if (entryFace >= 0)
        {
            worldStep(entryFace);
            ++steps;
        }
        return obj({ { "reached", destinationScene >= 0 ? Where == 1 && CurScene == destinationScene : Where == 0 && Mx == tx && My == ty }, { "world_steps", steps }, { "mode", "native world approach" } });
    }

    J step(int direction, int count)
    {
        require((Where == 0 || Where == 1) && direction >= 0 && direction < 4 && count >= 1 && count <= 100, "step requires world/scene, direction 0..3 and count 1..100");
        constexpr int dx[] = { -1, 0, 0, 1 }, dy[] = { 0, 1, -1, 0 };
        int moved = 0;
        for (int i = 0; i < count; ++i)
        {
            if (Where == 0)
            {
                int x = Mx, y = My;
                bool entered = worldStep(direction);
                if (Mx != x || My != y)
                {
                    ++moved;
                }
                if (entered || Mx == x && My == y)
                {
                    break;
                }
            }
            else
            {
                SFace = direction;
                int x = Sx + dx[direction], y = Sy + dy[direction];
                bool movedStep = CanWalkInScene(x, y);
                if (movedStep)
                {
                    Sx = x;
                    Sy = y;
                    Cx = x;
                    Cy = y;
                    ++moved;
                }
                int e = SData[CurScene][3][Sx][Sy];
                bool trigger = e >= 0 && DData[CurScene][e][4] > 0;
                CheckEvent3();
                if (transition() || trigger || !movedStep)
                {
                    break;
                }
            }
        }
        return obj({ { "moved", moved }, { "requested_steps", count }, { "mode", "native keyboard steps" } });
    }

    J interact(int slot, int item)
    {
        require(Where == 1, "Interaction requires a scene");
        require(slot >= -1 && slot < 200, "Invalid event slot");
        if (item >= 0)
        {
            require(item < itemCount && quantity(item) > 0, "Item is not owned");
        }
        if (slot < 0)
        {
            if (item >= 0)
            {
                UseItem(item);
            }
            else
            {
                require(CheckEvent1(), "Facing tile has no talk trigger");
            }
            transition();
            return obj({ { "mode", "current position and facing" }, { "item", item } });
        }
        // Approach the closest reachable adjacent tile, using the actual event map.
        int best = 10000, bx = -1, by = -1, ex = -1, ey = -1;
        constexpr int dx[] = { -1, 0, 0, 1 }, dy[] = { 0, 1, -1, 0 };
        // Distances come from a single BFS; no teleporting through blocked objects.
        int dist[64][64];
        std::fill(&dist[0][0], &dist[0][0] + 4096, -1);
        std::queue<TPosition> q;
        q.push({ Sx, Sy });
        dist[Sx][Sy] = 0;
        while (!q.empty())
        {
            auto p = q.front();
            q.pop();
            for (int d = 0; d < 4; ++d)
            {
                int x = p.x + dx[d], y = p.y + dy[d];
                if (x < 0 || x >= 64 || y < 0 || y >= 64)
                {
                    continue;
                }
                if (dist[x][y] < 0 && CanWalkInScene(p.x, p.y, x, y))
                {
                    dist[x][y] = dist[p.x][p.y] + 1;
                    q.push({ x, y });
                }
            }
        }
        for (int x = 0; x < 64; ++x)
        {
            for (int y = 0; y < 64; ++y)
            {
                if (SData[CurScene][3][x][y] == slot)
                {
                    for (int d = 0; d < 4; ++d)
                    {
                        int ax = x + dx[d], ay = y + dy[d];
                        if (ax < 0 || ax >= 64 || ay < 0 || ay >= 64)
                        {
                            continue;
                        }
                        if (dist[ax][ay] >= 0 && dist[ax][ay] < best)
                        {
                            best = dist[ax][ay];
                            bx = ax;
                            by = ay;
                            ex = x;
                            ey = y;
                        }
                    }
                }
            }
        }
        require(bx >= 0, "No reachable adjacent tile through native mouse-path/height rules; use inspect_scene and step for a native keyboard approach, then interact without slot");
        if (!walk(bx, by))
        {
            return obj({ { "interrupted", true }, { "reason", "step event or scene transition; inspect state then interact again" } });
        }
        SFace = ex < Sx ? 0 : ey > Sy ? 1 :
            ey < Sy                   ? 2 :
                                        3;
        if (item >= 0)
        {
            UseItem(item);
        }
        else
        {
            require(CheckEvent1(), "Event has no talk trigger");
        }
        return obj({ { "interacted_slot", slot }, { "item", item } });
    }

    J search(const J& a)
    {
        std::string kind = string(a, "kind", "item"), query = string(a, "query");
        int id = integer(a, "id"), offset = integer(a, "offset", 0), limit = integer(a, "limit", 30);
        require(offset >= 0 && limit > 0 && limit <= 100, "Use offset >= 0 and limit 1..100");
        A out;
        int matched = 0;
        int count = kind == "scene" ? SceneAmount : kind == "item" ? itemCount :
            kind == "role"                                         ? roleCount :
            kind == "magic"                                        ? magicCount :
                                                                     0;
        require(count > 0, "kind must be item, scene, role or magic");
        for (int i = 0; i < count; ++i)
        {
            std::string n = kind == "scene" ? name(Rscene[i].Name) : kind == "item" ? name(Ritem[i].Name) :
                kind == "role"                                                      ? name(Rrole[i].Name) :
                                                                                      name(Rmagic[i].Name);
            if ((id >= 0 && i != id) || (!query.empty() && n.find(query) == std::string::npos))
            {
                continue;
            }
            if (matched++ < offset || out.size() >= limit)
            {
                continue;
            }
            J v = obj({ { "id", i }, { "name", n } });
            if (id >= 0)
            {
                if (kind == "role")
                {
                    v = role(i);
                    v["data"] = numbers(Rrole[i].Data);
                }
                else if (kind == "scene")
                {
                    v = scene(i);
                }
                else if (kind == "item")
                {
                    auto& it = Ritem[i];
                    v["description"] = name(it.Introduction);
                    v["alias"] = name(it.Name1);
                    v["type"] = it.ItemType;
                    v["quantity"] = quantity(i);
                    v["magic"] = it.Magic;
                    v["user"] = it.User;
                    v["data"] = numbers(it.Data);
                    v["name_bytes"] = A{ };
                    for (unsigned char c : it.Name)
                    {
                        v["name_bytes"].get_array().push_back(c);
                    }
                    A eligible;
                    for (auto r : TeamList)
                    {
                        if (r >= 0)
                        {
                            eligible.push_back(obj({ { "role", r }, { "can_equip", CanEquip(r, i) } }));
                        }
                    }
                    v["eligibility"] = eligible;
                    v["requirements"] = obj({ { "role", it.OnlyPracRole }, { "mp_type", it.NeedMPType }, { "max_mp", it.NeedMP }, { "attack", it.NeedAttack }, { "speed", it.NeedSpeed }, { "poison", it.NeedUsePoi }, { "medicine", it.NeedMedicine }, { "detox", it.NeedMedPoi }, { "fist", it.NeedFist }, { "sword", it.NeedSword }, { "knife", it.NeedKnife }, { "unusual", it.NeedUnusual }, { "hidden_weapon", it.NeedHidWeapon }, { "aptitude", it.NeedAptitude } });
                    v["practice"] = obj({ { "base_exp", it.NeedExp }, { "craft_exp", it.NeedExpForItem }, { "material", it.NeedMaterial }, { "crafted_items", numbers(it.GetItem) }, { "material_amounts", numbers(it.NeedMatAmount) } });
                    static constexpr const char* labels[] = { "hp", "max_hp", "poison", "stamina", "mp_type", "mp", "max_mp", "attack", "speed", "defence", "medicine", "use_poison", "detox", "poison_resistance", "fist", "sword", "knife", "unusual", "hidden_weapon", "knowledge", "ethics", "attack_twice", "attack_poison" };
                    J effects = obj({ });
                    for (int e = 0; e < 23; ++e)
                    {
                        if (it.Data[45 + e] != 0)
                        {
                            effects[labels[e]] = it.Data[45 + e];
                        }
                    }
                    v["effects"] = effects;
                }
                else
                {
                    auto& m = Rmagic[i];
                    v["data"] = numbers(m.Data);
                    v["type"] = m.MagicType;
                    v["hurt_type"] = m.HurtType;
                    v["area_type"] = m.AttAreaType;
                    v["shape"] = attackShape(m.AttAreaType);
                    v["targeting"] = attackTargeting(m.AttAreaType);
                    auto info = BattleRules().inspectMagic(nullptr, m, 1);
                    v["base_mp_cost"] = m.NeedMP;
                    v["minimum_stamina"] = 10;
                    v["poison"] = m.Poison;
                    v["stamina_cost_per_strike"] = info.staminaPerStrike ? J(info.staminaPerStrike) : J{ };
                    if (info.staminaPerAction)
                    {
                        v["stamina_cost_per_action"] = info.staminaPerAction;
                    }
                    if (info.reportsEffectiveLevel)
                    {
                        v["mp_cost_uses_cached_hp_tier"] = info.usesCachedTier;
                    }
                    A levels;
                    for (int lv = 0; lv < 10; ++lv)
                    {
                        auto tier = BattleRules().inspectMagic(nullptr, m, lv + 1);
                        levels.push_back(obj({ { "level", lv + 1 }, { "attack", m.Attack[lv] }, { "move_distance", m.MoveDistance[lv] }, { "attack_distance", m.AttDistance[lv] }, { "mp_cost", tier.mpCost }, { "add_mp", m.AddMP[lv] }, { "hurt_mp", m.HurtMP[lv] } }));
                    }
                    v["levels"] = levels;
                }
            }
            out.push_back(v);
        }
        return obj({ { "results", out }, { "total", matched }, { "offset", offset }, { "limit", limit } });
    }

    J audit()
    {
        A names, entries, refs;
        for (int i = 0; i < itemCount; ++i)
        {
            auto n = name(Ritem[i].Name);
            if (n.find_first_of("\r\n\t") != std::string::npos)
            {
                names.push_back(obj({ { "item", i }, { "name", n } }));
            }
        }
        int old = CurScene;
        for (int s = 0; s < SceneAmount; ++s)
        {
            CurScene = s;
            int x = Rscene[s].EntranceX, y = Rscene[s].EntranceY;
            if (x < 0 || x >= 64 || y < 0 || y >= 64)
            {
                entries.push_back(obj({ { "scene", s }, { "name", name(Rscene[s].Name) }, { "xy", arr({ x, y }) }, { "reason", "out of bounds" } }));
            }
            else if (!CanWalkInScene(x, y))
            {
                entries.push_back(obj({ { "scene", s }, { "name", name(Rscene[s].Name) }, { "xy", arr({ x, y }) }, { "building", SData[s][1][x][y] }, { "event", SData[s][3][x][y] }, { "reason", "entry tile blocked; investigate triggers and exits before classifying" } }));
            }
            for (int e = 0; e < 200; ++e)
            {
                for (int t = 2; t <= 4; ++t)
                {
                    if (DData[s][e][t] >= static_cast<int>(KIdx.size()))
                    {
                        refs.push_back(obj({ { "scene", s }, { "slot", e }, { "trigger", t }, { "script", DData[s][e][t] } }));
                    }
                }
            }
        }
        CurScene = old;
        return obj({ { "item_name_control_characters", names }, { "entry_candidates", entries }, { "invalid_script_references", refs } });
    }

    J script(const J& a)
    {
        int id = integer(a, "id"), offset = integer(a, "offset", 0), limit = integer(a, "limit", 20);
        require(id >= 0 && id < static_cast<int>(KIdx.size()), "Invalid script ID");
        require(offset >= 0 && limit > 0 && limit <= 100, "offset >= 0; limit 1..100");
        int begin = id ? KIdx[id - 1] : 0, end = KIdx[id];
        require(begin >= 0 && end >= begin && end <= static_cast<int>(KDef.size()) && (end - begin) % 2 == 0, "Invalid script byte range");
        std::vector<int16_t> words((end - begin) / 2);
        std::memcpy(words.data(), KDef.data() + begin, end - begin);
        A instructions;
        int count = 0;
        for (int pc = 0; pc < static_cast<int>(words.size());)
        {
            int op = words[pc], width = op < 0 ? 1 : (op < static_cast<int>(EventWidths.size()) ? EventWidths[op] : 0);
            require(width > 0 && pc + width <= static_cast<int>(words.size()), "Malformed script instruction at " + std::to_string(pc));
            if (count++ >= offset && instructions.size() < limit)
            {
                A args;
                for (int w = 1; w < width; ++w)
                {
                    args.push_back(words[pc + w]);
                }
                J row = obj({ { "pc", pc }, { "opcode", op }, { "args", args } });
                if (op == 1 && integer(a, "include_text", 0))
                {
                    row["text"] = ReadTalk(words[pc + 1]);
                }
                instructions.push_back(row);
            }
            pc += width;
        }
        return obj({ { "script", id }, { "offset", offset }, { "total", count }, { "instructions", instructions } });
    }

    J call(const std::string& method, const J& a)
    {
        if (method == "new_game")
        {
            return run([&, a]
                {
                    require(!loaded, "A game is already loaded; restore a checkpoint or restart the process");
                    require(fs::exists(fs::path(AppPath) / "kysmod.ini"), "Missing mod kysmod.ini");
                    validateGameplayFiles();
                    ReadFiles();
                    SetMODVersion();
                    loadCounts();
                    legacyCheckpointLineage = false;
                    require(LoadIdxGrp(AppPath + "resource/kdef.idx", AppPath + "resource/kdef.grp", KIdx, KDef) > 0, "Missing kdef");
                    require(LoadIdxGrp(AppPath + "resource/talk.idx", AppPath + "resource/talk.grp", TIdx, TDef) > 0, "Missing talk");
                    HeadlessRandomState = static_cast<unsigned>(integer(a, "seed", 1));
                    InitialRole();
                    loaded = true;
                    Where = 1;
                    CurScene = BEGIN_SCENE;
                    Sx = BEGIN_Sx;
                    Sy = BEGIN_Sy;
                    Cx = Sx;
                    Cy = Sy;
                    SFace = 0;
                    before = std::make_unique<Snapshot>();
                    CurEvent = BEGIN_EVENT;
                    CallEvent(BEGIN_EVENT);
                    CurEvent = -1;
                    CheckEvent3();
                    return obj({ { "started", true }, { "mod", MODVersion } });
                });
        }
        require(loaded, "Call new_game first");
        if (method == "state")
        {
            return state();
        }
        if (method == "rules")
        {
            return rules();
        }
        if (method == "choose")
        {
            return resume(integer(a, "index"));
        }
        if (method == "battle_action")
        {
            return prepareManual(a);
        }
        // Read-only observation is allowed at a suspended native stack.
        if (method == "search")
        {
            return search(a);
        }
        if (method == "inspect_battle")
        {
            return inspectBattle(a);
        }
        if (method == "inspect_scene")
        {
            int id = integer(a, "scene", CurScene);
            J out = scene(id, true, integer(a, "include_inactive", 0) != 0);
            if (a.contains("x") || a.contains("y"))
            {
                int x = integer(a, "x"), y = integer(a, "y");
                require(x >= 0 && x < 64 && y >= 0 && y < 64, "Tile coordinates must be 0..63");
                int old = CurScene;
                CurScene = id;
                bool passable = CanWalkInScene(x, y);
                CurScene = old;
                A layers;
                for (int l = 0; l < 6; ++l)
                {
                    layers.push_back(SData[id][l][x][y]);
                }
                out["tile"] = obj({ { "xy", arr({ x, y }) }, { "data_xy", arr({ y, x }) }, { "layers", layers }, { "layer_names", arr({ "ground", "building", "decoration", "event", "height", "building_height" }) }, { "keyboard_passable", passable } });
            }
            return out;
        }
        if (method == "inspect_world")
        {
            int x = integer(a, "x", Mx), y = integer(a, "y", My), radius = integer(a, "radius", 1);
            require(x >= 0 && x < 480 && y >= 0 && y < 480 && radius >= 0 && radius <= 3, "World x/y must be 0..479 and radius 0..3");
            A tiles;
            for (int nx = std::max(0, x - radius); nx <= std::min(479, x + radius); ++nx)
            {
                for (int ny = std::max(0, y - radius); ny <= std::min(479, y + radius); ++ny)
                {
                    tiles.push_back(obj({ { "xy", arr({ nx, ny }) }, { "data_xy", arr({ ny, nx }) }, { "earth", Earth[nx][ny] }, { "building", Building[nx][ny] }, { "build_xy", arr({ BuildX[nx][ny], BuildY[nx][ny] }) }, { "entrance_scene", Entrance[nx][ny] }, { "keyboard_passable", worldPassable(nx, ny) } }));
                }
            }
            return obj({ { "xy", arr({ x, y }) }, { "data_xy", arr({ y, x }) }, { "tiles", tiles } });
        }
        if (method == "audit")
        {
            return audit();
        }
        if (method == "inspect_script")
        {
            return script(a);
        }
        if (method == "checkpoint")
        {
            require(done, "Checkpoints require an idle scene/world state; save before interacting with a one-shot event");
            auto label = string(a, "label", "quick"), action = string(a, "action", "save");
            require(!label.empty() && label.size() <= 64 && label.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-") == std::string::npos, "Checkpoint label must be 1..64 ASCII letters/digits/underscore/hyphen");
            if (action == "save")
            {
                require(checkpoints.size() < 12 || checkpoints.contains(label) || !saveDirectory.empty(), "At most 12 memory-only checkpoints; use --save-dir for campaign branches");
                auto snapshot = std::make_shared<Snapshot>();
                snapshot->legacyLineage = legacyCheckpointLineage;
                if (!saveDirectory.empty())
                {
                    fs::create_directories(saveDirectory);
                    snapshot->file(saveDirectory / (label + ".kys-save"), contentIdentity, false);
                }
                if (checkpoints.size() >= 12 && !checkpoints.contains(label))
                {
                    checkpoints.erase(checkpoints.begin());
                }
                checkpoints[label] = std::move(snapshot);
            }
            else if (action == "load")
            {
                if (!checkpoints.contains(label) && !saveDirectory.empty())
                {
                    auto snapshot = std::make_shared<Snapshot>();
                    snapshot->file(saveDirectory / (label + ".kys-save"), contentIdentity, true, legacyContentIdentity, allowLegacyCheckpoints);
                    if (checkpoints.size() >= 12)
                    {
                        checkpoints.erase(checkpoints.begin());
                    }
                    checkpoints[label] = std::move(snapshot);
                }
                require(checkpoints.contains(label), "Unknown checkpoint");
                checkpoints.at(label)->restore();
                legacyCheckpointLineage = checkpoints.at(label)->legacyLineage;
            }
            else
            {
                throw std::runtime_error("action must be save or load");
            }
            return obj({ { "checkpoint", label }, { "action", action }, { "checkpoint_format", checkpoints.at(label)->sourceVersion }, { "legacy_checkpoint_lineage", legacyCheckpointLineage }, { "state", state() }, { "persistence", saveDirectory.empty() ? "in memory; use --save-dir for durable checkpoints" : saveDirectory.generic_string() } });
        }
        if (method == "navigate")
        {
            return run([&, a]
                {
                    if (Where == 0)
                    {
                        return worldWalk(integer(a, "x"), integer(a, "y"));
                    }
                    return obj({ { "reached", walk(integer(a, "x"), integer(a, "y")) } });
                });
        }
        if (method == "step")
        {
            return run([&, a]
                {
                    return step(integer(a, "direction"), integer(a, "count", 1));
                });
        }
        if (method == "face")
        {
            return run([&, a]
                {
                    int d = integer(a, "direction");
                    require((Where == 0 || Where == 1) && d >= 0 && d < 4, "face requires world/scene and direction 0..3");
                    if (Where == 0)
                    {
                        MFace = d;
                    }
                    else
                    {
                        SFace = d;
                    }
                    return obj({ { "face", d } });
                });
        }
        if (method == "interact")
        {
            return run([&, a]
                {
                    return interact(integer(a, "slot"), integer(a, "item"));
                });
        }
        if (method == "travel")
        {
            return run([&, a]
                {
                    require(Where == 0, "Travel starts on world map; navigate to a scene exit first");
                    int id = integer(a, "scene");
                    require(id >= 0 && id < SceneAmount, "Invalid scene ID");
                    require(CheckCanEnter(id), Rscene[id].EnCondition == 2 ? "Entry denied: a party member needs speed > 70" : "Entry denied: scene is locked by plot (condition " + std::to_string(Rscene[id].EnCondition) + ")");
                    require(Rscene[id].MainEntranceX1 > 0 || Rscene[id].MainEntranceX2 > 0, "Scene has no world entrance; use its linked scene transition");
                    return worldWalk(Rscene[id].MainEntranceX1, Rscene[id].MainEntranceY1, id);
                });
        }
        if (method == "use_item")
        {
            return run([&, a]
                {
                    int id = integer(a, "item");
                    require(id >= 0 && id < itemCount && quantity(id) > 0, "Item is not owned");
                    UseItem(id);
                    return obj({ { "used_item", id } });
                });
        }
        if (method == "party_action")
        {
            return run([&, a]
                {
                    require(Where == 0 || Where == 1, "Party skills require an idle world/scene");
                    auto action = string(a, "action");
                    require(action == "medicine" || action == "detox", "action must be medicine or detox");
                    if (action == "medicine")
                    {
                        MenuMedcine();
                    }
                    else
                    {
                        MenuMedPoison();
                    }
                    return obj({ { "party_skill", action }, { "mode", "native out-of-battle menu and effects" } });
                });
        }
        if (method == "dismiss")
        {
            return run([&, a]
                {
                    int r = integer(a, "role");
                    require(r > 0 && instruct_16(r, 1, 0) == 1, "Role must be a non-protagonist party member");
                    int leave = -1;
                    for (int i = 0; i < 100; ++i)
                    {
                        if (LeaveList[i] == r)
                        {
                            leave = i;
                            break;
                        }
                    }
                    require(leave >= 0, "Role has no native leave event");
                    CallEvent(BEGIN_LEAVE_EVENT + leave * 2);
                    return obj({ { "dismissed", r } });
                });
        }
        if (method == "debug")
        {
            return run([&, a]
                {
                    require(debug, "Restart with --debug to enable explicit shortcuts");
                    int s = integer(a, "scene", CurScene);
                    require(s >= 0 && s < SceneAmount, "Invalid scene");
                    int x = integer(a, "x", Rscene[s].EntranceX), y = integer(a, "y", Rscene[s].EntranceY);
                    require(x >= 0 && x < 64 && y >= 0 && y < 64, "Invalid coordinates");
                    int r = integer(a, "role", 0), field = integer(a, "field"), value = integer(a, "value", 0), script = integer(a, "script");
                    require(r >= 0 && r < roleCount, "Invalid role");
                    require(field >= -1 && field < 91 && value >= -32768 && value <= 32767, "Invalid role field/value");
                    require(script >= -1 && script < static_cast<int>(KIdx.size()), "Invalid script");
                    CurScene = s;
                    Where = 1;
                    Sx = x;
                    Sy = y;
                    Cx = Sx;
                    Cy = Sy;
                    HeadlessJumpGuardX = HeadlessJumpGuardY = -1;
                    if (field >= 0)
                    {
                        Rrole[r].Data[field] = value;
                    }
                    if (script >= 0)
                    {
                        CallEvent(script);
                    }
                    return obj({ { "shortcut", "DEBUG state mutation / script invocation; excludes normal progression evidence" } });
                });
        }
        throw std::runtime_error("Unknown tool: " + method);
    }
};

J schema(std::initializer_list<std::pair<const std::string, J>> fields)
{
    return obj({ { "type", "object" }, { "properties", obj(fields) }, { "additionalProperties", false } });
}

J tools()
{
    J num = obj({ { "type", "integer" } }), str = obj({ { "type", "string" } });
    A out;
    auto add = [&](const char* n, const char* d, J s)
    {
        out.push_back(obj({ { "name", n }, { "description", d }, { "inputSchema", s } }));
    };
    add("new_game", "Start native character generation and opening event. Deterministic seed; mod directory is supplied on command line.", schema({ { "seed", num } }));
    add("state", "Compact native state, party stats, inventory, pending decision and battle roster.", schema({ }));
    add("rules", "Read active progression/combat profiles, caps, XP thresholds and DOS MP-cost cache. Configuration is in mod kysmod.ini [rules].", schema({ }));
    add("search", "Find IDs by exact CP950 decoded name substring. kind=item/scene/role/magic. Specify id for raw fields, item effects and requirements, equipment eligibility. Paginated.", schema({ { "kind", str }, { "query", str }, { "id", num }, { "offset", num }, { "limit", num } }));
    add("inspect_scene", "Sparse event slots, actual map tiles, script IDs, gates, entries/exits/jumps. Optional x,y adds one tile's six layers and keyboard passability; include_inactive=1 adds raw records. Native xy axes; data_xy swaps for guide/editor.", schema({ { "scene", num }, { "include_inactive", num }, { "x", num }, { "y", num } }));
    add("inspect_world", "Read world tiles around internal x,y (default current), radius0..3 (default1). Shows terrain, building anchor, actual entrance scene and native keyboard passability without moving or changing ship state.", schema({ { "x", num }, { "y", num }, { "radius", num } }));
    add("inspect_battle", "Read active battle terrain/occupancy, legal native reachable tiles with movement costs and selected actor skills/current magic ranges. actor defaults to pending actor; x,y center defaults to actor; radius0..10(default5). Does not advance turns or RNG.", schema({ { "actor", num }, { "x", num }, { "y", num }, { "radius", num } }));
    add("navigate", "Walk to internal x,y. World uses native keyboard passability (0..479); scenes use native path/height rules (0..63). Stops on entries, step triggers, exits and jumps. Check reached.", schema({ { "x", num }, { "y", num } }));
    add("step", "Native keyboard steps, count 1..100 (default 1). direction 0=x-1, 1=y+1, 2=y-1, 3=x+1. Scene keyboard uses native passability without mouse-path height filtering. Stops on events/transitions/obstacles.", schema({ { "direction", num }, { "count", num } }));
    add("face", "Face direction 0=x-1,1=y+1,2=y-1,3=x+1 without pathfinding. Then interact with slot omitted to test current-facing dispatch.", schema({ { "direction", num } }));
    add("interact", "With slot: walk adjacent to actual event map tile, face it and dispatch native talk/owned-item trigger, stopping on intervening events. Omit slot: dispatch from current position/facing without navigation. item optional. Script IDs are not event slots.", schema({ { "slot", num }, { "item", num } }));
    add("travel", "Find and walk a native world path to scene ID's actual reachable entrance, then use native CheckEntrance. Keeps approach/facing/terrain, entry gate, spawn and step event. May stop at another entrance on the route; check reached.", schema({ { "scene", num } }));
    add("choose", "Resume suspended native input using displayed zero-based option index. Battle offers native AI turn/rest/whole battle; combat, losses, experience and books use native calculations.", schema({ { "index", num } }));
    add("battle_action", "Act at a pending battle_turn using native move/attack/medicine/detox/poison/consume/hidden_weapon. Internal x,y target; magic_slot from party.magic[].slot for attack, item ID for consume/hidden_weapon. For area_type=1 aim at an adjacent cardinal direction, not a distant enemy; search magic ID exposes ranges/costs. Movement preserves remaining turn. Party selection uses choose(index=bitmask), e.g. slots 0,2 -> 5.", schema({ { "action", str }, { "x", num }, { "y", num }, { "magic_slot", num }, { "item", num } }));
    add("use_item", "Use an owned item through native equipment/practice/medicine/plot flow; further character/menu choices suspend as needed.", schema({ { "item", num } }));
    add("party_action", "Use out-of-battle medicine or detox. Menus ask actor then recipient via choose. Remake rules make these skills free outside battle; DOS medicine costs 2 stamina and requires 50. Poison or injury>33 prevents sleep recovery until treated.", schema({ { "action", str } }));
    add("dismiss", "Dismiss a party member through the native mod leave event.", schema({ { "role", num } }));
    add("checkpoint", "Save/load all mutations, RNG and DOS MP-cost cache. Idle only: save BEFORE one-shot interactions. Cache holds12 labels; --save-dir retains unlimited labels. V4 verifies world/list/mod fingerprints and checksum. V3 loads in remake mode; V1/V2 require --allow-legacy-checkpoints. Label uses ASCII letters/digits/underscore/hyphen.", schema({ { "action", str }, { "label", str } }));
    add("audit", "Read-only current-data audit for control characters in item names, blocked/invalid entry candidates and invalid event script references. Candidates need investigation.", schema({ }));
    add("inspect_script", "Read native event bytecode without executing it. Paginated instructions with word offset/opcode/args. include_text=1 expands dialogue for guide comparisons. Negative terminators may have other branch blocks after them.", schema({ { "id", num }, { "offset", num }, { "limit", num }, { "include_text", num } }));
    add("debug", "Explicit opt-in debug shortcut; requires --debug. Teleport, mutate a role Data[field], or invoke a script. Result marks evidence as debug.", schema({ { "scene", num }, { "x", num }, { "y", num }, { "role", num }, { "field", num }, { "value", num }, { "script", num } }));
    const std::map<std::string, std::vector<std::string>> required = { { "choose", { "index" } }, { "battle_action", { "action" } }, { "party_action", { "action" } }, { "navigate", { "x", "y" } }, { "step", { "direction" } }, { "face", { "direction" } }, { "travel", { "scene" } }, { "use_item", { "item" } }, { "dismiss", { "role" } }, { "checkpoint", { "action", "label" } }, { "inspect_script", { "id" } } };
    for (auto& tool : out)
    {
        if (required.contains(string(tool, "name")))
        {
            tool["inputSchema"]["required"] = numbers(required.at(string(tool, "name")));
        }
    }
    return out;
}

int main(int argc, char** argv)
{
    try
    {
        bool debug = false, allowLegacy = false;
        fs::path mod = fs::current_path(), saves;
        for (int i = 1; i < argc; ++i)
        {
            std::string a = argv[i];
            if (a == "--debug")
            {
                debug = true;
            }
            else if (a == "--allow-legacy-checkpoints")
            {
                allowLegacy = true;
            }
            else if (a == "--mod" && i + 1 < argc)
            {
                mod = fs::absolute(argv[++i]);
            }
            else if (a == "--save-dir" && i + 1 < argc)
            {
                saves = fs::absolute(argv[++i]);
            }
            else
            {
                throw std::runtime_error("Usage: kys_mcp [--mod DIRECTORY] [--save-dir DIRECTORY] [--debug] [--allow-legacy-checkpoints]");
            }
        }
        AppPath = mod.generic_string() + "/";
        AppPathCommon = AppPath;
        Session session(debug, saves, allowLegacy);
        std::string line;
        while (std::getline(std::cin, line))
        {
            J request;
            auto parse = glz::read_json(request, line);
            J id;
            if (parse)
            {
                std::cout << dump(obj({ { "jsonrpc", "2.0" }, { "id", J{ } }, { "error", obj({ { "code", -32700 }, { "message", "Parse error" } }) } })) << std::endl;
                continue;
            }
            if (!request.is_object())
            {
                std::cout << dump(obj({ { "jsonrpc", "2.0" }, { "id", J{ } }, { "error", obj({ { "code", -32600 }, { "message", "Invalid request" } }) } })) << std::endl;
                continue;
            }
            if (request.contains("id"))
            {
                id = request["id"];
            }
            else
            {
                continue;
            }
            try
            {
                auto method = string(request, "method");
                J result;
                if (method == "initialize")
                {
                    result = obj({ { "protocolVersion", "2024-11-05" }, { "capabilities", obj({ { "tools", obj({ }) } }) }, { "serverInfo", obj({ { "name", "kys-pascal-c" }, { "version", "0.3.0" } }) }, { "instructions", "Use new_game first; complete world/list gameplay files are required. Coordinates use native x/y; data_xy swaps to guide/editor. Decisions suspend native stacks; choose explicitly. Save before one-shot choices. travel uses native world approach and entrance; check reached for interruptions. step/face and interact without slot expose direct controls. inspect_battle exposes terrain/reachable tiles and skills for manual tactics. party_action exposes native out-of-battle medicine/detox. V1/V2 checkpoints require explicit legacy import; lineage remains visible. No graphics are initialized." } });
                }
                else if (method == "ping")
                {
                    result = obj({ });
                }
                else if (method == "tools/list")
                {
                    result = obj({ { "tools", tools() } });
                }
                else if (method == "tools/call")
                {
                    require(request.contains("params") && request["params"].is_object(), "Missing params");
                    auto& p = request["params"];
                    auto n = string(p, "name");
                    J args = p.contains("arguments") ? p["arguments"] : obj({ });
                    require(args.is_object(), "arguments must be object");
                    J value;
                    bool failed = false;
                    try
                    {
                        bool known = false;
                        auto catalog = tools();
                        for (auto& tool : catalog.get_array())
                        {
                            if (string(tool, "name") == n)
                            {
                                known = true;
                                auto& s = tool["inputSchema"];
                                if (s.contains("required"))
                                {
                                    for (auto& key : s["required"].get_array())
                                    {
                                        require(args.contains(key.as<std::string>()), "Missing required argument: " + key.as<std::string>());
                                    }
                                }
                                for (auto& [key, v] : args.get_object())
                                {
                                    require(s["properties"].contains(key), "Unknown argument: " + key);
                                }
                                break;
                            }
                        }
                        require(known, "Unknown tool: " + n);
                        value = session.call(n, args);
                        failed = value.is_object() && value.contains("error");
                    } catch (const std::exception& e)
                    {
                        value = obj({ { "error", e.what() } });
                        failed = true;
                    }
                    result = obj({ { "content", arr({ obj({ { "type", "text" }, { "text", dump(value) } }) }) }, { "isError", failed } });
                }
                else
                {
                    throw std::runtime_error("Unknown method");
                }
                std::cout << dump(obj({ { "jsonrpc", "2.0" }, { "id", id }, { "result", result } })) << std::endl;
            } catch (const std::exception& e) { std::cout << dump(obj({ { "jsonrpc", "2.0" }, { "id", id }, { "error", obj({ { "code", -32602 }, { "message", e.what() } }) } })) << std::endl; }
        }
    } catch (const std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        return 1;
    }
}
