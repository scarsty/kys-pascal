#include "kys_rules.h"
#include "kys_frontend.h"
#include "INIReader.h"
#include <algorithm>
#include <bit>
#include <charconv>
#include <sstream>
#include <stdexcept>

namespace
{
constexpr uint16_t originalXp[] = {
    50,150,300,500,750,1050,1400,1800,2250,2750,3850,5050,6350,7750,
    9250,10850,12550,14350,16750,18250,21400,24700,28150,31750,35500,
    39400,43450,47650,52000};
int16_t word(int value) { return std::bit_cast<int16_t>(static_cast<uint16_t>(value)); }
int bounded(const RulesRandom& random, int bound) { return bound<=1 || bound>30000 ? 0 : random(bound); }
int noise(const RulesRandom& random,int bound)
{
    int plus=bounded(random,bound);return plus-bounded(random,bound);
}
RulesMode mode(const std::string& name)
{
    if(name=="legacy")return RulesMode::Legacy;
    if(name=="dragon_dos12")return RulesMode::DragonDos12;
    throw std::runtime_error("Unknown rules mode: "+name+" (use legacy or dragon_dos12)");
}
int integer(INIReaderNormal& ini,const std::string& key,int fallback,int low,int high)
{
    auto text=ini.getString("rules",key,std::to_string(fallback));
    int value=0;auto [end,error]=std::from_chars(text.data(),text.data()+text.size(),value);
    if(error!=std::errc{} || end!=text.data()+text.size() || value<low || value>high)
        throw std::runtime_error("Invalid [rules] "+key+" (expected "+std::to_string(low)+".."+std::to_string(high)+")");
    return value;
}
}

