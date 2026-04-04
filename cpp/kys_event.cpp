// kys_event.cpp - 事件系统实现
// 对应 kys_event.pas

#include "kys_event.h"

#include "PotConv.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_main.h"
#include "kys_battle.h"
#include "kys_script.h"
#include "kys_type.h"
#include "filefunc.h"

#include <SDL3/SDL.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <format>
#include <string>
#include <vector>
#include <algorithm>
#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#endif

// ---- 基本事件指令 ----

void instruct_0() {
    if (NeedRefreshScene == 1) {
        InitialScene(1);
        NeedRefreshScene = 0;
    }
    Redraw();
}

std::string ReadTalk(int talknum) {
    int offset = 0, len = 0;
    if (talknum == 0) { offset = 0; len = TIdx[0]; }
    else { offset = TIdx[talknum - 1]; len = TIdx[talknum] - offset; }
    std::vector<uint8_t> buf(len + 1, 0);
    memcpy(buf.data(), &TDef[offset], len);
    for (int i = 0; i < len; i++)
    {
        if (buf[i])
        {
            buf[i] ^= 0xFF;
        }
    }
    auto str = PotConv::cp950tocp936((const char*)buf.data());
    return cp950toutf8((const char*)buf.data());
}

void talk_1(const std::string& talkstr, int headnum, int dismode) {
    int headx, heady, diagx, diagy;
    switch (dismode) {
        case 0: headx=40; heady=85; diagx=100; diagy=30; break;
        case 1: headx=546; heady=CENTER_Y*2-75; diagx=10; diagy=CENTER_Y*2-130; break;
        case 2: headx=-1; heady=-1; diagx=100; diagy=30; break;
        case 5: headx=40; heady=CENTER_Y*2-75; diagx=100; diagy=CENTER_Y*2-130; break;
        case 4: headx=546; heady=85; diagx=10; diagy=30; break;
        default: headx=-1; heady=-1; diagx=100; diagy=CENTER_Y*2-130; break;
    }
    DrawRectangleWithoutFrame(screen, 0, diagy - 10, CENTER_X * 2, 120, 0, 60);
    if (headx > 0) DrawHeadPic(headnum, headx, heady);

    // 分行
    std::vector<std::string> lines;
    std::string cur;
    int l = 0;
    for (size_t i = 0; i < talkstr.size();) {
        if (talkstr[i] == '*') {
            if (!cur.empty()) lines.push_back(cur);
            cur.clear(); l = 0; i++; continue;
        }
        int fl = utf8follow(talkstr[i]);
        if ((uint8_t)talkstr[i] >= 0xE0) l += 2; else l += 1;
        cur += talkstr.substr(i, fl);
        i += fl;
        if (l >= 48) { lines.push_back(cur); cur.clear(); l = 0; }
    }
    if (!cur.empty()) lines.push_back(cur);

    int li = 0;
    for (size_t i = 0; i < lines.size(); i++) {
        DrawShadowText(screen, lines[i], diagx + 20, diagy + li * 22, ColColor(0xFF), ColColor(0));
        li++;
        if (li >= 4 && i < lines.size() - 1) {
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            int key;
            do { key = WaitAnyKey(); } while (key==SDLK_LEFT||key==SDLK_RIGHT||key==SDLK_UP||key==SDLK_DOWN);
            Redraw();
            DrawRectangleWithoutFrame(screen, 0, diagy - 10, CENTER_X * 2, 120, 0, 60);
            if (headx > 0) DrawHeadPic(headnum, headx, heady);
            li = 0;
        }
    }
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    int key;
    do { key = WaitAnyKey(); } while (key==SDLK_LEFT||key==SDLK_RIGHT||key==SDLK_UP||key==SDLK_DOWN);
    Redraw();
}

void instruct_1(int talknum, int headnum, int dismode) {
    std::string talkstr = ReadTalk(talknum);
    talk_1(talkstr, headnum, dismode);
}

void instruct_2(int inum, int amount) {
    instruct_32(inum, amount);
    int x = CENTER_X;
    if (Where == 2) x = 190;
    DrawRectangle(screen, x - 85, 98, 170, 76, 0, ColColor(255), 50);
    std::string word = (amount >= 0) ? "得到物品" : "失去物品";
    DrawShadowText(screen, word, x - 80, 100, ColColor(0x21), ColColor(0x23));
    DrawBig5ShadowText(screen, Ritem[inum].Name, x - 80, 125, ColColor(0x05), ColColor(0x07));
    word = "數量";
    DrawShadowText(screen, word, x - 80, 150, ColColor(0x64), ColColor(0x66));
    auto buf = std::format(" {:5d}", amount);
    DrawEngShadowText(screen, buf, x, 150, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    WaitAnyKey();
    Redraw();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
}

void ReArrangeItem(int sort) {
    std::vector<int> item(MAX_ITEM_AMOUNT, -1);
    std::vector<int> amount(726, 0);
    int p = 0;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++) {
        if (RItemList[i].Number >= 0 && RItemList[i].Amount > 0) {
            if (amount[RItemList[i].Number] == 0) { item[p++] = RItemList[i].Number; }
            amount[RItemList[i].Number] += RItemList[i].Amount;
        }
    }
    if (sort == 0) {
        for (int i = 0; i < MAX_ITEM_AMOUNT; i++) {
            if (i < p) { RItemList[i].Number = item[i]; RItemList[i].Amount = amount[item[i]]; }
            else { RItemList[i].Number = -1; RItemList[i].Amount = 0; }
        }
    } else {
        for (int i = 0; i < MAX_ITEM_AMOUNT; i++) { RItemList[i].Number = -1; RItemList[i].Amount = 0; }
        int j = 0;
        for (int i = 0; i < (int)amount.size(); i++) {
            if (amount[i] > 0) { RItemList[j].Number = i; RItemList[j].Amount = amount[i]; j++; }
        }
    }
}

void instruct_3(int list[]) {
    if (list[0] == -2) list[0] = CurScene;
    if (list[1] == -2) list[1] = CurEvent;
    if (list[11] == -2) list[11] = DData[list[0]][list[1]][9];
    if (list[12] == -2) list[12] = DData[list[0]][list[1]][10];
    int prePic = DData[list[0]][list[1]][5];
    bool modifyS = true;
    if ((MODVersion == 12 || MODVersion == 31) && list[0] != CurScene) modifyS = false;
    if (modifyS) SData[list[0]][3][DData[list[0]][list[1]][10]][DData[list[0]][list[1]][9]] = -1;
    for (int i = 0; i <= 10; i++) {
        if (list[2 + i] != -2) DData[list[0]][list[1]][i] = list[2 + i];
    }
    SData[list[0]][3][DData[list[0]][list[1]][10]][DData[list[0]][list[1]][9]] = list[1];
    if (list[0] == CurScene && prePic != DData[list[0]][list[1]][5]) NeedRefreshScene = 1;
}

int instruct_4(int inum, int jump1, int jump2) { return (inum == CurItem) ? jump1 : jump2; }

