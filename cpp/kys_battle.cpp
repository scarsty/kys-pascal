// kys_battle.cpp - 战斗系统实现
// 对应 kys_battle.pas

#include "kys_battle.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_main.h"
#include "kys_event.h"
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

// 辅助：将战场格子坐标转为屏幕像素坐标
static int GetPositionOnBField(int gridX, int gridY, int coord) {
    TPosition pos = GetPositionOnScreen(gridX - Bx, gridY - By, CENTER_X, CENTER_Y);
    return (coord == 0) ? pos.x : pos.y;
}

static std::vector<TPosition> movetable;
static int maxdelaypicnum;

// ---- 战斗主控制----

bool Battle(int battlenum, int getexp) {
    BattleResult = 0;
    CurrentBattle = battlenum;
    BattleRound = 1;
    bool autoTeam = InitialBField();
    if (autoTeam) {
        int SelectTeamList = SelectTeamMembers();
        for (int i = 0; i < 6; i++) {
            int x = WarSta.TeamX[i], y = WarSta.TeamY[i];
            if (SelectTeamList & (1 << i)) {
                InitialBRole(BRoleAmount, TeamList[i], 0, x, y);
                BRoleAmount++;
            }
        }
        for (int i = 0; i < 6; i++) {
            int x = WarSta.TeamX[i], y = WarSta.TeamY[i] + 1;
            if (WarSta.TeamMate[i] > 0 && instruct_16(WarSta.TeamMate[i], 1, 0) == 0) {
                InitialBRole(BRoleAmount, WarSta.TeamMate[i], 0, x, y);
                BRoleAmount++;
            }
        }
    }
    instruct_14();
    Where = 2;
    InitialBFieldImage();

    int PreMusic = NowMusic;
    StopMP3();
    PlayMP3(WarSta.MusicNum, -1);

    for (int i = 0; i < BRoleAmount; i++)
        Brole[i].AutoMode = 1;

    // 载入战斗所需的额外贴图
    if (SEMIREAL == 1) {
        BHead.resize(BRoleAmount);
        for (int i = 0; i < BRoleAmount; i++) {
            int hn = Rrole[Brole[i].rnum].HeadNum;
            if (!HeadSurface[hn]) {
                char path[256];
                snprintf(path, sizeof(path), "%shead/%d.png", AppPath.c_str(), hn);
                HeadSurface[hn] = LoadSurfaceFromFile(path);
            }
            BHead[i] = HeadSurface[hn];
            if (!BHead[i]) {
                BHead[i] = SDL_CreateSurface(56, 71, SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
                SDL_FillSurfaceRect(BHead[i], nullptr, 1);
                SDL_SetSurfaceColorKey(BHead[i], true, 1);
                DrawHeadPic(hn, 0, 0, BHead[i]);
            }
            Brole[i].BHead = i;
        }
    }

    for (int i = 0; i < BRoleAmount; i++) {
        char path[256];
        int hn = Rrole[Brole[i].rnum].HeadNum;
        snprintf(path, sizeof(path), "fight/fight%03d", hn);
        std::string sp(path);
        FPicAmount = LoadIdxGrp(sp + ".idx", sp + ".grp", FIdx[hn], FPic[hn]);
    }

    BattleMainControl();
    RestoreRoleStatus();
    event.key.key = 0; event.button.button = 0;

    if (BattleResult == 1 || (BattleResult == 2 && getexp != 0)) {
        AddExp(); CheckLevelUp(); CheckBook();
    }
    UpdateScreen(screen, 0, 0, screen->w, screen->h);

    if (SEMIREAL == 1) BHead.clear();

    if (Rscene[CurScene].EntranceMusic >= 0) { StopMP3(); PlayMP3(Rscene[CurScene].EntranceMusic, -1); }
    else PlayMP3(PreMusic, -1);

    Where = 1;
    return BattleResult == 1;
}

bool InitialBField() {
    FILE* sta = fopen((AppPath + "resource/war.sta").c_str(), "rb");
    int offset = CurrentBattle * (int)sizeof(TWarData);
    fseek(sta, offset, SEEK_SET);
    fread(&WarSta, sizeof(TWarData), 1, sta);
    fclose(sta);

    int fieldnum = WarSta.BFieldNum;
    offset = 0;
    if (fieldnum != 0) {
        FILE* idx = fopen((AppPath + "resource/warfld.idx").c_str(), "rb");
        fseek(idx, (fieldnum - 1) * 4, SEEK_SET);
        fread(&offset, 4, 1, idx);
        fclose(idx);
    }
    FILE* grp = fopen((AppPath + "resource/warfld.grp").c_str(), "rb");
    fseek(grp, offset, SEEK_SET);
    fread(&BField[0][0][0], 2, 64 * 64 * 2, grp);
    fclose(grp);

    for (int i1 = 0; i1 < 64; i1++)
        for (int i2 = 0; i2 < 64; i2++)
            BField[2][i1][i2] = -1;
    BRoleAmount = 0;
    bool result = true;

    for (int i = 0; i < 6; i++) {
        int x = WarSta.TeamX[i], y = WarSta.TeamY[i];
        if (WarSta.AutoTeamMate[i] >= 0) {
            InitialBRole(BRoleAmount, WarSta.AutoTeamMate[i], 0, x, y);
            BRoleAmount++;
        }
    }
    if (BRoleAmount > 0) result = false;

    for (int i = 0; i < 20; i++) {
        int x = WarSta.EnemyX[i], y = WarSta.EnemyY[i];
        if (WarSta.Enemy[i] >= 0) {
            InitialBRole(BRoleAmount, WarSta.Enemy[i], 1, x, y);
            BRoleAmount++;
        }
    }
    return result;
}

void InitialBRole(int i, int rnum, int team, int x, int y) {
    if (i < 0 || i >= 200) return;
    Brole[i].rnum = rnum;
    Brole[i].Team = team;
    Brole[i].Y = y;
    Brole[i].X = x;
    Brole[i].Face = (team == 0) ? 2 : 1;
    Brole[i].Dead = 0;
    Brole[i].Step = 0;
    Brole[i].Acted = 0;
    Brole[i].ExpGot = 0;
    Brole[i].Auto = 0;
    Brole[i].RealSpeed = 0;
    Brole[i].RealProgress = rand() % 7000;
}

int SelectTeamMembers() {
    int result = 0, max = 1, menu = 0;
    std::string menuStr[9];
    for (int i = 0; i < 6; i++) {
        if (TeamList[i] >= 0) {
            menuStr[i + 1] = cp950toutf8(Rrole[TeamList[i]].Name);
            max++;
        }
    }
    menuStr[0] = "   全員參戰";
    menuStr[max] = "   開始戰鬥";
    std::string str = "選擇參戰人物";
    DrawTextWithRect(screen, str, CENTER_X - 63, 100, 126, ColColor(0x21), ColColor(0x23));
    UpdateAllScreen();
    RecordFreshScreen(0, 0, CENTER_X * 2, CENTER_Y * 2);

    auto ShowMultiMenu = [&]() {
        int x = CENTER_X - 105, y = 150;
        LoadFreshScreen(x + 30, y, 151, max * 22 + 29);
        std::string str1 = "參戰";
        DrawRectangle(screen, x + 30, y, 150, max * 22 + 28, 0, ColColor(255), 50);
        for (int i = 0; i <= max; i++) {
            uint32_t c1 = (i == menu) ? ColColor(0x64) : ColColor(0x05);
            uint32_t c2 = (i == menu) ? ColColor(0x66) : ColColor(0x07);
            DrawShadowText(screen, menuStr[i], x + 33, y + 3 + 22 * i, c1, c2);
            if ((result & (1 << (i - 1))) && i > 0 && i < max) {
                uint32_t cs1 = (i == menu) ? ColColor(0x64) : ColColor(0x21);
                uint32_t cs2 = (i == menu) ? ColColor(0x66) : ColColor(0x23);
                DrawShadowText(screen, str1, x + 133, y + 3 + 22 * i, cs1, cs2);
            }
        }
        UpdateScreen(screen, x + 30, y, 151, max * 22 + 29);
    };

    ShowMultiMenu();
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP) {
            if ((event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) && menu != max) {
                if (menu > 0) result ^= (1 << (menu - 1));
                else if (result < (int)(pow(2, max - 1) - 1)) result = (int)(pow(2, max - 1) - 1);
                else result = 0;
                ShowMultiMenu();
            }
            if ((event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) && menu == max) {
                if (result != 0) break;
            }
            if (event.key.key == SDLK_UP) { menu--; if (menu < 0) menu = max; ShowMultiMenu(); }
            if (event.key.key == SDLK_DOWN) { menu++; if (menu > max) menu = 0; ShowMultiMenu(); }
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= CENTER_X - 75 && mx < CENTER_X + 75 && my >= 150 && my < max * 22 + 178) {
                if (event.button.button == SDL_BUTTON_LEFT && menu != max) {
                    if (menu > 0) result ^= (1 << (menu - 1));
                    else if (result < (int)(pow(2, max - 1) - 1)) result = (int)(pow(2, max - 1) - 1);
                    else result = 0;
                    ShowMultiMenu();
                }
                if (event.button.button == SDL_BUTTON_LEFT && menu == max && result != 0) break;
            }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION) {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= CENTER_X - 75 && mx < CENTER_X + 75 && my >= 150 && my < max * 22 + 178) {
                int menup = menu;
                menu = (int)((my - 152) / 22);
                if (menup != menu) ShowMultiMenu();
            }
        }
    }
    return result;
}

