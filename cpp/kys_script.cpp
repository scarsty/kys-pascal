// kys_script.cpp - Lua脚本系统实现
// 对应 kys_script.pas

#include "kys_script.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_main.h"
#include "kys_event.h"
#include "kys_battle.h"
#include "kys_type.h"

#include <SDL3/SDL.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <string>
#include <algorithm>
#include <cctype>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

// 自定义lua_tointeger: 处理instruct_50e code 32改写
long long lua_tointeger_custom(lua_State* L, int pos) {
    int n = lua_gettop(L);
    long long result = lua_tointeger(L, pos);
    int realpos = (pos < 0) ? (n + pos + 1) : pos;
    if (realpos == Script5032Pos) {
        result = Script5032Value;
        Script5032Pos = -100;
    }
    return result;
}

#define LI(pos) ((int)lua_tointeger_custom(L, pos))

// ---- Lua函数实现 ----

static int l_Blank(lua_State* L) { return 0; }

static int l_Pause(lua_State* L) {
    lua_pushnumber(L, WaitAnyKey());
    return 1;
}

static int l_GetMousePosition(lua_State* L) {
    SDL_PollEvent(&event);
    float fx, fy;
    SDL_GetMouseState(&fx, &fy);
    lua_pushnumber(L, (int)fx);
    lua_pushnumber(L, (int)fy);
    return 2;
}

static int l_ClearButton(lua_State* L) {
    event.key.key = 0; event.button.button = 0;
    return 0;
}

static int l_CheckButton(lua_State* L) {
    SDL_PollEvent(&event);
    lua_pushnumber(L, (event.button.button > 0) ? 1 : 0);
    SDL_Delay(10);
    return 1;
}

static int l_GetButton(lua_State* L) {
    lua_pushnumber(L, event.key.key);
    lua_pushnumber(L, event.button.button);
    return 2;
}

static int l_GetTime(lua_State* L) {
    lua_pushnumber(L, (int)(SDL_GetTicks() / 1000));
    return 1;
}

static int l_ExecEvent(lua_State* L) {
    int n = lua_gettop(L);
    int e = LI(-n);
    for (int i = 0; i < n - 1; i++)
        x50[0x7100 + i] = LI(-n + 1 + i);
    CallEvent(e);
    return 0;
}

static int l_CallEvent_s(lua_State* L) {
    CallEvent(LI(-1));
    return 0;
}

static int l_Clear(lua_State* L) { Redraw(); return 0; }

static int l_OldTalk(lua_State* L) {
    instruct_1(LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_Talk(lua_State* L) {
    int rnum = LI(3);
    int dismode = LI(2);
    const char* content = lua_tostring(L, 1);
    talk_1(content ? content : "", dismode, rnum);
    return 0;
}

static int l_GetItem(lua_State* L) {
    instruct_2(LI(-2), LI(-1));
    return 0;
}

static int l_AddItem(lua_State* L) {
    instruct_32(LI(-2), LI(-1));
    return 0;
}

static int l_ShowString(lua_State* L) {
    int x = LI(2), y = LI(3);
    std::string str = std::string(" ") + (lua_tostring(L, 1) ? lua_tostring(L, 1) : "");
    DrawShadowText(screen, str, x, y, ColColor(5), ColColor(7));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    return 0;
}

static int l_ShowStringWithBox(lua_State* L) {
    int x = LI(2), y = LI(3);
    std::string str = lua_tostring(L, 1) ? lua_tostring(L, 1) : "";
    int w = DrawLength(str);
    DrawRectangle(screen, x, y - 2, w * 10 + 5, 27, 0, ColColor(255), 30);
    DrawShadowText(screen, str, x + 3, y, ColColor(5), ColColor(7));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    int i = WaitAnyKey();
    lua_pushinteger(L, i);
    return 1;
}

static int l_Menu(lua_State* L) {
    int n = LI(-1);
    int len = (int)luaL_len(L, -2);
    n = std::min(n, len);
    std::vector<std::string> menuStr(n);
    int maxwidth = 0;
    for (int i = 0; i < n; i++) {
        lua_pushinteger(L, i + 1);
        lua_gettable(L, -3);
        const char* p = lua_tostring(L, -1);
        menuStr[i] = p ? p : "";
        int w = DrawLength(menuStr[i]);
        if (w > maxwidth) maxwidth = w;
        lua_pop(L, 1);
    }
    int y = LI(-3), x = LI(-4);
    int w = maxwidth * 10 + 8;
    lua_pushinteger(L, CommonScrollMenu(x, y, w, n - 1, 15, menuStr.data()) + 1);
    return 1;
}

static int l_AskYesOrNo(lua_State* L) {
    std::string ms[3] = {" 否", " 是", ""};
    int y = LI(-2), x = LI(-1);
    lua_pushnumber(L, CommonMenu2(x, y, 78, ms));
    return 1;
}

static int l_ModifyEvent(lua_State* L) {
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++) x[i] = LI(-(n - i));
    if (n == 13) instruct_3(x.data());
    if (n == 4) {
        if (x[0] == -2) x[0] = CurScene;
        if (x[1] == -2) x[1] = CurEvent;
        DData[x[0]][x[1]][x[2]] = x[3];
    }
    return 0;
}

static int l_UseItem(lua_State* L) {
    int n = lua_gettop(L);
    int inum = LI(-1);
    if (n == 3) inum = LI(-3);
    lua_pushboolean(L, inum == CurItem);
    return 1;
}

static int l_HaveItem(lua_State* L) {
    int inum = LI(-1), n = 0;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++)
        if (RItemList[i].Number == inum) { n = RItemList[i].Amount; break; }
    lua_pushnumber(L, n);
    return 1;
}

