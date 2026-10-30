#pragma once

#include "kys_type.h"
#include <functional>
#include <optional>
#include <string>
#include <vector>

// Configuration binds these interfaces once. Each implementation owns its
// mechanics, costs and experience; frontends never select a profile themselves.
enum class BattleSkill
{
    Poison,
    Medicine,
    Detox
};

struct MagicRuleInfo
{
    int effectiveLevel, mpCost;
    int staminaPerAction = 0, staminaPerStrike = 3;
    bool reportsEffectiveLevel = false, usesCachedTier = false;
};

struct CombatDefaults
{
    std::optional<int> stamina;
    int minKnowledge, lifeHurt, poisonHurt;
};

class CombatRules
{
public:
    virtual ~CombatRules() = default;
    virtual const char* name() const = 0;
    virtual CombatDefaults defaults() const = 0;
    virtual int strikeCount(const TRole&) const = 0;
    virtual int beginStrike(TRole&, int slot, int selectedLevel) const = 0;
    virtual void finishStrike(TRole&, int slot) const = 0;
    virtual void finishAttack(TRole&) const = 0;
    virtual void resolveMagic(int actor, int magic, int trainedLevel) const = 0;
    virtual int hpDamage(int attacker, int defender, int magic, int trainedLevel) const = 0;
    virtual void roundEnd(int actor) const = 0;
    virtual void paySkillCost(TRole&, BattleSkill) const = 0;
    virtual void awardSkillExperience(int actor, int target, int amount) const = 0;
    virtual int poison(TRole& actor, TRole& target) const = 0;
    virtual int heal(TRole& actor, TRole& target) const = 0;
    virtual int detox(TRole& actor, TRole& target) const = 0;
    virtual int hiddenWeapon(int actor, int target, const TItem&) const = 0;
    virtual void rest(int actor) const = 0;
    virtual MagicRuleInfo inspectMagic(const TRole*, const TMagic&, int trainedLevel) const = 0;
    virtual int minimumCheckpointVersion() const = 0;
};

const CombatRules& BattleRules();

struct LevelGrowth
{
    int hp = 3, mp = 4, attack = 1, speed = 1, defence = 1;
};

struct GameRuleDescription
{
    std::string profile, progression, combat;
    bool cumulativeExperience = false, batchGrowth = false;
    std::vector<uint16_t> xpThresholds;
    std::optional<LevelGrowth> growth;
    std::optional<std::string> levelStatCaps;
};

// Reserved historical state. The MP-cost cache no longer affects gameplay;
// keep the binary layout and value range compatible with V4 checkpoints.
struct RuleRuntimeState
{
    int32_t magicCostTier = 0;
};

RuleRuntimeState CaptureRuleState();
void RestoreRuleState(RuleRuntimeState state);
GameRuleDescription DescribeGameRules();
void LoadGameRules(const std::string& iniPath);
int NextLevelExperience(const TRole& role);    // -1 at cap
int AdvanceRoleLevels(TRole& role);            // one settlement; zero when no level is due

using RulesRandom = std::function<int(int)>;
int RulesRandomDraw(int bound);
