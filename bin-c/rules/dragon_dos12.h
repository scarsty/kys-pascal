#pragma once

#include "kys_rules.h"

// Oracle tests exercise pure effects directly. Production uses the common
// interfaces; all profile-specific integration lives in this module.
namespace rules::dragon_dos12
{
struct HitContext
{
    int attackEquipment = 0, defenceEquipment = 0, weaponMatch = 0;
    int attackKnowledge = 0, defenceKnowledge = 0, distance = 1;
};
int EffectiveLevel(const TRole&, const TMagic&, int trainedLevel);
void PayMagicCost(TRole&, const TMagic&, int cachedLevel);
int LevelUp(TRole&, const RulesRandom& = RulesRandomDraw);
int HpDamage(const TRole&, const TRole&, const TMagic&, int effectiveLevel,
    const HitContext&, const RulesRandom& = RulesRandomDraw);
int ApplyHpHit(TRole&, TRole&, const TMagic&, int trainedLevel, const HitContext&,
    int16_t& experience, const RulesRandom& = RulesRandomDraw);
int ApplyMpHit(TRole&, TRole&, const TMagic&, int trainedLevel, const RulesRandom& = RulesRandomDraw);
int UsePoison(const TRole&, TRole&);
int Detox(const TRole&, TRole&, const RulesRandom& = RulesRandomDraw);
int Heal(TRole&, TRole&, const RulesRandom& = RulesRandomDraw);
int HiddenWeapon(const TRole&, TRole&, const TItem&, const RulesRandom& = RulesRandomDraw);
void Rest(TRole&, int remainingSteps, const RulesRandom& = RulesRandomDraw);
void RoundStatus(TRole&, bool dead);
}    //namespace rules::dragon_dos12
