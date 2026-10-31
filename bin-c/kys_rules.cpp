#include "kys_rules.h"
#include "INIReader.h"
#include "kys_frontend.h"
#include "rules/rules_internal.h"
#include <charconv>
#include <sstream>
#include <stdexcept>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

namespace rules
{
Configuration config;
RuleRuntimeState runtime;

namespace
{
const ProgressionRules* progression = &RemakeProgression();
const CombatRules* combat = &RemakeCombat();
}    //namespace

void SelectProfiles()
{
    progression = config.progression == Profile::Remake ? &RemakeProgression() : &DragonDos12Progression();
    combat = config.combat == Profile::Remake ? &RemakeCombat() : &DragonDos12Combat();
}
}    //namespace rules

namespace
{
rules::Profile mode(const std::string& name)
{
    if (name == "remake" || name == "legacy")
    {
        return rules::Profile::Remake;
    }
    if (name == "dragon_dos12")
    {
        return rules::Profile::DragonDos12;
    }
    throw std::runtime_error("Unknown rules mode: " + name + " (use remake or dragon_dos12)");
}

int integer(INIReaderNormal& ini, const std::string& key, int fallback, int low, int high)
{
    auto text = ini.getString("rules", key, std::to_string(fallback));
    int value = 0;
    auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), value);
    if (error != std::errc{ } || end != text.data() + text.size() || value < low || value > high)
    {
        throw std::runtime_error("Invalid [rules] " + key + " (expected " + std::to_string(low) + ".." + std::to_string(high) + ")");
    }
    return value;
}
}    //namespace

void LoadGameRules(const std::string& iniPath)
{
    INIReaderNormal ini;
    ini.loadFile(iniPath);
    rules::config = { };
    rules::runtime = { };
    rules::config.profile = ini.getString("rules", "profile", "remake");
    mode(rules::config.profile);    // fail on typos, including an unused profile
    if (rules::config.profile == "legacy")
    {
        rules::config.profile = "remake";
    }
    rules::config.progression = mode(ini.getString("rules", "progression", rules::config.profile));
    rules::config.combat = mode(ini.getString("rules", "combat", rules::config.profile));
    // These options and browser preferences belong only to Dragon progression.
    // A combat-only Dragon profile must keep the remake growth behavior.
    if (HasConfigurableGrowth())
    {
        auto growth = ini.getString("rules", "growth_mode", "original");
        if (growth == "original") rules::config.growthMode = GrowthMode::Original;
        else if (growth == "fixed_random") rules::config.growthMode = GrowthMode::FixedRandom;
        else if (growth == "average") rules::config.growthMode = GrowthMode::Average;
        else if (growth == "maximum") rules::config.growthMode = GrowthMode::Maximum;
        else throw std::runtime_error("Invalid [rules] growth_mode (use original, fixed_random, average or maximum)");
        auto priority = ini.getString("rules", "growth_max_priority", "stats");
        if (priority == "stats") rules::config.growthMaxPriority = GrowthMaxPriority::Stats;
        else if (priority == "mp") rules::config.growthMaxPriority = GrowthMaxPriority::Mp;
        else throw std::runtime_error("Invalid [rules] growth_max_priority (use stats or mp)");
#ifdef __EMSCRIPTEN__
        rules::config.growthMode = static_cast<GrowthMode>(EM_ASM_INT({ return Module.readGrowthMode($0); }, static_cast<int>(rules::config.growthMode)));
        rules::config.growthMaxPriority = static_cast<GrowthMaxPriority>(EM_ASM_INT({ return Module.readGrowthPriority($0); }, static_cast<int>(rules::config.growthMaxPriority)));
#endif
    }
    rules::SelectProfiles();
    auto progression = rules::progression->defaults();
    auto combat = BattleRules().defaults();
    MAX_LEVEL = integer(ini, "max_level", progression.maxLevel, 1, 100);
    MAX_HP = integer(ini, "max_hp", progression.maxHp, 1, 32767);
    MAX_MP = integer(ini, "max_mp", progression.maxMp, 1, 32767);
    MAX_PHYSICAL_POWER = integer(ini, "max_stamina", progression.stamina.value_or(combat.stamina.value_or(MAX_PHYSICAL_POWER)), 1, 32767);
    MIN_KNOWLEDGE = integer(ini, "min_knowledge", combat.minKnowledge, 0, 32767);
    LIFE_HURT = integer(ini, "life_hurt", combat.lifeHurt, 1, 32767);
    POISON_HURT = integer(ini, "poison_hurt", combat.poisonHurt, 0, 32767);
    rules::config.growth.hp = integer(ini, "hp_growth_factor", 3, 0, 100);
    rules::config.growth.mp = integer(ini, "mp_growth_factor", 4, 0, 100);
    rules::config.growth.attack = integer(ini, "attack_growth_factor", 1, 0, 100);
    rules::config.growth.speed = integer(ini, "speed_growth_factor", 1, 0, 100);
    rules::config.growth.defence = integer(ini, "defence_growth_factor", 1, 0, 100);
    if (!progression.xpThresholds.empty())
    {
        rules::config.xpThresholds = std::move(progression.xpThresholds);
        auto custom = ini.getString("rules", "xp_thresholds", "");
        if (!custom.empty())
        {
            rules::config.xpThresholds.clear();
            std::istringstream stream(custom);
            std::string token;
            if (custom.back() == ',')
            {
                throw std::runtime_error("Trailing comma in xp_thresholds");
            }
            while (std::getline(stream, token, ','))
            {
                auto first = token.find_first_not_of(" \t");
                auto last = token.find_last_not_of(" \t");
                if (first == std::string::npos)
                {
                    throw std::runtime_error("Empty XP threshold");
                }
                token = token.substr(first, last - first + 1);
                int value = 0;
                auto [end, error] = std::from_chars(token.data(), token.data() + token.size(), value);
                if (error != std::errc{ } || end != token.data() + token.size() || value <= 0 || value > 65535 || (!rules::config.xpThresholds.empty() && value <= rules::config.xpThresholds.back()))
                {
                    throw std::runtime_error("xp_thresholds must contain strictly increasing integers in 1..65535");
                }
                rules::config.xpThresholds.push_back(static_cast<uint16_t>(value));
            }
        }
        if (rules::config.xpThresholds.size() < static_cast<size_t>(MAX_LEVEL - 1))
        {
            throw std::runtime_error("MAX_LEVEL exceeds the profile XP table; supply [rules] xp_thresholds for every next level");
        }
    }
    if (MAX_LEVEL < 1 || MAX_LEVEL > 100)
    {
        throw std::runtime_error("MAX_LEVEL must be 1..100");
    }
}