int instruct_5(int jump1, int jump2) {
    std::string ms[3] = {"取消", "戰鬥", "是否與之戰鬥？"};
    DrawTextWithRect(screen, ms[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
    int menu = CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, ms);
    Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
    return (menu == 1) ? jump1 : jump2;
}

int instruct_6(int battlenum, int jump1, int jump2, int getexp) {
    return Battle(battlenum, getexp) ? jump1 : jump2;
}

void instruct_8(int musicnum) { ExitSceneMusicNum = musicnum; }

int instruct_9(int jump1, int jump2) {
    std::string ms[3] = {"取消", "要求", "是否要求加入？"};
    DrawTextWithRect(screen, ms[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
    int menu = CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, ms);
    Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
    return (menu == 1) ? jump1 : jump2;
}

void instruct_10(int rnum) {
    for (int i = 0; i < 6; i++) {
        if (TeamList[i] < 0) {
            TeamList[i] = rnum;
            for (int i1 = 0; i1 < 4; i1++) {
                if (Rrole[rnum].TakingItem[i1] >= 0 && Rrole[rnum].TakingItemAmount[i1] <= 0)
                    Rrole[rnum].TakingItemAmount[i1] = 1;
                if (Rrole[rnum].TakingItem[i1] >= 0 && Rrole[rnum].TakingItemAmount[i1] > 0) {
                    instruct_2(Rrole[rnum].TakingItem[i1], Rrole[rnum].TakingItemAmount[i1]);
                    Rrole[rnum].TakingItem[i1] = -1;
                    Rrole[rnum].TakingItemAmount[i1] = 0;
                }
            }
            break;
        }
    }
}

int instruct_11(int jump1, int jump2) {
    std::string ms[3] = {" 否", " 是", (MODVersion != 0) ? "请選擇是或者否" : "是否需要住宿？"};
    DrawTextWithRect(screen, ms[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
    int menu = CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, ms);
    Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
    return (menu == 1) ? jump1 : jump2;
}

void instruct_12() {
    for (int i = 0; i < 6; i++) {
        int rnum = TeamList[i];
        if (rnum >= 0 && !(Rrole[rnum].Hurt > 33 || Rrole[rnum].Poison > 0)) {
            Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
            Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
            Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
            Rrole[rnum].Hurt = std::max(0, (int)(Rrole[rnum].Hurt - 33));
            Rrole[rnum].Poison = std::max(0, (int)(Rrole[rnum].Poison - 33));
        }
    }
}

void instruct_13() {
    InitialScene(0); NeedRefreshScene = 0;
    for (int i = 0; i <= 5; i++) {
        Redraw();
        DrawRectangleWithoutFrame(screen, 0, 0, screen->w, screen->h, 0, 100 - i * 20);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    }
}

void instruct_14() {
    for (int i = 0; i <= 5; i++) {
        DrawRectangleWithoutFrame(screen, 0, 0, screen->w, screen->h, 0, i * 20);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    }
}

void instruct_15() {
    Where = 4; Redraw();
    DrawShadowText(screen, " 勝敗乃兵家常事，但是……", CENTER_X - 120, 340, ColColor(255), ColColor(255));
    DrawShadowText(screen, " 地球上又多了一失蹤人口", CENTER_X - 110, 370, ColColor(255), ColColor(255));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    WaitAnyKey();
}

int instruct_16(int rnum, int jump1, int jump2) {
    for (int i = 0; i < 6; i++) if (TeamList[i] == rnum) return jump1;
    return jump2;
}

void instruct_17(int list[]) {
    if (list[0] == -2) list[0] = CurScene;
    SData[list[0]][list[1]][list[3]][list[2]] = list[4];
    if (list[0] == CurScene) NeedRefreshScene = 1;
}

int instruct_18(int inum, int jump1, int jump2) {
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++)
        if (RItemList[i].Number == inum) return jump1;
    return jump2;
}

void instruct_19(int x, int y) {
    Sx = y; Sy = x; Cx = Sx; Cy = Sy;
    InitialScene(0); Redraw();
}

int instruct_20(int jump1, int jump2) {
    for (int i = 0; i < 6; i++) if (TeamList[i] < 0) return jump2;
    return jump1;
}

void instruct_21(int rnum) {
    int newlist[6]; int p = 0;
    for (int i = 0; i < 6; i++) { newlist[i] = -1; if (TeamList[i] != rnum) newlist[p++] = TeamList[i]; }
    memcpy(TeamList, newlist, sizeof(TeamList));
}

void instruct_22() { for (int i = 0; i < 6; i++) if (TeamList[i] >= 0) Rrole[TeamList[i]].CurrentMP = 0; }
void instruct_23(int rnum, int Poison) { Rrole[rnum].UsePoi = Poison; }
void instruct_24() {}

void instruct_25(int x1, int y1, int x2, int y2) {
    if (NeedRefreshScene == 1) { InitialScene(0); NeedRefreshScene = 0; }
    int s = (x2 > x1) ? 1 : (x2 < x1) ? -1 : 0;
    int i = x1 + s;
    if (s != 0) while (true) {
        CheckBasicEvent(); SDL_Delay(50);
        DrawSceneWithoutRole(y1, i); DrawRoleOnScene(y1, i);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        i += s; if (s * (x2 - i) < 0) break;
    }
    s = (y2 > y1) ? 1 : (y2 < y1) ? -1 : 0;
    i = y1 + s;
    if (s != 0) while (true) {
        CheckBasicEvent(); SDL_Delay(50);
        DrawSceneWithoutRole(i, x2); DrawRoleOnScene(i, x2);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        i += s; if (s * (y2 - i) < 0) break;
    }
    Cx = y2; Cy = x2;
}

void instruct_26(int snum, int en, int add1, int add2, int add3) {
    if (snum == -2) snum = CurScene;
    DData[snum][en][2] += add1; DData[snum][en][3] += add2; DData[snum][en][4] += add3;
    if (snum == CurScene) { InitialScene(0); NeedRefreshScene = 0; }
}

void instruct_27(int en, int beginpic, int endpic) {
    if (en == -1) {
        for (int i = beginpic; ; i++) {
            CheckBasicEvent(); SceneRolePic = i / 2;
            SDL_Delay(20); DrawScene(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
            if (i > endpic) break;
        }
    } else {
        for (int i = beginpic; ; i++) {
            CheckBasicEvent();
            DData[CurScene][en][5] = i; DData[CurScene][en][6] = i; DData[CurScene][en][7] = i;
            InitialScene(1); SDL_Delay(20); DrawScene(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
            if (i > endpic) break;
        }
    }
}

int instruct_28(int rnum, int e1, int e2, int jump1, int jump2) {
    return (Rrole[rnum].Ethics >= e1 && Rrole[rnum].Ethics <= e2) ? jump1 : jump2;
}

int instruct_29(int rnum, int r1, int r2, int jump1, int jump2) {
    if (MODVersion == 41) return (Rrole[rnum].Attack >= r1) ? jump1 : jump2;
    return (Rrole[rnum].Attack >= r1 && Rrole[rnum].Attack <= r2) ? jump1 : jump2;
}

void instruct_30(int x1, int y1, int x2, int y2) {
    if (NeedRefreshScene == 1) { InitialScene(0); NeedRefreshScene = 0; }
    auto sign = [](int v)->int{ return (v>0)?1:(v<0)?-1:0; };
    int s = sign(x2 - x1);
    Sy = x1 + s;
    if (s > 0) SFace = 1; if (s < 0) SFace = 2;
    if (s != 0) while (true) {
        CheckBasicEvent(); SDL_Delay(50);
        DrawSceneWithoutRole(Sx, Sy); SStep++;
        if (SStep >= 7) SStep = 1;
        SceneRolePic = BEGIN_WALKPIC + SFace * 7 + SStep;
        DrawRoleOnScene(Sx, Sy); UpdateScreen(screen, 0, 0, screen->w, screen->h);
        Sy += s; if (s * (x2 - Sy) < 0) break;
    }
    s = sign(y2 - y1);
    Sx = y1 + s;
    if (s > 0) SFace = 3; if (s < 0) SFace = 0;
    if (s != 0) while (true) {
        CheckBasicEvent(); SDL_Delay(50);
        DrawSceneWithoutRole(Sx, Sy); SStep++;
        if (SStep >= 7) SStep = 1;
        SceneRolePic = BEGIN_WALKPIC + SFace * 7 + SStep;
        DrawRoleOnScene(Sx, Sy); UpdateScreen(screen, 0, 0, screen->w, screen->h);
        Sx += s; if (s * (y2 - Sx) < 0) break;
    }
    Sx = y2; Sy = x2; SStep = 0; Cx = Sx; Cy = Sy;
    SceneRolePic = 2501 + SFace * 7;
    DrawSceneWithoutRole(Sx, Sy); DrawRoleOnScene(Sx, Sy);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
}

int instruct_31(int moneynum, int jump1, int jump2) {
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++)
        if (RItemList[i].Number == MONEY_ID && RItemList[i].Amount >= moneynum) return jump1;
    return jump2;
}

void instruct_32(int inum, int amount) {
    if (amount == 0) return;
    int i = 0;
    while (RItemList[i].Number >= 0 && i < MAX_ITEM_AMOUNT) {
        if (RItemList[i].Number == inum) {
            RItemList[i].Amount += amount;
            if (RItemList[i].Amount < 0 && amount >= 0) RItemList[i].Amount = 32767;
            if (RItemList[i].Amount < 0 && amount < 0) RItemList[i].Amount = 0;
            break;
        }
        i++;
    }
    if (i < MAX_ITEM_AMOUNT && RItemList[i].Number < 0) {
        RItemList[i].Number = inum; RItemList[i].Amount = amount;
    }
    ReArrangeItem();
}

void instruct_33(int rnum, int magicnum, int dismode) {
    for (int i = 0; i < 10; i++) {
        if (Rrole[rnum].Magic[i] <= 0 || Rrole[rnum].Magic[i] == magicnum) {
            if (Rrole[rnum].Magic[i] > 0) Rrole[rnum].MagLevel[i] += 100;
            Rrole[rnum].Magic[i] = magicnum;
            if (Rrole[rnum].MagLevel[i] > 999) Rrole[rnum].MagLevel[i] = 999;
            break;
        }
    }
    if (dismode == 0) {
        DrawRectangle(screen, CENTER_X - 75, 98, 145, 76, 0, ColColor(255), 50);
        DrawShadowText(screen, "學會", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
        DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
        DrawBig5ShadowText(screen, Rmagic[magicnum].Name, CENTER_X - 70, 150, ColColor(0x64), ColColor(0x66));
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        WaitAnyKey(); Redraw();
    }
}

void instruct_34(int rnum, int iq) {
    if (Rrole[rnum].Aptitude + iq > 100) iq = 100 - Rrole[rnum].Aptitude;
    Rrole[rnum].Aptitude += iq;
    if (iq > 0) {
        DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
        DrawShadowText(screen, "資質增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
        DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
        auto buf = std::format("{:3d}", iq);
        DrawEngShadowText(screen, buf, CENTER_X + 30, 125, ColColor(0x64), ColColor(0x66));
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        WaitAnyKey(); Redraw();
    }
}

void instruct_35(int rnum, int magiclistnum, int magicnum, int exp) {
    if (magiclistnum < 0 || magiclistnum > 9) {
        for (int i = 0; i < 10; i++) {
            if (Rrole[rnum].Magic[i] <= 0) {
                Rrole[rnum].Magic[i] = magicnum; Rrole[rnum].MagLevel[i] = exp; break;
            }
        }
    } else {
        Rrole[rnum].Magic[magiclistnum] = magicnum;
        Rrole[rnum].MagLevel[magiclistnum] = exp;
    }
}

int instruct_36(int sexual, int jump1, int jump2) {
    if (sexual > 255) return (x50[0x7000] == 0) ? jump1 : jump2;
    return (Rrole[0].Sexual == sexual) ? jump1 : jump2;
}

void instruct_37(int Ethics) {
    Rrole[0].Ethics += Ethics;
    if (Rrole[0].Ethics > 100) Rrole[0].Ethics = 100;
    if (Rrole[0].Ethics < 0) Rrole[0].Ethics = 0;
}

void instruct_38(int snum, int layernum, int oldpic, int newpic) {
    if (snum == -2) snum = CurScene;
    for (int i1 = 0; i1 < 64; i1++)
        for (int i2 = 0; i2 < 64; i2++)
            if (SData[snum][layernum][i1][i2] == oldpic) SData[snum][layernum][i1][i2] = newpic;
    if (snum == CurScene) { InitialScene(0); NeedRefreshScene = 0; }
}

void instruct_39(int snum) { Rscene[snum].EnCondition = 0; }

void instruct_40(int director) {
    SFace = director;
    SceneRolePic = 2500 + SFace * 7 + 1;
    DrawScene();
}

void instruct_41(int rnum, int inum, int amount) {
    int found = 0;
    for (int i = 0; i < 4; i++) {
        if (Rrole[rnum].TakingItem[i] == inum) {
            Rrole[rnum].TakingItemAmount[i] += amount; found = 1; break;
        }
    }
    if (!found) {
        for (int i = 0; i < 4; i++) {
            if (Rrole[rnum].TakingItem[i] == -1) {
                Rrole[rnum].TakingItem[i] = inum; Rrole[rnum].TakingItemAmount[i] = amount; break;
            }
        }
    }
    for (int i = 0; i < 4; i++) {
        if (Rrole[rnum].TakingItemAmount[i] <= 0) { Rrole[rnum].TakingItem[i] = -1; Rrole[rnum].TakingItemAmount[i] = 0; }
    }
}

int instruct_42(int jump1, int jump2) {
    for (int i = 0; i < 6; i++)
        if (TeamList[i] >= 0 && Rrole[TeamList[i]].Sexual == 1) return jump1;
    return jump2;
}

int instruct_43(int inum, int jump1, int jump2) { return instruct_18(inum, jump1, jump2); }

void instruct_44(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int endpic2) {
    if (enum1 == -1) enum1 = CurEvent;
    if (enum2 == -1) enum2 = CurEvent;
    SData[CurScene][3][DData[CurScene][enum1][10]][DData[CurScene][enum1][9]] = enum1;
    SData[CurScene][3][DData[CurScene][enum2][10]][DData[CurScene][enum2][9]] = enum2;
    for (int i = 0; ; i++) {
        CheckBasicEvent();
        DData[CurScene][enum1][5] = beginpic1 + i;
        DData[CurScene][enum2][5] = beginpic2 + i;
        InitialScene(1); SDL_Delay(20); DrawScene();
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        if (i > endpic1 - beginpic1) break;
    }
}

void instruct_44e(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int enum3, int beginpic3) {
    SData[CurScene][3][DData[CurScene][enum1][10]][DData[CurScene][enum1][9]] = enum1;
    SData[CurScene][3][DData[CurScene][enum2][10]][DData[CurScene][enum2][9]] = enum2;
    SData[CurScene][3][DData[CurScene][enum3][10]][DData[CurScene][enum3][9]] = enum3;
    for (int i = 0; ; i++) {
        CheckBasicEvent();
        DData[CurScene][enum1][5] = beginpic1 + i;
        DData[CurScene][enum2][5] = beginpic2 + i;
        DData[CurScene][enum3][5] = beginpic3 + i;
        InitialScene(1); SDL_Delay(20); DrawScene();
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        if (i > endpic1 - beginpic1) break;
    }
}

void instruct_45(int rnum, int speed) {
    Rrole[rnum].Speed += speed;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "輕功增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    auto buf = std::format("{:4d}", speed);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_46(int rnum, int mp) {
    Rrole[rnum].MaxMP += mp; Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "內力增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    auto buf = std::format("{:4d}", mp);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_47(int rnum, int Attack) {
    Rrole[rnum].Attack += Attack;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "武力增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    auto buf = std::format("{:4d}", Attack);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_48(int rnum, int hp) {
    Rrole[rnum].MaxHP += hp; Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "生命增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    auto buf = std::format("{:4d}", hp);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_49(int rnum, int MPpro) { Rrole[rnum].MPType = MPpro; }

int instruct_50(int list[]) {
    if (list[0] > 128 || MODVersion == 11) {
        int p = 0;
        for (int i = 0; i < 5; i++) p += instruct_18(list[i], 1, 0);
        return (p == 5) ? list[5] : list[6];
    }
    return instruct_50e(list[0], list[1], list[2], list[3], list[4], list[5], list[6]);
}

void instruct_51() { instruct_1(SOFTSTAR_BEGIN_TALK + rand() % SOFTSTAR_NUM_TALK, 0x72, 0); }

void instruct_52() {
    DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, ColColor(255), 50);
    DrawShadowText(screen, "你的品德指數為：", CENTER_X - 105, 100, ColColor(0x05), ColColor(0x07));
    auto buf = std::format("{:3d}", Rrole[0].Ethics);
    DrawEngShadowText(screen, buf, CENTER_X + 65, 100, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_53() {
    DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, ColColor(255), 50);
    DrawShadowText(screen, "你的聲望指數為：", CENTER_X - 105, 100, ColColor(0x05), ColColor(0x07));
    auto buf = std::format("{:3d}", Rrole[0].Repute);
    DrawEngShadowText(screen, buf, CENTER_X + 65, 100, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_54() {
    for (int i = 0; i <= 100; i++) Rscene[i].EnCondition = 0;
    Rscene[2].EnCondition = 2; Rscene[38].EnCondition = 2;
    Rscene[75].EnCondition = 1; Rscene[80].EnCondition = 1;
}

int instruct_55(int en, int Value, int jump1, int jump2) {
    return (DData[CurScene][en][2] == Value) ? jump1 : jump2;
}

void instruct_56(int Repute) {
    Rrole[0].Repute += Repute;
    if (Rrole[0].Repute > 200 && Rrole[0].Repute - Repute <= 200) {
        int list[] = {70, 11, 0, 11, 0x3A4, -1, -1, 0x1F20, 0x1F20, 0x1F20, 0, 18, 21};
        instruct_3(list);
    }
}

void instruct_57() {
    instruct_27(-1, 3832 * 2, 3844 * 2);
    instruct_44e(2, 3845 * 2, 3873 * 2, 3, 3874 * 2, 4, 3903 * 2);
}

void instruct_58() {
    static const int headarray[30] = {8,21,23,31,32,43,7,11,14,20,33,34,10,12,19,22,56,68,13,55,62,67,70,71,26,57,60,64,3,69};
    for (int i = 0; i < 15; i++) {
        int p = rand() % 2;
        instruct_1(2854 + i * 2 + p, headarray[i * 2 + p], rand()%2*4+rand()%2);
        if (!Battle(102 + i * 2 + p, 0)) { instruct_15(); break; }
        instruct_14(); instruct_13();
        if (i % 3 == 2) { instruct_1(2891,70,4); instruct_12(); instruct_14(); instruct_13(); }
    }
    if (Where != 3) {
        instruct_1(2884,0,3); instruct_1(2885,0,3); instruct_1(2886,0,3);
        instruct_1(2887,0,3); instruct_1(2888,0,3); instruct_1(2889,0,1);
        instruct_2(0x8F, 1);
    }
}

void instruct_59() { for (int i = 1; i < 6; i++) TeamList[i] = -1; }

int instruct_60(int snum, int en, int pic, int jump1, int jump2) {
    if (snum == -2) snum = CurScene;
    if (DData[snum][en][5]==pic || DData[snum][en][6]==pic || DData[snum][en][7]==pic) return jump1;
    return jump2;
}

int instruct_61(int jump1, int jump2) {
    for (int i = 11; i <= 24; i++) if (DData[CurScene][i][5] != 4664) return jump2;
    return jump1;
}

void instruct_62(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int endpic2) {
    SceneRolePic = -1;
    instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2);
    Where = 3; Redraw(); EndAmi();
}

void EndAmi() {
    instruct_14(); Redraw();
    // 读取 end.txt 并逐行显示
    std::string fn = AppPath + "list/end.txt";
    std::string str = filefunc::readFileToString(fn);
    if (str.empty()) return;
    int len = (int)str.size();
    int x = 30, y = 80;
    DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
    std::string line;
    for (int i = 0; i <= len; i++) {
        if (i == len || str[i] == '\r') {
            if (!line.empty()) {
                DrawShadowText(screen, line, x, y, ColColor(0xFF), ColColor(0xFF));
                UpdateScreen(screen, x, y, DrawLength(line) * 10 + 2, 22);
                y += 25;
            }
            line.clear();
            if (i < len && str[i] == '\r' && i + 1 < len && str[i+1] == '\n') i++;
        } else if (str[i] == '*') {
            y = 80; Redraw(); WaitAnyKey();
            DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
        } else if (str[i] != '\n') {
            line += str[i];
        }
    }
    WaitAnyKey();
}

void instruct_63(int rnum, int sexual) { Rrole[rnum].Sexual = sexual; }

void instruct_64() {
    int shopnum = rand() % 5, amount = 0;
    int list[5]; std::string menuStr[5];
    for (int i = 0; i < 5; i++) {
        if (RShop[shopnum].Amount[i] > 0) {
            auto buf = std::format("{:<20s}{:5d}", cp950toutf8(Ritem[RShop[shopnum].Item[i]].Name), RShop[shopnum].Price[i]);
            menuStr[amount] = buf; list[amount] = i; amount++;
        }
    }
    instruct_1(0xB9E, 0x6F, 0);
    if (amount >= 1) {
        int menu = CommonMenu(CENTER_X - 120, 150, 205, amount - 1, menuStr);
        Redraw();
        if (menu >= 0) {
            menu = list[menu]; int price = RShop[shopnum].Price[menu];
            if (instruct_31(price, 1, 0) == 1) {
                instruct_2(RShop[shopnum].Item[menu], 1);
                instruct_32(MONEY_ID, -price);
                RShop[shopnum].Amount[menu]--;
                instruct_1(0xBA0, 0x6F, 0);
            } else instruct_1(0xB9F, 0x6F, 0);
        }
    }
}

void instruct_66(int musicnum) { StopMP3(); PlayMP3(musicnum, -1); }
void instruct_67(int Soundnum) { PlaySoundA(Soundnum, 0); }

int e_GetValue(int bit, int t, int x) {
    return (t & (1 << bit)) ? x50[x] : x;
}

int CutRegion(int x) {
    if (x >= 0x8000 || x < -0x8000) return (x + 0x8000) % 0x10000 - 0x8000;
    return x;
}

int instruct_50e(int code, int e1, int e2, int e3, int e4, int e5, int e6) {
    int t1, i, len, i1, i2, x, y, w, h, w1, h1;
    char *p, *p1, *p2;
    std::string str, word, word1;
    switch (code) {
        case 0: x50[e1] = e2; break;
        case 1: t1 = CutRegion(e3 + e_GetValue(0, e1, e4)); x50[t1] = e_GetValue(1, e1, e5); if (e2==1) x50[t1] &= 0xFF; break;
        case 2: t1 = CutRegion(e3 + e_GetValue(0, e1, e4)); x50[e5] = x50[t1]; if (e2==1) x50[t1] &= 0xFF; break;
        case 3: { t1 = e_GetValue(0, e1, e5);
            switch (e2) {
                case 0: x50[e3] = x50[e4] + t1; break;
                case 1: x50[e3] = x50[e4] - t1; break;
                case 2: x50[e3] = x50[e4] * t1; break;
                case 3: if (t1) x50[e3] = x50[e4] / t1; break;
                case 4: if (t1) x50[e3] = x50[e4] % t1; break;
                case 5: if (t1) x50[e3] = (uint16_t)x50[e4] / t1; break;
            }
        } break;
        case 4: { x50[0x7000] = 0; t1 = e_GetValue(0, e1, e4);
            bool ok = false;
            switch (e2) {
                case 0: ok = (x50[e3] < t1); break;
                case 1: ok = (x50[e3] <= t1); break;
                case 2: ok = (x50[e3] == t1); break;
                case 3: ok = (x50[e3] != t1); break;
                case 4: ok = (x50[e3] >= t1); break;
                case 5: ok = (x50[e3] > t1); break;
                case 6: ok = true; break;
                case 7: ok = false; break;
            }
            if (!ok) x50[0x7000] = 1;
        } break;
        case 5: memset(x50, 0, sizeof(x50)); break;
        case 8: { // Read talk to string
            t1 = e_GetValue(0, e1, e2);
            len = 0;
            int offset = 0;
            if (t1 == 0) {
                offset = 0;
                len = TIdx[0];
            } else {
                offset = TIdx[t1 - 1];
                len = TIdx[t1] - offset;
            }
            p = (char*)&x50[e3];
            for (i = 0; i < len - 1; i++) {
                p[i] = TDef[offset + i] ^ 0xFF;
            }
            p[len - 1] = 0;
        } break;
        case 9: { // Format the string
            e4 = e_GetValue(0, e1, e4);
            p = (char*)&x50[e2];
            p1 = (char*)&x50[e3];
            str = std::string(p1);
            char buf[256];
            snprintf(buf, sizeof(buf), str.c_str(), e4);
            str = buf;
            memcpy(p, str.c_str(), str.size() + 1);
        } break;
        case 10: { // Get the length of a string
            p = (char*)&x50[e1];
            x50[e2] = (int16_t)strlen(p);
        } break;
        case 11: { // Combine 2 strings
            p = (char*)&x50[e1];
            p1 = (char*)&x50[e2];
            int len1 = (int)strlen(p1);
            memcpy(p, p1, len1);
            p += len1;
            if (len1 % 2 == 1) { *p = 0x20; p++; }
            p1 = (char*)&x50[e3];
            int len2 = (int)strlen(p1);
            memcpy(p, p1, len2 + 1);
        } break;
        case 12: { // Build a string with spaces
            e3 = e_GetValue(0, e1, e3);
            p = (char*)&x50[e2];
            for (i = 0; i <= e3 / 2; i++) { *p = ' '; p++; }
            *p = 0;
        } break;
        case 16: { e3 = e_GetValue(0, e1, e3); e4 = e_GetValue(1, e1, e4); e5 = e_GetValue(2, e1, e5);
            if (e3 >= 0) switch (e2) {
                case 0: Rrole[e3].Data[e4/2] = e5; break;
                case 1: Ritem[e3].Data[e4/2] = e5; break;
                case 2: Rscene[e3].Data[e4/2] = e5; break;
                case 3: Rmagic[e3].Data[e4/2] = e5; break;
                case 4: RShop[e3].Data[e4/2] = e5; break;
            }
        } break;
        case 17: { e3 = e_GetValue(0, e1, e3); e4 = e_GetValue(1, e1, e4);
            if (e3 >= 0) switch (e2) {
                case 0: x50[e5] = Rrole[e3].Data[e4/2]; break;
                case 1: x50[e5] = Ritem[e3].Data[e4/2]; break;
                case 2: x50[e5] = Rscene[e3].Data[e4/2]; break;
                case 3: x50[e5] = Rmagic[e3].Data[e4/2]; break;
                case 4: x50[e5] = RShop[e3].Data[e4/2]; break;
            }
        } break;
        case 18: { e2 = e_GetValue(0, e1, e2); e3 = e_GetValue(1, e1, e3); TeamList[e2] = e3; } break;
        case 19: { e2 = e_GetValue(0, e1, e2); x50[e3] = TeamList[e2]; } break;
        case 20: { e2 = e_GetValue(0, e1, e2); x50[e3] = 0;
            for (i = 0; i < MAX_ITEM_AMOUNT; i++) if (RItemList[i].Number == e2) { x50[e3] = RItemList[i].Amount; break; }
        } break;
        case 21: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); e5=e_GetValue(3,e1,e5); DData[e2][e3][e4]=e5; } break;
        case 22: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); x50[e5]=DData[e2][e3][e4]; } break;
        case 23: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); e5=e_GetValue(3,e1,e5); e6=e_GetValue(4,e1,e6); SData[e2][e3][e5][e4]=e6; } break;
        case 24: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); e5=e_GetValue(3,e1,e5); x50[e6]=SData[e2][e3][e5][e4]; } break;
        case 25: { // Write memory by address
            e5 = e_GetValue(0, e1, e5);
            e6 = e_GetValue(1, e1, e6);
            t1 = (uint16_t)e3 + (uint16_t)e4 * 0x10000 + (uint16_t)e6;
            i = (uint16_t)e3 + (uint16_t)e4 * 0x10000;
            switch (t1) {
                case 0x1D295A: Sx = e5; break;
                case 0x1D295C: Sy = e5; break;
            }
            switch (i) {
                case 0x18FE2C:
                    if (e6 % 4 <= 1) RItemList[e6 / 4].Number = e5;
                    else RItemList[e6 / 4].Amount = e5;
                    break;
                case 0x051C83:
                    *((uint16_t*)&ACol[e6]) = e5;
                    *((uint16_t*)&ACol1[e6]) = e5;
                    *((uint16_t*)&ACol2[e6]) = e5;
                    break;
                case 0x1D295E:
                    CurScene = e5;
                    break;
            }
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
        } break;
        case 26: { // Read memory by address
            e6 = e_GetValue(0, e1, e6);
            t1 = (uint16_t)e3 + (uint16_t)e4 * 0x10000 + (uint16_t)e6;
            i = (uint16_t)e3 + (uint16_t)e4 * 0x10000;
            switch (t1) {
                case 0x1D295E: x50[e5] = CurScene; break;
                case 0x1D295A: x50[e5] = Sx; break;
                case 0x1D295C: x50[e5] = Sy; break;
                case 0x1C0B88: x50[e5] = Mx; break;
                case 0x1C0B8C: x50[e5] = My; break;
                case 0x05B53A: x50[e5] = 1; break;
                case 0x0544F2: x50[e5] = SFace; break;
                case 0x1E6ED6: x50[e5] = x50[28100]; break;
                case 0x556DA: x50[e5] = Ax; break;
                case 0x556DC: x50[e5] = Ay; break;
                case 0x1C0B90: x50[e5] = SDL_GetTicks() / 55 % 65536; break;
            }
            if (t1 - 0x18FE2C >= 0 && t1 - 0x18FE2C < 800) {
                i = t1 - 0x18FE2C;
                if (i % 4 <= 1) x50[e5] = RItemList[i / 4].Number;
                else x50[e5] = RItemList[i / 4].Amount;
            }
            if (t1 >= 0x1E4A04 && t1 < 0x1E6A04) {
                i = (t1 - 0x1E4A04) / 2;
                x50[e5] = BField[2][i % 64][i / 64];
            }
        } break;
        case 27: { // Read name to string
            e3 = e_GetValue(0, e1, e3);
            p = (char*)&x50[e4];
            if (e3 >= 0) {
                switch (e2) {
                    case 0: p1 = (char*)Rrole[e3].Name; break;
                    case 1: p1 = (char*)Ritem[e3].Name; break;
                    case 2: p1 = (char*)Rscene[e3].Name; break;
                    case 3: p1 = (char*)Rmagic[e3].Name; break;
                    default: p1 = (char*)""; break;
                }
                len = std::min(10, (int)strlen(p1));
                memcpy(p, p1, len);
                p += len;
                if (len % 2 == 1) { *p = 0x20; p++; }
                *p = 0;
            }
        } break;
        case 28: x50[e1] = x50[28005]; break;
        case 29: { // Select aim
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            if (e5 == 0) SelectAim(e2, e3);
            x50[e4] = BField[2][Ax][Ay];
        } break;
        case 30: { // Read battle properties
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            x50[e4] = Brole[e2].Data[e3 / 2];
        } break;
        case 31: { // Write battle properties
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            Brole[e2].Data[e3 / 2] = e4;
        } break;
        case 32: { e3=e_GetValue(0,e1,e3); Script5032Pos=e3; Script5032Value=x50[e2]; return 655360*(e3+1)+x50[e2]; }
        case 33: { // Draw a string
            e3 = e_GetValue(0, e1, e3);
            e4 = e_GetValue(1, e1, e4);
            e5 = e_GetValue(2, e1, e5);
            p = (char*)&x50[e2];
            p1 = p;
            i = 0;
            x = e3; y = e4; w = 0;
            while ((uint8_t)*p > 0) {
                if ((uint8_t)*p == 0x2A) {
                    *p = 0;
                    DrawBig5ShadowText(screen, p1, e3 - 2, e4 + 22 * i - 3, ColColor(e5 & 0xFF), ColColor((e5 & 0xFF00) << 8));
                    i++;
                    p1 = p + 1;
                    w1 = (int)strlen(p1) * 11;
                    if (w1 > w) w = w1;
                }
                p++;
            }
            DrawBig5ShadowText(screen, p1, e3 - 2, e4 + 22 * i - 3, ColColor(e5 & 0xFF), ColColor((e5 & 0xFF00) << 8));
            w1 = (int)strlen(p1) * 11;
            if (w1 > w) w = w1;
            UpdateScreen(screen, x - 3, y - 3, w + 6, 22 * (i + 1) + 6);
        } break;
        case 34: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); e5=e_GetValue(3,e1,e5);
            DrawRectangle(screen, e2, e3, e4, e5, 0, ColColor(0xFF), 50);
            UpdateScreen(screen, e2, e3, e4+1, e5+1);
        } break;
        case 35: { i = WaitAnyKey(); x50[e1] = i;
            if (i==SDLK_LEFT) x50[e1]=154; if (i==SDLK_RIGHT) x50[e1]=156;
            if (i==SDLK_UP) x50[e1]=158; if (i==SDLK_DOWN) x50[e1]=152;
        } break;
        case 36: { // Draw a string with background then pause
            e3 = e_GetValue(0, e1, e3);
            e4 = e_GetValue(1, e1, e4);
            e5 = e_GetValue(2, e1, e5);
            p = (char*)&x50[e2];
            i1 = 1; i2 = 0; t1 = 0;
            e3 = abs(e3);
            char* pp = p;
            while ((uint8_t)*pp > 0) {
                if ((uint8_t)*pp == 0x2A) { if (t1 > i2) i2 = t1; t1 = 0; i1++; }
                if ((uint8_t)*pp == 0x20) t1++;
                pp++; t1++;
            }
            if (t1 > i2) i2 = t1;
            pp--;
            if (i1 == 0) i1 = 1;
            if ((uint8_t)*pp == 0x2A) i1--;
            DrawRectangle(screen, e3, e4, i2 * 10 + 25, i1 * 22 + 5, 0, ColColor(255), 50);
            p1 = p;
            i = 0;
            while ((uint8_t)*p > 0) {
                if ((uint8_t)*p == 0x2A) {
                    *p = 0;
                    DrawBig5ShadowText(screen, p1, e3 + 3, e4 + 22 * i + 2, ColColor(e5 & 0xFF), ColColor((e5 & 0xFF00) << 8));
                    i++; p1 = p + 1;
                }
                p++;
            }
            DrawBig5ShadowText(screen, p1, e3 + 3, e4 + 22 * i + 2, ColColor(e5 & 0xFF), ColColor((e5 & 0xFF00) << 8));
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            i = WaitAnyKey();
            if (i == SDLK_Y) x50[0x7000] = 0; else x50[0x7000] = 1;
        } break;
        case 37: { e2=e_GetValue(0,e1,e2); SDL_Delay(e2); } break;
        case 38: { e2=e_GetValue(0,e1,e2); x50[e3] = rand() % e2; } break;
        case 39: { // Show a menu to select
            e2 = e_GetValue(0, e1, e2);
            e5 = e_GetValue(1, e1, e5);
            e6 = e_GetValue(2, e1, e6);
            std::vector<std::string> menuString(e2);
            t1 = 0;
            for (i = 0; i < e2; i++) {
                p = (char*)&x50[x50[e3 + i]];
                menuString[i] = cp950toutf8(p);
                i1 = (int)strlen(p);
                if (i1 > t1) t1 = i1;
            }
            x50[e4] = CommonMenu(e5, e6, t1 * 10 + 5, e2 - 1, menuString.data()) + 1;
        } break;
        case 40: { // Show a scroll menu to select
            e2 = e_GetValue(0, e1, e2);
            e5 = e_GetValue(1, e1, e5);
            e6 = e_GetValue(2, e1, e6);
            std::vector<std::string> menuString(e2);
            i2 = 0;
            for (i = 0; i < e2; i++) {
                p = (char*)&x50[x50[e3 + i]];
                menuString[i] = cp950toutf8(p);
                i1 = (int)strlen(p);
                if (i1 > i2) i2 = i1;
            }
            t1 = (e1 >> 8) & 0xFF;
            if (t1 == 0) t1 = 5;
            x50[e4] = CommonScrollMenu(e5, e6, i2 * 10 + 5, e2 - 1, t1, menuString.data()) + 1;
        } break;
        case 41: { // Draw a picture
            e3 = e_GetValue(0, e1, e3);
            e4 = e_GetValue(1, e1, e4);
            e5 = e_GetValue(2, e1, e5);
            w = 0; h = 0; x = 0; y = 0;
            switch (e2) {
                case 0:
                    if (Where != 1 || (MODVersion == 22 && CurEvent == -1)) {
                        DrawMPic(e5 / 2, e3, e4);
                        GetPicSize(e5 / 2, MIdx.data(), MPic.data(), w, h, x, y);
                    } else {
                        DrawSPic(e5 / 2, e3, e4, 0, 0, screen->w, screen->h);
                        GetPicSize(e5 / 2, SIdx.data(), SPic.data(), w, h, x, y);
                    }
                    break;
                case 1:
                    DrawHeadPic(e5, e3, e4);
                    GetPicSize(e5 / 2, HIdx.data(), HPic.data(), w, h, x, y);
                    break;
                case 2: {
                    str = AppPath + "pic/" + std::to_string(e5) + ".png";
                    display_img(str.c_str(), e3, e4);
                } break;
            }
            UpdateScreen(screen, e3 - x, e4 - y, w, h);
        } break;
        case 42: { // Change position on world map
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(0, e1, e3);
            Mx = e3; My = e2;
        } break;
        case 43: { // Call another event
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            e5 = e_GetValue(3, e1, e5);
            e6 = e_GetValue(4, e1, e6);
            x50[0x7100] = e3;
            x50[0x7101] = e4;
            x50[0x7102] = e5;
            x50[0x7103] = e6;
            if (e2 == 202) {
                if (e5 == 0) instruct_2(e3, e4);
                else instruct_32(e3, e4);
            } else if (e2 == 201) {
                NewTalk(e3, e4, e5, e6 % 100, (e6 % 100) / 10, e6 / 100, 0);
            } else if (e2 == 176 && MODVersion == 22) {
                x50[10032] = EnterNumber(0, 32767, CENTER_X, CENTER_Y - 100);
                x50[0x7000] = 0;
                Redraw();
            } else {
                CallEvent(e2);
            }
        } break;
        case 44: { // Play animation
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            PlayActionAmination(e2, e3);
            PlayMagicAmination(e2, e4);
        } break;
        case 45: { // Show values
            e2 = e_GetValue(0, e1, e2);
            ShowHurtValue(e2);
        } break;
        case 46: { // Set effect layer
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            e5 = e_GetValue(3, e1, e5);
            e6 = e_GetValue(4, e1, e6);
            for (i1 = e2; i1 < e2 + e4; i1++)
                for (i2 = e3; i2 < e3 + e5; i2++)
                    BField[4][i1][i2] = e6;
        } break;
        case 47: break; // No need to re-set the pic
        case 48: { // Show some parameters (debug)
            str = "";
            for (i = e1; i < e1 + e2; i++)
                str += "x" + std::to_string(i) + "=" + std::to_string(x50[i]) + "\n";
            if (FULLSCREEN == 0) {
#ifdef _WIN32
                MessageBoxA(0, str.c_str(), "KYS Windows", MB_OK);
#endif
            }
        } break;
        case 49: break; // In PE files, you can't call any procedure as your wish
        case 50: { // Enter name for items, magics and roles
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            e5 = e_GetValue(3, e1, e5);
            switch (e2) {
                case 0: p = (char*)Rrole[e3].Name; break;
                case 1: p = (char*)Ritem[e3].Name; break;
                case 2: p = (char*)Rmagic[e3].Name; break;
                case 3: p = (char*)Rscene[e3].Name; break;
                default: p = nullptr; break;
            }
            if (p) {
                word1 = cp950toutf8(p);
                word = "\u8ACB\u8F38\u5165\u540D\u5B57\uFF1A";
                DrawTextWithRect(word, CENTER_X - 133, CENTER_Y - 30, 266, ColColor(0x21), ColColor(0x23));
                std::string inputStr = word1;
                if (EnterString(inputStr, CENTER_X - 43, CENTER_Y + 10, 86, 20)) {
                    str = utf8tocp950(inputStr);
                    int copyLen = std::min((int)e5, (int)str.size());
                    memcpy(p, str.c_str(), copyLen);
                    if (copyLen < 10) p[copyLen] = 0;
                }
            }
        } break;
        case 51: { // Enter a number
            x50[e1] = EnterNumber(0, 32767, CENTER_X, CENTER_Y - 100);
        } break;
        case 52: { // Judge someone grasp some magic
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            e4 = e_GetValue(2, e1, e4);
            x50[0x7000] = 1;
            if (HaveMagic(e2, e3, e4)) x50[0x7000] = 0;
        } break;
        case 60: { // Call scripts
            e2 = e_GetValue(0, e1, e2);
            e3 = e_GetValue(1, e1, e3);
            ExecScript("script/" + std::to_string(e2) + ".lua", "f" + std::to_string(e3));
        } break;
        default: break;
    }
    return 0;
}

