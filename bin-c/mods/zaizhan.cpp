#include "definitions.h"

namespace mods
{
namespace
{
class ZaizhanMod final : public Definition
{
public:
    int version() const override { return 31; }
    const char* name() const override { return "再战江湖"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Wider Rivers and Deeper Lakes";
    }
    bool clearPreviousEventTile(int targetScene, int currentScene) const override { return targetScene == currentScene; }
    StartingStatsResult createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const override
    {
        Definition::createStartingStats(role, "", random);
        role.Ethics = random(50) + random(50);
        return { };
    }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "南宮夢")
        {
            role.MaxHP = 50;
            role.CurrentHP = 50;
            role.MaxMP = 50;
            role.CurrentMP = 50;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 300;
            role.Speed = 30;
            role.Defence = 300;
            role.Medicine = 300;
            role.UsePoi = 30;
            role.MedPoi = 30;
            role.Fist = 30;
            role.Sword = 300;
            role.Knife = 30;
            role.Unusual = 30;
            role.HidWeapon = 300;
            role.Aptitude = 100;
            role.Ethics = 95;
            return true;
        }
        return false;
    }
};
}    //namespace

const Definition& Zaizhan()
{
    static ZaizhanMod mod;
    return mod;
}
}    //namespace mods
