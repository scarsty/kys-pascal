#include "definitions.h"

namespace mods
{
namespace
{
class TianshuQixiaMod final : public Definition
{
public:
    int version() const override { return 21; }
    const char* name() const override { return "天书奇侠"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Books";
        TitlePosition.x = 275;
        TitlePosition.y = 285;
    }
    StartingStatsResult createStartingStats(TRole& role, const std::string&, const RulesRandom& random) const override
    {
        role.Aptitude = 1 + random(100);
        return { };
    }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "古天奇" || input_name == "青狼火花")
        {
            role.MPType = 2;
            role.IncLife = 20;
            role.Aptitude = 100;
            return true;
        }
        return false;
    }
};
}    //namespace

const Definition& TianshuQixia()
{
    static TianshuQixiaMod mod;
    return mod;
}
}    //namespace mods
