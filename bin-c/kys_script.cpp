// kys_script.cpp - Lua脚本系统实现
// 对应 kys_script.pas

#include "kys_script.h"
#include "filefunc.h"
#include "kys_battle.h"
#include "kys_draw.h"
#include "kys_engine.h"
#include "kys_event.h"
#include "kys_main.h"
#include "kys_type.h"

#include <SDL3/SDL.h>
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

extern "C"
{
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

// 自定义lua_tointeger: 处理instruct_50e code 32改写
long long lua_tointeger_custom(lua_State* L, int pos)
{
    int n = lua_gettop(L);
    long long result = lua_tointeger(L, pos);
    int realpos = (pos < 0) ? (n + pos + 1) : pos;
    if (realpos == Script5032Pos)
    {
        result = Script5032Value;
        Script5032Pos = -100;
    }
    return result;
}

#define LI(pos) ((int)lua_tointeger_custom(L, pos))

// ---- Lua函数实现 ----

int Lua_Blank(lua_State* L) { return 0; }

int Lua_Pause(lua_State* L)
{
    lua_pushnumber(L, WaitAnyKey());
    return 1;
}

int Lua_GetMousePosition(lua_State* L)
{
    SDL_PollEvent(&event);
    float fx, fy;
    SDL_GetMouseState(&fx, &fy);
    lua_pushnumber(L, (int)fx);
    lua_pushnumber(L, (int)fy);
    return 2;
}

int Lua_ClearButton(lua_State* L)
{
    event.key.key = 0;
    event.button.button = 0;
    return 0;
}

int Lua_CheckButton(lua_State* L)
{
    SDL_PollEvent(&event);
    lua_pushnumber(L, (event.button.button > 0) ? 1 : 0);
    SDL_Delay(10);
    return 1;
}

int Lua_GetButton(lua_State* L)
{
    lua_pushnumber(L, event.key.key);
    lua_pushnumber(L, event.button.button);
    return 2;
}

int Lua_GetTime(lua_State* L)
{
    lua_pushnumber(L, (int)(SDL_GetTicks() / 1000));
    return 1;
}

int Lua_ExecEvent(lua_State* L)
{
    int n = lua_gettop(L);
    int e = LI(-n);
    for (int i = 0; i < n - 1; i++)
    {
        x50[0x7100 + i] = LI(-n + 1 + i);
    }
    CallEvent(e);
    return 0;
}

int Lua_CallEvent_s(lua_State* L)
{
    CallEvent(LI(-1));
    return 0;
}

int Lua_Clear(lua_State* L)
{
    Redraw();
    return 0;
}

int Lua_OldTalk(lua_State* L)
{
    instruct_1(LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_Talk(lua_State* L)
{
    int rnum = LI(3);
    int dismode = LI(2);
    const char* content = lua_tostring(L, 1);
    talk_1(content ? content : "", dismode, rnum);
    return 0;
}

int Lua_GetItem(lua_State* L)
{
    instruct_2(LI(-2), LI(-1));
    return 0;
}

int Lua_AddItem(lua_State* L)
{
    instruct_32(LI(-2), LI(-1));
    return 0;
}

int Lua_ShowString(lua_State* L)
{
    // 参数: showstring(x, y, str [, color1, color2])  pig3约定
    uint32_t color1 = ColColor(5);
    uint32_t color2 = ColColor(7);
    int n = lua_gettop(L);
    int x = LI(1);
    int y = LI(2);
    const char* str = lua_tostring(L, 3);
    if (n >= 5)
    {
        color1 = (uint32_t)LI(4);
        color2 = (uint32_t)LI(5);
    }
    DrawShadowText(str ? str : "", x, y, color1, color2);
    UpdateAllScreen();
    return 0;
}

int Lua_ShowStringWithBox(lua_State* L)
{
    // 参数: showstringwithbox(x, y, str [, alpha [, color1, color2]])  pig3约定
    // pig3对齐: 仅显示不等待按键
    int alpha = 0;
    uint32_t color1 = ColColor(5);
    uint32_t color2 = ColColor(7);
    int n = lua_gettop(L);
    int x = LI(1);
    int y = LI(2);
    const char* str = lua_tostring(L, 3);
    if (n >= 4) alpha = LI(4);
    if (n >= 6)
    {
        color1 = (uint32_t)LI(5);
        color2 = (uint32_t)LI(6);
    }
    int w = DrawLength(str ? str : "");
    DrawRectangle(screen, x, y - 2, w * 10 + 5, 27, 0, ColColor(255), alpha);
    DrawShadowText(str ? str : "", x + 3, y, color1, color2);
    UpdateAllScreen();
    return 0;
}

int Lua_Menu(lua_State* L)
{
    int n = LI(-1);
    int len = (int)luaL_len(L, -2);
    n = std::min(n, len);
    std::vector<std::string> menuStr(n);
    int maxwidth = 0;
    for (int i = 0; i < n; i++)
    {
        lua_pushinteger(L, i + 1);
        lua_gettable(L, -3);
        const char* p = lua_tostring(L, -1);
        menuStr[i] = p ? p : "";
        int w = DrawLength(menuStr[i]);
        if (w > maxwidth)
        {
            maxwidth = w;
        }
        lua_pop(L, 1);
    }
    int y = LI(-3), x = LI(-4);
    int w = maxwidth * 10 + 8;
    lua_pushinteger(L, CommonScrollMenu(x, y, w, n - 1, 15, menuStr.data()) + 1);
    return 1;
}

int Lua_AskYesOrNo(lua_State* L)
{
    std::string ms[3] = { " 否", " 是", "" };
    int y = LI(-2), x = LI(-1);
    lua_pushnumber(L, CommonMenu2(x, y, 78, ms));
    return 1;
}

int Lua_ModifyEvent(lua_State* L)
{
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++)
    {
        x[i] = LI(-(n - i));
    }
    if (n == 13)
    {
        instruct_3(x);
    }
    if (n == 4)
    {
        if (x[0] == -2)
        {
            x[0] = CurScene;
        }
        if (x[1] == -2)
        {
            x[1] = CurEvent;
        }
        DData[x[0]][x[1]][x[2]] = x[3];
    }
    return 0;
}

int Lua_UseItem(lua_State* L)
{
    int n = lua_gettop(L);
    int inum = LI(-1);
    if (n == 3)
    {
        inum = LI(-3);
    }
    lua_pushboolean(L, inum == CurItem);
    return 1;
}

int Lua_HaveItem(lua_State* L)
{
    int inum = LI(-1), n = 0;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++)
    {
        if (RItemList[i].Number == inum)
        {
            n = RItemList[i].Amount;
            break;
        }
    }
    lua_pushnumber(L, n);
    return 1;
}

int Lua_HaveItemBool(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_18(LI(-n), 1, 0) == 1);
    return 1;
}

