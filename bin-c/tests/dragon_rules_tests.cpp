#include "kys_rules.h"
#include "rules/dragon_dos12.h"
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
    for (int aptitude : { 0, 29, 30, 49, 50, 69, 70, 89, 90, 100 })
    {
        auto batch = role(), separate = batch;
        batch.Aptitude = separate.Aptitude = aptitude;
        unsigned batchSeed = 12345, separateSeed = batchSeed;
        auto batchRandom = sequence(batchSeed), separateRandom = sequence(separateSeed);
        batch.Exp = 750;
        check(dos::LevelUp(batch, batchRandom) == 5, "Batch must gain five levels");
        for (int xp : { 50, 150, 300, 500, 750 })
        {
            separate.Exp = xp;
            check(dos::LevelUp(separate, separateRandom) == 1, "Separate settlement must gain one level");
        }
        check(std::memcmp(&batch, &separate, sizeof(batch)) == 0,
            "Batch and separate growth must match for the same random sequence");
        check(batchSeed == separateSeed, "Batch must draw once for every level's growth");
    }
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
        for (auto [name, test] : { std::pair{ "per-level growth", levelGrowth },
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
