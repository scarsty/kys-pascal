#include "dragon_dos12.h"
#include "rules_internal.h"
#include <algorithm>
#include <bit>

namespace rules::dragon_dos12
{
namespace
{
int16_t word(int value) { return std::bit_cast<int16_t>(static_cast<uint16_t>(value)); }
int bounded(const RulesRandom& random, int bound) { return bound<=1 || bound>30000 ? 0 : random(bound); }
int noise(const RulesRandom& random,int bound)
{
    int plus=bounded(random,bound);return plus-bounded(random,bound);
}
}
int EffectiveLevel(const TRole& role,const TMagic& magic,int trainedLevel)
{
    int level=std::clamp(trainedLevel,1,10);
    while(level>1 && role.CurrentMP<magic.NeedMP*(level/2))--level;
    return level;
}
void PayMagicCost(TRole& role,const TMagic& magic,int cachedLevel)
{
    role.CurrentMP=std::max<int>(word(role.CurrentMP-magic.NeedMP*(cachedLevel/2)),0);
}
int LevelUp(TRole& role,const RulesRandom& random)
{
    if(role.Level<1 || role.Level>=MAX_LEVEL)return 0;
    int next=role.Level;
    while(next<MAX_LEVEL && role.Exp>=config.xpThresholds.at(next-1))++next;
    int delta=next-role.Level;
    if(!delta)return 0;
    int tier=role.Aptitude<30?2:role.Aptitude<50?3:role.Aptitude<70?4:role.Aptitude<90?5:6;
    int gain=1+bounded(random,tier);
    role.Level=static_cast<int16_t>(next);
    role.MaxHP=std::min<int>(word(role.MaxHP+delta*config.growth.hp*(role.IncLife+bounded(random,3))),MAX_HP);
    role.CurrentHP=role.MaxHP;role.Hurt=0;role.Poison=0;role.PhyPower=MAX_PHYSICAL_POWER;
    role.MaxMP=std::min<int>(word(role.MaxMP+delta*config.growth.mp*(9-gain)),MAX_MP);
    role.CurrentMP=role.MaxMP;
    role.Attack=word(role.Attack+delta*gain*config.growth.attack);
    role.Speed=word(role.Speed+delta*gain*config.growth.speed);
    role.Defence=word(role.Defence+delta*gain*config.growth.defence);
    for(int index:{46,47,48,50,51,52})
        if(role.Data[index]>20)role.Data[index]=word(role.Data[index]+bounded(random,3));
    role.HidWeapon=word(role.HidWeapon+bounded(random,3));
    for(int index:{46,47,48})role.Data[index]=std::min<int>(role.Data[index],100);
    return delta;
}
int HpDamage(const TRole& a,const TRole& d,const TMagic& m,int level,const HitContext& c,const RulesRandom& random)
{
    int attack=word((3*a.Attack+m.Attack[std::clamp(level,1,10)-1])/2+c.attackEquipment+c.weaponMatch+c.attackKnowledge);
    int defence=word(d.Defence+c.defenceEquipment+c.defenceKnowledge);
    int damage=word(2*(attack-3*defence)/3+noise(random,20));
    if(damage<=0)damage=word(attack/10+noise(random,4));
    if(damage<0)return 1;
    damage=word(damage+a.PhyPower/15);
    damage=word(damage+d.Hurt/20);
    damage=c.distance<=10?word(damage*(100-(c.distance-1)*3)/100):word(damage*2/3);
    return std::max(damage,1);
}
int ApplyHpHit(TRole& a,TRole& d,const TMagic& m,int trained,const HitContext& c,int16_t& exp,const RulesRandom& random)
{
    int damage=HpDamage(a,d,m,EffectiveLevel(a,m,trained),c,random);
    exp=word(exp+damage/5);
    d.CurrentHP=word(d.CurrentHP-damage);
    if(d.CurrentHP<0){d.CurrentHP=0;exp=word(exp+d.Level*10);}
    d.Hurt=std::min<int>(word(d.Hurt+damage/LIFE_HURT),99);
    int poison=a.AttPoi+trained*m.Poison;
    if(poison>d.DefPoi && d.DefPoi<90)
    {
        d.Poison=word(d.Poison+(poison-d.DefPoi)/15);
        if(d.Poison>100)d.Poison=99;
        d.Poison=std::max<int>(d.Poison,0);
    }
    return damage;
}
int ApplyMpHit(TRole& a,TRole& d,const TMagic& m,int trained,const RulesRandom& random)
{
    int level=std::clamp(trained,1,10)-1;
    int recoverNoise=noise(random,3);
    a.CurrentMP=word(a.CurrentMP+m.AddMP[level]);
    a.MaxMP=std::min<int>(word(a.MaxMP+bounded(random,m.AddMP[level]/2)),MAX_MP);
    a.CurrentMP=std::min<int>(word(a.CurrentMP+recoverNoise),a.MaxMP);
    int lostNoise=noise(random,3),before=d.CurrentMP;
    d.CurrentMP=std::max<int>(word(d.CurrentMP-m.HurtMP[level]-lostNoise),0);
    return before-d.CurrentMP;
}
int UsePoison(const TRole& a,TRole& d)
{
    int amount=std::clamp((a.UsePoi-d.DefPoi)/4,0,99);
    amount=std::min(amount,99-d.Poison);
    d.Poison=std::clamp<int>(word(d.Poison+amount),0,99);
    return amount;
}
int Detox(const TRole& a,TRole& d,const RulesRandom& random)
{
    int amount=std::clamp<int>(word(a.MedPoi/3+noise(random,10)),0,99);
    if(d.Poison>a.MedPoi+20)amount=0;
    amount=std::min<int>(amount,d.Poison);
    d.Poison=std::max<int>(word(d.Poison-amount),0);
    if(d.Poison>100)d.Poison=99;
    return amount;
}
int Heal(TRole& a,TRole& d,const RulesRandom& random)
{
    if(a.PhyPower<50)return 0;
    int medicine=std::max<int>(a.Medicine,0);
    int amount=d.Hurt<=25?medicine*2:d.Hurt<=50?medicine*3/4:d.Hurt<=75?medicine*2/3:medicine/2;
    amount+=bounded(random,5);
    if(d.Hurt>a.Medicine+20){amount=0;medicine=0;}
    amount=std::min<int>(amount,d.MaxHP-d.CurrentHP);
    d.CurrentHP=std::min<int>(word(d.CurrentHP+amount),d.MaxHP);
    d.Hurt=std::max<int>(word(d.Hurt-medicine),0);
    a.PhyPower=word(a.PhyPower-2);
    return amount;
}
int HiddenWeapon(const TRole& a,TRole& d,const TItem& item,const RulesRandom& random)
{
    int before=d.CurrentHP,divisor=d.Hurt==0?4:d.Hurt<=33?3:d.Hurt<=66?2:1;
    int change=(word(item.AddCurrentHP/divisor-bounded(random,5))-2*a.HidWeapon)/3;
    d.Hurt=std::clamp<int>(word(d.Hurt-change/4),0,99);
    d.CurrentHP=std::clamp<int>(word(d.CurrentHP+change),0,d.MaxHP);
    if(item.AddPoi>0)
    {
        int poison=(item.AddPoi-a.HidWeapon)/2-d.DefPoi;
        if(d.DefPoi>=100)poison=0;
        poison=std::max(poison,0);
        d.Poison=word(d.Poison+poison/2);
    }
    else d.Poison=word(d.Poison+item.AddPoi/2+noise(random,5));
    d.Poison=std::clamp<int>(d.Poison,0,99);
    return before-d.CurrentHP;
}
void Rest(TRole& r,int steps,const RulesRandom& random)
{
    r.PhyPower=std::min<int>(word(r.PhyPower+(steps==r.Speed/10?3:2)+bounded(random,3)),MAX_PHYSICAL_POWER);
    if(r.PhyPower>=30)
    {
        int bound=r.PhyPower/10-2;
        r.CurrentHP=std::min<int>(word(r.CurrentHP+3+bounded(random,bound)),r.MaxHP);
        r.CurrentMP=std::min<int>(word(r.CurrentMP+3+bounded(random,bound)),r.MaxMP);
    }
}
void RoundStatus(TRole& r,bool dead)
{
    // Original short-circuit ordering matters: injury bypasses the alive/
    // stamina checks. The executable clamps negative HP to 1 but leaves 0.
    if(r.Hurt<=0 && (r.Poison<=0 || r.CurrentHP<=0 || r.PhyPower<=0 || dead))return;
    int poison=POISON_HURT? r.Poison/POISON_HURT:0;
    r.CurrentHP=word(r.CurrentHP-r.Hurt/20-poison);
    if(r.PhyPower<0)r.PhyPower=1;
    if(r.CurrentHP<0)r.CurrentHP=1;
}
}

