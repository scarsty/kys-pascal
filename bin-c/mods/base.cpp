#include "definitions.h"
#include "kys_event.h"

namespace mods
{
namespace
{
class BaseMod final : public Definition
{
public:
    int version() const override { return 0; }
    const char* name() const override { return "原版"; }
    const char* confirmationPrompt() const override { return "是否需要住宿？"; }
    StartingStatsResult createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const override
    {
        Definition::createStartingStats(role, "", random);
        role.Magic[0] = 1;
        if (random(100) < 70) role.Magic[0] = random(93);
        return { };
    }
    bool applySpecialStartingStats(TRole& role, const std::string& name) const override { return ApplyBaseStartingStats(role, name); }
    void finishCharacterCreation(const std::string& input_name) const override { ApplyBaseCharacterSetup(input_name); }
};
}    //namespace

bool ApplyBaseStartingStats(TRole& role, const std::string& input_name)
{
    if (input_name == "TXDX尊使")
    {
        role.MaxHP = 50;
        role.CurrentHP = 50;
        role.MaxMP = 50;
        role.CurrentMP = 50;
        role.MPType = 2;
        role.IncLife = 10;
        role.Attack = 30;
        role.Speed = 30;
        role.Defence = 30;
        role.Medicine = 30;
        role.UsePoi = 30;
        role.MedPoi = 30;
        role.Fist = 30;
        role.Sword = 30;
        role.Knife = 30;
        role.Unusual = 30;
        role.HidWeapon = 30;
        role.Aptitude = 100;
        role.Magic[0] = 62;
        role.MagLevel[0] = 800;
        return true;
    }
    return false;
}

void ApplyBaseCharacterSetup(const std::string& input_name)
{
    if (input_name == "TXDX尊使")
    {
        Rmagic[62].Attack[9] = 2000;
        Ritem[93].Magic = 26;
        Ritem[66].OnlyPracRole = -1;
        Ritem[79].OnlyPracRole = -1;
        instruct_32(82, 1);
        instruct_32(74, 1);
    }
    Rrole[13].Magic[1] = 91;
}

const Definition& Base()
{
    static BaseMod mod;
    return mod;
}
}    //namespace mods
