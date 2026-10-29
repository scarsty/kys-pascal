#pragma once

#include "kys_rules.h"

namespace rules
{
enum class Profile { Legacy, DragonDos12 };
struct Configuration
{
    std::string profile = "legacy";
    Profile progression = Profile::Legacy, combat = Profile::Legacy;
    std::vector<uint16_t> xpThresholds;
    LevelGrowth growth;
};
extern Configuration config;
extern RuleRuntimeState runtime;
struct ProgressionDefaults
{
    int maxLevel, maxHp, maxMp;
    std::optional<int> stamina;
    std::vector<uint16_t> xpThresholds;
};
class ProgressionRules
{
public:
    virtual ~ProgressionRules() = default;
    virtual const char* name() const = 0;
    virtual ProgressionDefaults defaults() const = 0;
    virtual int nextExperience(const TRole&) const = 0;
    virtual int advance(TRole&) const = 0;
    virtual void describe(GameRuleDescription&) const = 0;
};
const ProgressionRules& LegacyProgression();
const CombatRules& LegacyCombat();
const ProgressionRules& DragonDos12Progression();
const CombatRules& DragonDos12Combat();
void SelectProfiles();
}