void BattleMainControl() {
    uint32_t delaytime = 5;
    Bx = Brole[0].X;
    By = Brole[0].Y;
    int i = 0;
    while (BattleResult == 0) {
        CalMoveAbility();
        if (SEMIREAL == 0) ReArrangeBRole();
        ClearDeadRolePic();
        for (int j = 0; j < BRoleAmount; j++) { Brole[j].Acted = 0; Brole[j].ShowNumber = 0; }
        memset(&BField[4][0][0], 0, sizeof(BField[4]));

        if (SEMIREAL == 1) {
            DrawBField(0);
            RecordFreshScreen(0, 0, screen->w, screen->h);
            DrawProgress();
            int act = 0;
            while (SDL_PollEvent(&event) || true) {
                for (i = 0; i < BRoleAmount; i++) {
                    Brole[i].RealProgress += Brole[i].RealSpeed;
                    if (Brole[i].RealProgress >= 10000) {
                        Brole[i].RealProgress -= 10000;
                        act = 1; break;
                    }
                }
                if (act) break;
                LoadFreshScreen(0, 0, screen->w, screen->h);
                DrawProgress();
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
                SDL_Delay(delaytime);
                CheckBasicEvent();
            }
        }
        if (SEMIREAL == 0) i = 0;

        while (i < BRoleAmount && BattleResult == 0) {
            while (SDL_PollEvent(&event) || true) {
                CheckBasicEvent();
                if (event.key.key == SDLK_ESCAPE || event.button.button == SDL_BUTTON_RIGHT) {
                    Brole[i].Auto = 0;
                    event.button.button = 0; event.key.key = 0;
                }
                break;
            }
            x50[28005] = i;
            if (Brole[i].Dead == 0) {
                Bx = Brole[i].X; By = Brole[i].Y;
                Redraw();
                TBattleRole tempBrole;
                if (Brole[i].Team == 0 && Brole[i].Auto == 0) {
                    if (Brole[i].Acted == 0) tempBrole = Brole[i];
                    int menuResult = BattleMenu(i);
                    switch (menuResult) {
                        case 0: MoveRole(i); break;
                        case 1: Attack(i); break;
                        case 2: UsePoison(i); break;
                        case 3: MedPoison(i); break;
                        case 4: Medcine(i); break;
                        case 5: BattleMenuItem(i); break;
                        case 6: Wait(i); break;
                        case 7: MenuStatus(); break;
                        case 8: Rest(i); break;
                        case 9:
                            if (MODVersion == 51) CallEvent(1077);
                            else {
                                if (TeamModeMenu(i))
                                    for (int j = 0; j < BRoleAmount; j++)
                                        if (Brole[j].Team == 0 && Brole[j].Dead == 0)
                                            Brole[j].Auto = (Brole[j].AutoMode > 0) ? 1 : (Brole[j].AutoMode < 0) ? -1 : 0;
                            }
                            break;
                        default:
                            if (tempBrole.rnum == Brole[i].rnum) {
                                BField[2][tempBrole.X][tempBrole.Y] = i;
                                BField[2][Brole[i].X][Brole[i].Y] = -1;
                                Brole[i] = tempBrole;
                            }
                            break;
                    }
                } else {
                    AutoBattle(i);
                    Brole[i].Acted = 1;
                }
            } else Brole[i].Acted = 1;

            ClearDeadRolePic();
            Redraw();
            BattleResult = BattleStatus();
            if (Brole[i].Acted == 1) {
                i++;
                if (SEMIREAL == 1) break;
            }
        }
        BattleRound++;
        CalPoiHurtLife();
    }
}