int Lua_AnotherGetItem(lua_State* L)
{
    instruct_41(LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_CompareProInTeam(lua_State* L)
{
    int n = 0;
    for (int i = 0; i < 6; i++)
    {
        if (TeamList[i] >= 0 && Rrole[TeamList[i]].Data[LI(-2)] == LI(-1))
        {
            n++;
        }
    }
    lua_pushnumber(L, n);
    return 1;
}

int Lua_AllLeave(lua_State* L)
{
    instruct_59();
    return 0;
}

int Lua_AskBattle(lua_State* L)
{
    lua_pushboolean(L, instruct_5(1, 0) == 1);
    return 1;
}

int Lua_TryBattle(lua_State* L)
{
    int n = lua_gettop(L);
    int t = LI(-n);
    lua_pushboolean(L, Battle(t, LI(-1)));
    return 1;
}

int Lua_AskJoin(lua_State* L)
{
    lua_pushboolean(L, instruct_9(1, 0) == 1);
    return 1;
}

int Lua_Join(lua_State* L)
{
    instruct_10(LI(-1));
    return 0;
}

int Lua_AskRest(lua_State* L)
{
    lua_pushboolean(L, instruct_11(1, 0) == 1);
    return 1;
}

int Lua_Rest(lua_State* L)
{
    instruct_12();
    return 0;
}
int Lua_LightScene(lua_State* L)
{
    instruct_13();
    return 0;
}
int Lua_DarkScene(lua_State* L)
{
    instruct_14();
    return 0;
}
int Lua_Dead(lua_State* L)
{
    instruct_15();
    return 0;
}

int Lua_InTeam(lua_State* L)
{
    lua_pushboolean(L, instruct_16(LI(-lua_gettop(L)), 1, 0) == 1);
    return 1;
}

int Lua_TeamIsFull(lua_State* L)
{
    lua_pushboolean(L, instruct_20(1, 0) == 1);
    return 1;
}

int Lua_LeaveTeam(lua_State* L)
{
    instruct_21(LI(-1));
    return 0;
}

int Lua_LearnMagic(lua_State* L)
{
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++)
    {
        x[i] = LI(-(n - i));
    }
    if (n == 2)
    {
        instruct_33(x[0], x[1], 0);
    }
    if (n == 3)
    {
        StudyMagic(x[0], 0, x[1], x[2], 0);
    }
    if (n == 4)
    {
        StudyMagic(x[0], x[1], x[2], x[3], 0);
    }
    return 0;
}

int Lua_OldLearnMagic(lua_State* L)
{
    instruct_33(LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_GetMainMapPosition(lua_State* L)
{
    lua_pushnumber(L, My);
    lua_pushnumber(L, Mx);
    return 2;
}

int Lua_SetMainMapPosition(lua_State* L)
{
    Mx = LI(-1);
    My = LI(-2);
    return 0;
}

int Lua_GetScenePosition(lua_State* L)
{
    lua_pushnumber(L, Sy);
    lua_pushnumber(L, Sx);
    return 2;
}

int Lua_SetScenePosition(lua_State* L)
{
    Sx = LI(-1);
    Sy = LI(-2);
    return 0;
}

int Lua_OldSetScenePosition(lua_State* L)
{
    instruct_19(LI(-2), LI(-1));
    return 0;
}

int Lua_GetSceneFace(lua_State* L)
{
    lua_pushnumber(L, SFace);
    return 1;
}

int Lua_SetSceneFace(lua_State* L)
{
    SFace = LI(-1);
    return 0;
}

int Lua_Delay(lua_State* L)
{
    SDL_Delay(LI(-1));
    return 0;
}

int Lua_DrawRect(lua_State* L)
{
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++)
    {
        x[i] = LI(-(n - i));
    }
    if (n == 7)
    {
        DrawRectangle(screen, x[0], x[1], x[2], x[3], x[4], x[5], x[6]);
    }
    if (n == 6)
    {
        DrawRectangleWithoutFrame(screen, x[0], x[1], x[2], x[3], x[4], x[5]);
    }
    if (n == 4)
    {
        DrawRectangle(screen, x[0], x[1], x[2], x[3], 0, ColColor(255), 50);
    }
    return 0;
}

int Lua_MemberAmount(lua_State* L)
{
    int n = 0;
    for (int i = 0; i < 6; i++)
    {
        if (TeamList[i] >= 0)
        {
            n++;
        }
    }
    lua_pushnumber(L, n);
    return 1;
}

int Lua_GetMember(lua_State* L)
{
    int n = LI(-1);
    lua_pushnumber(L, (n >= 0 && n <= 5) ? TeamList[n] : 0);
    return 1;
}

int Lua_PutMember(lua_State* L)
{
    TeamList[LI(-1)] = LI(-2);
    return 0;
}

int Lua_GetRolePro(lua_State* L)
{
    lua_pushnumber(L, Rrole[LI(-2)].Data[LI(-1)]);
    return 1;
}

int Lua_PutRolePro(lua_State* L)
{
    Rrole[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

int Lua_GetItemPro(lua_State* L)
{
    lua_pushnumber(L, Ritem[LI(-2)].Data[LI(-1)]);
    return 1;
}

int Lua_PutItemPro(lua_State* L)
{
    Ritem[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

int Lua_GetMagicPro(lua_State* L)
{
    lua_pushnumber(L, Rmagic[LI(-2)].Data[LI(-1)]);
    return 1;
}

int Lua_PutMagicPro(lua_State* L)
{
    Rmagic[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

int Lua_GetScenePro(lua_State* L)
{
    lua_pushnumber(L, Rscene[LI(-2)].Data[LI(-1)]);
    return 1;
}

int Lua_PutScenePro(lua_State* L)
{
    Rscene[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

int Lua_GetSceneMapPro(lua_State* L)
{
    lua_pushnumber(L, SData[LI(-4)][LI(-3)][LI(-2)][LI(-1)]);
    return 1;
}

int Lua_PutSceneMapPro(lua_State* L)
{
    SData[LI(-5)][LI(-4)][LI(-3)][LI(2)] = LI(-1);
    return 0;
}

int Lua_OldPutSceneMapPro(lua_State* L)
{
    std::vector<int> list(5);
    for (int i = 0; i < 5; i++)
    {
        list[i] = LI(i - 5);
    }
    instruct_17(list);
    return 0;
}

int Lua_GetSceneEventPro(lua_State* L)
{
    lua_pushnumber(L, DData[LI(-3)][LI(-2)][LI(-1)]);
    return 1;
}

int Lua_PutSceneEventPro(lua_State* L)
{
    DData[LI(-4)][LI(-3)][LI(-2)] = LI(-1);
    return 0;
}

int Lua_JudgeSceneEvent(lua_State* L)
{
    int t = (DData[CurScene][LI(-3)][2 + LI(-2)] == LI(-1)) ? 1 : 0;
    lua_pushnumber(L, t);
    return 1;
}

int Lua_PlayMusic(lua_State* L)
{
    instruct_66(LI(-1));
    return 0;
}
int Lua_PlayWave(lua_State* L)
{
    instruct_67(LI(-1));
    return 0;
}

int Lua_WalkFromTo(lua_State* L)
{
    instruct_30(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_SceneFromTo(lua_State* L)
{
    instruct_25(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_PlayAnimation(lua_State* L)
{
    instruct_27(LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_GetNameAsString(lua_State* L)
{
    int typenum = LI(-2), num = LI(-1);
    std::string str;
    switch (typenum)
    {
    case 0: str = cp950toutf8(Rrole[num].Name); break;
    case 1: str = cp950toutf8(Ritem[num].Name); break;
    case 2: str = cp950toutf8(Rscene[num].Name); break;
    case 3: str = cp950toutf8(Rmagic[num].Name); break;
    }
    lua_pushstring(L, str.c_str());
    return 1;
}

int Lua_ChangeScene(lua_State* L)
{
    int n = lua_gettop(L);
    CurScene = LI(-n);
    int x, y;
    if (n == 1)
    {
        x = Rscene[CurScene].EntranceX;
        y = Rscene[CurScene].EntranceY;
    }
    else
    {
        x = LI(-n + 1);
        y = LI(-n + 2);
    }
    Cx = x + Cx - Sx;
    Cy = y + Cy - Sy;
    Sx = x;
    Sy = y;
    instruct_14();
    InitialScene(0);
    DrawScene();
    instruct_13();
    ShowSceneName(CurScene);
    CheckEvent3();
    return 0;
}

int Lua_ShowPicture(lua_State* L)
{
    int n = lua_gettop(L);
    int x = LI(-2), y = LI(-1);
    if (n == 4)
    {
        int t = LI(-4), p = LI(-3);
        switch (t)
        {
        case 0: DrawMPic(p, x, y); break;
        case 1: DrawSPic(p, x, y, 0, 0, screen->w, screen->h); break;
        case 2: DrawBPic(p, x, y, 0); break;
        case 3: DrawHeadPic(p, x, y); break;
        case 4: DrawEPic(p, x, y); break;
        }
    }
    if (n == 3)
    {
        display_img(lua_tostring(L, -3), x, y);
    }
    return 0;
}

int Lua_GetItemList(lua_State* L)
{
    int i = LI(-1);
    lua_pushnumber(L, RItemList[i].Number);
    lua_pushnumber(L, RItemList[i].Amount);
    return 2;
}

int Lua_GetCurrentScene(lua_State* L)
{
    lua_pushnumber(L, CurScene);
    return 1;
}
int Lua_GetCurrentEvent(lua_State* L)
{
    lua_pushnumber(L, CurEvent);
    return 1;
}

int Lua_GetBattleNumber(lua_State* L)
{
    int n = lua_gettop(L);
    if (n == 0)
    {
        lua_pushnumber(L, x50[28005]);
    }
    if (n == 1)
    {
        int rnum = LI(-1), t = -1;
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (Brole[i].rnum == rnum)
            {
                t = i;
                break;
            }
        }
        lua_pushnumber(L, t);
    }
    return 1;
}

int Lua_SelectOneAim(lua_State* L)
{
    if (LI(-1) == 0)
    {
        SelectAim(LI(-3), LI(-2));
    }
    lua_pushnumber(L, BField[2][Ax][Ay]);
    return 1;
}

int Lua_GetBattleRolePro(lua_State* L)
{
    lua_pushnumber(L, Brole[LI(-2)].Data[LI(-1)]);
    return 1;
}

int Lua_PutBattleRolePro(lua_State* L)
{
    Brole[LI(-2)].Data[LI(-1)] = LI(-3);
    return 0;
}

int Lua_PlayAction(lua_State* L)
{
    int bnum = LI(-3), mtype = LI(-2);
    PlayActionAmination(bnum, mtype);
    PlayMagicAmination(bnum, mtype);
    return 0;
}

int Lua_PlayHurtValue(lua_State* L)
{
    ShowHurtValue(LI(-1));
    return 0;
}

int Lua_SetAminationLayer(lua_State* L)
{
    int x = LI(-5), y = LI(-4), w = LI(-3), h = LI(-2), t = LI(-1);
    for (int i1 = x; i1 < x + w; i1++)
    {
        for (int i2 = y; i2 < y + h; i2++)
        {
            BField[4][i1][i2] = t;
        }
    }
    return 0;
}

int Lua_ClearRoleFromBattle(lua_State* L)
{
    Brole[LI(-1)].Dead = 1;
    return 0;
}

int Lua_AddRoleIntoBattle(lua_State* L)
{
    int bnum = BRoleAmount++;
    int team = LI(-4), rnum = LI(-3), x = LI(-2), y = LI(-1);
    Brole[bnum].rnum = rnum;
    Brole[bnum].Team = team;
    Brole[bnum].X = x;
    Brole[bnum].Y = y;
    Brole[bnum].Face = 1;
    Brole[bnum].Dead = 0;
    Brole[bnum].Step = 0;
    Brole[bnum].Acted = 1;
    Brole[bnum].ShowNumber = -1;
    Brole[bnum].ExpGot = 0;
    lua_pushnumber(L, bnum);
    return 1;
}

int Lua_ForceBattleResult(lua_State* L)
{
    BattleResult = LI(-1);
    return 0;
}

int Lua_AskSoftStar(lua_State* L)
{
    instruct_51();
    return 0;
}
int Lua_WeiShop(lua_State* L)
{
    instruct_64();
    return 0;
}
int Lua_OpenAllScene(lua_State* L)
{
    instruct_54();
    return 0;
}
int Lua_ShowEthics(lua_State* L)
{
    instruct_52();
    return 0;
}
int Lua_ShowRepute(lua_State* L)
{
    instruct_53();
    return 0;
}
int Lua_ChangeMMapMusic(lua_State* L)
{
    instruct_8(LI(-1));
    return 0;
}
int Lua_ZeroAllMP(lua_State* L)
{
    instruct_22();
    return 0;
}
int Lua_SetOneUsePoi(lua_State* L)
{
    instruct_23(LI(-2), LI(-1));
    return 0;
}
int Lua_Add3EventNum(lua_State* L)
{
    instruct_26(LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_Judge5Item(lua_State* L)
{
    std::vector<int> list(7);
    for (int i = 0; i < 7; i++)
    {
        list[i] = LI(i - 7);
    }
    int n = instruct_50(list);
    lua_pushboolean(L, n == list[5]);
    return 1;
}

int Lua_JudgeEthics(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_28(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

int Lua_JudgeAttack(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_29(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

int Lua_JudgeMoney(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_31(LI(-n), 1, 0) == 1);
    return 1;
}

int Lua_AddAptitude(lua_State* L)
{
    instruct_34(LI(-2), LI(-1));
    return 0;
}
int Lua_SetOneMagic(lua_State* L)
{
    instruct_35(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_JudgeSexual(lua_State* L)
{
    lua_pushboolean(L, instruct_36(LI(-lua_gettop(L)), 1, 0) == 1);
    return 1;
}

int Lua_AddEthics(lua_State* L)
{
    instruct_37(LI(-1));
    return 0;
}
int Lua_ChangeScenePic(lua_State* L)
{
    instruct_38(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}
int Lua_OpenScene(lua_State* L)
{
    instruct_39(LI(-1));
    return 0;
}

int Lua_JudgeFemaleInTeam(lua_State* L)
{
    lua_pushboolean(L, instruct_42(1, 0) == 1);
    return 1;
}

int Lua_Play2Amination(lua_State* L)
{
    instruct_44(LI(-6), LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_AddSpeed(lua_State* L)
{
    instruct_45(LI(-2), LI(-1));
    return 0;
}
int Lua_AddMP(lua_State* L)
{
    instruct_46(LI(-2), LI(-1));
    return 0;
}
int Lua_AddAttack(lua_State* L)
{
    instruct_47(LI(-2), LI(-1));
    return 0;
}
int Lua_AddHP(lua_State* L)
{
    instruct_48(LI(-2), LI(-1));
    return 0;
}
int Lua_SetMPPro(lua_State* L)
{
    instruct_49(LI(-2), LI(-1));
    return 0;
}

int Lua_JudgeEventNum(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_55(LI(-n), LI(1 - n), 1, 0) == 1);
    return 1;
}

int Lua_AddRepute(lua_State* L)
{
    instruct_56(LI(-1));
    return 0;
}
int Lua_BreakStoneGate(lua_State* L)
{
    instruct_57();
    return 0;
}
int Lua_FightForTop(lua_State* L)
{
    instruct_58();
    return 0;
}

int Lua_JudgeScenePic(lua_State* L)
{
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_60(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

int Lua_Judge14BooksPlaced(lua_State* L)
{
    lua_pushboolean(L, instruct_61(1, 0) == 1);
    return 1;
}

int Lua_SetSexual(lua_State* L)
{
    instruct_63(LI(-2), LI(-1));
    return 0;
}

int Lua_BackHome(lua_State* L)
{
    instruct_62(LI(-6), LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_EatOneItemScript(lua_State* L)
{
    int n = lua_gettop(L);
    if (n == 2)
    {
        EatOneItem(LI(-n), LI(1 - n));
    }
    return 0;
}

int Lua_SelectOneTeamMemberScript(lua_State* L)
{
    const char* s = lua_tostring(L, -3);
    lua_pushnumber(L, SelectOneTeamMember(0, 0, s ? s : "", LI(-2), LI(-1)));
    return 1;
}

int Lua_setteam(lua_State* L)
{
    TeamList[LI(-2)] = LI(-1);
    return 0;
}
int Lua_getteam(lua_State* L)
{
    lua_pushnumber(L, TeamList[LI(-1)]);
    return 1;
}

int Lua_readmem(lua_State* L)
{
    int x = LI(-1);
    instruct_50e(26, 0, 0, x % 65536, x / 65536, 9999, 0);
    lua_pushnumber(L, x50[9999]);
    return 1;
}

int Lua_writemem(lua_State* L)
{
    int x = LI(-2);
    x50[9999] = LI(-1);
    instruct_50e(25, 1, 0, x % 65536, x / 65536, 9999, 0);
    return 0;
}

int Lua_getrolename(lua_State* L)
{
    lua_pushstring(L, cp950toutf8(Rrole[LI(-1)].Name).c_str());
    return 1;
}

int Lua_getitemname(lua_State* L)
{
    lua_pushstring(L, cp950toutf8(Ritem[LI(-1)].Name).c_str());
    return 1;
}

int Lua_getmagicname(lua_State* L)
{
    lua_pushstring(L, cp950toutf8(Rmagic[LI(-1)].Name).c_str());
    return 1;
}

int Lua_getsubmapname(lua_State* L)
{
    lua_pushstring(L, cp950toutf8(Rscene[LI(-1)].Name).c_str());
    return 1;
}

int Lua_drawlength_s(lua_State* L)
{
    const char* s = lua_tostring(L, -1);
    lua_pushinteger(L, DrawLength(s ? s : ""));
    return 1;
}

int Lua_getkey(lua_State* L)
{
    lua_pushinteger(L, WaitAnyKey());
    return 1;
}

int Lua_gettalk(lua_State* L)
{
    int talknum = LI(-1);
    std::string str = ReadTalk(talknum);
    lua_pushstring(L, str.c_str());
    return 1;
}

// ---- pig3 同步新增函数 ----

int Lua_GetGlobalValue(lua_State* L)
{
    int n1 = LI(-2);
    int n2 = LI(-1);
    if (n1 >= 0 && n1 <= 10 && n2 >= 0 && n2 <= 14)
        lua_pushinteger(L, RShop[n1].Data[n2]);
    else
        lua_pushinteger(L, -2);
    return 1;
}

int Lua_SetGlobalValue(lua_State* L)
{
    int n1 = LI(-2);
    int n2 = LI(-1);
    int val = LI(-3);
    if (n1 >= 0 && n1 <= 10 && n2 >= 0 && n2 <= 14)
        RShop[n1].Data[n2] = val;
    return 0;
}

int Lua_GetX50(lua_State* L)
{
    lua_pushinteger(L, x50[LI(-1)]);
    return 1;
}

int Lua_SetX50(lua_State* L)
{
    int idx = LI(1);
    if (lua_isstring(L, 2))
    {
        const char* str = lua_tostring(L, 2);
        char* p = (char*)&x50[idx];
        int len = (int)strlen(str);
        for (int i = 0; i < len; i++)
            p[i] = str[i];
    }
    else
        x50[idx] = LI(2);
    return 0;
}

int Lua_ShowTitle(lua_State* L)
{
    int n = lua_gettop(L);
    int talknum = LI(-n);
    std::string str;
    if (!lua_isnumber(L, -n))
        str = lua_tostring(L, -n) ? lua_tostring(L, -n) : "";
    int color = 1;
    if (n > 1)
        color = LI(-1);
    NewTalk(0, talknum, -1, 2, 1, color, 0, str);
    return 0;
}

int Lua_ReadTalkAsString(lua_State* L)
{
    std::string str = ReadTalk(LI(-1));
    lua_pushstring(L, str.c_str());
    return 1;
}

int Lua_CheckJumpFlag(lua_State* L)
{
    lua_pushboolean(L, instruct_36(256, 1, 0) == 1);
    return 1;
}

int Lua_ExitScript(lua_State* L)
{
    lua_pushstring(L, "exit()");
    lua_error(L);
    return 1;
}

int Lua_ColColor(lua_State* L)
{
    lua_pushinteger(L, (int)ColColor((uint8_t)LI(-1)));
    return 1;
}

int Lua_ShowSimpleStatus(lua_State* L)
{
    ShowSimpleStatus(LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_UpdateAllScreen(lua_State* L)
{
    UpdateAllScreen();
    return 0;
}

int Lua_SetItemIntro(lua_State* L)
{
    int itemnum = LI(-2);
    const char* str = lua_tostring(L, -1);
    if (!str) return 0;
    int len = (int)strlen(str);
    int maxlen = (int)sizeof(Ritem[itemnum].Introduction) - 1;
    if (len > maxlen) len = maxlen;
    memset(Ritem[itemnum].Introduction, 0, sizeof(Ritem[itemnum].Introduction));
    memcpy(Ritem[itemnum].Introduction, str, len);
    return 0;
}

int Lua_ShowStatus(lua_State* L)
{
    ShowStatus(LI(-1));
    UpdateAllScreen();
    return 0;
}

int Lua_SetNameAsString(lua_State* L)
{
    int typenum = LI(-2);
    int num = LI(-1);
    char* p = nullptr;
    switch (typenum)
    {
    case 0: p = Rrole[num].Name; break;
    case 1: p = Ritem[num].Name; break;
    case 2: p = Rscene[num].Name; break;
    case 3: p = Rmagic[num].Name; break;
    }
    if (p)
    {
        const char* s = lua_tostring(L, -3);
        int len = s ? (int)strlen(s) : 0;
        int maxlen = 15; // Name字段最大长度
        if (len > maxlen) len = maxlen;
        for (int i = 0; i <= len; i++)
            p[i] = (i < len) ? s[i] : 0;
    }
    return 0;
}

int Lua_SetAttribute(lua_State* L)
{
    SetAttribute(LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

int Lua_EnterNumber(lua_State* L)
{
    lua_pushinteger(L, EnterNumber(LI(-5), LI(-4), LI(-3), LI(-2), LI(-1)));
    return 1;
}

int Lua_SetRoleFace(lua_State* L)
{
    instruct_40(LI(-1));
    return 0;
}

int Lua_HaveItemAmount(lua_State* L)
{
    int inum = LI(-1), count = 0;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++)
    {
        if (RItemList[i].Number == inum)
            count += RItemList[i].Amount;
    }
    lua_pushinteger(L, count);
    return 1;
}

int Lua_GetScreenSize(lua_State* L)
{
    lua_pushinteger(L, CENTER_X * 2);
    lua_pushinteger(L, CENTER_Y * 2);
    return 2;
}

// ---- 初始化/销毁 ----

void InitialScript()
{
    Lua_script = luaL_newstate();
    luaL_openlibs(Lua_script);

    auto R = [](const char* name, lua_CFunction f)
    {
        lua_register(Lua_script, name, f);
    };

    R("pause", Lua_Pause);
    R("getmouseposition", Lua_GetMousePosition);
    R("clearbutton", Lua_ClearButton);
    R("checkbutton", Lua_CheckButton);
    R("getbutton", Lua_GetButton);
    R("gettime", Lua_GetTime);
    R("execevent", Lua_ExecEvent);
    R("callevent", Lua_CallEvent_s);
    R("clear", Lua_Clear);
    R("talk", Lua_Talk);
    R("getitem", Lua_GetItem);
    R("additem", Lua_GetItem);
    R("showstring", Lua_ShowString);
    R("drawstring", Lua_ShowString);
    R("showstringwithbox", Lua_ShowStringWithBox);
    R("showmessage", Lua_ShowStringWithBox);
    R("menu", Lua_Menu);
    R("askyesorno", Lua_AskYesOrNo);
    R("modifyevent", Lua_ModifyEvent);
    R("useitem", Lua_UseItem);
    R("haveitem", Lua_HaveItem);
    R("haveitembool", Lua_HaveItemBool);
    R("anothergetitem", Lua_AnotherGetItem);
    R("compareprointeam", Lua_CompareProInTeam);
    R("allleave", Lua_AllLeave);
    R("askbattle", Lua_AskBattle);
    R("trybattle", Lua_TryBattle);
    R("askjoin", Lua_AskJoin);
    R("join", Lua_Join);
    R("askrest", Lua_AskRest);
    R("rest", Lua_Rest);
    R("lightscene", Lua_LightScene);
    R("darkscene", Lua_DarkScene);
    R("dead", Lua_Dead);
    R("inteam", Lua_InTeam);
    R("teamisfull", Lua_TeamIsFull);
    R("leaveteam", Lua_LeaveTeam);
    R("learnmagic", Lua_LearnMagic);
    R("getmainmapposition", Lua_GetMainMapPosition);
    R("setmainmapposition", Lua_SetMainMapPosition);
    R("getsceneposition", Lua_GetScenePosition);
    R("setsceneposition", Lua_SetScenePosition);
    R("getsceneface", Lua_GetSceneFace);
    R("setsceneface", Lua_SetSceneFace);
    R("delay", Lua_Delay);
    R("lib.delay", Lua_Delay);
    R("drawrect", Lua_DrawRect);
    R("memberamount", Lua_MemberAmount);
    R("getmember", Lua_GetMember);
    R("setmember", Lua_PutMember);
    R("getrole", Lua_GetRolePro);
    R("setrole", Lua_PutRolePro);
    R("getitem", Lua_GetItemPro);
    R("setitem", Lua_PutItemPro);
    R("getmagic", Lua_GetMagicPro);
    R("setmagic", Lua_PutMagicPro);
    R("getsubmapinfo", Lua_GetScenePro);
    R("setsubmapinfo", Lua_PutScenePro);
    R("gets", Lua_GetSceneMapPro);
    R("sets", Lua_PutSceneMapPro);
    R("getd", Lua_GetSceneEventPro);
    R("setd", Lua_PutSceneEventPro);
    R("judgesceneevent", Lua_JudgeSceneEvent);
    R("playmusic", Lua_PlayMusic);
    R("playwave", Lua_PlayWave);
    R("walkfromto", Lua_WalkFromTo);
    R("scenefromto", Lua_SceneFromTo);
    R("playanimation", Lua_PlayAnimation);
    R("getnameasstring", Lua_GetNameAsString);
    R("changescene", Lua_ChangeScene);
    R("showpicture", Lua_ShowPicture);
    R("getitemlist", Lua_GetItemList);
    R("getcurrentscene", Lua_GetCurrentScene);
    R("getcurrentevent", Lua_GetCurrentEvent);
    R("getbattlenumber", Lua_GetBattleNumber);
    R("selectoneaim", Lua_SelectOneAim);
    R("getbattlerolepro", Lua_GetBattleRolePro);
    R("putbattlerolepro", Lua_PutBattleRolePro);
    R("playaction", Lua_PlayAction);
    R("playhurtvalue", Lua_PlayHurtValue);
    R("setaminationlayer", Lua_SetAminationLayer);
    R("clearrolefrombattle", Lua_ClearRoleFromBattle);
    R("addroleintobattle", Lua_AddRoleIntoBattle);
    R("forcebattleresult", Lua_ForceBattleResult);
    R("changemmapmusic", Lua_ChangeMMapMusic);
    R("changemainmapmusic", Lua_ChangeMMapMusic);
    R("asksoftstar", Lua_AskSoftStar);
    R("showethics", Lua_ShowEthics);
    R("showrepute", Lua_ShowRepute);
    R("openallscene", Lua_OpenAllScene);

    // instruct_N 别名
    R("instruct_0", Lua_Clear);
    R("instruct_1", Lua_OldTalk);
    R("instruct_2", Lua_GetItem);
    R("instruct_3", Lua_ModifyEvent);
    R("instruct_4", Lua_UseItem);
    R("instruct_5", Lua_AskBattle);
    R("instruct_6", Lua_TryBattle);
    R("instruct_7", Lua_Blank);
    R("instruct_8", Lua_ChangeMMapMusic);
    R("instruct_9", Lua_AskJoin);
    R("instruct_10", Lua_Join);
    R("instruct_11", Lua_AskRest);
    R("instruct_12", Lua_Rest);
    R("instruct_13", Lua_LightScene);
    R("instruct_14", Lua_DarkScene);
    R("instruct_15", Lua_Dead);
    R("instruct_16", Lua_InTeam);
    R("instruct_17", Lua_OldPutSceneMapPro);
    R("setsubmaplayerdata", Lua_OldPutSceneMapPro);
    R("instruct_18", Lua_HaveItemBool);
    R("instruct_19", Lua_OldSetScenePosition);
    R("oldsetsceneposition", Lua_OldSetScenePosition);
    R("instruct_20", Lua_TeamIsFull);
    R("instruct_21", Lua_LeaveTeam);
    R("instruct_22", Lua_ZeroAllMP);
    R("zeroallmp", Lua_ZeroAllMP);
    R("instruct_23", Lua_SetOneUsePoi);
    R("setroleusepoison", Lua_SetOneUsePoi);
    R("instruct_24", Lua_Blank);
    R("submapviewfromto", Lua_SceneFromTo);
    R("instruct_25", Lua_SceneFromTo);
    R("instruct_26", Lua_Add3EventNum);
    R("add3eventnum", Lua_Add3EventNum);
    R("instruct_27", Lua_PlayAnimation);
    R("instruct_28", Lua_JudgeEthics);
    R("checkrolemorality", Lua_JudgeEthics);
    R("instruct_29", Lua_JudgeAttack);
    R("checkroleattack", Lua_JudgeAttack);
    R("instruct_30", Lua_WalkFromTo);
    R("instruct_31", Lua_JudgeMoney);
    R("checkenoughmoney", Lua_JudgeMoney);
    R("instruct_32", Lua_AddItem);
    R("additemwithouthint", Lua_AddItem);
    R("instruct_33", Lua_OldLearnMagic);
    R("oldlearnmagic", Lua_OldLearnMagic);
    R("instruct_34", Lua_AddAptitude);
    R("addiq", Lua_AddAptitude);
    R("instruct_35", Lua_SetOneMagic);
    R("setrolemagic", Lua_SetOneMagic);
    R("instruct_36", Lua_JudgeSexual);
    R("checkrolesexual", Lua_JudgeSexual);
    R("instruct_37", Lua_AddEthics);
    R("addmorality", Lua_AddEthics);
    R("instruct_38", Lua_ChangeScenePic);
    R("changesubmappic", Lua_ChangeScenePic);
    R("instruct_39", Lua_OpenScene);
    R("opensubmap", Lua_OpenScene);
    R("instruct_40", Lua_SetRoleFace);
    R("setroleface", Lua_SetRoleFace);
    R("settowards", Lua_SetSceneFace);
    R("instruct_41", Lua_AnotherGetItem);
    R("roleadditem", Lua_AnotherGetItem);
    R("instruct_42", Lua_JudgeFemaleInTeam);
    R("checkfemaleinteam", Lua_JudgeFemaleInTeam);
    R("instruct_43", Lua_HaveItemBool);
    R("instruct_44", Lua_Play2Amination);
    R("instruct_45", Lua_AddSpeed);
    R("addspeed", Lua_AddSpeed);
    R("instruct_46", Lua_AddMP);
    R("addmaxmp", Lua_AddMP);
    R("instruct_47", Lua_AddAttack);
    R("addattack", Lua_AddAttack);
    R("instruct_48", Lua_AddHP);
    R("addmaxhp", Lua_AddHP);
    R("instruct_49", Lua_SetMPPro);
    R("setmptype", Lua_SetMPPro);
    R("instruct_50", Lua_Judge5Item);
    R("instruct_50e", Lua_Judge5Item);
    R("instruct_51", Lua_AskSoftStar);
    R("showmorality", Lua_ShowEthics);
    R("instruct_52", Lua_ShowEthics);
    R("instruct_53", Lua_ShowRepute);
    R("showfame", Lua_ShowRepute);
    R("instruct_54", Lua_OpenAllScene);
    R("openallsubmap", Lua_OpenAllScene);
    R("instruct_55", Lua_JudgeEventNum);
    R("checkeventid", Lua_JudgeEventNum);
    R("instruct_56", Lua_AddRepute);
    R("addfame", Lua_AddRepute);
    R("instruct_57", Lua_BreakStoneGate);
    R("breakstonegate", Lua_BreakStoneGate);
    R("instruct_58", Lua_FightForTop);
    R("instruct_59", Lua_AllLeave);
    R("instruct_60", Lua_JudgeScenePic);
    R("checksubmappic", Lua_JudgeScenePic);
    R("instruct_61", Lua_Judge14BooksPlaced);
    R("check14booksplaced", Lua_Judge14BooksPlaced);
    R("instruct_62", Lua_BackHome);
    R("backhome", Lua_BackHome);
    R("instruct_63", Lua_SetSexual);
    R("setsexual", Lua_SetSexual);
    R("instruct_64", Lua_WeiShop);
    R("shop", Lua_WeiShop);
    R("instruct_65", Lua_Blank);
    R("instruct_66", Lua_PlayMusic);
    R("instruct_67", Lua_PlayWave);

    R("eatoneitem", Lua_EatOneItemScript);
    R("selectoneteammember", Lua_SelectOneTeamMemberScript);
    R("setteam", Lua_setteam);
    R("getteam", Lua_getteam);
    R("read_mem", Lua_readmem);
    R("write_mem", Lua_writemem);
    R("getrolename", Lua_getrolename);
    R("getitemname", Lua_getitemname);
    R("getmagicname", Lua_getmagicname);
    R("getsubmapname", Lua_getsubmapname);
    R("drawlength", Lua_drawlength_s);
    R("getkey", Lua_getkey);
    R("gettalk", Lua_gettalk);

    // pig3同步：set*/get* pro别名
    R("getrolepro", Lua_GetRolePro);
    R("setrolepro", Lua_PutRolePro);
    R("putrolepro", Lua_PutRolePro);
    R("getitempro", Lua_GetItemPro);
    R("setitempro", Lua_PutItemPro);
    R("putitempro", Lua_PutItemPro);
    R("getmagicpro", Lua_GetMagicPro);
    R("setmagicpro", Lua_PutMagicPro);
    R("putmagicpro", Lua_PutMagicPro);
    R("getscenepro", Lua_GetScenePro);
    R("setscenepro", Lua_PutScenePro);
    R("putscenepro", Lua_PutScenePro);
    R("getscenemappro", Lua_GetSceneMapPro);
    R("setscenemappro", Lua_PutSceneMapPro);
    R("putscenemappro", Lua_PutSceneMapPro);
    R("getsceneeventpro", Lua_GetSceneEventPro);
    R("setsceneeventpro", Lua_PutSceneEventPro);
    R("putsceneeventpro", Lua_PutSceneEventPro);
    R("setbattlerolepro", Lua_PutBattleRolePro);
    R("putmember", Lua_PutMember);

    // pig3同步：新增函数
    R("getglobalvalue", Lua_GetGlobalValue);
    R("setglobalvalue", Lua_SetGlobalValue);
    R("putglobalvalue", Lua_SetGlobalValue);
    R("getx50", Lua_GetX50);
    R("setx50", Lua_SetX50);
    R("putx50", Lua_SetX50);
    R("showtitle", Lua_ShowTitle);
    R("readtalkasstring", Lua_ReadTalkAsString);
    R("checkjumpflag", Lua_CheckJumpFlag);
    R("exit", Lua_ExitScript);
    R("colcolor", Lua_ColColor);
    R("showsimplestatus", Lua_ShowSimpleStatus);
    R("updateallscreen", Lua_UpdateAllScreen);
    R("setitemintro", Lua_SetItemIntro);
    R("putitemintro", Lua_SetItemIntro);
    R("showstatus", Lua_ShowStatus);
    R("setnameasstring", Lua_SetNameAsString);
    R("setattribute", Lua_SetAttribute);
    R("enternumber", Lua_EnterNumber);
    R("haveitemamount", Lua_HaveItemAmount);
    R("getscreensize", Lua_GetScreenSize);
    R("endamination", Lua_BackHome);
    R("npcgetitem", Lua_AnotherGetItem);
    R("leave", Lua_LeaveTeam);
    R("learnmagic2", Lua_OldLearnMagic);

    ExecScriptString("x={}; for i=0,30000 do x[i]=0; end;", "");
}

void DestroyScript()
{
    lua_close(Lua_script);
}

int ExecScript(const std::string& filename, const std::string& functionname)
{
    std::string script = filefunc::readFileToString(filename);
    if (script.empty())
    {
        return 0;
    }
    return ExecScriptString(script, functionname);
}

int ExecScriptString(const std::string& script_in, const std::string& functionname)
{
    std::string script = script_in;
    // 去BOM
    if (script.size() >= 3 && (uint8_t)script[0] == 0xEF && (uint8_t)script[1] == 0xBB && (uint8_t)script[2] == 0xBF)
    {
        script[0] = ' ';
        script[1] = ' ';
        script[2] = ' ';
    }
    // 转小写
    std::transform(script.begin(), script.end(), script.begin(), [](unsigned char c)
        {
            return std::tolower(c);
        });

    int result = luaL_loadbuffer(Lua_script, script.c_str(), script.size(), "code");
    if (result == 0)
    {
        result = lua_pcall(Lua_script, 0, 0, 0);
        if (!functionname.empty())
        {
            lua_getglobal(Lua_script, functionname.c_str());
            result = lua_pcall(Lua_script, 0, 1, 0);
        }
    }
    if (result != 0)
    {
        kyslog(lua_tostring(Lua_script, -1));
        lua_pop(Lua_script, 1);
    }
    return result;
}