const CombatRules& BattleRules() { return *rules::combat; }

int NextLevelExperience(const TRole& role)
{
    return role.Level < 1 || role.Level >= MAX_LEVEL ? -1 : rules::progression->nextExperience(role);
}

int AdvanceRoleLevels(TRole& role) { return rules::progression->advance(role); }

bool HasConfigurableGrowth() { return rules::config.progression == rules::Profile::DragonDos12; }
GrowthMode GetGrowthMode() { return rules::config.growthMode; }
GrowthMaxPriority GetGrowthMaxPriority() { return rules::config.growthMaxPriority; }
void SetGrowthMode(GrowthMode mode) { GrowthModeName(mode); rules::config.growthMode = mode; }
void SetGrowthMaxPriority(GrowthMaxPriority priority) { GrowthMaxPriorityName(priority); rules::config.growthMaxPriority = priority; }

const char* GrowthModeName(GrowthMode mode)
{
    switch (mode)
    {
    case GrowthMode::Original: return "original";
    case GrowthMode::FixedRandom: return "fixed_random";
    case GrowthMode::Average: return "average";
    case GrowthMode::Maximum: return "maximum";
    }
    throw std::runtime_error("Invalid growth mode");
}

const char* GrowthMaxPriorityName(GrowthMaxPriority priority)
{
    switch (priority)
    {
    case GrowthMaxPriority::Stats: return "stats";
    case GrowthMaxPriority::Mp: return "mp";
    }
    throw std::runtime_error("Invalid growth maximum priority");
}

GameRuleDescription DescribeGameRules()
{
    GameRuleDescription out;
    out.profile = rules::config.profile;
    out.progression = rules::progression->name();
    out.combat = rules::combat->name();
    rules::progression->describe(out);
    return out;
}

RuleRuntimeState CaptureRuleState() { return rules::runtime; }

void RestoreRuleState(RuleRuntimeState state)
{
    if (state.magicCostTier < 0 || state.magicCostTier > 10)
    {
        throw std::runtime_error("Invalid rule runtime state");
    }
    rules::runtime = state;
}

int RulesRandomDraw(int bound) { return bound <= 1 || bound > 30000 ? 0 : GameRandom() % bound; }
