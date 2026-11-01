#include "definitions.h"
#include "kys_event.h"

namespace mods
{
namespace
{
class XiaozhuMod final : public Definition
{
public:
    int version() const override { return 11; }
    const char* name() const override { return "小猪闯江湖"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - A Pig";
        TitlePosition.y = 270;
        CENTER_Y = 240;
    }
    bool renameHomeScene() const override { return false; }
    bool instruction50UsesItemCheck(int) const override { return true; }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "小小豬")
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
            role.Ethics = 90;
            return true;
        }
        if (input_name == "晴空飛雪")
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
    void finishCharacterCreation(const std::string& input_name) const override
    {
        if (input_name == "晴空飛雪")
        {
            instruct_32(19, 10000);
        }
    }
};
}    //namespace

const Definition& Xiaozhu()
{
    static XiaozhuMod mod;
    return mod;
}
}    //namespace mods
