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
int main()
{
    try
    {
        TestFrontend frontend;Frontend=&frontend;
        HeadlessRandomState=123;auto first=GameRandom();HeadlessRandomState=123;
        check(GameRandom()==first,"Headless RNG must replay after restore");
        check(screen==nullptr && window==nullptr && render==nullptr,"Headless tests must not create graphics objects");
        Frontend=nullptr;std::cout<<"Frontend regression checks passed\n";
    }
    catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