void CalMoveAbility() {
    for (int i = 0; i < BRoleAmount; i++) {
        int rnum = Brole[i].rnum;
        int addspeed = 0;
        if (Rrole[rnum].Equip[0] >= 0) addspeed += Ritem[Rrole[rnum].Equip[0]].AddSpeed;
        if (Rrole[rnum].Equip[1] >= 0) addspeed += Ritem[Rrole[rnum].Equip[1]].AddSpeed;
        Brole[i].Step = (Rrole[rnum].Speed + addspeed) / 15;
        if (Brole[i].Step > 15) Brole[i].Step = 15;
        if (SEMIREAL == 1) {
            Brole[i].RealSpeed = (int)((Rrole[rnum].Speed + addspeed) / (log10((double)MaxProList[44]) - 1)) - Rrole[rnum].Hurt / 10 - Rrole[rnum].Poison / 30;
            if (Brole[i].RealSpeed > 200) Brole[i].RealSpeed = 200 + (Brole[i].RealSpeed - 200) / 3;
            if (Brole[i].Step > 7) Brole[i].Step = 7;
        }
    }
}

void ReArrangeBRole() {
    for (int i1 = 0; i1 < BRoleAmount - 1; i1++)
        for (int i2 = i1 + 1; i2 < BRoleAmount; i2++)
            if (Rrole[Brole[i1].rnum].Speed * 10 + rand() % 10 < Rrole[Brole[i2].rnum].Speed * 10 + rand() % 10)
                std::swap(Brole[i1], Brole[i2]);
    for (int i1 = 0; i1 < 64; i1++)
        for (int i2 = 0; i2 < 64; i2++)
            BField[2][i1][i2] = -1;
    for (int i = 0; i < BRoleAmount; i++)
        BField[2][Brole[i].X][Brole[i].Y] = (Brole[i].Dead == 0) ? i : -1;
}

int BattleStatus() {
    int sum0 = 0, sum1 = 0;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == 0 && Brole[i].Dead == 0) sum0++;
        if (Brole[i].Team == 1 && Brole[i].Dead == 0) sum1++;
    }
    if (sum0 > 0 && sum1 > 0) return 0;
    if (sum1 == 0) return 1;
    return 2;
}

int BattleMenu(int bnum) {
    static const char* word[] = {"移動","攻擊","用毒","解毒","醫療","物品","等待","狀態","休息","自動"};
    int MenuStat = 0x3E0, max = 4, rnum = Brole[bnum].rnum;
    if (Brole[bnum].Step > 0) { MenuStat |= 1; max++; }
    if (Rrole[rnum].PhyPower >= 10) {
        int p = 0;
        for (int i = 0; i < 10; i++) if (Rrole[rnum].Magic[i] > 0) { p = 1; break; }
        if (p) { MenuStat |= 2; max++; }
    }
    if (Rrole[rnum].UsePoi > 0 && Rrole[rnum].PhyPower >= 30) { MenuStat |= 4; max++; }
    if (Rrole[rnum].MedPoi > 0 && Rrole[rnum].PhyPower >= 50) { MenuStat |= 8; max++; }
    if (Rrole[rnum].Medcine > 0 && Rrole[rnum].PhyPower >= 50) { MenuStat |= 16; max++; }
    if (SEMIREAL == 1) { MenuStat &= ~64; max--; }

    int menu = 0;
    Redraw();
    ShowSimpleStatus(Brole[bnum].rnum, CENTER_X + 100, 50);
    char buf[32]; snprintf(buf, sizeof(buf), "回合%d", BattleRound);
    std::string s(buf);
    DrawTextWithRect(screen, s, 160, 50, DrawLength(s) * 10 + 6, ColColor(0x21), ColColor(0x23));
    RecordFreshScreen(0, 0, screen->w, screen->h);

    auto ShowBMenu = [&]() {
        LoadFreshScreen(100, 50, 47, max * 22 + 29);
        DrawRectangle(screen, 100, 50, 47, max * 22 + 28, 0, ColColor(255), 50);
        int p2 = 0;
        for (int i2 = 0; i2 < 10; i2++) {
            if (MenuStat & (1 << i2)) {
                uint32_t c1 = (p2 == menu) ? ColColor(0x66) : ColColor(0x23);
                uint32_t c2 = (p2 == menu) ? ColColor(0x64) : ColColor(0x21);
                DrawShadowText(screen, word[i2], 103, 53 + 22 * p2, c1, c2);
                p2++;
            }
        }
        UpdateScreen(screen, 100, 50, 47, max * 22 + 29);
    };

    ShowBMenu();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP) {
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) break;
            if (event.key.key == SDLK_ESCAPE) { menu = -1; break; }
            if (event.key.key == SDLK_UP) { menu--; if (menu < 0) menu = max; ShowBMenu(); }
            if (event.key.key == SDLK_DOWN) { menu++; if (menu > max) menu = 0; ShowBMenu(); }
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (event.button.button == SDL_BUTTON_LEFT && mx >= 100 && mx < 147 && my >= 50 && my < max * 22 + 78) break;
            if (event.button.button == SDL_BUTTON_RIGHT) { menu = -1; break; }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION) {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= 100 && mx < 147 && my >= 50 && my < max * 22 + 78) {
                int menup = menu;
                menu = (int)((my - 52) / 22);
                if (menu > max) menu = max; if (menu < 0) menu = 0;
                if (menup != menu) ShowBMenu();
            }
        }
    }
    if (menu == -1) return -1;
    int p = 0;
    int idx = 0;
    for (int i = 0; i < 10; i++) {
        if (MenuStat & (1 << i)) {
            p++;
            if (p > menu) { idx = i; break; }
        }
    }
    return idx;
}

void MoveRole(int bnum) {
    CalCanSelect(bnum, 0, Brole[bnum].Step);
    if (SelectAim(bnum, Brole[bnum].Step)) MoveAmination(bnum);
}

