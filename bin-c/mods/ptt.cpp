#include "definitions.h"

namespace mods
{
namespace
{
class PttMod final : public Definition
{
public:
    int version() const override { return 41; }
    const char* name() const override { return "PTT"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Here is PTT";
        TitlePosition.y = 255;
        CENTER_Y = 240;
    }
    bool attackRequirementMet(int attack, int minimum, int) const override { return attack >= minimum; }
    StartingStatsResult createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const override
    {
        Definition::createStartingStats(role, "", random);
        role.Magic[0] = 0;
        return { };
    }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "leo")
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
            return true;
        }
        return false;
    }
};
}    //namespace

const Definition& Ptt()
{
    static PttMod mod;
    return mod;
}
}    //namespace mods
