#include "definitions.h"

namespace mods
{
namespace
{
class BoluoSanguoMod final : public Definition
{
public:
    int version() const override { return 22; }
    const char* name() const override { return "菠萝三国"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "Why I have to go after a pineapple in the period of Three Kingdoms??";
        MAX_ITEM_AMOUNT = 456;
        StartMusic = 37;
        CENTER_Y = 240;
    }
    bool renameHomeScene() const override { return false; }
    const char* partyMenuLabel() const override { return "特殊"; }
    const char* partySelectionPrompt() const override { return "選擇一個隊友"; }
    bool worldStepPassable(bool passable, int16_t& inShip) const override
    {
        if (inShip == 1) { inShip = 0; return false; }
        return passable;
    }
    bool worldPathTilePassable(int terrain, bool inShip) const override
    {
        return inShip ? terrain == 5 : terrain == 0 || terrain == 4;
    }
    bool eventUsesWorldPictures(int location, int event) const override { return location != 1 || event == -1; }
    bool eventRequestsNumber(int event) const override { return event == 176; }
    void customizeStatusLabels(std::span<std::string, 22> labels) const override
    {
        labels[2] = "靈力";
        labels[6] = "武力";
        labels[8] = "移動";
        labels[9] = "仙術能力";
        labels[10] = "毒術能力";
        labels[12] = "火系能力";
        labels[13] = "水系能力";
        labels[14] = "雷系能力";
        labels[15] = "土系能力";
        labels[16] = "射擊能力";
        labels[19] = "所會法術";
    }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "k小邪")
        {
            role.MaxHP = 50;
            role.CurrentHP = 50;
            role.MaxMP = 50;
            role.CurrentMP = 50;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 150;
            role.Speed = 150;
            role.Defence = 130;
            role.Medicine = 130;
            role.UsePoi = 130;
            role.MedPoi = 130;
            role.Fist = 130;
            role.Sword = 130;
            role.Knife = 130;
            role.Unusual = 130;
            role.HidWeapon = 130;
            role.Aptitude = 100;
            role.Knowledge = 85;
            role.Magic[0] = 94;
            role.MagLevel[0] = 850;
            role.Magic[1] = 93;
            role.AttPoi = 0;
            return true;
        }
        if (input_name == "龍吟星落")
        {
            role.MaxHP = 150;
            role.CurrentHP = 120;
            role.MaxMP = 150;
            role.CurrentMP = 220;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 130;
            role.Speed = 130;
            role.Defence = 130;
            role.Medicine = 130;
            role.UsePoi = 130;
            role.MedPoi = 130;
            role.Fist = 130;
            role.Sword = 130;
            role.Knife = 130;
            role.Unusual = 130;
            role.HidWeapon = 130;
            role.Aptitude = 100;
            role.Knowledge = 0;
            role.Magic[0] = 168;
            role.Magic[1] = 169;
            role.Magic[2] = 170;
            role.Magic[3] = 171;
            role.Magic[4] = 172;
            return true;
        }
        if (input_name == "小隨")
        {
            role.MaxHP = 150;
            role.CurrentHP = 120;
            role.MaxMP = 150;
            role.CurrentMP = 220;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 130;
            role.Speed = 130;
            role.Defence = 130;
            role.Medicine = 130;
            role.UsePoi = 130;
            role.MedPoi = 130;
            role.Fist = 130;
            role.Sword = 130;
            role.Knife = 130;
            role.Unusual = 130;
            role.HidWeapon = 130;
            role.Aptitude = 100;
            role.Knowledge = 0;
            role.Magic[0] = 94;
            role.MagLevel[0] = 850;
            role.AttTwice = 1;
            return true;
        }
        if (input_name == "破大俠")
        {
            role.MaxHP = 1150;
            role.CurrentHP = 1120;
            role.MaxMP = 1150;
            role.CurrentMP = 1220;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 230;
            role.Speed = 230;
            role.Defence = 230;
            role.Medicine = 230;
            role.UsePoi = 230;
            role.MedPoi = 230;
            role.Fist = 230;
            role.Sword = 230;
            role.Knife = 230;
            role.Unusual = 230;
            role.HidWeapon = 230;
            role.Aptitude = 100;
            role.Knowledge = 100;
            role.Magic[0] = 168;
            role.Magic[1] = 169;
            role.Magic[2] = 170;
            role.Magic[3] = 171;
            role.Magic[4] = 172;
            role.Magic[5] = 94;
            return true;
        }
        if (input_name == "鳳凰")
        {
            role.MaxHP = 250;
            role.CurrentHP = 50;
            role.MaxMP = 250;
            role.CurrentMP = 50;
            role.MPType = 2;
            role.IncLife = 10;
            role.Aptitude = 100;
            return true;
        }
        return false;
    }
    void finishCharacterCreation(const std::string& input_name) const override
    {
        if (input_name == "鳳凰")
        {
            for (int i = 1; i <= 14; i++)
            {
                Rrole[i].MaxHP = 500;
                Rrole[i].CurrentHP = 500;
                Rrole[i].MaxMP = 500;
                Rrole[i].CurrentMP = 500;
                Rrole[i].MPType = 2;
                Rrole[i].IncLife = 30;
                Rrole[i].Attack = 300;
                Rrole[i].Speed = 100;
                Rrole[i].Defence = 130;
                Rrole[i].Medicine = 130;
                Rrole[i].UsePoi = 130;
                Rrole[i].MedPoi = 130;
                Rrole[i].Fist = 130;
                Rrole[i].Sword = 130;
                Rrole[i].Knife = 130;
                Rrole[i].Unusual = 130;
                Rrole[i].HidWeapon = 130;
                Rrole[i].Aptitude = 100;
            }
        }
    }
};
}    //namespace

const Definition& BoluoSanguo()
{
    static BoluoSanguoMod mod;
    return mod;
}
}    //namespace mods