bool MoveAmination(int bnum) {
    bool result = abs(Ax - Bx) + abs(Ay - By) > 0;
    if (BField[3][Ax][Ay] > 0) {
        int Xinc[] = {0, 1, -1, 0, 0}, Yinc[] = {0, 0, 0, 1, -1};
        int16_t linebx[4097], lineby[4097];
        linebx[0] = Bx; lineby[0] = By;
        linebx[BField[3][Ax][Ay]] = Ax;
        lineby[BField[3][Ax][Ay]] = Ay;
        int a = BField[3][Ax][Ay] - 1;
        while (a >= 0) {
            bool seekError = true;
            for (int i = 1; i <= 4; i++) {
                int tx = linebx[a + 1] + Xinc[i], ty = lineby[a + 1] + Yinc[i];
                if (tx >= 0 && tx < 64 && ty >= 0 && ty < 64 && BField[3][tx][ty] == BField[3][linebx[a + 1]][lineby[a + 1]] - 1) {
                    linebx[a] = tx; lineby[a] = ty; seekError = false; break;
                }
            }
            if (seekError) break;
            a--;
        }
        for (int j = 1; j <= BField[3][Ax][Ay]; j++) {
            if (linebx[j] > Bx && lineby[j] == By) Brole[bnum].Face = 3;
            else if (linebx[j] < Bx && lineby[j] == By) Brole[bnum].Face = 0;
            else if (linebx[j] == Bx && lineby[j] > By) Brole[bnum].Face = 1;
            else if (linebx[j] == Bx && lineby[j] < By) Brole[bnum].Face = 2;
            if (BField[2][Bx][By] == bnum) BField[2][Bx][By] = -1;
            Bx = linebx[j]; By = lineby[j];
            if (BField[2][Bx][By] == -1) BField[2][Bx][By] = bnum;
            Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
            SDL_Delay(30);
        }
        Brole[bnum].X = Bx; Brole[bnum].Y = By;
        BField[2][Bx][By] = bnum;
        Brole[bnum].Step = BField[5][Ax][Ay];
    }
    return result;
}

bool SelectAim(int bnum, int step, int AreaType, int AreaRange) {
    Ax = Bx; Ay = By;
    RecordFreshScreen(0, 0, screen->w, screen->h);
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP) {
            int px = Ax, py = Ay;
            if (event.key.key == SDLK_LEFT) Ax--;
            if (event.key.key == SDLK_RIGHT) Ax++;
            if (event.key.key == SDLK_UP) Ay--;
            if (event.key.key == SDLK_DOWN) Ay++;
            if (Ax < 0) Ax = 0; if (Ax > 63) Ax = 63;
            if (Ay < 0) Ay = 0; if (Ay > 63) Ay = 63;
            if (BField[3][Ax][Ay] < 0) { Ax = px; Ay = py; }
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) {
                if (BField[3][Ax][Ay] >= 0) return true;
            }
            if (event.key.key == SDLK_ESCAPE) return false;
            Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
            if (event.button.button == SDL_BUTTON_LEFT && BField[3][Ax][Ay] >= 0) return true;
            if (event.button.button == SDL_BUTTON_RIGHT) return false;
        }
    }
    return false;
}

bool SelectDirector(int bnum, int step) {
    Ax = Bx; Ay = By;
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP) {
            if (event.key.key == SDLK_LEFT) { Ax = Bx - 1; Ay = By; }
            if (event.key.key == SDLK_RIGHT) { Ax = Bx + 1; Ay = By; }
            if (event.key.key == SDLK_UP) { Ax = Bx; Ay = By - 1; }
            if (event.key.key == SDLK_DOWN) { Ax = Bx; Ay = By + 1; }
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) return true;
            if (event.key.key == SDLK_ESCAPE) return false;
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
            if (event.button.button == SDL_BUTTON_RIGHT) return false;
        }
    }
    return false;
}

void SeekPath2(int x, int y, int step, int myteam, int mode) {
    // BFS寻路
    struct QNode { int x, y, s; };
    std::vector<QNode> queue;
    queue.push_back({x, y, 0});
    BField[3][x][y] = 0;
    int dx[] = {1, -1, 0, 0}, dy[] = {0, 0, 1, -1};
    int head = 0;
    while (head < (int)queue.size()) {
        auto cur = queue[head++];
        if (cur.s >= step) continue;
        for (int d = 0; d < 4; d++) {
            int nx = cur.x + dx[d], ny = cur.y + dy[d];
            if (nx < 0 || nx >= 64 || ny < 0 || ny >= 64) continue;
            if (BField[3][nx][ny] >= 0) continue;
            bool canPass = true;
            if (mode == 0) {
                if (BField[1][nx][ny] > 0 || (BField[2][nx][ny] >= 0 && BField[2][nx][ny] != -1)) canPass = false;
            }
            if (canPass) {
                BField[3][nx][ny] = cur.s + 1;
                queue.push_back({nx, ny, cur.s + 1});
            }
        }
    }
}

void CalCanSelect(int bnum, int mode, int step) {
    for (int i = 0; i < 64; i++)
        for (int j = 0; j < 64; j++)
            BField[3][i][j] = -1;
    int x = Brole[bnum].X, y = Brole[bnum].Y;
    SeekPath2(x, y, step, Brole[bnum].Team, mode);
}

void Attack(int bnum) {
    int rnum = Brole[bnum].rnum;
    int mnum = SelectMagic(rnum);
    if (mnum < 0) return;
    int level = 0;
    for (int i = 0; i < 10; i++) {
        if (Rrole[rnum].Magic[i] == mnum) { level = Rrole[rnum].MagLevel[i] / 100; break; }
    }
    if (level > 9) level = 9;

    int AreaType = Rmagic[mnum].AttAreaType;
    int step = Rmagic[mnum].MoveDistance[level];
    CalCanSelect(bnum, 1, step);

    bool selected = false;
    if (AreaType == 1 || AreaType == 2) selected = SelectDirector(bnum, step);
    else selected = SelectAim(bnum, step, AreaType, Rmagic[mnum].AttDistance[level]);

    if (!selected) return;
    SetAminationPosition(AreaType, step, Rmagic[mnum].AttDistance[level]);

    ShowMagicName(mnum);
    AttackActionAll(bnum, mnum, level);
    CalHurtRole(bnum, mnum, level);
    ShowHurtValue(0);

    Rrole[rnum].PhyPower -= 3 + rand() % 5;
    if (Rrole[rnum].PhyPower < 0) Rrole[rnum].PhyPower = 0;
    int mpCost = Rmagic[mnum].NeedMP;
    Rrole[rnum].CurrentMP -= mpCost;
    if (Rrole[rnum].CurrentMP < 0) Rrole[rnum].CurrentMP = 0;

    for (int i = 0; i < 10; i++) {
        if (Rrole[rnum].Magic[i] == mnum) {
            Rrole[rnum].MagLevel[i]++;
            if (Rrole[rnum].MagLevel[i] > 999) Rrole[rnum].MagLevel[i] = 999;
            break;
        }
    }
    Brole[bnum].Acted = 1;
}