const char* RulesModeName(RulesMode mode) { return mode==RulesMode::DragonDos12?"dragon_dos12":"legacy"; }
void LoadGameRules(const std::string& iniPath)
{
    INIReaderNormal ini;ini.loadFile(iniPath);
    ActiveRules={};
    DosLastEffectiveLevel=0;
    ActiveRules.profile=ini.getString("rules","profile","legacy");
    mode(ActiveRules.profile); // fail on typos, including an unused profile
    ActiveRules.progression=mode(ini.getString("rules","progression",ActiveRules.profile));
    ActiveRules.combat=mode(ini.getString("rules","combat",ActiveRules.profile));
    bool dosLevel=ActiveRules.progression==RulesMode::DragonDos12;
    bool dosCombat=ActiveRules.combat==RulesMode::DragonDos12;
    MAX_LEVEL=integer(ini,"max_level",dosLevel?30:MAX_LEVEL,1,100);
    MAX_HP=integer(ini,"max_hp",dosLevel?999:MAX_HP,1,32767);
    MAX_MP=integer(ini,"max_mp",dosLevel?9999:MAX_MP,1,32767);
    MAX_PHYSICAL_POWER=integer(ini,"max_stamina",dosLevel||dosCombat?100:MAX_PHYSICAL_POWER,1,32767);
    MIN_KNOWLEDGE=integer(ini,"min_knowledge",dosCombat?80:MIN_KNOWLEDGE,0,32767);
    LIFE_HURT=integer(ini,"life_hurt",dosCombat?10:LIFE_HURT,1,32767);
    POISON_HURT=integer(ini,"poison_hurt",dosCombat?1:POISON_HURT,0,32767);
    ActiveRules.hpGrowthFactor=integer(ini,"hp_growth_factor",3,0,100);
    ActiveRules.mpGrowthFactor=integer(ini,"mp_growth_factor",4,0,100);
    ActiveRules.attackGrowthFactor=integer(ini,"attack_growth_factor",1,0,100);
    ActiveRules.speedGrowthFactor=integer(ini,"speed_growth_factor",1,0,100);
    ActiveRules.defenceGrowthFactor=integer(ini,"defence_growth_factor",1,0,100);
    if(dosLevel)
    {
        ActiveRules.xpThresholds.assign(std::begin(originalXp),std::end(originalXp));
        auto custom=ini.getString("rules","xp_thresholds","");
        if(!custom.empty())
        {
            ActiveRules.xpThresholds.clear();
            std::istringstream stream(custom);std::string token;
            if(custom.back()==',')throw std::runtime_error("Trailing comma in xp_thresholds");
            while(std::getline(stream,token,','))
            {
                auto first=token.find_first_not_of(" \t");auto last=token.find_last_not_of(" \t");
                if(first==std::string::npos)throw std::runtime_error("Empty XP threshold");
                token=token.substr(first,last-first+1);
                int value=0;auto [end,error]=std::from_chars(token.data(),token.data()+token.size(),value);
                if(error!=std::errc{} || end!=token.data()+token.size() || value<=0 || value>65535 ||
                   (!ActiveRules.xpThresholds.empty() && value<=ActiveRules.xpThresholds.back()))
                    throw std::runtime_error("xp_thresholds must contain strictly increasing integers in 1..65535");
                ActiveRules.xpThresholds.push_back(static_cast<uint16_t>(value));
            }
        }
        if(ActiveRules.xpThresholds.size()<static_cast<size_t>(MAX_LEVEL-1))
            throw std::runtime_error("MAX_LEVEL exceeds the DOS XP table; supply [rules] xp_thresholds for every next level");
    }
    if(MAX_LEVEL<1 || MAX_LEVEL>100)throw std::runtime_error("MAX_LEVEL must be 1..100");
}
int NextLevelExperience(const TRole& role)
{
    if(role.Level<1 || role.Level>=MAX_LEVEL)return -1;
    if(ActiveRules.progression==RulesMode::DragonDos12)
        return ActiveRules.xpThresholds.at(role.Level-1);
    return static_cast<uint16_t>(LevelUpList[role.Level-1]);
}
int RulesRandomDraw(int bound) { return bound<=1 || bound>30000?0:GameRandom()%bound; }
int DosEffectiveLevel(const TRole& role,const TMagic& magic,int trainedLevel)
{
    int level=std::clamp(trainedLevel,1,10);
    while(level>1 && role.CurrentMP<magic.NeedMP*(level/2))--level;
    return level;
}
void DosPayMagicCost(TRole& role,const TMagic& magic,int cachedLevel)
{
    role.CurrentMP=std::max<int>(word(role.CurrentMP-magic.NeedMP*(cachedLevel/2)),0);
}
int DosLevelUp(TRole& role,const RulesRandom& random)
{
    if(role.Level<1 || role.Level>=MAX_LEVEL)return 0;
    int next=role.Level;
    while(next<MAX_LEVEL && role.Exp>=ActiveRules.xpThresholds.at(next-1))++next;
    int delta=next-role.Level;
    if(!delta)return 0;
    int tier=role.Aptitude<30?2:role.Aptitude<50?3:role.Aptitude<70?4:role.Aptitude<90?5:6;
    int gain=1+bounded(random,tier);
    role.Level=static_cast<int16_t>(next);
    role.MaxHP=std::min<int>(word(role.MaxHP+delta*ActiveRules.hpGrowthFactor*(role.IncLife+bounded(random,3))),MAX_HP);
    role.CurrentHP=role.MaxHP;role.Hurt=0;role.Poison=0;role.PhyPower=MAX_PHYSICAL_POWER;
    role.MaxMP=std::min<int>(word(role.MaxMP+delta*ActiveRules.mpGrowthFactor*(9-gain)),MAX_MP);
    role.CurrentMP=role.MaxMP;
    role.Attack=word(role.Attack+delta*gain*ActiveRules.attackGrowthFactor);
    role.Speed=word(role.Speed+delta*gain*ActiveRules.speedGrowthFactor);
    role.Defence=word(role.Defence+delta*gain*ActiveRules.defenceGrowthFactor);
    for(int index:{46,47,48,50,51,52})
        if(role.Data[index]>20)role.Data[index]=word(role.Data[index]+bounded(random,3));
    role.HidWeapon=word(role.HidWeapon+bounded(random,3));
    for(int index:{46,47,48})role.Data[index]=std::min<int>(role.Data[index],100);
    return delta;
}
int DosHpDamage(const TRole& a,const TRole& d,const TMagic& m,int level,const DosHitContext& c,const RulesRandom& random)
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
int DosApplyHpHit(TRole& a,TRole& d,const TMagic& m,int trained,const DosHitContext& c,int16_t& exp,const RulesRandom& random)
{
    int damage=DosHpDamage(a,d,m,DosEffectiveLevel(a,m,trained),c,random);
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
int DosApplyMpHit(TRole& a,TRole& d,const TMagic& m,int trained,const RulesRandom& random)
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
int DosUsePoison(const TRole& a,TRole& d)
{
    int amount=std::clamp((a.UsePoi-d.DefPoi)/4,0,99);
    amount=std::min(amount,99-d.Poison);
    d.Poison=std::clamp<int>(word(d.Poison+amount),0,99);
    return amount;
}
int DosDetox(const TRole& a,TRole& d,const RulesRandom& random)
{
    int amount=std::clamp<int>(word(a.MedPoi/3+noise(random,10)),0,99);
    if(d.Poison>a.MedPoi+20)amount=0;
    amount=std::min<int>(amount,d.Poison);
    d.Poison=std::max<int>(word(d.Poison-amount),0);
    if(d.Poison>100)d.Poison=99;
    return amount;
}
int DosHeal(TRole& a,TRole& d,const RulesRandom& random)
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
int DosHiddenWeapon(const TRole& a,TRole& d,const TItem& item,const RulesRandom& random)
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
void DosRest(TRole& r,int steps,const RulesRandom& random)
{
    r.PhyPower=std::min<int>(word(r.PhyPower+(steps==r.Speed/10?3:2)+bounded(random,3)),MAX_PHYSICAL_POWER);
    if(r.PhyPower>=30)
    {
        int bound=r.PhyPower/10-2;
        r.CurrentHP=std::min<int>(word(r.CurrentHP+3+bounded(random,bound)),r.MaxHP);
        r.CurrentMP=std::min<int>(word(r.CurrentMP+3+bounded(random,bound)),r.MaxMP);
    }
}
void DosRoundStatus(TRole& r,bool dead)
{
    // Original short-circuit ordering matters: injury bypasses the alive/
    // stamina checks. The executable clamps negative HP to 1 but leaves 0.
    if(r.Hurt<=0 && (r.Poison<=0 || r.CurrentHP<=0 || r.PhyPower<=0 || dead))return;
    int poison=POISON_HURT? r.Poison/POISON_HURT:0;
    r.CurrentHP=word(r.CurrentHP-r.Hurt/20-poison);
    if(r.PhyPower<0)r.PhyPower=1;
    if(r.CurrentHP<0)r.CurrentHP=1;
}
