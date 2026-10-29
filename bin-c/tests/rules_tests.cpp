#include "kys_rules.h"
#include "rules/dragon_dos12.h"
#include "rules/rules_internal.h"

namespace dos=rules::dragon_dos12;
#include "kys_battle.h"
#include "kys_frontend.h"
#include <glaze/glaze.hpp>
#include <array>
#include <bit>
#include <cstring>
#include <fstream>
#include <iostream>
#include <map>
#include <stdexcept>

using Fields=std::map<std::string,int>;
struct Draw { int bound=0,value=0; };
struct Expected
{
    std::optional<uint32_t> eax;
    std::map<std::string,std::vector<int>> roles;
    std::vector<Draw> rng;
    int battle_exp=0,effective_level=0;
};
struct Case
{
    std::string name,kind;
    std::vector<Fields> roles;
    Fields magic;
    std::vector<Fields> items,actors;
    int distance=1,match=0,step=0,cache=0,seed=-1;
    Expected expected;
};
struct Vectors { std::string binary_sha256;std::vector<int> xp_table;std::vector<Case> cases; };
struct TestFrontend final:GameFrontend
{
    void text(const std::string&,int)override{}
    int choose(const std::string&,const std::vector<std::string>&,bool)override{return 0;}
    int number(int,int,int n)override{return n;}
    bool battle(int,int)override{return false;}
    bool aim(int,int,int,int)override{return false;}
    void instruction(int,int,int)override{}
};
void expect(bool ok,const std::string& message){if(!ok)throw std::runtime_error(message);}
template<class T> void fill(T& record,const Fields& fields)
{
    record={};for(auto& [key,value]:fields)record.Data[std::stoi(key)]=std::bit_cast<int16_t>(static_cast<uint16_t>(value));
}
int main(int argc,char** argv)
{
    try
    {
        expect(argc==2,"Expected native fixture path");
        std::ifstream input(argv[1]);std::string json((std::istreambuf_iterator<char>(input)),{});
        Vectors vectors;auto error=glz::read_json(vectors,json);
        expect(!error,"Cannot parse native oracle fixtures");
        expect(vectors.binary_sha256=="60ff7e91d7be7a848242e2ddc2ef105b906e160e19f3086bf13ff55d8e951928","Wrong oracle identity");
        rules::config={};rules::config.progression=rules::Profile::DragonDos12;rules::config.combat=rules::Profile::DragonDos12;
        rules::config.xpThresholds.assign(vectors.xp_table.begin()+1,vectors.xp_table.end());
        rules::SelectProfiles();
        MAX_LEVEL=30;MAX_HP=999;MAX_MP=9999;MAX_PHYSICAL_POWER=100;LIFE_HURT=10;POISON_HURT=1;
        for(auto& c:vectors.cases)
        {
            std::vector<TRole> roles(c.roles.size());TMagic magic{};std::vector<TItem> items(c.items.size());
            for(size_t i=0;i<roles.size();++i)fill(roles[i],c.roles[i]);fill(magic,c.magic);
            for(size_t i=0;i<items.size();++i)fill(items[i],c.items[i]);
            size_t draw=0;
            auto random=[&](int bound)
            {
                // Native wrapper calls with bound <=1 return zero without an RNG draw.
                while(draw<c.expected.rng.size() && c.expected.rng[draw].bound<=1)++draw;
                expect(draw<c.expected.rng.size(),c.name+": extra random draw");
                auto value=c.expected.rng[draw++];
                expect(value.bound==bound,c.name+": RNG bound mismatch at "+std::to_string(draw));return value.value;
            };
            dos::HitContext ctx;ctx.distance=c.distance;ctx.weaponMatch=c.match;
            for(int id:roles[0].Equip)if(id>=0)ctx.attackEquipment+=items.at(id).AddAttack;
            if(roles.size()>1)for(int id:roles[1].Equip)if(id>=0)ctx.defenceEquipment+=items.at(id).AddDefence;
            for(auto& actor:c.actors)
            {
                int id=actor.contains("0")?actor.at("0"):0,team=actor.contains("1")?actor.at("1"):0;
                bool dead=actor.contains("5") && actor.at("5")!=0;
                if(roles[id].Knowledge>80 && roles[id].CurrentHP>0 && !dead)
                    (team?ctx.defenceKnowledge:ctx.attackKnowledge)+=2*roles[id].Knowledge;
            }
            int value=0;int16_t xp=0;
            auto& a=roles[0];int trained=a.MagLevel[0]/100+1;
            if(c.kind=="level")dos::LevelUp(a,random);
            else if(c.kind=="hp")value=dos::ApplyHpHit(a,roles[1],magic,trained,ctx,xp,random);
            else if(c.kind=="mp")value=dos::ApplyMpHit(a,roles[1],magic,trained,random);
            else if(c.kind=="poison")value=dos::UsePoison(a,roles[1]);
            else if(c.kind=="detox")value=dos::Detox(a,roles[1],random);
            else if(c.kind=="heal")value=dos::Heal(a,roles[1],random);
            else if(c.kind=="hidden")dos::HiddenWeapon(a,roles[1],items[0],random);
            else if(c.kind=="rest")dos::Rest(a,c.step,random);
            else if(c.kind=="tick")dos::RoundStatus(a,false);
            else if(c.kind=="cost")dos::PayMagicCost(a,magic,c.cache);
            else throw std::runtime_error("Unknown fixture kind");
            if(c.expected.eax)expect(static_cast<uint32_t>(value)==*c.expected.eax,c.name+": result mismatch, got "+std::to_string(value));
            expect(xp==c.expected.battle_exp,c.name+": XP mismatch");
            if(c.kind=="hp")expect(dos::EffectiveLevel(a,magic,trained)==c.expected.effective_level,c.name+": effective tier mismatch");
            for(size_t i=0;i<roles.size();++i)
                for(int j=0;j<91;++j)
                    expect(roles[i].Data[j]==c.expected.roles.at(std::to_string(i)).at(j),c.name+": role "+std::to_string(i)+" word "+std::to_string(j)+" expected "+std::to_string(c.expected.roles.at(std::to_string(i)).at(j))+" got "+std::to_string(roles[i].Data[j]));
            while(draw<c.expected.rng.size() && c.expected.rng[draw].bound<=1)++draw;
            expect(draw==c.expected.rng.size(),c.name+": missing random draws");
            if(c.seed>=0)
            {
                TestFrontend frontend;Frontend=&frontend;
                for(size_t i=0;i<c.roles.size();++i)fill(Rrole[i],c.roles[i]);
                fill(Rmagic[1],c.magic);BRoleAmount=static_cast<int>(c.roles.size());
                std::memset(Brole,0,sizeof(Brole));std::memset(BField,0,sizeof(BField));
                for(int i=0;i<BRoleAmount;++i){Brole[i].rnum=i;Brole[i].Team=i;Brole[i].X=10+i;Brole[i].Y=10;}
                BField[4][11][10]=1;MAX_WEAPON_MATCH=0;HeadlessRandomState=c.seed;RestoreRuleState({});
                if(c.kind=="level")CheckLevelUp();
                else
                {
                    Rmagic[1].HurtType=c.kind=="mp"?1:0;CalHurtRole(0,1,trained);
                    // The oracle's isolated hit excludes the caller's cost and
                    // action XP, both recovered from obj2+1826c..18551.
                    dos::PayMagicCost(roles[0],Rmagic[1],c.kind=="hp"?c.expected.effective_level:0);
                    expect(Brole[0].ExpGot==xp+2,c.name+": caller action XP");
                    expect(CaptureRuleState().magicCostTier==(c.kind=="hp"?c.expected.effective_level:0),c.name+": caller tier cache");
                }
                for(size_t i=0;i<roles.size();++i)for(int j=0;j<91;++j)
                    expect(Rrole[i].Data[j]==roles[i].Data[j],c.name+": shared engine adapter word "+std::to_string(j));
                Frontend=nullptr;
            }
        }
        TRole custom{};custom.Level=1;custom.Exp=150;custom.IncLife=3;custom.MaxHP=100;custom.MaxMP=200;custom.Aptitude=56;
        rules::config.growth.hp=5;rules::config.growth.mp=6;
        rules::config.growth.attack=2;rules::config.growth.speed=0;rules::config.growth.defence=3;
        dos::LevelUp(custom,[](int){return 1;});
        expect(custom.Level==3 && custom.Exp==150 && custom.MaxHP==140 && custom.MaxMP==284 &&
               custom.Attack==8 && custom.Speed==0 && custom.Defence==12,"Custom growth coefficients must affect the actual batch");
        // Cross a proficiency boundary during a real double strike. This
        // distinguishes per-strike tier/cost timing from per-action stamina.
        for(auto profile:{rules::Profile::Legacy,rules::Profile::DragonDos12})
        {
            rules::config.combat=profile;rules::SelectProfiles();RestoreRuleState({});
            TestFrontend frontend;Frontend=&frontend;HeadlessRandomState=7;
            std::memset(Brole,0,sizeof(Brole));std::memset(BField,0,sizeof(BField));
            BRoleAmount=2;MAX_WEAPON_MATCH=0;
            for(int i=0;i<2;++i)
            {
                Rrole[i]={};Rrole[i].Equip[0]=Rrole[i].Equip[1]=-1;
                Rrole[i].CurrentHP=Rrole[i].MaxHP=2000;Rrole[i].Defence=20;
                Brole[i].rnum=i;Brole[i].Team=i;Brole[i].X=10+i;Brole[i].Y=10;
            }
            auto& hero=Rrole[0];hero.Attack=50;hero.PhyPower=50;hero.CurrentMP=hero.MaxMP=20;
            hero.AttTwice=1;hero.MagLevel[0]=99;Brole[0].Acted=1;BField[4][11][10]=1;
            Rmagic[1]={};Rmagic[1].NeedMP=10;
            for(auto& power:Rmagic[1].Attack)power=100;
            AttackAction(0,0,1,1);
            bool original=profile==rules::Profile::DragonDos12;
            expect(hero.PhyPower==(original?47:44),"Double-strike stamina changed across rule dispatch");
            expect(hero.CurrentMP==(original?10:0),"Double-strike tier/cost timing changed across rule dispatch");
            expect(hero.MagLevel[0]>=101 && hero.MagLevel[0]<=103,"Double-strike proficiency growth");
            expect(BattleRules().minimumCheckpointVersion()==(original?4:1),"Runtime-state checkpoint requirement");
            Brole[0].ExpGot=Brole[1].ExpGot=0;hero.PhyPower=100;
            BattleRules().paySkillCost(hero,BattleSkill::Poison);
            BattleRules().awardSkillExperience(0,1,8);
            expect(hero.PhyPower==(original?98:97) && Brole[0].ExpGot==(original?1:0) &&
                   Brole[1].ExpGot==(original?0:8),"Skill cost and experience recipient changed");
            Frontend=nullptr;
        }
        std::cout<<vectors.cases.size()<<" original-machine-code rule vectors passed\n";
    }
    catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