void AttackAction(int bnum, int i, int mnum, int level) {
    if (i >= BRoleAmount || Brole[i].Dead != 0) return;
    int hurt = CalHurtValue(bnum, i, mnum, level);
    Brole[i].ShowNumber = hurt;
}

void AttackActionAll(int bnum, int mnum, int level) {
    PlayMagicAmination(bnum, Rmagic[mnum].AmiNum);
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead == 0 && BField[4][Brole[i].X][Brole[i].Y] > 0)
            AttackAction(bnum, i, mnum, level);
    }
}

void ShowMagicName(int mnum, int mode) {
    DrawRectangle(screen, CENTER_X - 50, 20, 100, 26, 0, ColColor(255), 50);
    DrawBig5ShadowText(screen, Rmagic[mnum].Name, CENTER_X - 45, 23, ColColor(5), ColColor(7));
    UpdateScreen(screen, CENTER_X - 50, 20, 100, 26);
    SDL_Delay(300);
}

int SelectMagic(int rnum) {
    std::string magicStr[10];
    int magicList[10], cnt = 0;
    for (int i = 0; i < 10; i++) {
        if (Rrole[rnum].Magic[i] > 0) {
            char buf[64];
            snprintf(buf, sizeof(buf), "%-16s%4d", cp950toutf8(Rmagic[Rrole[rnum].Magic[i]].Name).c_str(), Rrole[rnum].MagLevel[i]);
            magicStr[cnt] = buf;
            magicList[cnt] = Rrole[rnum].Magic[i];
            cnt++;
        }
    }
    if (cnt == 0) return -1;
    int menu = CommonMenu(CENTER_X - 120, 80, 200, cnt - 1, magicStr);
    Redraw();
    return (menu >= 0) ? magicList[menu] : -1;
}

void SetAminationPosition(int mode, int step, int range) {
    SetAminationPosition2(Bx, By, Ax, Ay, mode, step, range);
}

void SetAminationPosition2(int bx1, int by1, int ax1, int ay1, int mode, int step, int range) {
    memset(&BField[4][0][0], 0, sizeof(BField[4]));
    switch (mode) {
        case 0: // 点
            if (range == 0) { BField[4][ax1][ay1] = 1; }
            else {
                for (int i = -range; i <= range; i++)
                    for (int j = -range; j <= range; j++)
                        if (abs(i) + abs(j) <= range && ax1 + i >= 0 && ax1 + i < 64 && ay1 + j >= 0 && ay1 + j < 64)
                            BField[4][ax1 + i][ay1 + j] = 1;
            }
            break;
        case 1: { // 线
            int dx = ax1 - bx1, dy = ay1 - by1;
            int sx = (dx > 0) ? 1 : (dx < 0) ? -1 : 0;
            int sy = (dy > 0) ? 1 : (dy < 0) ? -1 : 0;
            for (int s = 1; s <= step; s++) {
                int nx = bx1 + sx * s, ny = by1 + sy * s;
                if (nx >= 0 && nx < 64 && ny >= 0 && ny < 64) BField[4][nx][ny] = 1;
            }
        } break;
        case 2: { // 十字
            int dx = ax1 - bx1, dy = ay1 - by1;
            int sx = (dx > 0) ? 1 : (dx < 0) ? -1 : 0;
            int sy = (dy > 0) ? 1 : (dy < 0) ? -1 : 0;
            for (int s = 1; s <= step; s++) {
                int nx = bx1 + sx * s, ny = by1 + sy * s;
                if (nx >= 0 && nx < 64 && ny >= 0 && ny < 64) BField[4][nx][ny] = 1;
                // 交叉方向
                if (sx == 0) {
                    for (int r = 1; r <= range; r++) {
                        if (bx1 + r < 64) BField[4][bx1 + r][ny] = 1;
                        if (bx1 - r >= 0) BField[4][bx1 - r][ny] = 1;
                    }
                }
                if (sy == 0) {
                    for (int r = 1; r <= range; r++) {
                        if (by1 + r < 64) BField[4][nx][by1 + r] = 1;
                        if (by1 - r >= 0) BField[4][nx][by1 - r] = 1;
                    }
                }
            }
        } break;
        case 3: // 区域
            for (int i = 0; i < 64; i++)
                for (int j = 0; j < 64; j++)
                    if (abs(i - bx1) + abs(j - by1) <= step) BField[4][i][j] = 1;
            break;
    }
}

void PlayMagicAmination(int bnum, int enumv, int ForTeam, int mode) {
    if (enumv < 0) return;
    int beginPic = EIdx[enumv], endPic = (enumv + 1 < EPicAmount) ? EIdx[enumv + 1] - 1 : EPicAmount - 1;
    for (int p = beginPic; p <= endPic; p++) {
        CheckBasicEvent();
        Redraw();
        for (int i = 0; i < 64; i++)
            for (int j = 0; j < 64; j++)
                if (BField[4][i][j] > 0) DrawEPic(p, GetPositionOnBField(i, j, 0), GetPositionOnBField(i, j, 1));
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        SDL_Delay(BATTLE_SPEED);
    }
}

void CalHurtRole(int bnum, int mnum, int level) {
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead != 0) continue;
        if (BField[4][Brole[i].X][Brole[i].Y] <= 0) continue;
        if (Brole[i].Team == Brole[bnum].Team && i != bnum) continue;
        int hurt = CalHurtValue(bnum, i, mnum, level);
        int rnum2 = Brole[i].rnum;
        if (Brole[i].Team != Brole[bnum].Team) {
            Rrole[rnum2].CurrentHP -= hurt;
            if (Rrole[rnum2].CurrentHP <= 0) { Rrole[rnum2].CurrentHP = 0; Brole[i].Dead = 1; }
            // 中毒
            if (Rmagic[mnum].Poison > 0 && Rrole[Brole[bnum].rnum].UsePoi > 0)
                Rrole[rnum2].Poison += Rmagic[mnum].Poison / 3;
            Brole[i].ShowNumber = hurt;
        } else {
            Rrole[rnum2].CurrentHP += hurt;
            if (Rrole[rnum2].CurrentHP > Rrole[rnum2].MaxHP) Rrole[rnum2].CurrentHP = Rrole[rnum2].MaxHP;
            Brole[i].ShowNumber = -hurt;
        }
        Brole[bnum].ExpGot += hurt;
    }
}

