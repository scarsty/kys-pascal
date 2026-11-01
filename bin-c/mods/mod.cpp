#include "definitions.h"
#include "INIReader.h"
#include "rules/rules_internal.h"
#include <array>
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <stdexcept>

namespace mods
{
namespace
{
const Definition* active = nullptr;
}    //namespace

const rules::ProgressionRules& Definition::progression() const { return rules::RemakeProgression(); }
const CombatRules& Definition::combat() const { return rules::RemakeCombat(); }
const Definition& Active() { return active ? *active : Base(); }

StartingStatsResult Definition::createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const
{
    role.MaxHP = 25 + random(26);
    role.CurrentHP = role.MaxHP;
    role.MaxMP = 25 + random(26);
    role.CurrentMP = role.MaxMP;
    role.MPType = random(2);
    role.IncLife = 1 + random(10);
    role.Attack = 25 + random(6);
    role.Speed = 25 + random(6);
    role.Defence = 25 + random(6);
    role.Medicine = 25 + random(6);
    role.UsePoi = 25 + random(6);
    role.MedPoi = 25 + random(6);
    role.Fist = 25 + random(6);
    role.Sword = 25 + random(6);
    role.Knife = 25 + random(6);
    role.Unusual = 25 + random(6);
    role.HidWeapon = 25 + random(6);
    role.Aptitude = 1 + random(100);
    return { };
}

bool Definition::worldPathTilePassable(int terrain, bool) const
{
    return terrain == 0 || terrain == 4 || terrain == 5 || terrain == 7;
}

bool Definition::attackRequirementMet(int attack, int minimum, int maximum) const
{
    return attack >= minimum && attack <= maximum;
}

void LoadDefinition(const std::string& iniPath)
{
    INIReaderNormal ini;
    ini.loadFile(iniPath);
    const bool explicitVersion = ini.hasKey("system", "MODVersion");
    int version = 0;
    if (explicitVersion)
    {
        auto text = ini.getString("system", "MODVersion");
        char* end = nullptr;
        errno = 0;
        long value = std::strtol(text.c_str(), &end, 0);
        if (end == text.c_str() || *end != '\0' || errno == ERANGE || value < 0 || value > INT_MAX)
            throw std::runtime_error("Invalid [system] MODVersion (expected a nonnegative integer)");
        version = static_cast<int>(value);
    }
    const std::array<const char*, 3> keys{ "profile", "progression", "combat" };
    std::array<std::string, 3> selectors;
    bool requestsDragon = false;
    for (size_t i = 0; i < keys.size(); ++i)
    {
        if (!ini.hasKey("rules", keys[i])) continue;
        auto value = ini.getString("rules", keys[i]);
        if (value == "legacy") value = "remake";
        if (value != "remake" && value != Dragon().ruleProfile())
            throw std::runtime_error(std::string("Unknown [rules] ") + keys[i] + ": " + value);
        requestsDragon |= value == Dragon().ruleProfile();
        selectors[i] = value;
    }
    if (requestsDragon && explicitVersion && version != Dragon().version())
        throw std::runtime_error("dragon_dos12 belongs to Canglong; remove the conflicting MODVersion or set it to 12");
    const bool dragon = version == Dragon().version() || requestsDragon;
    const Definition* selected = &Find(version);
    if (dragon)
    {
        for (size_t i = 0; i < keys.size(); ++i)
            if (!selectors[i].empty() && selectors[i] != Dragon().ruleProfile())
                throw std::runtime_error(std::string("Canglong uses DOS 1.2 rules only; remove [rules] ") + keys[i] + "=" + selectors[i]);
        selected = &Dragon();
    }
    active = selected;
    MODVersion = active->version();
}
}    //namespace mods
