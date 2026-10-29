#include "rules_internal.h"
#include "kys_frontend.h"
#include <algorithm>

namespace rules
{
namespace
{
class RemakeProgression final : public ProgressionRules
{
public:
    const char* name() const override { return "legacy"; }
    ProgressionDefaults defaults() const override { return {MAX_LEVEL,MAX_HP,MAX_MP,std::nullopt,{}}; }
    int nextExperience(const TRole& role) const override { return static_cast<uint16_t>(LevelUpList[role.Level-1]); }
    int advance(TRole& role) const override
    {
        if (role.Level < 1 || role.Level >= MAX_LEVEL || role.Exp < nextExperience(role)) return 0;
        role.Exp -= LevelUpList[role.Level - 1];
        role.Level++;
        // MaxHP: IncLife * 3 + random(6)
        role.MaxHP = role.MaxHP + role.IncLife * 3 + GameRandom() % 6;
        role.MaxHP = std::min((int)role.MaxHP, MAX_HP);
        role.CurrentHP = role.MaxHP;

        int add = role.Aptitude / 15 + 1;
        if (MAX_ADD_PRO == 0)
        {
            add = GameRandom() % add + 1;
        }

        // MaxMP: (9 - add) * 3
        role.MaxMP = role.MaxMP + (9 - add) * 3;
        role.MaxMP = std::min((int)role.MaxMP, MAX_MP);
        role.CurrentMP = role.MaxMP;

        role.Attack += add;
        role.Speed += add;
        role.Defence += add;

        // 抗性成长 Data[46..54]
        for (int j = 46; j <= 54; j++)
        {
            if (role.Data[j] > 0)
            {
                role.Data[j] += GameRandom() % 3 + 1;
            }
        }
        // 属性上限 Data[43..58]
        for (int j = 43; j <= 58; j++)
        {
            role.Data[j] = std::min((int)role.Data[j], MaxProList[j - 43]);
        }

        role.PhyPower = MAX_PHYSICAL_POWER;
        role.Hurt = 0;
        role.Poison = 0;
        return 1;
    }
    void describe(GameRuleDescription&) const override {}
};
class RemakeCombat final : public CombatRules
{
public:
    const char* name() const override { return "legacy"; }
    CombatDefaults defaults() const override { return {std::nullopt,MIN_KNOWLEDGE,LIFE_HURT,POISON_HURT}; }
    int strikeCount(const TRole& role) const override { return role.AttTwice>0?2:1; }
    int beginStrike(TRole& role,int slot,int selected) const override
    {
        role.MagLevel[slot]+=GameRandom()%2+1;
        if(role.MagLevel[slot]>999)role.MagLevel[slot]=999;
        return selected;
    }
    void finishStrike(TRole&,int) const override {}
    void finishAttack(TRole&) const override {}
    void resolveMagic(int bnum,int mnum,int level) const override
    {
        int rnum = Brole[bnum].rnum;
        Rrole[rnum].PhyPower -= 3;
        // 根据内力调整等级
        if (Rrole[rnum].CurrentMP < Rmagic[mnum].NeedMP * ((level + 1) / 2))
        {
            level = Rrole[rnum].CurrentMP / Rmagic[mnum].NeedMP * 2;
        }
        if (level > 10)
        {
            level = 10;
        }
        Rrole[rnum].CurrentMP -= Rmagic[mnum].NeedMP * ((level + 1) / 2);

        for (int i = 0; i < BRoleAmount; i++)
        {
            Brole[i].ShowNumber = -1;
            if (BField[4][Brole[i].X][Brole[i].Y] != 0 && Brole[bnum].Team != Brole[i].Team && Brole[i].Dead == 0)
            {
                // 生命伤害
                if (Rmagic[mnum].HurtType == 0)
                {
                    int hurt = hpDamage(bnum, i, mnum, level);
                    Brole[i].ShowNumber = hurt;
                    Rrole[Brole[i].rnum].CurrentHP -= hurt;
                    Rrole[Brole[i].rnum].Hurt += hurt / LIFE_HURT;
                    if (Rrole[Brole[i].rnum].Hurt > 99)
                    {
                        Rrole[Brole[i].rnum].Hurt = 99;
                    }
                    Brole[bnum].ExpGot += hurt / 2;
                    if (Rrole[Brole[i].rnum].CurrentHP <= 0)
                    {
                        Brole[bnum].ExpGot += hurt / 2;
                    }
                    if (Brole[bnum].ExpGot < 0)
                    {
                        Brole[bnum].ExpGot = 32767;
                    }
                }
                // 内力伤害
                if (Rmagic[mnum].HurtType == 1)
                {
                    int hurt = Rmagic[mnum].HurtMP[level - 1] + GameRandom() % 5 - GameRandom() % 5;
                    Brole[i].ShowNumber = hurt;
                    Rrole[Brole[i].rnum].CurrentMP -= hurt;
                    if (Rrole[Brole[i].rnum].CurrentMP <= 0)
                    {
                        Rrole[Brole[i].rnum].CurrentMP = 0;
                    }
                    // 增加己方内力及最大值
                    Rrole[rnum].CurrentMP += hurt;
                    Brole[bnum].ExpGot += hurt;
                    Rrole[rnum].MaxMP += GameRandom() % (hurt / 2 + 1);
                    if (Rrole[rnum].MaxMP > MAX_MP)
                    {
                        Rrole[rnum].MaxMP = MAX_MP;
                    }
                    if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP)
                    {
                        Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
                    }
                }
                // 中毒
                int addpoi = Rrole[rnum].AttPoi / 5 + Rmagic[mnum].Poison * level / 2 * (100 - Rrole[Brole[i].rnum].DefPoi) / 100;
                if (addpoi + Rrole[Brole[i].rnum].Poison > 99)
                {
                    addpoi = 99 - Rrole[Brole[i].rnum].Poison;
                }
                if (addpoi < 0)
                {
                    addpoi = 0;
                }
                if (Rrole[Brole[i].rnum].DefPoi >= 99)
                {
                    addpoi = 0;
                }
                Rrole[Brole[i].rnum].Poison += addpoi;
            }
        }
    }
    int hpDamage(int bnum1,int bnum2,int mnum,int level) const override
    {
        int rnum1 = Brole[bnum1].rnum, rnum2 = Brole[bnum2].rnum;
        // 计算双方武学常识
        int k1 = 0, k2 = 0;
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (Brole[i].Team == Brole[bnum1].Team && Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)
            {
                k1 += Rrole[Brole[i].rnum].Knowledge;
            }
            if (Brole[i].Team == Brole[bnum2].Team && Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)
            {
                k2 += Rrole[Brole[i].rnum].Knowledge;
            }
        }

