#include "mod.h"
#include "kys_frontend.h"
#include "rules/dragon_dos12.h"
#include "rules/growth_state.h"
#include "rules/rules_internal.h"
#include <random>

namespace mods
{
namespace
{
class DragonMod final : public Definition
{
public:
    int version() const override { return 12; }
    const char* name() const override { return "苍龙逐日"; }
    const char* ruleProfile() const override { return "dragon_dos12"; }
    const rules::ProgressionRules& progression() const override { return rules::DragonDos12Progression(); }
    const CombatRules& combat() const override { return rules::DragonDos12Combat(); }
    bool configurableGrowth() const override { return true; }
    const char* titleMenuImage() const override { return "resource/title-menu.webp"; }
    bool renameHomeScene() const override { return false; }
    bool clearPreviousEventTile(int targetScene, int currentScene) const override { return targetScene == currentScene; }

    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - We Are Dragons";
        TitlePosition.x = 200;
        TitlePosition.y = 250;
    }

    std::string defaultPlayerName(const std::string& dataName) const override
    {
        return dataName == "資" ? "小虾米" : dataName;
    }

    StartingStatsResult createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const override
    {
        rules::dragon_dos12::RollStartingStats(role, random);
        return { };
    }

    bool applySpecialStartingStats(TRole& role, const std::string& name) const override
    {
        if (name != "小小豬" && name != "見賢思齊")
            return false;
        const bool alternate = name == "見賢思齊";
        role.CurrentHP = role.MaxHP = 50;
        role.CurrentMP = role.MaxMP = 50;
        role.MPType = 2;
        role.IncLife = 10;
        role.Attack = role.Defence = alternate ? 60 : 30;
        role.Speed = 30;
        role.Medicine = role.UsePoi = role.MedPoi = 30;
        role.Fist = role.Sword = role.Knife = role.Unusual = role.HidWeapon = 30;
        role.Aptitude = alternate ? 45 : 100;
        return true;
    }

    void finishCharacterCreation(const std::string&) const override
    {
        // Growth has its own seed and does not consume battle randomness.
        uint32_t seed = Headless() ? HeadlessRandomState : std::random_device{}();
        rules::growth::StartCampaign(Rrole, seed);
    }
};
}    //namespace

const Definition& Dragon()
{
    static DragonMod mod;
    return mod;
}
}    //namespace mods