namespace rules
{
static dragon_dos12::HitContext hitContext(int bnum1,int bnum2,int mnum)
{
    dragon_dos12::HitContext context;
    auto& attacker=Rrole[Brole[bnum1].rnum];auto& defender=Rrole[Brole[bnum2].rnum];
    context.distance=abs(Brole[bnum1].X-Brole[bnum2].X)+abs(Brole[bnum1].Y-Brole[bnum2].Y);
    for(int id:attacker.Equip)if(id>=0 && id<725)context.attackEquipment+=Ritem[id].AddAttack;
    for(int id:defender.Equip)if(id>=0 && id<725)context.defenceEquipment+=Ritem[id].AddDefence;
    for(int i=0;i<MAX_WEAPON_MATCH;++i)
        if(attacker.Equip[0]==MatchList[i][0] && mnum==MatchList[i][1])context.weaponMatch=MatchList[i][2];
    for(int i=0;i<BRoleAmount;++i)
    {
        auto& role=Rrole[Brole[i].rnum];
        if(Brole[i].Dead || role.CurrentHP<=0 || role.Knowledge<=MIN_KNOWLEDGE)continue;
        if(Brole[i].Team==Brole[bnum1].Team)context.attackKnowledge+=role.Knowledge*2;
        else context.defenceKnowledge+=role.Knowledge*2;
    }
    return context;
}

namespace
{
class DragonProgression final : public ProgressionRules
{
public:
    const char* name() const override { return "dragon_dos12"; }
    ProgressionDefaults defaults() const override
    {
        return {30,999,9999,100,
            {50,150,300,500,750,1050,1400,1800,2250,2750,3850,5050,6350,7750,
             9250,10850,12550,14350,16750,18250,21400,24700,28150,31750,35500,
             39400,43450,47650,52000}};
    }
    int nextExperience(const TRole& role) const override { return config.xpThresholds.at(role.Level-1); }
    int advance(TRole& role) const override { return dragon_dos12::LevelUp(role); }
    void describe(GameRuleDescription& out) const override
    {
        out.cumulativeExperience=true;out.batchGrowth=true;
        out.xpThresholds=config.xpThresholds;out.growth=config.growth;
        out.levelStatCaps="Medicine/use-poison/detox 100; attack/speed/defence/fist/sword/knife/hidden weapon retain original 16-bit growth without a 100 cap. Resistance/unusual do not grow.";
    }
};
class DragonCombat final : public CombatRules
{
public:
    const char* name() const override { return "dragon_dos12"; }
    CombatDefaults defaults() const override { return {100,80,10,1}; }
    int strikeCount(const TRole& role) const override { return role.AttTwice==1?2:1; }
    int beginStrike(TRole& role,int slot,int) const override { return role.MagLevel[slot]/100+1; }
    void finishStrike(TRole& role,int slot) const override
    {
        role.MagLevel[slot]=std::min<int>(role.MagLevel[slot]+RulesRandomDraw(2)+1,999);
    }
    void finishAttack(TRole& role) const override { role.PhyPower=std::max<int>(role.PhyPower-3,0); }
    void resolveMagic(int bnum,int mnum,int level) const override
    {
        int rnum=Brole[bnum].rnum;
        auto& attacker=Rrole[rnum];auto& magic=Rmagic[mnum];
        for(int i=0;i<BRoleAmount;++i)
        {
            Brole[i].ShowNumber=-1;
            if(BField[4][Brole[i].X][Brole[i].Y]==0 || Brole[bnum].Team==Brole[i].Team || Brole[i].Dead)continue;
            auto& defender=Rrole[Brole[i].rnum];
            if(magic.HurtType==0)
            {
                runtime.magicCostTier=dragon_dos12::EffectiveLevel(attacker,magic,level);
                Brole[i].ShowNumber=dragon_dos12::ApplyHpHit(attacker,defender,magic,level,
                    hitContext(bnum,i,mnum),Brole[bnum].ExpGot);
            }
            else if(magic.HurtType==1)Brole[i].ShowNumber=dragon_dos12::ApplyMpHit(attacker,defender,magic,level);
        }
        // Original obj2+18520 consumes this HP cache even on an MP attack.
        dragon_dos12::PayMagicCost(attacker,magic,runtime.magicCostTier);
        Brole[bnum].ExpGot+=2;
    }
    int hpDamage(int attacker,int defender,int magic,int trained) const override
    {
        auto& role=Rrole[Brole[attacker].rnum];
        return dragon_dos12::HpDamage(role,Rrole[Brole[defender].rnum],Rmagic[magic],
            dragon_dos12::EffectiveLevel(role,Rmagic[magic],trained),hitContext(attacker,defender,magic));
    }
    void roundEnd(int actor) const override { dragon_dos12::RoundStatus(Rrole[Brole[actor].rnum],Brole[actor].Dead!=0); }
    void paySkillCost(TRole& role,BattleSkill skill) const override
    {
        // Healing owns its eligibility check and cost, including out of battle.
        if(skill!=BattleSkill::Medicine)role.PhyPower-=2;
    }
    void awardSkillExperience(int actor,int,int) const override { Brole[actor].ExpGot++; }
    int poison(TRole& a,TRole& d) const override { return dragon_dos12::UsePoison(a,d); }
    int heal(TRole& a,TRole& d) const override { return dragon_dos12::Heal(a,d); }
    int detox(TRole& a,TRole& d) const override { return dragon_dos12::Detox(a,d); }
    int hiddenWeapon(int actor,int target,const TItem& item) const override
    {
        return dragon_dos12::HiddenWeapon(Rrole[Brole[actor].rnum],Rrole[Brole[target].rnum],item);
    }
    void rest(int actor) const override { dragon_dos12::Rest(Rrole[Brole[actor].rnum],Brole[actor].Step); }
    MagicRuleInfo inspectMagic(const TRole* role,const TMagic& magic,int trained) const override
    {
        int effective=magic.HurtType==0 && role?dragon_dos12::EffectiveLevel(*role,magic,trained):trained;
        int costTier=magic.HurtType==0?effective:runtime.magicCostTier;
        return {effective,magic.NeedMP*(costTier/2),3,0,true,magic.HurtType==1};
    }
    int minimumCheckpointVersion() const override { return 4; }
};
}
const ProgressionRules& DragonDos12Progression() { static DragonProgression rules;return rules; }
const CombatRules& DragonDos12Combat() { static DragonCombat rules;return rules; }
}