int CalHurtValue(int bnum1, int bnum2, int mnum, int level) {
    int rnum1 = Brole[bnum1].rnum, rnum2 = Brole[bnum2].rnum;
    double attack = Rrole[rnum1].Attack;
    double defend = Rrole[rnum2].Defence;
    double mp1 = Rrole[rnum1].CurrentMP, maxmp1 = Rrole[rnum1].MaxMP;
    int hurt;

    // 武功威力
    double magicPower = Rmagic[mnum].HurtMP[level];
    // 内力加成
    double mpRate = (maxmp1 > 0) ? mp1 / maxmp1 : 0.5;
    // 知识加成
    double knowledge = Rrole[rnum1].Knowledge;

    hurt = (int)(attack / 3.0 + magicPower - defend / 4.0 + 20.0);
    hurt = (int)(hurt * (0.5 + mpRate * 0.5));
    // 装备加成
    for (int e = 0; e < 2; e++) {
        if (Rrole[rnum1].Equip[e] >= 0) {
            int inum = Rrole[rnum1].Equip[e];
            hurt += Ritem[inum].AddAttack / 3;
            // 武器匹配加成
            if (Rmagic[mnum].MagicType == Ritem[inum].NeedMP) hurt += Ritem[inum].AddAttack / 3;
        }
    }
    // 距离衰减
    int dist = abs(Brole[bnum1].X - Brole[bnum2].X) + abs(Brole[bnum1].Y - Brole[bnum2].Y);
    if (dist > 1) hurt = hurt * 9 / (8 + dist);

    // 随机浮动
    hurt += rand() % 10 - 5;
    if (hurt < 1) hurt = 1 + rand() % 10;
    return hurt;
}

int CalHurtValue2(int bnum1, int bnum2, int mnum, int level) {
    return CalHurtValue(bnum1, bnum2, mnum, level);
}

void SelectModeColor(int mode, uint32_t& color1, uint32_t& color2, std::string& str, int trans) {
    switch (mode) {
        case 0: color1 = ColColor(0x10); color2 = ColColor(0x14); str = "-%d"; break;
        case 1: color1 = ColColor(0x50); color2 = ColColor(0x53); str = "-%d"; break;
        case 2: color1 = ColColor(0x30); color2 = ColColor(0x32); str = "+%d"; break;
        case 3: color1 = ColColor(0x07); color2 = ColColor(0x05); str = "+%d"; break;
        case 4: color1 = ColColor(0x91); color2 = ColColor(0x93); str = "-%d"; break;
        default: color1 = ColColor(0x10); color2 = ColColor(0x14); str = "-%d"; break;
    }
}

void ShowHurtValue(int mode) {
    for (int ti = 0; ti < 10; ti++) {
        Redraw();
        for (int i = 0; i < BRoleAmount; i++) {
            if (Brole[i].ShowNumber != 0) {
                int px = GetPositionOnBField(Brole[i].X, Brole[i].Y, 0);
                int py = GetPositionOnBField(Brole[i].X, Brole[i].Y, 1) - ti * 3;
                char buf[16]; snprintf(buf, sizeof(buf), "%d", abs(Brole[i].ShowNumber));
                uint32_t c = (Brole[i].ShowNumber > 0) ? ColColor(0x42) : ColColor(0x24);
                DrawEngShadowText(screen, buf, px, py, c, ColColor(0));
            }
        }
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        SDL_Delay(80);
    }
    for (int i = 0; i < BRoleAmount; i++) Brole[i].ShowNumber = 0;
}

void CalPoiHurtLife() {
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Poison > 0) {
            int hurt = Rrole[Brole[i].rnum].Poison * 3;
            Rrole[Brole[i].rnum].CurrentHP -= hurt;
            if (Rrole[Brole[i].rnum].CurrentHP <= 0) { Rrole[Brole[i].rnum].CurrentHP = 0; Brole[i].Dead = 1; }
            Brole[i].ShowNumber = hurt;
        }
    }
}

void ClearDeadRolePic() {
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead == 1) {
            BField[2][Brole[i].X][Brole[i].Y] = -1;
            Brole[i].Dead = 2;
        }
    }
}

void Wait(int bnum) {
    // 交换至列表尾部
    int pos = -1;
    for (int i = 0; i < BRoleAmount; i++) if (&Brole[i] == &Brole[bnum]) { pos = i; break; }
    // 标记为已行动但不结束回合 - 简化实现
    Brole[bnum].Acted = 1;
}

void RestoreRoleStatus() {
    for (int i = 0; i < BRoleAmount; i++) {
        int rnum = Brole[i].rnum;
        if (Rrole[rnum].CurrentHP <= 0 && Brole[i].Team == 0)
            Rrole[rnum].CurrentHP = 1;
    }
}

void AddExp() {
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == 0 && Brole[i].Dead != 2) {
            int rnum = Brole[i].rnum;
            int exp = Brole[i].ExpGot / 2 + 20;
            Rrole[rnum].Exp += exp;
            Brole[i].ShowNumber = exp;
        }
    }
    ShowHurtValue(1);
}

void CheckLevelUp() {
    for (int i = 0; i < BRoleAmount; i++) {
        int rnum = Brole[i].rnum;
        while ((uint16_t)Rrole[rnum].Exp >= (uint16_t)LevelUpList[Rrole[rnum].Level - 1] && Rrole[rnum].Level < MAX_LEVEL) {
            Rrole[rnum].Exp -= LevelUpList[Rrole[rnum].Level - 1];
            Rrole[rnum].Level++;
            LevelUp(i);
        }
    }
}

void LevelUp(int bnum) {
    int rnum = Brole[bnum].rnum;
    Rrole[rnum].Level++;
    int apt = Rrole[rnum].Aptitude;
    // 属性成长
    Rrole[rnum].MaxHP += 3 + rand() % (apt / 10 + 1);
    Rrole[rnum].MaxMP += 2 + rand() % (apt / 10 + 1);
    Rrole[rnum].Attack += 1 + rand() % (apt / 15 + 1);
    Rrole[rnum].Speed += 1 + rand() % (apt / 15 + 1);
    Rrole[rnum].Defence += 1 + rand() % (apt / 15 + 1);
    Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
    Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;

    DrawRectangle(screen, CENTER_X - 80, 98, 160, 26, 0, ColColor(255), 50);
    DrawBig5ShadowText(screen, Rrole[rnum].Name, CENTER_X - 75, 100, ColColor(0x21), ColColor(0x23));
    DrawShadowText(screen, " 升級！", CENTER_X - 20, 100, ColColor(0x64), ColColor(0x66));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    SDL_Delay(1000);
}

