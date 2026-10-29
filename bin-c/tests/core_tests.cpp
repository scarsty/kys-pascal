#include "kys_frontend.h"
#include "kys_main.h"
#include "kys_event.h"
#include "kys_engine.h"
#include "kys_battle.h"
#include <algorithm>
#include <cstring>
#include <iostream>
#include <stdexcept>

struct TestFrontend final : GameFrontend
{
    bool aimAccepted=false;
    void text(const std::string&,int) override {}
    int choose(const std::string&,const std::vector<std::string>&,bool) override { return 0; }
    int number(int,int,int n) override { return n; }
    bool battle(int,int) override { return false; }
    bool aim(int,int,int,int) override { return aimAccepted; }
    void instruction(int,int,int) override {}
};
void check(bool condition,const char* message)
{
    if(!condition)throw std::runtime_error(message);
}
void checkBattleMovement()
{
    int failures=0;
    auto expect=[&](bool condition,const char* message)
    {
        if(!condition){std::cerr<<"Battle movement: "<<message<<'\n';++failures;}
    };
    auto reset=[]
    {
        std::memset(BField,0,sizeof(BField));
        std::memset(BField[2],0xFF,sizeof(BField[2]));
        std::memset(Brole,0,sizeof(Brole));
        BRoleAmount=2;Brole[0].rnum=0;Brole[0].X=10;Brole[0].Y=10;
        Brole[0].Step=4;Brole[1].rnum=1;Brole[1].Team=1;
        Brole[1].X=50;Brole[1].Y=50;
        BField[2][10][10]=0;BField[2][50][50]=1;
        Bx=10;By=10;Ax=10;Ay=10;
    };
    auto corridor=[]
    {
        for(auto& row:BField[1])std::fill(std::begin(row),std::end(row),1);
        for(int x=10;x<=14;++x)BField[1][x][10]=0;
    };

    reset();corridor();BField[0][11][10]=179*2;
    CalCanSelect(0,0,4);
    expect(BField[3][11][10]<0 && BField[3][12][10]<0,
        "water must block movement and propagation through a narrow route");
    CalCanSelect(0,1,2);
    expect(BField[3][12][10]==0,
        "attack/skill mode must retain Pascal Manhattan targeting across terrain");

    reset();corridor();BField[1][12][11]=0;BField[2][12][11]=1;
    Brole[1].X=12;Brole[1].Y=11;
    CalCanSelect(0,0,4);
    expect(BField[3][12][10]==2 && BField[3][13][10]<0,
        "entering enemy adjacency must stop further movement along that route");
    expect(BField[7][12][10]==1,"enemy-adjacent tiles must be marked for path backtracking");
    expect(BField[6][12][10]==2 && BField[6][13][10]<0,
        "the first movement calculation must save its reachability envelope");
    BField[2][10][10]=-1;BField[2][12][10]=0;
    Brole[0].X=12;Brole[0].Y=10;Brole[0].Acted=2;Brole[0].Step=2;
    // This is the Pascal envelope after the first move; set it explicitly so
    // this check also isolates second-move enforcement in the old C++ engine.
    std::memset(BField[6],0xFF,sizeof(BField[6]));
    BField[6][10][10]=0;BField[6][11][10]=1;BField[6][12][10]=2;
    CalCanSelect(0,0,2);
    expect(BField[3][13][10]<0,
        "splitting a move must not escape the first movement envelope");

    reset();corridor();BField[1][10][11]=0;BField[2][10][11]=1;
    Brole[1].X=10;Brole[1].Y=11;
    CalCanSelect(0,0,4);
    expect(BField[3][14][10]==4,
        "an actor may leave enemy adjacency at its initial position");
    Brole[1].Dead=1;BField[2][11][10]=1;
    CalCanSelect(0,0,4);
    expect(BField[3][11][10]==1,
        "a dead actor marker must not block movement like a living actor");

    reset();BField[2][11][12]=1;Brole[1].X=11;Brole[1].Y=12;
    CalCanSelect(0,0,3);Brole[0].Step=3;Ax=12;Ay=11;
    expect(MoveAnimation(0),"a valid alternate path around enemy adjacency must move");
    expect(Brole[0].X==12 && Brole[0].Y==11 && Brole[0].Face==1 && Brole[0].Step==0,
        "backtracking must prefer the path that avoids intermediate enemy-adjacent tiles");

    reset();std::memset(BField[3],0xFF,sizeof(BField[3]));
    BField[3][10][10]=0;BField[3][12][10]=1;Ax=12;Ay=10;
    expect(!MoveAnimation(0),"a broken distance gradient must fail instead of teleporting");
    expect(Brole[0].X==10 && Brole[0].Y==10 && Brole[0].Step==4 && BField[2][10][10]==0,
        "failed path reconstruction must leave actor position, steps and occupancy unchanged");
    check(failures==0,"Battle movement parity regressions failed");
}
void checkEquipmentRemoval()
{
    int failures=0;
    auto expect=[&](bool ok,const char* message)
    {
        if(!ok){std::cerr<<"Equipment removal: "<<message<<'\n';++failures;}
    };
    auto reset=[](int count)
    {
        MAX_ITEM_AMOUNT=3;RItemList={{40,static_cast<int16_t>(count)},{-1,0},{-1,0}};
        Ritem[40]={};Ritem[40].ItemType=1;Ritem[40].EquipType=0;Ritem[40].User=0;
        Rrole[0]={};Rrole[1]={};Rrole[0].Equip[0]=40;Rrole[0].Equip[1]=60;
        Rrole[1].Equip[0]=60;Rrole[1].Equip[1]=-1;Rrole[0].Attack=123;
    };
    reset(1);instruct_32(40,-1);
    expect(Rrole[0].Equip[0]==-1 && Ritem[40].User==-1,
        "handing over the final owned weapon must remove its equipment links");
    expect(Rrole[0].Equip[1]==60 && Rrole[1].Equip[0]==60 && Rrole[0].Attack==123,
        "removal must preserve unrelated equipment and base stats");
    reset(2);instruct_32(40,-1);
    expect(RItemList[0].Amount==1 && Rrole[0].Equip[0]==40 && Ritem[40].User==0,
        "removing part of a stack must retain its equipment links");
    reset(1);instruct_32(40,-3);
    expect(Rrole[0].Equip[0]==-1 && Ritem[40].User==-1,
        "over-removal must also release equipment when the last unit is gone");
    reset(1);Ritem[40].User=1;Rrole[1].Equip[1]=40;instruct_32(40,-1);
    expect(Rrole[0].Equip[0]==-1 && Rrole[1].Equip[1]==-1 && Rrole[1].Equip[0]==60,
        "inconsistent user links must not leave matching ghost equipment behind");
    reset(1);RItemList={{-1,0},{-1,0},{-1,0}};instruct_32(40,-1);
    expect(Rrole[0].Equip[0]==40 && Ritem[40].User==0,
        "an unowned-item removal attempt must not migrate existing links");
    reset(1);Ritem[71]={};Ritem[71].ItemType=2;Ritem[71].User=0;
    Rrole[0].PracticeBook=71;RItemList={{71,1},{-1,0},{-1,0}};instruct_32(71,-1);
    expect(Rrole[0].PracticeBook==71 && Ritem[71].User==0 && Rrole[0].Equip[0]==40,
        "equipment correction must not change legacy practice-book behavior");
    check(failures==0,"Equipment removal regressions failed");
}
void checkHiddenWeaponPoison(TestFrontend& frontend)
{
    struct Case { int itemPoison,resistance,before,after; };
    int failures=0;
    frontend.aimAccepted=true;
    for(auto c:{Case{80,0,0,80},Case{80,60,0,32},Case{100,99,0,1},
                Case{80,100,0,0},Case{80,112,0,0},Case{80,112,30,30},Case{80,60,90,99}})
    {
        std::memset(BField,0,sizeof(BField));std::memset(BField[2],0xFF,sizeof(BField[2]));
        std::memset(Brole,0,sizeof(Brole));Rrole[0]={};Rrole[1]={};Ritem[0]={};
        BRoleAmount=2;Brole[0].rnum=0;Brole[0].X=10;Brole[0].Y=10;
        Brole[1].rnum=1;Brole[1].Team=1;Brole[1].X=11;Brole[1].Y=10;
        BField[2][10][10]=0;BField[2][11][10]=1;Ax=11;Ay=10;
        Rrole[0].HidWeapon=90;Rrole[1].CurrentHP=1000;Rrole[1].MaxHP=1000;
        Rrole[1].DefPoi=c.resistance;Rrole[1].Poison=c.before;
        Ritem[0].ItemType=4;Ritem[0].AddCurrentHP=-80;Ritem[0].AddPoi=c.itemPoison;
        RItemList={{0,2},{-1,0},{-1,0}};HeadlessRandomState=7;
        UseHiddenWeapon(0,0);
        if(Rrole[1].Poison!=c.after)
        {
            std::cerr<<"Hidden weapon poison: resistance="<<c.resistance<<" before="<<c.before
                <<" expected="<<c.after<<" actual="<<Rrole[1].Poison<<'\n';++failures;
        }
        check(Rrole[1].CurrentHP<1000,"Poison immunity must not remove hidden-weapon HP damage");
        check(RItemList[0].Amount==1,"Poison immunity must not bypass hidden-weapon item consumption");
        check(Brole[0].Acted==1,"A hidden-weapon use must consume the native action");
    }
    frontend.aimAccepted=false;
    check(failures==0,"Hidden-weapon poison boundary regressions failed");
}
int main()
{
    try
    {
        TestFrontend frontend;Frontend=&frontend;
        std::fill(std::begin(TeamList),std::end(TeamList),-1);
        TeamList[0]=0;Rscene[0].EnCondition=2;Rrole[0].Speed=70;
        check(!CheckCanEnter(0),"Speed 70 must not open condition 2");
        Rrole[0].Speed=71;check(CheckCanEnter(0),"Speed 71 must open condition 2");
        TeamList[0]=-1;check(!CheckCanEnter(0),"Absent role cannot satisfy entry gate");
        Rscene[0].EnCondition=1;check(!CheckCanEnter(0),"Condition 1 remains locked");
        Rscene[0].EnCondition=0;check(CheckCanEnter(0),"Condition 0 is open");

        const char packed[]={'A','B','C','D'};
        check(cp950toutf8(packed,3)=="ABC","Fixed-field decoder must respect length");
        const char terminated[]={'A','\0','B'};
        check(cp950toutf8(terminated,3)=="A","Fixed-field decoder must stop at embedded terminator");

        MAX_ITEM_AMOUNT=3;RItemList={{0,1},{1,1},{2,1}};
        instruct_32(3,1);check(RItemList.size()==3 && RItemList[2].Number==2,"Full inventory must not write beyond its capacity");
        instruct_32(1,-1);check(RItemList[2].Number==-1,"Zero-count items must be removed");
        instruct_32(3,1);check(RItemList[2].Number==3,"Freed inventory slot must be reusable");
        instruct_32(3,32767);check(RItemList[2].Amount==32767,"Item count must saturate without wrapping");

        HeadlessRandomState=123;auto first=GameRandom();HeadlessRandomState=123;
        check(GameRandom()==first,"Headless RNG must replay after restore");
        check(screen==nullptr && window==nullptr && render==nullptr,"Headless tests must not create graphics objects");
        KIdx={2};KDef={1,0};bool rejected=false;
        try {CallEvent(0);}catch(const std::runtime_error&){rejected=true;}
        check(rejected,"Truncated event operands must fail before access");
        for (auto end : {-2, 1, 100})
        {
            KIdx={end};rejected=false;
            try {CallEvent(0);}catch(const std::runtime_error&){rejected=true;}
            check(rejected,"Malformed event byte ranges must fail before copying");
        }
        checkEquipmentRemoval();
        checkBattleMovement();
        checkHiddenWeaponPoison(frontend);
        Frontend=nullptr;std::cout<<"Core regression checks passed\n";
    }
    catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
