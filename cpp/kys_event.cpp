// kys_event.cpp - 事件系统实现
// 对应 kys_event.pas

#include "kys_event.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_main.h"
#include "kys_battle.h"
#include "kys_script.h"
#include "kys_type.h"

#include <SDL3/SDL.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>

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
    for (int i = 0; i < len; i++) buf[i] ^= 0xFF;
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
    char buf[32]; snprintf(buf, sizeof(buf), " %5d", amount);
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

void instruct_8(int musicnum) { exitscenemusicnum = musicnum; }

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
        char buf[16]; snprintf(buf, sizeof(buf), "%3d", iq);
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
    char buf[16]; snprintf(buf, sizeof(buf), "%4d", speed);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_46(int rnum, int mp) {
    Rrole[rnum].MaxMP += mp; Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "內力增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    char buf[16]; snprintf(buf, sizeof(buf), "%4d", mp);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_47(int rnum, int Attack) {
    Rrole[rnum].Attack += Attack;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "武力增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    char buf[16]; snprintf(buf, sizeof(buf), "%4d", Attack);
    DrawEngShadowText(screen, buf, CENTER_X + 20, 125, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_48(int rnum, int hp) {
    Rrole[rnum].MaxHP += hp; Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    DrawShadowText(screen, "生命增加", CENTER_X - 70, 125, ColColor(0x05), ColColor(0x07));
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 70, 100, ColColor(0x21), ColColor(0x23));
    char buf[16]; snprintf(buf, sizeof(buf), "%4d", hp);
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
    char buf[16]; snprintf(buf, sizeof(buf), "%3d", Rrole[0].Ethics);
    DrawEngShadowText(screen, buf, CENTER_X + 65, 100, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h); WaitAnyKey(); Redraw();
}

void instruct_53() {
    DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, ColColor(255), 50);
    DrawShadowText(screen, "你的聲望指數為：", CENTER_X - 105, 100, ColColor(0x05), ColColor(0x07));
    char buf[16]; snprintf(buf, sizeof(buf), "%3d", Rrole[0].Repute);
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
    FILE* f = fopen(fn.c_str(), "rb");
    if (!f) return;
    fseek(f, 0, SEEK_END); int len = (int)ftell(f); fseek(f, 0, SEEK_SET);
    std::string str(len, 0); fread(&str[0], 1, len, f); fclose(f);
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
            char buf[64]; snprintf(buf, sizeof(buf), "%-20s%5d", cp950toutf8(Ritem[RShop[shopnum].Item[i]].Name).c_str(), RShop[shopnum].Price[i]);
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
    int t1, i, len;
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
        case 28: x50[e1] = x50[28005]; break;
        case 32: { e3=e_GetValue(0,e1,e3); Script5032Pos=e3; Script5032Value=x50[e2]; return 655360*(e3+1)+x50[e2]; }
        case 35: { i = WaitAnyKey(); x50[e1] = i;
            if (i==SDLK_LEFT) x50[e1]=154; if (i==SDLK_RIGHT) x50[e1]=156;
            if (i==SDLK_UP) x50[e1]=158; if (i==SDLK_DOWN) x50[e1]=152;
        } break;
        case 37: { e2=e_GetValue(0,e1,e2); SDL_Delay(e2); } break;
        case 38: { e2=e_GetValue(0,e1,e2); x50[e3] = rand() % e2; } break;
        case 34: { e2=e_GetValue(0,e1,e2); e3=e_GetValue(1,e1,e3); e4=e_GetValue(2,e1,e4); e5=e_GetValue(3,e1,e5);
            DrawRectangle(screen, e2, e3, e4, e5, 0, ColColor(0xFF), 50);
            UpdateScreen(screen, e2, e3, e4+1, e5+1);
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
    std::string talkstr = content.empty() ? ReadTalk(talknum) : content;
    talk_1(talkstr, headnum, place);
}

int EnterNumber(int MinValue, int MaxValue, int x, int y, int Default) {
    int val = Default;
    if (val < MinValue) val = MinValue;
    if (val > MaxValue) val = MaxValue;
    while (true) {
        Redraw();
        char buf[32]; snprintf(buf, sizeof(buf), "%d", val);
        DrawTextWithRect(buf, x, y, 80, ColColor(0x66), ColColor(0x63));
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        int key = WaitAnyKey();
        if (key == SDLK_UP) { val++; if (val > MaxValue) val = MaxValue; }
        if (key == SDLK_DOWN) { val--; if (val < MinValue) val = MinValue; }
        if (key == SDLK_RETURN || key == SDLK_SPACE) return val;
        if (key == SDLK_ESCAPE) return -1;
    }
}

void SetAttribute(int rnum, int selecttype, int modlevel, int minlevel, int maxlevel) {
    // 留空 - 原始Pascal中也注释了实现
}
