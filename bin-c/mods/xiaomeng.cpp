#include "definitions.h"

namespace mods
{
namespace
{
class XiaomengMod final : public Definition
{
public:
    int version() const override { return 23; }
    const char* name() const override { return "笑梦游记"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Four Dreams";
        TitlePosition.y = 165;
        StartMusic = 24;
        CENTER_Y = 240;
    }
    bool sceneTilePassable(int picture, bool passable) const override { return passable || picture == 1358 * 2 || picture == 1269 * 2; }
    bool applySpecialStartingStats(TRole& role, const std::string& input_name) const override
    {
        if (input_name == "小小豬")
        {
            role.MaxHP = 10;
            role.CurrentHP = 10;
            role.MaxMP = 50;
            role.CurrentMP = 50;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 10;
            role.Speed = 10;
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
            role.Knowledge = 0;
            role.Magic[0] = 27;
            role.MagLevel[0] = 850;
            role.Magic[1] = 37;
            role.MagLevel[1] = 850;
            role.Magic[2] = 94;
            role.MagLevel[2] = 850;
            role.Magic[3] = 62;
            role.MagLevel[3] = 850;
            role.AttPoi = 0;
            return true;
        }
        if (input_name == "k小邪")
        {
            role.MaxHP = 150;
            role.CurrentHP = 120;
            role.MaxMP = 150;
            role.CurrentMP = 220;
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
            role.Knowledge = 0;
            role.Magic[0] = 27;
            role.MagLevel[0] = 850;
            role.AttPoi = 70;
            role.Magic[1] = 15;
            return true;
        }
        if (input_name == "南宮夢")
        {
            role.MaxHP = 500;
            role.CurrentHP = 500;
            role.MaxMP = 500;
            role.CurrentMP = 500;
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 70;
            role.Speed = 90;
            role.Defence = 30;
            role.Medicine = 30;
            role.UsePoi = 30;
            role.MedPoi = 30;
            role.Fist = 30;
            role.Sword = 60;
            role.Knife = 30;
            role.Unusual = 30;
            role.HidWeapon = 30;
            role.Aptitude = 100;
            role.Knowledge = 0;
            role.Magic[0] = 37;
            role.MagLevel[0] = 890;
            return true;
        }
        if (input_name == "遊客" || input_name == "游客")
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
            role.Knowledge = 0;
            role.Magic[0] = 94;
            role.MagLevel[0] = 850;
            role.AttTwice = 1;
            return true;
        }
        if (input_name == "飛蟲王")
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
            role.Knowledge = 60;
            role.Magic[0] = 62;
            role.MagLevel[0] = 850;
            role.AttPoi = 95;
            return true;
        }
        if (input_name == "破劍式")
        {
            role.MaxHP = 499;
            role.CurrentHP = 499;
            role.MaxMP = 499;
            role.CurrentMP = 499;
            role.MPType = 2;
            role.IncLife = 5;
            role.Attack = 90;
            role.Speed = 90;
            role.Defence = 90;
            role.Medicine = 90;
            role.UsePoi = 90;
            role.MedPoi = 90;
            role.Fist = 90;
            role.Sword = 90;
            role.Knife = 90;
            role.Unusual = 90;
            role.HidWeapon = 90;
            role.Aptitude = 100;
            role.Knowledge = 0;
            role.Magic[0] = 27;
            role.MagLevel[0] = 899;
            role.Magic[1] = 37;
            role.MagLevel[1] = 899;
            role.Magic[2] = 94;
            role.MagLevel[2] = 899;
            role.Magic[3] = 62;
            role.MagLevel[3] = 899;
            role.AttPoi = 90;
            return true;
        }
        if (input_name == "9523")
        {
            role.MPType = 2;
            role.IncLife = 10;
            role.Attack = 10;
            role.Speed = 10;
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
            role.Magic[0] = 15;
            role.Magic[1] = 16;
            role.Magic[2] = 17;
            return true;
        }
        if (input_name == "鳳凰ice")
        {
            role.MPType = 2;
            role.IncLife = 10;
            role.Aptitude = 100;
            return true;
        }
        return false;
    }
    void finishCharacterCreation(const std::string& input_name) const override
    {
        if (input_name == "k小邪")
        {
            for (int i = 0; i <= 9; i++)
            {
                Rmagic[15].Attack[i] = 1400;
                Rmagic[16].Attack[i] = 1400;
                Rmagic[17].Attack[i] = 1000;
                Rmagic[15].AttDistance[i] = 6;
                Rmagic[16].AttDistance[i] = 4;
                Rmagic[17].AttDistance[i] = 8;
            }
        }
        if (input_name == "南宮夢")
        {
            Rmagic[37].AttAreaType = 3;
            Rmagic[37].MoveDistance[9] = 4;
            Rmagic[37].AttDistance[9] = 4;
        }

        if (input_name == "9523")
        {
            for (int i = 0; i <= 9; i++)
            {
                Rmagic[15].Attack[i] = 1400;
                Rmagic[16].Attack[i] = 1400;
                Rmagic[17].Attack[i] = 1000;
                Rmagic[15].AttDistance[i] = 6;
                Rmagic[16].AttDistance[i] = 4;
                Rmagic[17].AttDistance[i] = 8;
            }
        }
        if (input_name == "鳳凰ice")
        {
            for (int i = 0; i < 100; i++)
            {
                if (LeaveList[i] > 0)
                {
                    Rrole[LeaveList[i]].IncLife = 30;
                    Rrole[LeaveList[i]].MPType = 2;
                    Rrole[LeaveList[i]].Attack = 90;
                    Rrole[LeaveList[i]].Aptitude = 95;
                }
            }
        }
        Rrole[401] = Rrole[0];
        Rrole[402] = Rrole[0];
        Rrole[403] = Rrole[0];
        Rrole[404] = Rrole[0];
    }
};
}    //namespace

const Definition& Xiaomeng()
{
    static XiaomengMod mod;
    return mod;
}
}    //namespace mods