void CheckBook() {
    for (int i = 0; i < BRoleAmount; i++) {
        int rnum = Brole[i].rnum;
        int inum = Rrole[rnum].PracticeBook;
        if (inum < 0) continue;
        int mnum = Ritem[inum].Magic;
        int mlevel = 0;
        if (mnum > 0) {
            for (int m = 0; m < 10; m++) {
                if (Rrole[rnum].Magic[m] == mnum) {
                    mlevel = Rrole[rnum].MagLevel[m] / 100 + 1;
                    break;
                }
            }
        }
        int ap = 7 - Rrole[rnum].Aptitude / 15;
        if (mnum > 0) {
            int p = 0;
            while (mlevel < 10) {
                int needexp = mlevel * Ritem[inum].NeedExp * ap;
                if (mlevel == 0) needexp = Ritem[inum].NeedExp * ap;
                if (Rrole[rnum].ExpForBook >= (uint16_t)needexp && mlevel < 10) {
                    Rrole[rnum].ExpForBook -= needexp;
                    instruct_33(rnum, mnum, 1);
                    mlevel++;
                } else break;
                p++;
                if (p >= 10 || mlevel > 10) break;
            }
        }
    }
}

int CalRNum(int team) {
    int cnt = 0;
    for (int i = 0; i < BRoleAmount; i++)
        if (Brole[i].Team == team && Brole[i].Dead == 0) cnt++;
    return cnt;
}

void BattleMenuItem(int bnum) {
    // 使用物品
    std::vector<std::string> itemStr;
    std::vector<int> itemIdx;
    int cnt = 0;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++) {
        if (RItemList[i].Number >= 0 && RItemList[i].Amount > 0 && Ritem[RItemList[i].Number].ItemType == 3) {
            char buf[64];
            snprintf(buf, sizeof(buf), "%-16s %3d", cp950toutf8(Ritem[RItemList[i].Number].Name).c_str(), RItemList[i].Amount);
            itemStr.push_back(buf); itemIdx.push_back(i); cnt++;
        }
    }
    if (cnt == 0) return;
    int menu = CommonMenu(CENTER_X - 120, 80, 200, cnt - 1, itemStr.data());
    Redraw();
    if (menu >= 0) {
        int inum = RItemList[itemIdx[menu]].Number;
        if (Ritem[inum].ItemType == 3 && Ritem[inum].AddCurrentHP > 0) {
            // 食物恢复
            int rnum = Brole[bnum].rnum;
            Rrole[rnum].CurrentHP += Ritem[inum].AddCurrentHP;
            if (Rrole[rnum].CurrentHP > Rrole[rnum].MaxHP) Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
            Rrole[rnum].CurrentMP += Ritem[inum].AddCurrentMP;
            if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP) Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
            instruct_32(inum, -1);
        }
        Brole[bnum].Acted = 1;
    }
}

void PlayActionAmination(int bnum, int mode, int mnum) {
    int rnum = Brole[bnum].rnum;
    int hn = Rrole[rnum].HeadNum;
    int face = Brole[bnum].Face;
    int beginPic = face * 7, endPic = beginPic + 6;
    if (mode == 1) { beginPic = 28 + face * 3; endPic = beginPic + 2; }
    for (int p = beginPic; p <= endPic; p++) {
        CheckBasicEvent();
        Redraw(); UpdateScreen(screen, 0, 0, screen->w, screen->h);
        SDL_Delay(BATTLE_SPEED);
    }
}

void UsePoison(int bnum) {
    CalCanSelect(bnum, 1, 1);
    if (SelectAim(bnum, 1)) {
        SetAminationPosition(0, 1, 0);
        for (int i = 0; i < BRoleAmount; i++) {
            if (Brole[i].Dead == 0 && Brole[i].X == Ax && Brole[i].Y == Ay && Brole[i].Team != Brole[bnum].Team) {
                int rnum2 = Brole[i].rnum;
                Rrole[rnum2].Poison += Rrole[Brole[bnum].rnum].UsePoi / 3;
                if (Rrole[rnum2].Poison > 100) Rrole[rnum2].Poison = 100;
                Brole[i].ShowNumber = Rrole[Brole[bnum].rnum].UsePoi / 3;
            }
        }
        ShowHurtValue(2);
        Rrole[Brole[bnum].rnum].PhyPower -= 5;
        Brole[bnum].Acted = 1;
    }
}

void Medcine(int bnum) {
    CalCanSelect(bnum, 1, 1);
    if (SelectAim(bnum, 1)) {
        for (int i = 0; i < BRoleAmount; i++) {
            if (Brole[i].Dead == 0 && Brole[i].X == Ax && Brole[i].Y == Ay && Brole[i].Team == Brole[bnum].Team) {
                int rnum2 = Brole[i].rnum;
                int heal = Rrole[Brole[bnum].rnum].Medcine * 3 + rand() % 20;
                Rrole[rnum2].CurrentHP += heal;
                if (Rrole[rnum2].CurrentHP > Rrole[rnum2].MaxHP) Rrole[rnum2].CurrentHP = Rrole[rnum2].MaxHP;
                Rrole[rnum2].Hurt -= Rrole[Brole[bnum].rnum].Medcine / 10;
                if (Rrole[rnum2].Hurt < 0) Rrole[rnum2].Hurt = 0;
                Brole[i].ShowNumber = -heal;
            }
        }
        ShowHurtValue(1);
        Rrole[Brole[bnum].rnum].PhyPower -= 5;
        Brole[bnum].Acted = 1;
    }
}

void MedPoison(int bnum) {
    CalCanSelect(bnum, 1, 1);
    if (SelectAim(bnum, 1)) {
        for (int i = 0; i < BRoleAmount; i++) {
            if (Brole[i].Dead == 0 && Brole[i].X == Ax && Brole[i].Y == Ay && Brole[i].Team == Brole[bnum].Team) {
                int rnum2 = Brole[i].rnum;
                int cure = Rrole[Brole[bnum].rnum].MedPoi / 3;
                Rrole[rnum2].Poison -= cure;
                if (Rrole[rnum2].Poison < 0) Rrole[rnum2].Poison = 0;
                Brole[i].ShowNumber = cure;
            }
        }
        ShowHurtValue(2);
        Rrole[Brole[bnum].rnum].PhyPower -= 5;
        Brole[bnum].Acted = 1;
    }
}

void UseHiddenWeapon(int bnum, int inum) {
    int rnum = Brole[bnum].rnum;
    int step = Rrole[rnum].HidWeapon / 15 + 1;
    CalCanSelect(bnum, 1, step);
    if (SelectAim(bnum, step)) {
        for (int i = 0; i < BRoleAmount; i++) {
            if (Brole[i].Dead == 0 && Brole[i].X == Ax && Brole[i].Y == Ay && Brole[i].Team != Brole[bnum].Team) {
                int hurt = Ritem[inum].AddAttack + Rrole[Brole[bnum].rnum].Attack / 3;
                Rrole[Brole[i].rnum].CurrentHP -= hurt;
                if (Rrole[Brole[i].rnum].CurrentHP <= 0) { Rrole[Brole[i].rnum].CurrentHP = 0; Brole[i].Dead = 1; }
                Brole[i].ShowNumber = hurt;
            }
        }
        ShowHurtValue(0);
        instruct_32(inum, -1);
        Brole[bnum].Acted = 1;
    }
}