static int l_HaveItemBool(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_18(LI(-n), 1, 0) == 1);
    return 1;
}

static int l_AnotherGetItem(lua_State* L) {
    instruct_41(LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_CompareProInTeam(lua_State* L) {
    int n = 0;
    for (int i = 0; i < 6; i++)
        if (TeamList[i] >= 0 && Rrole[TeamList[i]].Data[LI(-2)] == LI(-1)) n++;
    lua_pushnumber(L, n);
    return 1;
}

static int l_AllLeave(lua_State* L) { instruct_59(); return 0; }

static int l_AskBattle(lua_State* L) {
    lua_pushboolean(L, instruct_5(1, 0) == 1);
    return 1;
}

static int l_TryBattle(lua_State* L) {
    int n = lua_gettop(L);
    int t = LI(-n);
    lua_pushboolean(L, Battle(t, LI(-1)));
    return 1;
}

static int l_AskJoin(lua_State* L) {
    lua_pushboolean(L, instruct_9(1, 0) == 1);
    return 1;
}

static int l_Join(lua_State* L) { instruct_10(LI(-1)); return 0; }

static int l_AskRest(lua_State* L) {
    lua_pushboolean(L, instruct_11(1, 0) == 1);
    return 1;
}

static int l_Rest(lua_State* L) { instruct_12(); return 0; }
static int l_LightScene(lua_State* L) { instruct_13(); return 0; }
static int l_DarkScene(lua_State* L) { instruct_14(); return 0; }
static int l_Dead(lua_State* L) { instruct_15(); return 0; }

static int l_InTeam(lua_State* L) {
    lua_pushboolean(L, instruct_16(LI(-lua_gettop(L)), 1, 0) == 1);
    return 1;
}

static int l_TeamIsFull(lua_State* L) {
    lua_pushboolean(L, instruct_20(1, 0) == 1);
    return 1;
}

static int l_LeaveTeam(lua_State* L) { instruct_21(LI(-1)); return 0; }

static int l_LearnMagic(lua_State* L) {
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++) x[i] = LI(-(n - i));
    if (n == 2) instruct_33(x[0], x[1], 0);
    if (n == 3) StudyMagic(x[0], 0, x[1], x[2], 0);
    if (n == 4) StudyMagic(x[0], x[1], x[2], x[3], 0);
    return 0;
}

static int l_OldLearnMagic(lua_State* L) {
    instruct_33(LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_GetMainMapPosition(lua_State* L) {
    lua_pushnumber(L, My); lua_pushnumber(L, Mx);
    return 2;
}

static int l_SetMainMapPosition(lua_State* L) {
    Mx = LI(-1); My = LI(-2);
    return 0;
}

static int l_GetScenePosition(lua_State* L) {
    lua_pushnumber(L, Sy); lua_pushnumber(L, Sx);
    return 2;
}

static int l_SetScenePosition(lua_State* L) {
    Sx = LI(-1); Sy = LI(-2);
    return 0;
}

static int l_OldSetScenePosition(lua_State* L) {
    instruct_19(LI(-2), LI(-1));
    return 0;
}

static int l_GetSceneFace(lua_State* L) {
    lua_pushnumber(L, SFace);
    return 1;
}

static int l_SetSceneFace(lua_State* L) {
    SFace = LI(-1);
    return 0;
}

static int l_Delay(lua_State* L) {
    SDL_Delay(LI(-1));
    return 0;
}

static int l_DrawRect(lua_State* L) {
    int n = lua_gettop(L);
    std::vector<int> x(n);
    for (int i = 0; i < n; i++) x[i] = LI(-(n - i));
    if (n == 7) DrawRectangle(screen, x[0], x[1], x[2], x[3], x[4], x[5], x[6]);
    if (n == 6) DrawRectangleWithoutFrame(screen, x[0], x[1], x[2], x[3], x[4], x[5]);
    if (n == 4) DrawRectangle(screen, x[0], x[1], x[2], x[3], 0, ColColor(255), 50);
    return 0;
}

static int l_MemberAmount(lua_State* L) {
    int n = 0;
    for (int i = 0; i < 6; i++) if (TeamList[i] >= 0) n++;
    lua_pushnumber(L, n);
    return 1;
}

static int l_GetMember(lua_State* L) {
    int n = LI(-1);
    lua_pushnumber(L, (n >= 0 && n <= 5) ? TeamList[n] : 0);
    return 1;
}

static int l_PutMember(lua_State* L) {
    TeamList[LI(-1)] = LI(-2);
    return 0;
}

static int l_GetRolePro(lua_State* L) {
    lua_pushnumber(L, Rrole[LI(-2)].Data[LI(-1)]);
    return 1;
}

static int l_PutRolePro(lua_State* L) {
    Rrole[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

static int l_GetItemPro(lua_State* L) {
    lua_pushnumber(L, Ritem[LI(-2)].Data[LI(-1)]);
    return 1;
}

static int l_PutItemPro(lua_State* L) {
    Ritem[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

static int l_GetMagicPro(lua_State* L) {
    lua_pushnumber(L, Rmagic[LI(-2)].Data[LI(-1)]);
    return 1;
}

static int l_PutMagicPro(lua_State* L) {
    Rmagic[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

static int l_GetScenePro(lua_State* L) {
    lua_pushnumber(L, Rscene[LI(-2)].Data[LI(-1)]);
    return 1;
}

static int l_PutScenePro(lua_State* L) {
    Rscene[LI(-3)].Data[LI(-2)] = LI(-1);
    return 0;
}

static int l_GetSceneMapPro(lua_State* L) {
    lua_pushnumber(L, SData[LI(-4)][LI(-3)][LI(-2)][LI(-1)]);
    return 1;
}

static int l_PutSceneMapPro(lua_State* L) {
    SData[LI(-5)][LI(-4)][LI(-3)][LI(2)] = LI(-1);
    return 0;
}

static int l_OldPutSceneMapPro(lua_State* L) {
    int list[5];
    for (int i = 0; i < 5; i++) list[i] = LI(i - 5);
    instruct_17(list);
    return 0;
}

static int l_GetSceneEventPro(lua_State* L) {
    lua_pushnumber(L, DData[LI(-3)][LI(-2)][LI(-1)]);
    return 1;
}

static int l_PutSceneEventPro(lua_State* L) {
    DData[LI(-4)][LI(-3)][LI(-2)] = LI(-1);
    return 0;
}

static int l_JudgeSceneEvent(lua_State* L) {
    int t = (DData[CurScene][LI(-3)][2 + LI(-2)] == LI(-1)) ? 1 : 0;
    lua_pushnumber(L, t);
    return 1;
}

static int l_PlayMusic(lua_State* L) { instruct_66(LI(-1)); return 0; }
static int l_PlayWave(lua_State* L) { instruct_67(LI(-1)); return 0; }

static int l_WalkFromTo(lua_State* L) {
    instruct_30(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_SceneFromTo(lua_State* L) {
    instruct_25(LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_PlayAnimation(lua_State* L) {
    instruct_27(LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_GetNameAsString(lua_State* L) {
    int typenum = LI(-2), num = LI(-1);
    std::string str;
    switch (typenum) {
        case 0: str = cp950toutf8(Rrole[num].Name); break;
        case 1: str = cp950toutf8(Ritem[num].Name); break;
        case 2: str = cp950toutf8(Rscene[num].Name); break;
        case 3: str = cp950toutf8(Rmagic[num].Name); break;
    }
    lua_pushstring(L, str.c_str());
    return 1;
}

static int l_ChangeScene(lua_State* L) {
    int n = lua_gettop(L);
    CurScene = LI(-n);
    int x, y;
    if (n == 1) { x = Rscene[CurScene].EntranceX; y = Rscene[CurScene].EntranceY; }
    else { x = LI(-n + 1); y = LI(-n + 2); }
    Cx = x + Cx - Sx; Cy = y + Cy - Sy;
    Sx = x; Sy = y;
    instruct_14(); InitialScene(0); DrawScene(); instruct_13();
    ShowSceneName(CurScene); CheckEvent3();
    return 0;
}

static int l_ShowPicture(lua_State* L) {
    int n = lua_gettop(L);
    int x = LI(-2), y = LI(-1);
    if (n == 4) {
        int t = LI(-4), p = LI(-3);
        switch (t) {
            case 0: DrawMPic(p, x, y); break;
            case 1: DrawSPic(p, x, y, 0, 0, screen->w, screen->h); break;
            case 2: DrawBPic(p, x, y, 0); break;
            case 3: DrawHeadPic(p, x, y); break;
            case 4: DrawEPic(p, x, y); break;
        }
    }
    if (n == 3) display_img(lua_tostring(L, -3), x, y);
    return 0;
}

static int l_GetItemList(lua_State* L) {
    int i = LI(-1);
    lua_pushnumber(L, RItemList[i].Number);
    lua_pushnumber(L, RItemList[i].Amount);
    return 2;
}

static int l_GetCurrentScene(lua_State* L) { lua_pushnumber(L, CurScene); return 1; }
static int l_GetCurrentEvent(lua_State* L) { lua_pushnumber(L, CurEvent); return 1; }

static int l_GetBattleNumber(lua_State* L) {
    int n = lua_gettop(L);
    if (n == 0) lua_pushnumber(L, x50[28005]);
    if (n == 1) {
        int rnum = LI(-1), t = -1;
        for (int i = 0; i < BRoleAmount; i++)
            if (Brole[i].rnum == rnum) { t = i; break; }
        lua_pushnumber(L, t);
    }
    return 1;
}

static int l_SelectOneAim(lua_State* L) {
    if (LI(-1) == 0) SelectAim(LI(-3), LI(-2));
    lua_pushnumber(L, BField[2][Ax][Ay]);
    return 1;
}

static int l_GetBattleRolePro(lua_State* L) {
    lua_pushnumber(L, Brole[LI(-2)].Data[LI(-1)]);
    return 1;
}

static int l_PutBattleRolePro(lua_State* L) {
    Brole[LI(-2)].Data[LI(-1)] = LI(-3);
    return 0;
}

static int l_PlayAction(lua_State* L) {
    int bnum = LI(-3), mtype = LI(-2);
    PlayActionAmination(bnum, mtype);
    PlayMagicAmination(bnum, mtype);
    return 0;
}

static int l_PlayHurtValue(lua_State* L) {
    ShowHurtValue(LI(-1));
    return 0;
}

static int l_SetAminationLayer(lua_State* L) {
    int x = LI(-5), y = LI(-4), w = LI(-3), h = LI(-2), t = LI(-1);
    for (int i1 = x; i1 < x + w; i1++)
        for (int i2 = y; i2 < y + h; i2++)
            BField[4][i1][i2] = t;
    return 0;
}

static int l_ClearRoleFromBattle(lua_State* L) {
    Brole[LI(-1)].Dead = 1;
    return 0;
}

static int l_AddRoleIntoBattle(lua_State* L) {
    int bnum = BRoleAmount++;
    int team = LI(-4), rnum = LI(-3), x = LI(-2), y = LI(-1);
    Brole[bnum].rnum = rnum; Brole[bnum].Team = team;
    Brole[bnum].X = x; Brole[bnum].Y = y;
    Brole[bnum].Face = 1; Brole[bnum].Dead = 0;
    Brole[bnum].Step = 0; Brole[bnum].Acted = 1;
    Brole[bnum].ShowNumber = -1; Brole[bnum].ExpGot = 0;
    lua_pushnumber(L, bnum);
    return 1;
}

static int l_ForceBattleResult(lua_State* L) {
    BattleResult = LI(-1);
    return 0;
}

static int l_AskSoftStar(lua_State* L) { instruct_51(); return 0; }
static int l_WeiShop(lua_State* L) { instruct_64(); return 0; }
static int l_OpenAllScene(lua_State* L) { instruct_54(); return 0; }
static int l_ShowEthics(lua_State* L) { instruct_52(); return 0; }
static int l_ShowRepute(lua_State* L) { instruct_53(); return 0; }
static int l_ChangeMMapMusic(lua_State* L) { instruct_8(LI(-1)); return 0; }
static int l_ZeroAllMP(lua_State* L) { instruct_22(); return 0; }
static int l_SetOneUsePoi(lua_State* L) { instruct_23(LI(-2), LI(-1)); return 0; }
static int l_Add3EventNum(lua_State* L) { instruct_26(LI(-5), LI(-4), LI(-3), LI(-2), LI(-1)); return 0; }

static int l_Judge5Item(lua_State* L) {
    int list[7];
    for (int i = 0; i < 7; i++) list[i] = LI(i - 7);
    int n = instruct_50(list);
    lua_pushboolean(L, n == list[5]);
    return 1;
}

static int l_JudgeEthics(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_28(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

static int l_JudgeAttack(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_29(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

static int l_JudgeMoney(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_31(LI(-n), 1, 0) == 1);
    return 1;
}

static int l_AddAptitude(lua_State* L) { instruct_34(LI(-2), LI(-1)); return 0; }
static int l_SetOneMagic(lua_State* L) { instruct_35(LI(-4), LI(-3), LI(-2), LI(-1)); return 0; }

static int l_JudgeSexual(lua_State* L) {
    lua_pushboolean(L, instruct_36(LI(-lua_gettop(L)), 1, 0) == 1);
    return 1;
}

static int l_AddEthics(lua_State* L) { instruct_37(LI(-1)); return 0; }
static int l_ChangeScenePic(lua_State* L) { instruct_38(LI(-4), LI(-3), LI(-2), LI(-1)); return 0; }
static int l_OpenScene(lua_State* L) { instruct_39(LI(-1)); return 0; }

static int l_JudgeFemaleInTeam(lua_State* L) {
    lua_pushboolean(L, instruct_42(1, 0) == 1);
    return 1;
}

static int l_Play2Amination(lua_State* L) {
    instruct_44(LI(-6), LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_AddSpeed(lua_State* L) { instruct_45(LI(-2), LI(-1)); return 0; }
static int l_AddMP(lua_State* L) { instruct_46(LI(-2), LI(-1)); return 0; }
static int l_AddAttack(lua_State* L) { instruct_47(LI(-2), LI(-1)); return 0; }
static int l_AddHP(lua_State* L) { instruct_48(LI(-2), LI(-1)); return 0; }
static int l_SetMPPro(lua_State* L) { instruct_49(LI(-2), LI(-1)); return 0; }

static int l_JudgeEventNum(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_55(LI(-n), LI(1 - n), 1, 0) == 1);
    return 1;
}

static int l_AddRepute(lua_State* L) { instruct_56(LI(-1)); return 0; }
static int l_BreakStoneGate(lua_State* L) { instruct_57(); return 0; }
static int l_FightForTop(lua_State* L) { instruct_58(); return 0; }

static int l_JudgeScenePic(lua_State* L) {
    int n = lua_gettop(L);
    lua_pushboolean(L, instruct_60(LI(-n), LI(1 - n), LI(2 - n), 1, 0) == 1);
    return 1;
}

static int l_Judge14BooksPlaced(lua_State* L) {
    lua_pushboolean(L, instruct_61(1, 0) == 1);
    return 1;
}

static int l_SetSexual(lua_State* L) { instruct_63(LI(-2), LI(-1)); return 0; }

static int l_BackHome(lua_State* L) {
    instruct_62(LI(-6), LI(-5), LI(-4), LI(-3), LI(-2), LI(-1));
    return 0;
}

static int l_EatOneItemScript(lua_State* L) {
    int n = lua_gettop(L);
    if (n == 2) EatOneItem(LI(-n), LI(1 - n));
    return 0;
}

static int l_SelectOneTeamMemberScript(lua_State* L) {
    lua_pushnumber(L, SelectOneTeamMember(LI(-5), LI(-4), lua_tostring(L, -3), LI(-2), LI(-1)));
    return 1;
}

static int l_setteam(lua_State* L) { TeamList[LI(-2)] = LI(-1); return 0; }
static int l_getteam(lua_State* L) { lua_pushnumber(L, TeamList[LI(-1)]); return 1; }

static int l_readmem(lua_State* L) {
    int x = LI(-1);
    instruct_50e(26, 0, 0, x % 65536, x / 65536, 9999, 0);
    lua_pushnumber(L, x50[9999]);
    return 1;
}

static int l_writemem(lua_State* L) {
    int x = LI(-2);
    x50[9999] = LI(-1);
    instruct_50e(25, 1, 0, x % 65536, x / 65536, 9999, 0);
    return 0;
}

static int l_getrolename(lua_State* L) {
    lua_pushstring(L, cp950toutf8(Rrole[LI(-1)].Name).c_str());
    return 1;
}

static int l_getitemname(lua_State* L) {
    lua_pushstring(L, cp950toutf8(Ritem[LI(-1)].Name).c_str());
    return 1;
}

static int l_getmagicname(lua_State* L) {
    lua_pushstring(L, cp950toutf8(Rmagic[LI(-1)].Name).c_str());
    return 1;
}

static int l_getsubmapname(lua_State* L) {
    lua_pushstring(L, cp950toutf8(Rscene[LI(-1)].Name).c_str());
    return 1;
}

static int l_drawlength_s(lua_State* L) {
    const char* s = lua_tostring(L, -1);
    lua_pushinteger(L, DrawLength(s ? s : ""));
    return 1;
}

static int l_getkey(lua_State* L) {
    lua_pushinteger(L, WaitAnyKey());
    return 1;
}

static int l_gettalk(lua_State* L) {
    int talknum = LI(-1);
    std::string str = ReadTalk(talknum);
    lua_pushstring(L, str.c_str());
    return 1;
}

// ---- 初始化/销毁 ----

void InitialScript() {
    Lua_script = luaL_newstate();
    luaL_openlibs(Lua_script);

    auto R = [](const char* name, lua_CFunction f) { lua_register(Lua_script, name, f); };

    R("pause", l_Pause);
    R("getmouseposition", l_GetMousePosition);
    R("clearbutton", l_ClearButton);
    R("checkbutton", l_CheckButton);
    R("getbutton", l_GetButton);
    R("gettime", l_GetTime);
    R("execevent", l_ExecEvent);
    R("callevent", l_CallEvent_s);
    R("clear", l_Clear);
    R("talk", l_Talk);
    R("getitem", l_GetItem);
    R("additem", l_GetItem);
    R("showstring", l_ShowString);
    R("drawstring", l_ShowString);
    R("showstringwithbox", l_ShowStringWithBox);
    R("showmessage", l_ShowStringWithBox);
    R("menu", l_Menu);
    R("askyesorno", l_AskYesOrNo);
    R("modifyevent", l_ModifyEvent);
    R("useitem", l_UseItem);
    R("haveitem", l_HaveItem);
    R("haveitembool", l_HaveItemBool);
    R("anothergetitem", l_AnotherGetItem);
    R("compareprointeam", l_CompareProInTeam);
    R("allleave", l_AllLeave);
    R("askbattle", l_AskBattle);
    R("trybattle", l_TryBattle);
    R("askjoin", l_AskJoin);
    R("join", l_Join);
    R("askrest", l_AskRest);
    R("rest", l_Rest);
    R("lightscene", l_LightScene);
    R("darkscene", l_DarkScene);
    R("dead", l_Dead);
    R("inteam", l_InTeam);
    R("teamisfull", l_TeamIsFull);
    R("leaveteam", l_LeaveTeam);
    R("learnmagic", l_LearnMagic);
    R("getmainmapposition", l_GetMainMapPosition);
    R("setmainmapposition", l_SetMainMapPosition);
    R("getsceneposition", l_GetScenePosition);
    R("setsceneposition", l_SetScenePosition);
    R("getsceneface", l_GetSceneFace);
    R("setsceneface", l_SetSceneFace);
    R("delay", l_Delay);
    R("lib.delay", l_Delay);
    R("drawrect", l_DrawRect);
    R("memberamount", l_MemberAmount);
    R("getmember", l_GetMember);
    R("setmember", l_PutMember);
    R("getrole", l_GetRolePro);
    R("setrole", l_PutRolePro);
    R("getitem", l_GetItemPro);
    R("setitem", l_PutItemPro);
    R("getmagic", l_GetMagicPro);
    R("setmagic", l_PutMagicPro);
    R("getsubmapinfo", l_GetScenePro);
    R("setsubmapinfo", l_PutScenePro);
    R("gets", l_GetSceneMapPro);
    R("sets", l_PutSceneMapPro);
    R("getd", l_GetSceneEventPro);
    R("setd", l_PutSceneEventPro);
    R("judgesceneevent", l_JudgeSceneEvent);
    R("playmusic", l_PlayMusic);
    R("playwave", l_PlayWave);
    R("walkfromto", l_WalkFromTo);
    R("scenefromto", l_SceneFromTo);
    R("playanimation", l_PlayAnimation);
    R("getnameasstring", l_GetNameAsString);
    R("changescene", l_ChangeScene);
    R("showpicture", l_ShowPicture);
    R("getitemlist", l_GetItemList);
    R("getcurrentscene", l_GetCurrentScene);
    R("getcurrentevent", l_GetCurrentEvent);
    R("getbattlenumber", l_GetBattleNumber);
    R("selectoneaim", l_SelectOneAim);
    R("getbattlerolepro", l_GetBattleRolePro);
    R("putbattlerolepro", l_PutBattleRolePro);
    R("playaction", l_PlayAction);
    R("playhurtvalue", l_PlayHurtValue);
    R("setaminationlayer", l_SetAminationLayer);
    R("clearrolefrombattle", l_ClearRoleFromBattle);
    R("addroleintobattle", l_AddRoleIntoBattle);
    R("forcebattleresult", l_ForceBattleResult);
    R("changemmapmusic", l_ChangeMMapMusic);
    R("changemainmapmusic", l_ChangeMMapMusic);
    R("asksoftstar", l_AskSoftStar);
    R("showethics", l_ShowEthics);
    R("showrepute", l_ShowRepute);
    R("openallscene", l_OpenAllScene);

    // instruct_N 别名
    R("instruct_0", l_Clear);
    R("instruct_1", l_OldTalk);
    R("instruct_2", l_GetItem);
    R("instruct_3", l_ModifyEvent);
    R("instruct_4", l_UseItem);
    R("instruct_5", l_AskBattle);
    R("instruct_6", l_TryBattle);
    R("instruct_7", l_Blank);
    R("instruct_8", l_ChangeMMapMusic);
    R("instruct_9", l_AskJoin);
    R("instruct_10", l_Join);
    R("instruct_11", l_AskRest);
    R("instruct_12", l_Rest);
    R("instruct_13", l_LightScene);
    R("instruct_14", l_DarkScene);
    R("instruct_15", l_Dead);
    R("instruct_16", l_InTeam);
    R("instruct_17", l_OldPutSceneMapPro);
    R("setsubmaplayerdata", l_OldPutSceneMapPro);
    R("instruct_18", l_HaveItemBool);
    R("instruct_19", l_OldSetScenePosition);
    R("oldsetsceneposition", l_OldSetScenePosition);
    R("instruct_20", l_TeamIsFull);
    R("instruct_21", l_LeaveTeam);
    R("instruct_22", l_ZeroAllMP);
    R("zeroallmp", l_ZeroAllMP);
    R("instruct_23", l_SetOneUsePoi);
    R("setroleusepoison", l_SetOneUsePoi);
    R("instruct_24", l_Blank);
    R("submapviewfromto", l_SceneFromTo);
    R("instruct_25", l_SceneFromTo);
    R("instruct_26", l_Add3EventNum);
    R("add3eventnum", l_Add3EventNum);
    R("instruct_27", l_PlayAnimation);
    R("instruct_28", l_JudgeEthics);
    R("checkrolemorality", l_JudgeEthics);
    R("instruct_29", l_JudgeAttack);
    R("checkroleattack", l_JudgeAttack);
    R("instruct_30", l_WalkFromTo);
    R("instruct_31", l_JudgeMoney);
    R("checkenoughmoney", l_JudgeMoney);
    R("instruct_32", l_AddItem);
    R("additemwithouthint", l_AddItem);
    R("instruct_33", l_OldLearnMagic);
    R("oldlearnmagic", l_OldLearnMagic);
    R("instruct_34", l_AddAptitude);
    R("addiq", l_AddAptitude);
    R("instruct_35", l_SetOneMagic);
    R("setrolemagic", l_SetOneMagic);
    R("instruct_36", l_JudgeSexual);
    R("checkrolesexual", l_JudgeSexual);
    R("instruct_37", l_AddEthics);
    R("addmorality", l_AddEthics);
    R("instruct_38", l_ChangeScenePic);
    R("changesubmappic", l_ChangeScenePic);
    R("instruct_39", l_OpenScene);
    R("opensubmap", l_OpenScene);
    R("instruct_40", l_SetSceneFace);
    R("settowards", l_SetSceneFace);
    R("instruct_41", l_AnotherGetItem);
    R("roleadditem", l_AnotherGetItem);
    R("instruct_42", l_JudgeFemaleInTeam);
    R("checkfemaleinteam", l_JudgeFemaleInTeam);
    R("instruct_43", l_HaveItemBool);
    R("instruct_44", l_Play2Amination);
    R("instruct_45", l_AddSpeed);
    R("addspeed", l_AddSpeed);
    R("instruct_46", l_AddMP);
    R("addmaxmp", l_AddMP);
    R("instruct_47", l_AddAttack);
    R("addattack", l_AddAttack);
    R("instruct_48", l_AddHP);
    R("addmaxhp", l_AddHP);
    R("instruct_49", l_SetMPPro);
    R("setmptype", l_SetMPPro);
    R("instruct_50", l_Judge5Item);
    R("instruct_50e", l_Judge5Item);
    R("instruct_51", l_AskSoftStar);
    R("showmorality", l_ShowEthics);
    R("instruct_52", l_ShowEthics);
    R("instruct_53", l_ShowRepute);
    R("showfame", l_ShowRepute);
    R("instruct_54", l_OpenAllScene);
    R("openallsubmap", l_OpenAllScene);
    R("instruct_55", l_JudgeEventNum);
    R("checkeventid", l_JudgeEventNum);
    R("instruct_56", l_AddRepute);
    R("addfame", l_AddRepute);
    R("instruct_57", l_BreakStoneGate);
    R("breakstonegate", l_BreakStoneGate);
    R("instruct_58", l_FightForTop);
    R("instruct_59", l_AllLeave);
    R("instruct_60", l_JudgeScenePic);
    R("checksubmappic", l_JudgeScenePic);
    R("instruct_61", l_Judge14BooksPlaced);
    R("check14booksplaced", l_Judge14BooksPlaced);
    R("instruct_62", l_BackHome);
    R("backhome", l_BackHome);
    R("instruct_63", l_SetSexual);
    R("setsexual", l_SetSexual);
    R("instruct_64", l_WeiShop);
    R("shop", l_WeiShop);
    R("instruct_65", l_Blank);
    R("instruct_66", l_PlayMusic);
    R("instruct_67", l_PlayWave);

    R("eatoneitem", l_EatOneItemScript);
    R("selectoneteammember", l_SelectOneTeamMemberScript);
    R("setteam", l_setteam);
    R("getteam", l_getteam);
    R("read_mem", l_readmem);
    R("write_mem", l_writemem);
    R("getrolename", l_getrolename);
    R("getitemname", l_getitemname);
    R("getmagicname", l_getmagicname);
    R("getsubmapname", l_getsubmapname);
    R("drawlength", l_drawlength_s);
    R("getkey", l_getkey);
    R("gettalk", l_gettalk);

    ExecScriptString("x={}; for i=0,30000 do x[i]=0; end;", "");
}

void DestroyScript() {
    lua_close(Lua_script);
}

int ExecScript(const std::string& filename, const std::string& functionname) {
    FILE* f = fopen(filename.c_str(), "rb");
    if (!f) return 0;
    fseek(f, 0, SEEK_END);
    int len = (int)ftell(f);
    fseek(f, 0, SEEK_SET);
    std::string script(len, 0);
    fread(&script[0], 1, len, f);
    fclose(f);
    return ExecScriptString(script, functionname);
}

int ExecScriptString(const std::string& script_in, const std::string& functionname) {
    std::string script = script_in;
    // 去BOM
    if (script.size() >= 3 && (uint8_t)script[0] == 0xEF && (uint8_t)script[1] == 0xBB && (uint8_t)script[2] == 0xBF) {
        script[0] = ' '; script[1] = ' '; script[2] = ' ';
    }
    // 转小写
    std::transform(script.begin(), script.end(), script.begin(), [](unsigned char c){ return std::tolower(c); });

    int result = luaL_loadbuffer(Lua_script, script.c_str(), script.size(), "code");
    if (result == 0) {
        result = lua_pcall(Lua_script, 0, 0, 0);
        if (!functionname.empty()) {
            lua_getglobal(Lua_script, functionname.c_str());
            result = lua_pcall(Lua_script, 0, 1, 0);
        }
    }
    if (result != 0) {
        kyslog(lua_tostring(Lua_script, -1));
        lua_pop(Lua_script, 1);
    }
    return result;
}