bool HaveMagic(int person, int mnum, int lv) {
    for (int i = 0; i < 10; i++) {
        if (Rrole[person].Magic[i] == mnum && Rrole[person].MagLevel[i] >= lv) return true;
    }
    return false;
}

void StudyMagic(int rnum, int magicnum, int newmagicnum, int level, int dismode) {
    instruct_33(rnum, newmagicnum, dismode);
}

void DivideName(const std::string& fullname, std::string& surname, std::string& givenname) {
    if (fullname.size() >= 3 && (uint8_t)fullname[0] >= 0x80) {
        int fl = utf8follow(fullname[0]);
        surname = fullname.substr(0, fl);
        givenname = fullname.substr(fl);
    } else {
        surname = fullname; givenname = "";
    }
}

std::string ReplaceStr(const std::string& S, const std::string& Srch, const std::string& Replace) {
    std::string result = S;
    size_t pos = 0;
    while ((pos = result.find(Srch, pos)) != std::string::npos) {
        result.replace(pos, Srch.size(), Replace);
        pos += Replace.size();
    }
    return result;
}

void NewTalk(int headnum, int talknum, int namenum, int place, int showhead, int color, int frame, const std::string& content, const std::string& disname) {
    const int RowSpacing = 25;
    const int ColSpacing = 20;
    const int MaxRow = 5;
    const int ExpressionMin = 412;
    const int ExpressionMax = 429;
    const std::string FullNameCode = "&&";
    const std::string SurNameCode = "$$";
    const std::string GivenNameCode = "%%";
    const std::string WaitAnyKeyCode = "@@";
    const std::string DelayCode = "##";
    const std::string NextLineCode = "**";
    const std::string ChangeColorCode = "^";

    int MaxCol = 25;
    MaxCol = (int)((CENTER_X * 2 - (768 - MaxCol * ColSpacing)) / ColSpacing);

    int Frame_X = 50;
    int Frame_Y = CENTER_Y * 2 - 180;
    int Talk_X = Frame_X + 50;
    int Talk_Y = Frame_Y + 35;
    int Talk_W = MaxCol;
    int Talk_H = MaxRow;
    int Name_X = Talk_X;
    int Name_Y = Frame_Y + 7;
    int Head_X = 30, Head_Y = CENTER_Y * 2 - 120;

    if (place > 2) place = 5 - place;
    if (place == 0) {
        Head_X = 30; Head_Y = CENTER_Y * 2 - 120;
    } else if (place == 1) {
        Head_X = CENTER_X * 2 - 200; Head_Y = CENTER_Y * 2 - 120;
        Talk_X = 30; Name_X = Talk_X; Name_Y = Frame_Y + 7;
    } else if (place == 2) {
        Talk_X = Frame_X + 70;
    }

    // 特殊颜色值
    switch (color) {
        case 0: color = 28515; break; case 1: color = 28421; break;
        case 2: color = 28435; break; case 3: color = 28563; break;
        case 4: color = 28466; break; case 5: color = 28450; break;
    }
    uint8_t ForeGroundCol = color & 0xFF;
    uint8_t BackGroundCol = (color & 0xFF00) >> 8;

    // 读取对话内容
    std::string TalkStr;
    if (content.empty()) {
        if (talknum >= 0) {
            TalkStr = ReadTalk(talknum);
        } else {
            if (-talknum >= 0 && -talknum <= 32767)
                TalkStr = std::string((const char*)&x50[-talknum]);
            else
                TalkStr = "";
        }
    } else {
        TalkStr = content;
    }
    TalkStr = " " + TalkStr;

    // 读取名字
    std::string NameStr;
    if (disname.empty()) {
        if (namenum > 0) {
            NameStr = ReadTalk(namenum);
        }
        int HeadNumR = headnum;
        if (headnum >= ExpressionMin && headnum <= ExpressionMax)
            HeadNumR = 0;
        if (namenum == -2) {
            for (int i = 0; i < (int)(sizeof(Rrole)/sizeof(Rrole[0])); i++) {
                if (Rrole[i].HeadNum == HeadNumR || (i == 0 && HeadNumR == 0)) {
                    NameStr = cp950toutf8(Rrole[i].Name, 20);
                    break;
                }
            }
        }
        if (namenum == -1 || namenum == 0)
            NameStr = "";
    } else {
        NameStr = disname;
    }

    // 分析主角名字并替换
    std::string FullNameStr = cp950toutf8(Rrole[0].Name, 20);
    if (TalkStr.find(FullNameCode) != std::string::npos) {
        std::string result;
        size_t pos = 0, found;
        while ((found = TalkStr.find(FullNameCode, pos)) != std::string::npos) {
            result += TalkStr.substr(pos, found - pos) + FullNameStr;
            pos = found + FullNameCode.size();
        }
        result += TalkStr.substr(pos);
        TalkStr = result;
    }
    // $$ 和 %% 替换 (SurName/GivenName 暂为空)
    {
        std::string result;
        size_t pos = 0, found;
        while ((found = TalkStr.find(SurNameCode, pos)) != std::string::npos) {
            result += TalkStr.substr(pos, found - pos);
            pos = found + SurNameCode.size();
        }
        result += TalkStr.substr(pos);
        TalkStr = result;
    }
    {
        std::string result;
        size_t pos = 0, found;
        while ((found = TalkStr.find(GivenNameCode, pos)) != std::string::npos) {
            result += TalkStr.substr(pos, found - pos);
            pos = found + GivenNameCode.size();
        }
        result += TalkStr.substr(pos);
        TalkStr = result;
    }

    // 显示对话
    Redraw();
    uint32_t DrawForeGroundCol = ColColor(ForeGroundCol);
    uint32_t DrawBackGroundCol = ColColor(BackGroundCol);
    int len = (int)TalkStr.size();
    int I = 0; // 0-based index in C++
    CleanKeyValue();
    while (true) {
        Redraw();
        DrawRectangleWithoutFrame(screen, 0, Frame_Y, CENTER_X * 2, 170, 0, 40);
        if (showhead == 0 && headnum >= 0)
            DrawHeadPic(headnum, Head_X, Head_Y);
        if (!NameStr.empty() || showhead != 0)
            DrawShadowText(screen, NameStr, Name_X, Name_Y, ColColor(5), ColColor(7));
        UpdateAllScreen();

        int ix = 0, iy = 0;
        bool skipSync = false;
        while (SDL_WaitEvent(&event)) {
            CheckBasicEvent();
            // ESC / 右键 - 跳过
            if ((event.type == SDL_EVENT_KEY_UP && event.key.key == SDLK_ESCAPE) ||
                (event.type == SDL_EVENT_MOUSE_BUTTON_UP && event.button.button == SDL_BUTTON_RIGHT)) {
                skipSync = true; SkipTalk = 1; break;
            }
            // Enter/Space/左键 - 加速
            if ((event.type == SDL_EVENT_KEY_UP && (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE)) ||
                (event.type == SDL_EVENT_MOUSE_BUTTON_UP && event.button.button == SDL_BUTTON_LEFT)) {
                skipSync = true; SkipTalk = 0;
            }
            if (!(ix < Talk_W && iy < Talk_H && I < len)) break;

            // 检查@@等待按键
            if (I + 1 < len && TalkStr.substr(I, 2) == WaitAnyKeyCode) {
                I += 2; WaitAnyKey(); continue;
            }
            // 检查##延时
            if (I + 1 < len && TalkStr.substr(I, 2) == DelayCode) {
                I += 2; SDL_Delay(500); continue;
            }
            // 检查**换行
            if (I + 1 < len && TalkStr.substr(I, 2) == NextLineCode) {
                iy++; ix = 0; I += 2;
                if (iy >= Talk_H) {
                    if (I < len) WaitAnyKey();
                    break;
                }
                continue;
            }
            // 检查颜色更换 ^0-^5
            bool changed = false;
            for (int i2 = 0; i2 <= 5; i2++) {
                char code[3] = {'^', (char)('0' + i2), 0};
                if (I + 1 < len && TalkStr.substr(I, 2) == code) {
                    DrawBackGroundCol = ColColor(0x6F);
                    switch (i2) {
                        case 0: DrawForeGroundCol = ColColor(0x63); break;
                        case 1: DrawForeGroundCol = ColColor(0x05); break;
                        case 2: DrawForeGroundCol = ColColor(0x13); break;
                        case 3: DrawForeGroundCol = ColColor(0x93); break;
                        case 4: DrawForeGroundCol = ColColor(0x32); break;
                        case 5: DrawForeGroundCol = ColColor(0x22); break;
                    }
                    I += 2; changed = true; break;
                }
            }
            if (changed) continue;
            // 检查^^ 恢复默认颜色
            if (I + 1 < len && TalkStr.substr(I, 2) == "^^") {
                DrawBackGroundCol = ColColor(BackGroundCol);
                DrawForeGroundCol = ColColor(ForeGroundCol);
                I += 2; continue;
            }
            // 写字符
            if (I < len) {
                int len_utf8 = utf8follow(TalkStr[I]);
                std::string tempstr = TalkStr.substr(I, len_utf8);
                int xtemp = Talk_X + ColSpacing * ix;
                // Pascal: uint16(tempstr[1]) < $1000 始终为真, 所有字符都 +5
                xtemp += 5;
                DrawShadowText(screen, tempstr, xtemp, Talk_Y + RowSpacing * iy, DrawForeGroundCol, DrawBackGroundCol);
                I += len_utf8;
            }
            if (!skipSync && SkipTalk == 0) {
                SDL_Delay(5);
                UpdateAllScreen();
            }
            ix++;
            if (ix >= Talk_W || iy >= Talk_H) {
                ix = 0; iy++;
                if (iy >= Talk_H) {
                    if (I < len) {
                        UpdateAllScreen();
                        if (SkipTalk == 0) {
                            WaitAnyKey();
                            if (skipSync) WaitAnyKey();
                            skipSync = false;
                        }
                    }
                    UpdateAllScreen();
                    break;
                }
            }
        }
        if (I >= len) break;
    }
    UpdateAllScreen();
    if (SkipTalk == 0) {
        WaitAnyKey();
        if (false) WaitAnyKey(); // skipSync is local, already handled
    }
}