        int mhurt = 0;
        if (level > 0)
        {
            mhurt = Rmagic[mnum].Attack[level - 1];
        }

        int att = Rrole[rnum1].Attack + k1 * 3 / 2 + mhurt / 3;
        int def = Rrole[rnum2].Defence * 2 + k2 * 3;

        // 武功类型加成
        switch (Rmagic[mnum].MagicType)
        {
        case 1:
            att += Rrole[rnum1].Fist;
            def += Rrole[rnum2].Fist;
            break;
        case 2:
            att += Rrole[rnum1].Sword;
            def += Rrole[rnum2].Sword;
            break;
        case 3:
            att += Rrole[rnum1].Knife;
            def += Rrole[rnum2].Knife;
            break;
        case 4:
            att += Rrole[rnum1].Unusual;
            def += Rrole[rnum2].Unusual;
            break;
        }

        // 按受伤折扣
        att = att * (100 - Rrole[rnum1].Hurt / 2) / 100;
        def = def * (100 - Rrole[rnum2].Hurt / 2) / 100;

        // 武器加攻击 + 配合列表
        if (Rrole[rnum1].Equip[0] >= 0)
        {
            att += Ritem[Rrole[rnum1].Equip[0]].AddAttack;
            for (int i = 0; i < MAX_WEAPON_MATCH; i++)
            {
                if (Rrole[rnum1].Equip[0] == MatchList[i][0] && mnum == MatchList[i][1])
                {
                    att += MatchList[i][2] * 2 / 3;
                    break;
                }
            }
        }
        // 防具加攻击
        if (Rrole[rnum1].Equip[1] >= 0)
        {
            att += Ritem[Rrole[rnum1].Equip[1]].AddAttack;
        }
        // 对方武器防具加防御
        if (Rrole[rnum2].Equip[0] >= 0)
        {
            def += Ritem[Rrole[rnum2].Equip[0]].AddDefence;
        }
        if (Rrole[rnum2].Equip[1] >= 0)
        {
            def += Ritem[Rrole[rnum2].Equip[1]].AddDefence;
        }

        int result = att - def + GameRandom() % 20 - GameRandom() % 20;
        int dis = abs(Brole[bnum1].X - Brole[bnum2].X) + abs(Brole[bnum1].Y - Brole[bnum2].Y);
        if (dis > 10)
        {
            dis = 10;
        }

