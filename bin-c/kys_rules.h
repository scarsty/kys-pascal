#pragma once

#include "kys_type.h"
#include <functional>
#include <string>
#include <vector>

// Both frontends call the same rules. The opt-in DOS profile is independent
// of rendering, saved records and the legacy Pascal formulas.
enum class RulesMode { Legacy, DragonDos12 };
struct GameRules
{
    std::string profile = "legacy";
    RulesMode progression = RulesMode::Legacy;
    RulesMode combat = RulesMode::Legacy;
    std::vector<uint16_t> xpThresholds; // cumulative, level 1 -> 2 first
    int hpGrowthFactor = 3, mpGrowthFactor = 4;
    int attackGrowthFactor = 1, speedGrowthFactor = 1, defenceGrowthFactor = 1;
};
inline GameRules ActiveRules;
// Original HP routine writes this global; MP drain leaves it unchanged.
// Subsequent MP cost uses the most recent HP attack's effective tier.
inline int DosLastEffectiveLevel = 0;
void LoadGameRules(const std::string& iniPath);
const char* RulesModeName(RulesMode mode);
int NextLevelExperience(const TRole& role); // -1 at cap

// Bounded draws allow the recovered routines to be compared directly with
// native machine-code vectors. Production uses the shared game RNG.
using RulesRandom = std::function<int(int)>;
int RulesRandomDraw(int bound);
int DosEffectiveLevel(const TRole& role, const TMagic& magic, int trainedLevel);
void DosPayMagicCost(TRole& role, const TMagic& magic, int cachedLevel);
int DosLevelUp(TRole& role, const RulesRandom& random = RulesRandomDraw);
struct DosHitContext
{
    int attackEquipment = 0, defenceEquipment = 0, weaponMatch = 0;
    int attackKnowledge = 0, defenceKnowledge = 0, distance = 1;
};
int DosHpDamage(const TRole& attacker, const TRole& defender, const TMagic& magic,
                int effectiveLevel, const DosHitContext& context,
                const RulesRandom& random = RulesRandomDraw);
int DosApplyHpHit(TRole& attacker, TRole& defender, const TMagic& magic,
                  int trainedLevel, const DosHitContext& context, int16_t& experience,
                  const RulesRandom& random = RulesRandomDraw);
int DosApplyMpHit(TRole& attacker, TRole& defender, const TMagic& magic, int trainedLevel,
                  const RulesRandom& random = RulesRandomDraw);
int DosUsePoison(const TRole& actor, TRole& target);
int DosDetox(const TRole& actor, TRole& target, const RulesRandom& random = RulesRandomDraw);
int DosHeal(TRole& actor, TRole& target, const RulesRandom& random = RulesRandomDraw);
int DosHiddenWeapon(const TRole& actor, TRole& target, const TItem& item,
                     const RulesRandom& random = RulesRandomDraw);
void DosRest(TRole& role, int remainingSteps, const RulesRandom& random = RulesRandomDraw);
void DosRoundStatus(TRole& role, bool dead);