int EnterNumber(int MinValue, int MaxValue, int x, int y, int Default) {
    CleanKeyValue();
    int Value = Default;
    if (MinValue < -32768) MinValue = -32768;
    if (MaxValue > 32767) MaxValue = 32767;

    // 13个按钮：0-9=数字, 10=±, 11=←, 12=AC, 13=OK
    std::string str[14];
    SDL_Rect Button[14];
    for (int i = 0; i <= 9; i++) {
        str[i] = std::to_string(i);
        Button[i].x = x + (i + 2) % 3 * 35 + 20;
        Button[i].y = y + (3 - (i + 2) / 3) * 30 + 50;
        Button[i].w = 25;
        Button[i].h = 23;
    }
    str[10] = "  ±";
    Button[10].x = x + 20;  Button[10].y = y + 140; Button[10].w = 60; Button[10].h = 23;
    str[11] = "←";
    Button[11].x = x + 125; Button[11].y = y + 50;  Button[11].w = 35; Button[11].h = 23;
    str[12] = "AC";
    Button[12].x = x + 125; Button[12].y = y + 80;  Button[12].w = 35; Button[12].h = 23;
    str[13] = "OK";
    Button[13].x = x + 125; Button[13].y = y + 110; Button[13].w = 35; Button[13].h = 53;
    int highButton = 13;

    // 绘制底板和按钮框
    DrawRectangle(screen, x, y, 180, 180, 0, ColColor(255), 50);
    DrawRectangle(screen, x + 20, y + 10, 140, 23, 0, ColColor(255), 75);
    for (int i = 0; i <= highButton; i++) {
        DrawRectangle(screen, Button[i].x, Button[i].y, Button[i].w, Button[i].h, 0, ColColor(255), 50);
    }
    UpdateAllScreen();
    RecordFreshScreen(x, y, 181, 181);

    // 显示范围提示
    auto strv = std::format("{}~{}", MinValue, MaxValue);
    DrawTextWithRect(strv, x, y - 35, DrawLength(strv) * 10 + 7, ColColor(0x21), ColColor(0x27));

    int menu = -1;
    int sure = 0; // 1=键盘, 2=鼠标
    int pvalue = -1;
    int pmenu = -1;

    while (SDL_PollEvent(&event) || true) {
        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_KEY_UP:
                if (event.key.key >= SDLK_0 && event.key.key <= SDLK_9)
                    menu = event.key.key - SDLK_0;
                else if (event.key.key >= SDLK_KP_1 && event.key.key <= SDLK_KP_9)
                    menu = event.key.key - SDLK_KP_1 + 1;
                else if (event.key.key == SDLK_KP_0)
                    menu = 0;
                else if (event.key.key == SDLK_MINUS || event.key.key == SDLK_KP_MINUS)
                    menu = 10;
                else if (event.key.key == SDLK_DELETE || event.key.key == SDLK_BACKSPACE)
                    menu = 11;
                else if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE || event.key.key == SDLK_KP_ENTER)
                    menu = highButton;
                sure = 1;
                break;
            case SDL_EVENT_MOUSE_MOTION:
                menu = -1;
                for (int i = 0; i <= highButton; i++) {
                    if (MouseInRegion(Button[i].x, Button[i].y, Button[i].w, Button[i].h)) {
                        menu = i;
                        break;
                    }
                }
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_LEFT) {
                    menu = -1;
                    for (int i = 0; i <= highButton; i++) {
                        if (MouseInRegion(Button[i].x, Button[i].y, Button[i].w, Button[i].h)) {
                            menu = i;
                            break;
                        }
                    }
                    if (menu >= 0 && menu <= highButton)
                        sure = 2;
                }
                break;
        }
        // 刷新界面
        if (Value != pvalue || menu != pmenu) {
            LoadFreshScreen(x, y, 181, 181);
            auto vbuf = std::format("{:6d}", Value);
            DrawShadowText(screen, vbuf, x + 80, y + 10, ColColor(0x64), ColColor(0x66));
            if (menu >= 0 && menu <= highButton) {
                DrawRectangle(screen, Button[menu].x, Button[menu].y, Button[menu].w, Button[menu].h,
                              ColColor(rand() % 20), ColColor(255), 50);
            }
            for (int i = 0; i <= highButton; i++) {
                DrawShadowText(screen, str[i], Button[i].x + 8, Button[i].y + Button[i].h / 2 - 11,
                               ColColor(5), ColColor(7));
            }
            UpdateAllScreen();
            pvalue = Value;
            pmenu = menu;
        }
        CleanKeyValue();
        // 计算数值变化
        if (sure > 0) {
            if (menu >= 0 && menu <= 9) {
                if ((double)Value * 10 < 1E5)
                    Value = 10 * Value + menu;
            } else if (menu == 10) {
                Value = -Value;
            } else if (menu == 11) {
                Value = Value / 10;
            } else if (menu == 12) {
                Value = 0;
            } else if (menu == highButton) {
                break;
            }
            if (sure == 1) menu = -1;
        }
        sure = 0;
        SDL_Delay(25);
    }
    int Result = RegionParameter(Value, MinValue, MaxValue);
    if (Result != Value) {
        Redraw();
        UpdateAllScreen();
        auto msg = std::format("依據範圍自動調整為{}！", Result);
        DrawTextWithRect(msg, x, y, DrawLength(msg) * 10 + 7, ColColor(0x64), ColColor(0x66));
        WaitAnyKey();
    }
    CleanKeyValue();
    return Result;
}

void SetAttribute(int rnum, int selecttype, int modlevel, int minlevel, int maxlevel) {
    // 留空 - 原始Pascal中也注释了实现
}