void Rest(int bnum) {
    int rnum = Brole[bnum].rnum;
    Rrole[rnum].PhyPower += 5 + rand() % 5;
    if (Rrole[rnum].PhyPower > MAX_PHYSICAL_POWER) Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
    Rrole[rnum].CurrentHP += Rrole[rnum].MaxHP / 15;
    if (Rrole[rnum].CurrentHP > Rrole[rnum].MaxHP) Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
    Rrole[rnum].CurrentMP += Rrole[rnum].MaxMP / 15;
    if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP) Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
    Brole[bnum].Acted = 1;
}

bool TeamModeMenu(int bnum) {
    std::string ms[4] = {"取消", "手動", "自動", "自動模式"};
    int menu = CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, ms);
    Redraw();
    if (menu == 1) {
        for (int i = 0; i < BRoleAmount; i++) if (Brole[i].Team == 0) Brole[i].Auto = 0;
        return false;
    }
    if (menu == 2) return true;
    return false;
}

// ---- AI ----

void AutoBattle(int bnum) {
    int rnum = Brole[bnum].rnum;
    // 简单AI: 找最近敌人，移动并攻击
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int bestTarget = -1, bestDist = 9999;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0) {
            int dist = abs(Brole[i].X - Brole[bnum].X) + abs(Brole[i].Y - Brole[bnum].Y);
            if (dist < bestDist) { bestDist = dist; bestTarget = i; }
        }
    }
    if (bestTarget < 0) return;

    // 移动
    CalCanSelect(bnum, 0, Brole[bnum].Step);
    int Mx1 = Brole[bnum].X, My1 = Brole[bnum].Y;
    NearestMove(Mx1, My1, bnum);
    Ax = Mx1; Ay = My1;
    MoveAmination(bnum);

    // 尝试攻击
    if (Rrole[rnum].PhyPower >= 10) {
        int bestMagic = -1, bestLevel = 0;
        for (int m = 0; m < 10; m++) {
            if (Rrole[rnum].Magic[m] > 0) {
                int mnum = Rrole[rnum].Magic[m];
                int level = std::min(9, Rrole[rnum].MagLevel[m] / 100);
                if (Rrole[rnum].CurrentMP >= Rmagic[mnum].NeedMP) {
                    if (bestMagic < 0) { bestMagic = mnum; bestLevel = level; }
                }
            }
        }
        if (bestMagic >= 0) {
            int step = Rmagic[bestMagic].MoveDistance[bestLevel];
            int dist = abs(Brole[bestTarget].X - Brole[bnum].X) + abs(Brole[bestTarget].Y - Brole[bnum].Y);
            if (dist <= step) {
                Ax = Brole[bestTarget].X; Ay = Brole[bestTarget].Y;
                SetAminationPosition(Rmagic[bestMagic].AttAreaType, step, Rmagic[bestMagic].AttDistance[bestLevel]);
                ShowMagicName(bestMagic);
                AttackActionAll(bnum, bestMagic, bestLevel);
                CalHurtRole(bnum, bestMagic, bestLevel);
                ShowHurtValue(0);
                Rrole[rnum].PhyPower -= 3 + rand() % 5;
                Rrole[rnum].CurrentMP -= Rmagic[bestMagic].NeedMP;
                if (Rrole[rnum].CurrentMP < 0) Rrole[rnum].CurrentMP = 0;
            }
        }
    }
}

void AutoUseItem(int bnum, int list) {
    // AI使用物品 - 简化
    BattleMenuItem(bnum);
}

void TryMoveAttack(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int bnum, int mnum, int level) {
    int AreaType = Rmagic[mnum].AttAreaType;
    switch (AreaType) {
        case 0: CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
        case 1: calline(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
        case 2: calcross(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
        case 3: CalArea(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
    }
}

void CalPoint(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level) {
    int step = Rmagic[mnum].MoveDistance[level];
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0) {
            int dist = abs(Brole[i].X - curX) + abs(Brole[i].Y - curY);
            if (dist <= step) {
                int hurt = CalHurtValue2(bnum, i, mnum, level);
                if (hurt > tempmaxhurt) {
                    tempmaxhurt = hurt; Mx1 = curX; My1 = curY; Ax1 = Brole[i].X; Ay1 = Brole[i].Y;
                }
            }
        }
    }
}


void calline(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level) {
    CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
}

void calcross(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level) {
    CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
}

void CalArea(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level) {
    int step = Rmagic[mnum].MoveDistance[level];
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int totalHurt = 0;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0) {
            int dist = abs(Brole[i].X - curX) + abs(Brole[i].Y - curY);
            if (dist <= step) totalHurt += CalHurtValue2(bnum, i, mnum, level);
        }
    }
    if (totalHurt > tempmaxhurt) { tempmaxhurt = totalHurt; Mx1 = curX; My1 = curY; Ax1 = curX; Ay1 = curY; }
}

void NearestMove(int& Mx1, int& My1, int bnum) {
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int bestDist = 9999;
    int tx = -1, ty = -1;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0) {
            int dist = abs(Brole[i].X - Brole[bnum].X) + abs(Brole[i].Y - Brole[bnum].Y);
            if (dist < bestDist) { bestDist = dist; tx = Brole[i].X; ty = Brole[i].Y; }
        }
    }
    if (tx < 0) return;
    // 在可移动范围内找最接近目标的位置
    int bestMDist = 9999;
    for (int i = 0; i < 64; i++)
        for (int j = 0; j < 64; j++)
            if (BField[3][i][j] >= 0 && (BField[2][i][j] == -1 || (i == Brole[bnum].X && j == Brole[bnum].Y))) {
                int dist = abs(i - tx) + abs(j - ty);
                if (dist < bestMDist) { bestMDist = dist; Mx1 = i; My1 = j; }
            }
}

void NearestMoveByPro(int& Mx1, int& My1, int& Ax1, int& Ay1, int bnum, int TeamMate, int KeepDis, int Prolist, int MaxMinPro, int mode) {
    NearestMove(Mx1, My1, bnum);
    Ax1 = Mx1; Ay1 = My1;
}