        result = std::max(result, att / 10 + GameRandom() % 10 - GameRandom() % 10);
        result = result * (100 - (dis - 1) * 3) / 100;
        if (result <= 0 || level <= 0)
        {
            result = GameRandom() % 10 + 1;
        }
        if (result > 9999)
        {
            result = 9999;
        }
        return result;
    }
    void roundEnd(int actor) const override
    {
        auto& state=Brole[actor];auto& role=Rrole[state.rnum];
        if(role.Poison>0 && state.Dead==0 && state.Acted==1)
        {
            if(POISON_HURT!=0)role.CurrentHP-=role.Poison/POISON_HURT+1;
            if(role.CurrentHP<=0)role.CurrentHP=1;
        }
    }
    void paySkillCost(TRole& role,BattleSkill skill) const override { role.PhyPower-=skill==BattleSkill::Poison?3:5; }
    void awardSkillExperience(int,int target,int amount) const override { Brole[target].ExpGot+=amount; }
    int poison(TRole& a,TRole& d) const override
    {
        int amount=std::max(a.UsePoi/3-d.DefPoi/4,0);
        if(amount+d.Poison>99)amount=99-d.Poison;
        d.Poison+=amount;return amount;
    }
    int heal(TRole& a,TRole& d) const override
    {
        int addlife=0,minushurt=0;

        addlife = a.Medicine * MED_LIFE * (10 - d.Hurt / 15) / 10;
        if (d.Hurt - a.Medicine > 20)
        {
            addlife = 0;
        }
        minushurt = addlife / LIFE_HURT;
        if (minushurt > d.Hurt)
        {
            minushurt = d.Hurt;
        }
        d.Hurt -= minushurt;
        if (d.Hurt < 0)
        {
            d.Hurt = 0;
        }
        if (addlife > d.MaxHP - d.CurrentHP)
        {
            addlife = d.MaxHP - d.CurrentHP;
        }
        d.CurrentHP += addlife;
        return addlife;
    }
    int detox(TRole& a,TRole& d) const override
    {
        int minuspoi;

        minuspoi = a.MedPoi;
        if (minuspoi > d.Poison)
        {
            minuspoi = d.Poison;
        }
        d.Poison -= minuspoi;
        return minuspoi;
    }
    int hiddenWeapon(int bnum,int bnum1,const TItem& item) const override
    {
        int rnum = Brole[bnum].rnum, rnum1 = Brole[bnum1].rnum;
        int hidden = Rrole[rnum].HidWeapon, hurt;
        hurt = hidden / 2 - item.AddCurrentHP / 3 - Rrole[rnum1].HidWeapon;
        hurt = std::max(hurt * (Rrole[rnum1].Hurt / 33 + 1), 1 + GameRandom() % 10);
        Rrole[rnum1].CurrentHP -= hurt;
        Brole[bnum1].ExpGot += hurt;
        Rrole[rnum1].Hurt = std::min<int>(Rrole[rnum1].Hurt + hurt / LIFE_HURT, 99);
        // Mods can legitimately raise resistance above 100. A hostile
        // poisoned weapon must not create negative poison or cleanse
        // existing poison when the resistance multiplier becomes negative.
        int poisonAdded = item.AddPoi * std::max(0, 100 - Rrole[rnum1].DefPoi) / 100;
        Rrole[rnum1].Poison = std::clamp<int>(Rrole[rnum1].Poison + poisonAdded, 0, 99);
        return hurt;
    }
    void rest(int bnum) const override
    {
        int rnum = Brole[bnum].rnum;
        Rrole[rnum].CurrentHP = std::min<int>(Rrole[rnum].CurrentHP + (5 + Brole[bnum].Step) * Rrole[rnum].MaxHP / 200, Rrole[rnum].MaxHP);
        Rrole[rnum].CurrentMP = std::min<int>(Rrole[rnum].CurrentMP + (5 + Brole[bnum].Step) * Rrole[rnum].MaxMP / 200, Rrole[rnum].MaxMP);
        Rrole[rnum].PhyPower = std::min<int>(Rrole[rnum].PhyPower + (5 + Brole[bnum].Step) * MAX_PHYSICAL_POWER / 200, MAX_PHYSICAL_POWER);
    }
    MagicRuleInfo inspectMagic(const TRole*,const TMagic& magic,int trained) const override
    {
        return {trained,magic.NeedMP*((trained+1)/2)};
    }
    int minimumCheckpointVersion() const override { return 1; }
};
}
const ProgressionRules& LegacyProgression() { static RemakeProgression rules;return rules; }
const CombatRules& LegacyCombat() { static RemakeCombat rules;return rules; }
}
