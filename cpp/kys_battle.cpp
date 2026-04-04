// kys_battle.cpp - 战斗系统实现
// 对应 kys_battle.pas

#include "kys_battle.h"
#include "kys_draw.h"
#include "kys_engine.h"
#include "kys_event.h"
#include "kys_main.h"
#include "kys_script.h"
#include "kys_type.h"

#include <SDL3/SDL.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <format>
#include <string>
#include <vector>

// 辅助：将战场格子坐标转为屏幕像素坐标
static int GetPositionOnBField(int gridX, int gridY, int coord)
{
    TPosition pos = GetPositionOnScreen(gridX, gridY, Bx, By);
    return (coord == 0) ? pos.x : pos.y;
}

static std::vector<TPosition> movetable;
static int maxdelaypicnum;

// ---- 战斗主控制----

bool Battle(int battlenum, int getexp)
{
    BattleResult = 0;
    CurrentBattle = battlenum;
    BattleRound = 1;
    bool autoTeam = InitialBField();
    if (autoTeam)
    {
        int SelectTeamList = SelectTeamMembers();
        for (int i = 0; i < 6; i++)
        {
            int x = WarSta.TeamX[i], y = WarSta.TeamY[i];
            if (SelectTeamList & (1 << i))
            {
                InitialBRole(BRoleAmount, TeamList[i], 0, x, y);
                BRoleAmount++;
            }
        }
        for (int i = 0; i < 6; i++)
        {
            int x = WarSta.TeamX[i], y = WarSta.TeamY[i] + 1;
            if (WarSta.TeamMate[i] > 0 && instruct_16(WarSta.TeamMate[i], 1, 0) == 0)
            {
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
    {
        Brole[i].AutoMode = 1;
    }

    // 载入战斗所需的额外贴图
    if (SEMIREAL == 1)
    {
        BHead.resize(BRoleAmount);
        for (int i = 0; i < BRoleAmount; i++)
        {
            int hn = Rrole[Brole[i].rnum].HeadNum;
            if (!HeadSurface[hn])
            {
                auto path = std::format("{}head/{}.png", AppPath, hn);
                HeadSurface[hn] = LoadSurfaceFromFile(path);
            }
            BHead[i] = HeadSurface[hn];
            if (!BHead[i])
            {
                BHead[i] = SDL_CreateSurface(56, 71, SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
                SDL_FillSurfaceRect(BHead[i], nullptr, 1);
                SDL_SetSurfaceColorKey(BHead[i], true, 1);
                DrawHeadPic(hn, 0, 0, BHead[i]);
            }
            Brole[i].BHead = i;
        }
    }

    for (int i = 0; i < BRoleAmount; i++)
    {
        int hn = Rrole[Brole[i].rnum].HeadNum;
        auto sp = std::format("fight/fight{:03d}", hn);
        FPicAmount = LoadIdxGrp(sp + ".idx", sp + ".grp", FIdx[hn], FPic[hn]);
    }

    BattleMainControl();
    RestoreRoleStatus();
    event.key.key = 0;
    event.button.button = 0;

    if (BattleResult == 1 || (BattleResult == 2 && getexp != 0))
    {
        AddExp();
        CheckLevelUp();
        CheckBook();
    }
    UpdateScreen(screen, 0, 0, screen->w, screen->h);

    if (SEMIREAL == 1)
    {
        BHead.clear();
    }

    if (Rscene[CurScene].EntranceMusic >= 0)
    {
        StopMP3();
        PlayMP3(Rscene[CurScene].EntranceMusic, -1);
    }
    else
    {
        PlayMP3(PreMusic, -1);
    }

    Where = 1;
    return BattleResult == 1;
}

bool InitialBField()
{
    FILE* sta = fopen((AppPath + "resource/war.sta").c_str(), "rb");
    int offset = CurrentBattle * (int)sizeof(TWarData);
    fseek(sta, offset, SEEK_SET);
    fread(&WarSta, sizeof(TWarData), 1, sta);
    fclose(sta);

    int fieldnum = WarSta.BFieldNum;
    offset = 0;
    if (fieldnum != 0)
    {
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
    {
        for (int i2 = 0; i2 < 64; i2++)
        {
            BField[2][i1][i2] = -1;
        }
    }
    BRoleAmount = 0;
    bool result = true;

    for (int i = 0; i < 6; i++)
    {
        int x = WarSta.TeamX[i], y = WarSta.TeamY[i];
        if (WarSta.AutoTeamMate[i] >= 0)
        {
            InitialBRole(BRoleAmount, WarSta.AutoTeamMate[i], 0, x, y);
            BRoleAmount++;
        }
    }
    if (BRoleAmount > 0)
    {
        result = false;
    }

    for (int i = 0; i < 20; i++)
    {
        int x = WarSta.EnemyX[i], y = WarSta.EnemyY[i];
        if (WarSta.Enemy[i] >= 0)
        {
            InitialBRole(BRoleAmount, WarSta.Enemy[i], 1, x, y);
            BRoleAmount++;
        }
    }
    return result;
}

void InitialBRole(int i, int rnum, int team, int x, int y)
{
    if (i < 0 || i >= 200)
    {
        return;
    }
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

int SelectTeamMembers()
{
    int result = 0, max = 1, menu = 0;
    std::string menuStr[9];
    for (int i = 0; i < 6; i++)
    {
        if (TeamList[i] >= 0)
        {
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

    auto ShowMultiMenu = [&]()
    {
        int x = CENTER_X - 105, y = 150;
        LoadFreshScreen(x + 30, y, 151, max * 22 + 29);
        std::string str1 = "參戰";
        DrawRectangle(screen, x + 30, y, 150, max * 22 + 28, 0, ColColor(255), 50);
        for (int i = 0; i <= max; i++)
        {
            uint32_t c1 = (i == menu) ? ColColor(0x64) : ColColor(0x05);
            uint32_t c2 = (i == menu) ? ColColor(0x66) : ColColor(0x07);
            DrawShadowText(screen, menuStr[i], x + 33, y + 3 + 22 * i, c1, c2);
            if ((result & (1 << (i - 1))) && i > 0 && i < max)
            {
                uint32_t cs1 = (i == menu) ? ColColor(0x64) : ColColor(0x21);
                uint32_t cs2 = (i == menu) ? ColColor(0x66) : ColColor(0x23);
                DrawShadowText(screen, str1, x + 133, y + 3 + 22 * i, cs1, cs2);
            }
        }
        UpdateScreen(screen, x + 30, y, 151, max * 22 + 29);
    };

    ShowMultiMenu();
    while (SDL_WaitEvent(&event))
    {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP)
        {
            if ((event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) && menu != max)
            {
                if (menu > 0)
                {
                    result ^= (1 << (menu - 1));
                }
                else if (result < (int)(pow(2, max - 1) - 1))
                {
                    result = (int)(pow(2, max - 1) - 1);
                }
                else
                {
                    result = 0;
                }
                ShowMultiMenu();
            }
            if ((event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) && menu == max)
            {
                if (result != 0)
                {
                    break;
                }
            }
            if (event.key.key == SDLK_UP)
            {
                menu--;
                if (menu < 0)
                {
                    menu = max;
                }
                ShowMultiMenu();
            }
            if (event.key.key == SDLK_DOWN)
            {
                menu++;
                if (menu > max)
                {
                    menu = 0;
                }
                ShowMultiMenu();
            }
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= CENTER_X - 75 && mx < CENTER_X + 75 && my >= 150 && my < max * 22 + 178)
            {
                if (event.button.button == SDL_BUTTON_LEFT && menu != max)
                {
                    if (menu > 0)
                    {
                        result ^= (1 << (menu - 1));
                    }
                    else if (result < (int)(pow(2, max - 1) - 1))
                    {
                        result = (int)(pow(2, max - 1) - 1);
                    }
                    else
                    {
                        result = 0;
                    }
                    ShowMultiMenu();
                }
                if (event.button.button == SDL_BUTTON_LEFT && menu == max && result != 0)
                {
                    break;
                }
            }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION)
        {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= CENTER_X - 75 && mx < CENTER_X + 75 && my >= 150 && my < max * 22 + 178)
            {
                int menup = menu;
                menu = (int)((my - 152) / 22);
                if (menup != menu)
                {
                    ShowMultiMenu();
                }
            }
        }
    }
    return result;
}

void BattleMainControl()
{
    uint32_t delaytime = 5;
    Bx = Brole[0].X;
    By = Brole[0].Y;
    int i = 0;
    while (BattleResult == 0)
    {
        CalMoveAbility();
        if (SEMIREAL == 0)
        {
            ReArrangeBRole();
        }
        ClearDeadRolePic();
        for (int j = 0; j < BRoleAmount; j++)
        {
            Brole[j].Acted = 0;
            Brole[j].ShowNumber = 0;
        }
        memset(&BField[4][0][0], 0, sizeof(BField[4]));

        if (SEMIREAL == 1)
        {
            DrawBField(0);
            RecordFreshScreen(0, 0, screen->w, screen->h);
            DrawProgress();
            int act = 0;
            while (SDL_PollEvent(&event) || true)
            {
                for (i = 0; i < BRoleAmount; i++)
                {
                    Brole[i].RealProgress += Brole[i].RealSpeed;
                    if (Brole[i].RealProgress >= 10000)
                    {
                        Brole[i].RealProgress -= 10000;
                        act = 1;
                        break;
                    }
                }
                if (act)
                {
                    break;
                }
                LoadFreshScreen(0, 0, screen->w, screen->h);
                DrawProgress();
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
                SDL_Delay(delaytime);
                CheckBasicEvent();
            }
        }
        if (SEMIREAL == 0)
        {
            i = 0;
        }

        while (i < BRoleAmount && BattleResult == 0)
        {
            while (SDL_PollEvent(&event) || true)
            {
                CheckBasicEvent();
                if (event.key.key == SDLK_ESCAPE || event.button.button == SDL_BUTTON_RIGHT)
                {
                    Brole[i].Auto = 0;
                    event.button.button = 0;
                    event.key.key = 0;
                }
                break;
            }
            x50[28005] = i;
            if (Brole[i].Dead == 0)
            {
                Bx = Brole[i].X;
                By = Brole[i].Y;
                Redraw();
                TBattleRole tempBrole;
                if (Brole[i].Team == 0 && Brole[i].Auto == 0)
                {
                    if (Brole[i].Acted == 0)
                    {
                        tempBrole = Brole[i];
                    }
                    int menuResult = BattleMenu(i);
                    switch (menuResult)
                    {
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
                        if (MODVersion == 51)
                        {
                            CallEvent(1077);
                        }
                        else
                        {
                            if (TeamModeMenu(i))
                            {
                                for (int j = 0; j < BRoleAmount; j++)
                                {
                                    if (Brole[j].Team == 0 && Brole[j].Dead == 0)
                                    {
                                        Brole[j].Auto = (Brole[j].AutoMode > 0) ? 1 : (Brole[j].AutoMode < 0) ? -1 :
                                                                                                                0;
                                    }
                                }
                            }
                        }
                        break;
                    default:
                        if (tempBrole.rnum == Brole[i].rnum)
                        {
                            BField[2][tempBrole.X][tempBrole.Y] = i;
                            BField[2][Brole[i].X][Brole[i].Y] = -1;
                            Brole[i] = tempBrole;
                        }
                        break;
                    }
                }
                else
                {
                    AutoBattle(i);
                    Brole[i].Acted = 1;
                }
            }
            else
            {
                Brole[i].Acted = 1;
            }

            ClearDeadRolePic();
            Redraw();
            BattleResult = BattleStatus();
            if (Brole[i].Acted == 1)
            {
                i++;
                if (SEMIREAL == 1)
                {
                    break;
                }
            }
        }
        BattleRound++;
        CalPoiHurtLife();
    }
}

void CalMoveAbility()
{
    for (int i = 0; i < BRoleAmount; i++)
    {
        int rnum = Brole[i].rnum;
        int addspeed = 0;
        if (Rrole[rnum].Equip[0] >= 0)
        {
            addspeed += Ritem[Rrole[rnum].Equip[0]].AddSpeed;
        }
        if (Rrole[rnum].Equip[1] >= 0)
        {
            addspeed += Ritem[Rrole[rnum].Equip[1]].AddSpeed;
        }
        Brole[i].Step = (Rrole[rnum].Speed + addspeed) / 15;
        if (Brole[i].Step > 15)
        {
            Brole[i].Step = 15;
        }
        if (SEMIREAL == 1)
        {
            Brole[i].RealSpeed = (int)((Rrole[rnum].Speed + addspeed) / (log10((double)MaxProList[44]) - 1)) - Rrole[rnum].Hurt / 10 - Rrole[rnum].Poison / 30;
            if (Brole[i].RealSpeed > 200)
            {
                Brole[i].RealSpeed = 200 + (Brole[i].RealSpeed - 200) / 3;
            }
            if (Brole[i].Step > 7)
            {
                Brole[i].Step = 7;
            }
        }
    }
}

void ReArrangeBRole()
{
    for (int i1 = 0; i1 < BRoleAmount - 1; i1++)
    {
        for (int i2 = i1 + 1; i2 < BRoleAmount; i2++)
        {
            if (Rrole[Brole[i1].rnum].Speed * 10 + rand() % 10 < Rrole[Brole[i2].rnum].Speed * 10 + rand() % 10)
            {
                std::swap(Brole[i1], Brole[i2]);
            }
        }
    }
    for (int i1 = 0; i1 < 64; i1++)
    {
        for (int i2 = 0; i2 < 64; i2++)
        {
            BField[2][i1][i2] = -1;
        }
    }
    for (int i = 0; i < BRoleAmount; i++)
    {
        BField[2][Brole[i].X][Brole[i].Y] = (Brole[i].Dead == 0) ? i : -1;
    }
}

int BattleStatus()
{
    int sum0 = 0, sum1 = 0;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == 0 && Brole[i].Dead == 0)
        {
            sum0++;
        }
        if (Brole[i].Team == 1 && Brole[i].Dead == 0)
        {
            sum1++;
        }
    }
    if (sum0 > 0 && sum1 > 0)
    {
        return 0;
    }
    if (sum1 == 0)
    {
        return 1;
    }
    return 2;
}

int BattleMenu(int bnum)
{
    static const char* word[] = { "移動", "攻擊", "用毒", "解毒", "醫療", "物品", "等待", "狀態", "休息", "自動" };
    int MenuStat = 0x3E0, max = 4, rnum = Brole[bnum].rnum;
    if (Brole[bnum].Step > 0)
    {
        MenuStat |= 1;
        max++;
    }
    if (Rrole[rnum].PhyPower >= 10)
    {
        int p = 0;
        for (int i = 0; i < 10; i++)
        {
            if (Rrole[rnum].Magic[i] > 0)
            {
                p = 1;
                break;
            }
        }
        if (p)
        {
            MenuStat |= 2;
            max++;
        }
    }
    if (Rrole[rnum].UsePoi > 0 && Rrole[rnum].PhyPower >= 30)
    {
        MenuStat |= 4;
        max++;
    }
    if (Rrole[rnum].MedPoi > 0 && Rrole[rnum].PhyPower >= 50)
    {
        MenuStat |= 8;
        max++;
    }
    if (Rrole[rnum].Medcine > 0 && Rrole[rnum].PhyPower >= 50)
    {
        MenuStat |= 16;
        max++;
    }
    if (SEMIREAL == 1)
    {
        MenuStat &= ~64;
        max--;
    }

    int menu = 0;
    Redraw();
    ShowSimpleStatus(Brole[bnum].rnum, CENTER_X + 100, 50);
    auto buf = std::format("回合{}", BattleRound);
    std::string s(buf);
    DrawTextWithRect(screen, s, 160, 50, DrawLength(s) * 10 + 6, ColColor(0x21), ColColor(0x23));
    RecordFreshScreen(0, 0, screen->w, screen->h);

    auto ShowBMenu = [&]()
    {
        LoadFreshScreen(100, 50, 47, max * 22 + 29);
        DrawRectangle(screen, 100, 50, 47, max * 22 + 28, 0, ColColor(255), 50);
        int p2 = 0;
        for (int i2 = 0; i2 < 10; i2++)
        {
            if (MenuStat & (1 << i2))
            {
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
    while (SDL_WaitEvent(&event))
    {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP)
        {
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE)
            {
                break;
            }
            if (event.key.key == SDLK_ESCAPE)
            {
                menu = -1;
                break;
            }
            if (event.key.key == SDLK_UP)
            {
                menu--;
                if (menu < 0)
                {
                    menu = max;
                }
                ShowBMenu();
            }
            if (event.key.key == SDLK_DOWN)
            {
                menu++;
                if (menu > max)
                {
                    menu = 0;
                }
                ShowBMenu();
            }
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (event.button.button == SDL_BUTTON_LEFT && mx >= 100 && mx < 147 && my >= 50 && my < max * 22 + 78)
            {
                break;
            }
            if (event.button.button == SDL_BUTTON_RIGHT)
            {
                menu = -1;
                break;
            }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION)
        {
            float mx = event.button.x / (RESOLUTIONX / (float)screen->w);
            float my = event.button.y / (RESOLUTIONY / (float)screen->h);
            if (mx >= 100 && mx < 147 && my >= 50 && my < max * 22 + 78)
            {
                int menup = menu;
                menu = (int)((my - 52) / 22);
                if (menu > max)
                {
                    menu = max;
                }
                if (menu < 0)
                {
                    menu = 0;
                }
                if (menup != menu)
                {
                    ShowBMenu();
                }
            }
        }
    }
    if (menu == -1)
    {
        return -1;
    }
    int p = 0;
    int idx = 0;
    for (int i = 0; i < 10; i++)
    {
        if (MenuStat & (1 << i))
        {
            p++;
            if (p > menu)
            {
                idx = i;
                break;
            }
        }
    }
    return idx;
}

void MoveRole(int bnum)
{
    CalCanSelect(bnum, 0, Brole[bnum].Step);
    if (SelectAim(bnum, Brole[bnum].Step))
    {
        MoveAmination(bnum);
    }
}

bool MoveAmination(int bnum)
{
    bool result = abs(Ax - Bx) + abs(Ay - By) > 0;
    if (BField[3][Ax][Ay] > 0)
    {
        int Xinc[] = { 0, 1, -1, 0, 0 }, Yinc[] = { 0, 0, 0, 1, -1 };
        int16_t linebx[4097], lineby[4097];
        linebx[0] = Bx;
        lineby[0] = By;
        linebx[BField[3][Ax][Ay]] = Ax;
        lineby[BField[3][Ax][Ay]] = Ay;
        int a = BField[3][Ax][Ay] - 1;
        while (a >= 0)
        {
            bool seekError = true;
            for (int i = 1; i <= 4; i++)
            {
                int tx = linebx[a + 1] + Xinc[i], ty = lineby[a + 1] + Yinc[i];
                if (tx >= 0 && tx < 64 && ty >= 0 && ty < 64 && BField[3][tx][ty] == BField[3][linebx[a + 1]][lineby[a + 1]] - 1)
                {
                    linebx[a] = tx;
                    lineby[a] = ty;
                    seekError = false;
                    break;
                }
            }
            if (seekError)
            {
                break;
            }
            a--;
        }
        for (int j = 1; j <= BField[3][Ax][Ay]; j++)
        {
            if (linebx[j] > Bx && lineby[j] == By)
            {
                Brole[bnum].Face = 3;
            }
            else if (linebx[j] < Bx && lineby[j] == By)
            {
                Brole[bnum].Face = 0;
            }
            else if (linebx[j] == Bx && lineby[j] > By)
            {
                Brole[bnum].Face = 1;
            }
            else if (linebx[j] == Bx && lineby[j] < By)
            {
                Brole[bnum].Face = 2;
            }
            if (BField[2][Bx][By] == bnum)
            {
                BField[2][Bx][By] = -1;
            }
            Bx = linebx[j];
            By = lineby[j];
            if (BField[2][Bx][By] == -1)
            {
                BField[2][Bx][By] = bnum;
            }
            Redraw();
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            SDL_Delay(30);
        }
        Brole[bnum].X = Bx;
        Brole[bnum].Y = By;
        BField[2][Bx][By] = bnum;
        Brole[bnum].Step = BField[5][Ax][Ay];
    }
    return result;
}

bool SelectAim(int bnum, int step, int AreaType, int AreaRange)
{
    Ax = Bx;
    Ay = By;
    BattleSelecting = true;
    Redraw();
    SetAminationPosition(AreaType, step, AreaRange);
    DrawBFieldWithCursor(step);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    while (SDL_WaitEvent(&event))
    {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP)
        {
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE)
            {
                if (Ax >= 0 && Ax <= 63 && Ay >= 0 && Ay <= 63 && abs(Ax - Bx) + abs(Ay - By) <= step && BField[3][Ax][Ay] >= 0)
                {
                    x50[28927] = 1;
                    BattleSelecting = false;
                    return true;
                }
            }
            if (event.key.key == SDLK_ESCAPE)
            {
                x50[28927] = 0;
                BattleSelecting = false;
                return false;
            }
        }
        if (event.type == SDL_EVENT_KEY_DOWN)
        {
            int px = Ax, py = Ay;
            if (event.key.key == SDLK_LEFT)
            {
                Ay--;
            }
            else if (event.key.key == SDLK_RIGHT)
            {
                Ay++;
            }
            else if (event.key.key == SDLK_DOWN)
            {
                Ax++;
            }
            else if (event.key.key == SDLK_UP)
            {
                Ax--;
            }
            if (abs(Ax - Bx) + abs(Ay - By) > step || BField[3][Ax][Ay] < 0 || Ax < 0 || Ax > 63 || Ay < 0 || Ay > 63)
            {
                Ax = px;
                Ay = py;
            }
            event.key.key = SDLK_UNKNOWN;
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            if (event.button.button == SDL_BUTTON_RIGHT)
            {
                BattleSelecting = false;
                return false;
            }
            if (TouchWalk && event.button.button == SDL_BUTTON_LEFT)
            {
                BattleSelecting = false;
                return true;
            }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION)
        {
            if (TouchWalk)
            {
                int axp = (int)(-(event.button.x / (RESOLUTIONX / (float)screen->w)) + CENTER_X + 2 * (event.button.y / (RESOLUTIONY / (float)screen->h)) - 2 * CENTER_Y + 18) / 36 + Bx;
                int ayp = (int)((event.button.x / (RESOLUTIONX / (float)screen->w)) - CENTER_X + 2 * (event.button.y / (RESOLUTIONY / (float)screen->h)) - 2 * CENTER_Y + 18) / 36 + By;
                if (abs(axp - Bx) + abs(ayp - By) <= step && BField[3][axp][ayp] >= 0)
                {
                    Ax = axp;
                    Ay = ayp;
                }
            }
        }
        SetAminationPosition(AreaType, step, AreaRange);
        DrawBFieldWithCursor(step);
        if (BField[2][Ax][Ay] >= 0)
        {
            ShowSimpleStatus(Brole[BField[2][Ax][Ay]].rnum, CENTER_X + 100, 50);
        }
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    }
    BattleSelecting = false;
    return false;
}

bool SelectDirector(int bnum, int step)
{
    Ax = Bx;
    Ay = By;
    BattleSelecting = true;
    switch (Brole[bnum].Face)
    {
    case 0: Ax = Ax - 1; break;
    case 1: Ay = Ay + 1; break;
    case 2: Ay = Ay - 1; break;
    case 3: Ax = Ax + 1; break;
    }

    SetAminationPosition(1, step);
    DrawBFieldWithCursor(-1);

    std::string str = "選擇攻擊方向";
    DrawTextWithRect(screen, str, 280, 200, 125, ColColor(0x23), ColColor(0x21));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    bool result = false;
    while (SDL_WaitEvent(&event))
    {
        CheckBasicEvent();
        if (event.type == SDL_EVENT_KEY_UP)
        {
            if (event.key.key == SDLK_ESCAPE)
            {
                result = false;
                break;
            }
            if (event.key.key == SDLK_LEFT)
            {
                Ay = By - 1;
                Ax = Bx;
            }
            if (event.key.key == SDLK_RIGHT)
            {
                Ay = By + 1;
                Ax = Bx;
            }
            if (event.key.key == SDLK_DOWN)
            {
                Ax = Bx + 1;
                Ay = By;
            }
            if (event.key.key == SDLK_UP)
            {
                Ax = Bx - 1;
                Ay = By;
            }
            if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE)
            {
                if (Ax != Bx || Ay != By)
                {
                    result = true;
                    break;
                }
            }
        }
        if (event.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            if (event.button.button == SDL_BUTTON_RIGHT)
            {
                result = false;
                break;
            }
            if (TouchWalk && event.button.button == SDL_BUTTON_LEFT)
            {
                if (Ax != Bx || Ay != By)
                {
                    result = true;
                    break;
                }
            }
        }
        if (event.type == SDL_EVENT_MOUSE_MOTION)
        {
            if (TouchWalk)
            {
                Ax = Bx;
                Ay = By;
                float mx = event.button.x / ((float)RESOLUTIONX / screen->w);
                float my = event.button.y / ((float)RESOLUTIONY / screen->h);
                if (mx < CENTER_X && my < CENTER_Y)
                {
                    Ay = By - 1;
                }
                if (mx < CENTER_X && my >= CENTER_Y)
                {
                    Ax = Bx + 1;
                }
                if (mx >= CENTER_X && my < CENTER_Y)
                {
                    Ax = Bx - 1;
                }
                if (mx >= CENTER_X && my >= CENTER_Y)
                {
                    Ay = By + 1;
                }
            }
        }
        SetAminationPosition(1, step);
        DrawBFieldWithCursor(-1);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    }
    BattleSelecting = false;
    return result;
}

void SeekPath2(int x, int y, int step, int myteam, int mode)
{
    // BFS寻路
    struct QNode
    {
        int x, y, s;
    };
    std::vector<QNode> queue;
    queue.push_back({ x, y, 0 });
    BField[3][x][y] = 0;
    int dx[] = { 1, -1, 0, 0 }, dy[] = { 0, 0, 1, -1 };
    int head = 0;
    while (head < (int)queue.size())
    {
        auto cur = queue[head++];
        if (cur.s >= step)
        {
            continue;
        }
        for (int d = 0; d < 4; d++)
        {
            int nx = cur.x + dx[d], ny = cur.y + dy[d];
            if (nx < 0 || nx >= 64 || ny < 0 || ny >= 64)
            {
                continue;
            }
            if (BField[3][nx][ny] >= 0)
            {
                continue;
            }
            bool canPass = true;
            if (mode == 0)
            {
                if (BField[1][nx][ny] > 0 || (BField[2][nx][ny] >= 0 && BField[2][nx][ny] != -1))
                {
                    canPass = false;
                }
            }
            if (canPass)
            {
                BField[3][nx][ny] = cur.s + 1;
                queue.push_back({ nx, ny, cur.s + 1 });
            }
        }
    }
}

void CalCanSelect(int bnum, int mode, int step)
{
    for (int i = 0; i < 64; i++)
    {
        for (int j = 0; j < 64; j++)
        {
            BField[3][i][j] = -1;
        }
    }
    int x = Brole[bnum].X, y = Brole[bnum].Y;

    if (mode == 0)
    {
        BField[3][x][y] = 0;
        SeekPath2(x, y, step, Brole[bnum].Team, mode);
    }

    if (mode == 1)
    {
        for (int i1 = 0; i1 < 64; i1++)
        {
            for (int i2 = 0; i2 < 64; i2++)
            {
                if (abs(i1 - x) + abs(i2 - y) <= step)
                {
                    BField[3][i1][i2] = 0;
                }
            }
        }
    }

    if (mode == 2)
    {
        for (int i1 = 0; i1 < 64; i1++)
        {
            for (int i2 = 0; i2 < 64; i2++)
            {
                if (BField[2][i1][i2] >= 0)
                {
                    BField[3][i1][i2] = 0;
                }
            }
        }
    }
}

void Attack(int bnum)
{
    int rnum = Brole[bnum].rnum;

    while (true)
    {
        int magicIdx = -1;
        int mnum = SelectMagic(rnum);
        if (mnum < 0)
        {
            break;
        }

        // 找到mnum对应的索引i
        int magIdx = 0;
        for (int i = 0; i < 10; i++)
        {
            if (Rrole[rnum].Magic[i] == mnum)
            {
                magIdx = i;
                break;
            }
        }
        int level = Rrole[rnum].MagLevel[magIdx] / 100 + 1;

        int AreaType = Rmagic[mnum].AttAreaType;
        int step = Rmagic[mnum].MoveDistance[level - 1];
        bool selected = false;

        switch (AreaType)
        {
        case 0:
        case 3:
            CalCanSelect(bnum, 1, step);
            if (SelectAim(bnum, step, AreaType, Rmagic[mnum].AttDistance[level - 1]))
            {
                Brole[bnum].Acted = 1;
            }
            break;
        case 1:
            if (SelectDirector(bnum, Rmagic[mnum].MoveDistance[level - 1]))
            {
                Brole[bnum].Acted = 1;
            }
            break;
        case 2:
            SetAminationPosition(AreaType, Rmagic[mnum].MoveDistance[level - 1], Rmagic[mnum].AttDistance[level - 1]);
            DrawBFieldWithCursor(-1);
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            {
                int key = 0;
                while (key != SDLK_RETURN && key != SDLK_SPACE && key != SDLK_ESCAPE)
                {
                    key = WaitAnyKey();
                }
                if (key != SDLK_ESCAPE)
                {
                    Brole[bnum].Acted = 1;
                }
            }
            break;
        }

        if (Brole[bnum].Acted == 1)
        {
            // 攻击成功, 武功等级增加并播放效果
            for (int i1 = 0; i1 <= (Rrole[rnum].AttTwice > 0 ? 1 : 0); i1++)
            {
                Rrole[rnum].MagLevel[magIdx] += rand() % 2 + 1;
                if (Rrole[rnum].MagLevel[magIdx] > 999)
                {
                    Rrole[rnum].MagLevel[magIdx] = 999;
                }
                if (Rmagic[mnum].UnKnow[4] > 0)
                {
                    CallEvent(Rmagic[mnum].UnKnow[4]);
                }
                else
                {
                    // 攻击效果
                    ShowMagicName(mnum);
                    PlayActionAmination(bnum, Rmagic[mnum].MagicType, mnum);
                    PlayMagicAmination(bnum, Rmagic[mnum].AmiNum);
                    CalHurtRole(bnum, mnum, level);
                    ShowHurtValue(Rmagic[mnum].HurtType);
                }
            }
            break;
        }
    }
}

void AttackAction(int bnum, int i, int mnum, int level)
{
    if (i >= BRoleAmount || Brole[i].Dead != 0)
    {
        return;
    }
    int hurt = CalHurtValue(bnum, i, mnum, level);
    Brole[i].ShowNumber = hurt;
}

void AttackActionAll(int bnum, int mnum, int level)
{
    PlayMagicAmination(bnum, Rmagic[mnum].AmiNum);
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Dead == 0 && BField[4][Brole[i].X][Brole[i].Y] > 0)
        {
            AttackAction(bnum, i, mnum, level);
        }
    }
}

void ShowMagicName(int mnum, int mode)
{
    Redraw();
    std::string str;
    if (mode == 1)
    {
        str = cp950toutf8(Ritem[mnum].Name);
    }
    else
    {
        str = cp950toutf8(Rmagic[mnum].Name);
    }
    int l = DrawLength(str);
    DrawTextWithRectNoUpdate(screen, str, CENTER_X - l * 5, CENTER_Y - 150, l * 10 + 7, ColColor(0x14), ColColor(0x16));
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    SDL_Delay(500);
}

int SelectMagic(int rnum)
{
    // Pascal: custom menu at (100, 50), width 167, shows magic name + level number
    int menuStatus = 0;
    int maxMenu = 0;
    std::string menuString[10], menuEngString[10];

    for (int i = 0; i < 10; i++)
    {
        if (Rrole[rnum].Magic[i] > 0)
        {
            menuStatus |= (1 << i);
            menuString[i] = cp950toutf8(Rmagic[Rrole[rnum].Magic[i]].Name);
            menuEngString[i] = std::format("{:3d}", Rrole[rnum].MagLevel[i] / 100 + 1);
            maxMenu++;
        }
    }
    if (maxMenu == 0)
    {
        return -1;
    }
    maxMenu--;

    int menu = 0;

    // ShowMagicMenu lambda
    auto ShowMagicMenu = [&]()
    {
        Redraw();
        DrawRectangle(screen, 100, 50, 167, maxMenu * 22 + 28, 0, ColColor(255), 30);
        int p2 = 0;
        for (int i2 = 0; i2 < 10; i2++)
        {
            if (menuStatus & (1 << i2))
            {
                if (p2 == menu)
                {
                    DrawShadowText(screen, menuString[i2], 103, 53 + 22 * p2, ColColor(0x66), ColColor(0x64));
                    DrawEngShadowText(screen, menuEngString[i2], 223, 53 + 22 * p2, ColColor(0x66), ColColor(0x64));
                }
                else
                {
                    DrawShadowText(screen, menuString[i2], 103, 53 + 22 * p2, ColColor(0x23), ColColor(0x21));
                    DrawEngShadowText(screen, menuEngString[i2], 223, 53 + 22 * p2, ColColor(0x23), ColColor(0x21));
                }
                p2++;
            }
        }
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    };

    Redraw();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    ShowMagicMenu();

    int result = 0;
    SDL_Event e;
    while (SDL_WaitEvent(&e))
    {
        CheckBasicEvent();
        if (e.type == SDL_EVENT_KEY_UP)
        {
            if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE)
            {
                break;
            }
            if (e.key.key == SDLK_ESCAPE)
            {
                result = -1;
                break;
            }
            if (e.key.key == SDLK_UP)
            {
                menu--;
                if (menu < 0)
                {
                    menu = maxMenu;
                }
                ShowMagicMenu();
            }
            if (e.key.key == SDLK_DOWN)
            {
                menu++;
                if (menu > maxMenu)
                {
                    menu = 0;
                }
                ShowMagicMenu();
            }
        }
        else if (e.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            if (e.button.button == SDL_BUTTON_LEFT)
            {
                break;
            }
            if (e.button.button == SDL_BUTTON_RIGHT)
            {
                result = -1;
                break;
            }
        }
        else if (e.type == SDL_EVENT_MOUSE_MOTION)
        {
            int xm, ym;
            if (MouseInRegion(100, 50, 167, maxMenu * 22 + 28, xm, ym))
            {
                int menup = menu;
                menu = (ym - 52) / 22;
                if (menu > maxMenu)
                {
                    menu = maxMenu;
                }
                if (menu < 0)
                {
                    menu = 0;
                }
                if (menup != menu)
                {
                    ShowMagicMenu();
                }
            }
        }
    }

    if (result >= 0)
    {
        // Convert menu position back to magic index -> magic number
        int p = 0;
        int i = 0;
        for (i = 0; i < 10; i++)
        {
            if (menuStatus & (1 << i))
            {
                if (p == menu)
                {
                    break;
                }
                p++;
            }
        }
        return Rrole[rnum].Magic[i];
    }
    Redraw();
    return -1;
}

void SetAminationPosition(int mode, int step, int range)
{
    SetAminationPosition2(Bx, By, Ax, Ay, mode, step, range);
}

void SetAminationPosition2(int bx1, int by1, int ax1, int ay1, int mode, int step, int range)
{
    memset(&BField[4][0][0], 0, sizeof(BField[4]));
    switch (mode)
    {
    case 0:    // 单点
        BField[4][ax1][ay1] = 1;
        break;
    case 3:    // 范围 (以Ax,Ay为中心, range为半径)
        for (int i1 = std::max(ax1 - range, 0); i1 <= std::min(ax1 + range, 63); i1++)
        {
            for (int i2 = std::max(ay1 - range, 0); i2 <= std::min(ay1 + range, 63); i2++)
            {
                BField[4][i1][i2] = (abs(i1 - bx1) + abs(i2 - by1)) * 1 + rand() % 24 + 1;
            }
        }
        break;
    case 1:
    {    // 线
        int i = 1;
        int i1 = (ax1 > bx1) ? 1 : (ax1 < bx1) ? -1 :
                                                 0;
        int i2 = (ay1 > by1) ? 1 : (ay1 < by1) ? -1 :
                                                 0;
        if (i1 > 0)
        {
            step = std::min(63 - bx1, step);
        }
        if (i2 > 0)
        {
            step = std::min(63 - by1, step);
        }
        if (i1 < 0)
        {
            step = std::min(bx1, step);
        }
        if (i2 < 0)
        {
            step = std::min(by1, step);
        }
        if (i1 == 0 && i2 == 0)
        {
            step = 0;
        }
        while (i <= step)
        {
            BField[4][bx1 + i1 * i][by1 + i2 * i] = i * 2;
            i++;
        }
    }
    break;
    case 2:    // 十字 (以Bx,By为中心)
        for (int i1 = std::max(bx1 - step, 0); i1 <= std::min(bx1 + step, 63); i1++)
        {
            BField[4][i1][by1] = abs(i1 - bx1) * 2;
        }
        for (int i2 = std::max(by1 - step, 0); i2 <= std::min(by1 + step, 63); i2++)
        {
            BField[4][bx1][i2] = abs(i2 - by1) * 2;
        }
        break;
    }
    switch (mode)
    {
    case 0: maxdelaypicnum = 1; break;
    case 3: maxdelaypicnum = 24; break;
    case 1: maxdelaypicnum = step * 4; break;
    case 2: maxdelaypicnum = step * 4; break;
    }
}

void PlayMagicAmination(int bnum, int enumv, int ForTeam, int mode)
{
    if (enumv < 0 || enumv > 199)
    {
        return;
    }

    uint32_t color1, color2;
    std::string str;
    SelectModeColor(mode, color1, color2, str, 1);

    int min_ = 1000, max_ = 0;
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            if (BField[4][i1][i2] > 0)
            {
                if (BField[4][i1][i2] > max_)
                {
                    max_ = BField[4][i1][i2];
                }
                if (BField[4][i1][i2] < min_)
                {
                    min_ = BField[4][i1][i2];
                }
            }
        }
    }

    int beginPic = 0;
    // 播放音效
    TPosition posA = GetPositionOnScreen(Ax, Ay, CENTER_X, CENTER_Y);
    TPosition posB = GetPositionOnScreen(Bx, By, CENTER_X, CENTER_Y);
    int sx = posA.x - posB.x;
    int sy = posB.y - posA.y;
    int sz = -((Ax + Ay) - (Bx + By)) * 9;
    PlaySoundE(enumv, 0, sx, sy, sz);

    for (int i = 0; i < enumv; i++)
    {
        beginPic += EffectList[i];
    }
    int endPic = beginPic + EffectList[enumv] - 1;

    int p = beginPic;
    while (true)
    {
        CheckBasicEvent();
        DrawBFieldWithEft(p, beginPic, endPic, min_, bnum, ForTeam, 1, 0xFFFFFFFF);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        SDL_Delay(BATTLE_SPEED);
        p++;
        if (p > endPic + max_ - min_)
        {
            break;
        }
    }
    Brole[bnum].Pic = 0;
}

void CalHurtRole(int bnum, int mnum, int level)
{
    int rnum = Brole[bnum].rnum;
    Rrole[rnum].PhyPower -= 3;
    // 根据内力调整等级
    if (Rrole[rnum].CurrentMP < Rmagic[mnum].NeedMP * ((level + 1) / 2))
    {
        level = Rrole[rnum].CurrentMP / Rmagic[mnum].NeedMP * 2;
    }
    if (level > 10)
    {
        level = 10;
    }
    Rrole[rnum].CurrentMP -= Rmagic[mnum].NeedMP * ((level + 1) / 2);

    for (int i = 0; i < BRoleAmount; i++)
    {
        Brole[i].ShowNumber = -1;
        if (BField[4][Brole[i].X][Brole[i].Y] != 0 && Brole[bnum].Team != Brole[i].Team && Brole[i].Dead == 0)
        {
            // 生命伤害
            if (Rmagic[mnum].HurtType == 0)
            {
                int hurt = CalHurtValue(bnum, i, mnum, level);
                Brole[i].ShowNumber = hurt;
                Rrole[Brole[i].rnum].CurrentHP -= hurt;
                Rrole[Brole[i].rnum].Hurt += hurt / LIFE_HURT;
                if (Rrole[Brole[i].rnum].Hurt > 99)
                {
                    Rrole[Brole[i].rnum].Hurt = 99;
                }
                Brole[bnum].ExpGot += hurt / 2;
                if (Rrole[Brole[i].rnum].CurrentHP <= 0)
                {
                    Brole[bnum].ExpGot += hurt / 2;
                }
                if (Brole[bnum].ExpGot < 0)
                {
                    Brole[bnum].ExpGot = 32767;
                }
            }
            // 内力伤害
            if (Rmagic[mnum].HurtType == 1)
            {
                int hurt = Rmagic[mnum].HurtMP[level - 1] + rand() % 5 - rand() % 5;
                Brole[i].ShowNumber = hurt;
                Rrole[Brole[i].rnum].CurrentMP -= hurt;
                if (Rrole[Brole[i].rnum].CurrentMP <= 0)
                {
                    Rrole[Brole[i].rnum].CurrentMP = 0;
                }
                // 增加己方内力及最大值
                Rrole[rnum].CurrentMP += hurt;
                Brole[bnum].ExpGot += hurt;
                Rrole[rnum].MaxMP += rand() % (hurt / 2 + 1);
                if (Rrole[rnum].MaxMP > MAX_MP)
                {
                    Rrole[rnum].MaxMP = MAX_MP;
                }
                if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP)
                {
                    Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
                }
            }
            // 中毒
            int addpoi = Rrole[rnum].AttPoi / 5 + Rmagic[mnum].Poison * level / 2 * (100 - Rrole[Brole[i].rnum].DefPoi) / 100;
            if (addpoi + Rrole[Brole[i].rnum].Poison > 99)
            {
                addpoi = 99 - Rrole[Brole[i].rnum].Poison;
            }
            if (addpoi < 0)
            {
                addpoi = 0;
            }
            if (Rrole[Brole[i].rnum].DefPoi >= 99)
            {
                addpoi = 0;
            }
            Rrole[Brole[i].rnum].Poison += addpoi;
        }
    }
}

int CalHurtValue(int bnum1, int bnum2, int mnum, int level)
{
    int rnum1 = Brole[bnum1].rnum, rnum2 = Brole[bnum2].rnum;

    // 计算双方武学常识
    int k1 = 0, k2 = 0;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == Brole[bnum1].Team && Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)
        {
            k1 += Rrole[Brole[i].rnum].Knowledge;
        }
        if (Brole[i].Team == Brole[bnum2].Team && Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)
        {
            k2 += Rrole[Brole[i].rnum].Knowledge;
        }
    }

    int mhurt = 0;
    if (level > 0)
    {
        mhurt = Rmagic[mnum].Attack[level - 1];
    }

    int att = Rrole[rnum1].Attack + k1 * 3 / 2 + mhurt / 3;
    int def = Rrole[rnum2].Defence * 2 + k2 * 3;

    // 武功类型加成
    switch (Rmagic[mnum].MagicType)
    {
    case 1:
        att += Rrole[rnum1].Fist;
        def += Rrole[rnum2].Fist;
        break;
    case 2:
        att += Rrole[rnum1].Sword;
        def += Rrole[rnum2].Sword;
        break;
    case 3:
        att += Rrole[rnum1].Knife;
        def += Rrole[rnum2].Knife;
        break;
    case 4:
        att += Rrole[rnum1].Unusual;
        def += Rrole[rnum2].Unusual;
        break;
    }

    // 按受伤折扣
    att = att * (100 - Rrole[rnum1].Hurt / 2) / 100;
    def = def * (100 - Rrole[rnum2].Hurt / 2) / 100;

    // 武器加攻击 + 配合列表
    if (Rrole[rnum1].Equip[0] >= 0)
    {
        att += Ritem[Rrole[rnum1].Equip[0]].AddAttack;
        for (int i = 0; i < MAX_WEAPON_MATCH; i++)
        {
            if (Rrole[rnum1].Equip[0] == MatchList[i][0] && mnum == MatchList[i][1])
            {
                att += MatchList[i][2] * 2 / 3;
                break;
            }
        }
    }
    // 防具加攻击
    if (Rrole[rnum1].Equip[1] >= 0)
    {
        att += Ritem[Rrole[rnum1].Equip[1]].AddAttack;
    }
    // 对方武器防具加防御
    if (Rrole[rnum2].Equip[0] >= 0)
    {
        def += Ritem[Rrole[rnum2].Equip[0]].AddDefence;
    }
    if (Rrole[rnum2].Equip[1] >= 0)
    {
        def += Ritem[Rrole[rnum2].Equip[1]].AddDefence;
    }

    int result = att - def + rand() % 20 - rand() % 20;
    int dis = abs(Brole[bnum1].X - Brole[bnum2].X) + abs(Brole[bnum1].Y - Brole[bnum2].Y);
    if (dis > 10)
    {
        dis = 10;
    }

    result = std::max(result, att / 10 + rand() % 10 - rand() % 10);
    result = result * (100 - (dis - 1) * 3) / 100;
    if (result <= 0 || level <= 0)
    {
        result = rand() % 10 + 1;
    }
    if (result > 9999)
    {
        result = 9999;
    }
    return result;
}

int CalHurtValue2(int bnum1, int bnum2, int mnum, int level)
{
    int result = CalHurtValue(bnum1, bnum2, mnum, level);
    if (result >= Rrole[Brole[bnum2].rnum].CurrentHP)
    {
        result = result * 3 / 2;
    }
    if (Rmagic[mnum].HurtType == 1)
    {
        result = Rmagic[mnum].HurtMP[level - 1] * 3 / 2;
    }
    return result;
}

void SelectModeColor(int mode, uint32_t& color1, uint32_t& color2, std::string& str, int trans)
{
    switch (mode)
    {
    case 0:
        color1 = ColColor(0x10);
        color2 = ColColor(0x14);
        str = "-%d";
        break;
    case 1:
        color1 = ColColor(0x50);
        color2 = ColColor(0x53);
        str = "-%d";
        break;
    case 2:
        color1 = ColColor(0x30);
        color2 = ColColor(0x32);
        str = "+%d";
        break;
    case 3:
        color1 = ColColor(0x07);
        color2 = ColColor(0x05);
        str = "+%d";
        break;
    case 4:
        color1 = ColColor(0x91);
        color2 = ColColor(0x93);
        str = "-%d";
        break;
    default:
        color1 = ColColor(0x10);
        color2 = ColColor(0x14);
        str = "-%d";
        break;
    }
}

void ShowHurtValue(int mode)
{
    uint32_t color1, color2;
    std::string str;
    SelectModeColor(mode, color1, color2, str);
    std::vector<std::string> word(BRoleAmount);
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].ShowNumber > 0)
        {
            char buf[32];
            snprintf(buf, sizeof(buf), str.c_str(), Brole[i].ShowNumber);
            word[i] = buf;
        }
        Brole[i].ShowNumber = -1;
    }
    int i1 = 0;
    while (true)
    {
        CheckBasicEvent();
        Redraw();
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (!word[i].empty())
            {
                int x = -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
                int y = (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
                DrawEngShadowText(screen, word[i], x, y - i1 * 2, color1, color2);
            }
        }
        SDL_Delay(BATTLE_SPEED);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        i1++;
        if (i1 > 10)
        {
            break;
        }
    }
    Redraw();
}

void CalPoiHurtLife()
{
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Dead == 0 && Rrole[Brole[i].rnum].Poison > 0)
        {
            int hurt = Rrole[Brole[i].rnum].Poison * 3;
            Rrole[Brole[i].rnum].CurrentHP -= hurt;
            if (Rrole[Brole[i].rnum].CurrentHP <= 0)
            {
                Rrole[Brole[i].rnum].CurrentHP = 0;
                Brole[i].Dead = 1;
            }
            Brole[i].ShowNumber = hurt;
        }
    }
}

void ClearDeadRolePic()
{
    // Pascal: 先检查是否有HP<=0的存活角色需要播放撤退效果
    bool needeffect = false;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Rrole[Brole[i].rnum].CurrentHP <= 0 && Brole[i].Dead == 0)
        {
            needeffect = true;
            break;
        }
    }
    // 撤退渐变效果
    if (needeffect)
    {
        int fade = 0;
        while (true)
        {
            CheckBasicEvent();
            DrawBfieldWithoutRole();
            for (int i1 = 0; i1 <= 63; i1++)
            {
                for (int i2 = 0; i2 <= 63; i2++)
                {
                    if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0)
                    {
                        int rnum = Brole[BField[2][i1][i2]].rnum;
                        if (Rrole[rnum].CurrentHP <= 0)
                        {
                            DrawRoleOnBfield(i1, i2, 0, fade, fade * 256 + 75);
                        }
                        else
                        {
                            DrawRoleOnBfield(i1, i2);
                        }
                    }
                }
            }
            DrawProgress();
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            SDL_Delay(BATTLE_SPEED / 2);
            fade += 5;
            if (fade > 100)
            {
                break;
            }
        }
    }
    // 设置Dead并清除位置
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Rrole[Brole[i].rnum].CurrentHP <= 0)
        {
            Brole[i].Dead = 1;
            BField[2][Brole[i].X][Brole[i].Y] = -1;
        }
    }
    // 刷新BField[2]
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Dead == 0)
        {
            BField[2][Brole[i].X][Brole[i].Y] = i;
        }
    }
}

void Wait(int bnum)
{
    // 交换至列表尾部
    int pos = -1;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (&Brole[i] == &Brole[bnum])
        {
            pos = i;
            break;
        }
    }
    // 标记为已行动但不结束回合 - 简化实现
    Brole[bnum].Acted = 1;
}

void RestoreRoleStatus()
{
    for (int i = 0; i < BRoleAmount; i++)
    {
        int rnum = Brole[i].rnum;
        // 我方恢复部分生命、内力；敌方恢复全部
        if (Brole[i].Team == 0)
        {
            Rrole[rnum].CurrentHP = Rrole[rnum].CurrentHP + Rrole[rnum].MaxHP / 2;
            if (Rrole[rnum].CurrentHP <= 0)
            {
                Rrole[rnum].CurrentHP = 1;
            }
            if (Rrole[rnum].CurrentHP > Rrole[rnum].MaxHP)
            {
                Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
            }
            Rrole[rnum].CurrentMP = Rrole[rnum].CurrentMP + Rrole[rnum].MaxMP / 20;
            if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP)
            {
                Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
            }
            Rrole[rnum].PhyPower = Rrole[rnum].PhyPower + MAX_PHYSICAL_POWER / 10;
            if (Rrole[rnum].PhyPower > MAX_PHYSICAL_POWER)
            {
                Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
            }
        }
        else
        {
            Rrole[rnum].Hurt = 0;
            Rrole[rnum].Poison = 0;
            Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
            Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
            Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER * 9 / 10;
        }
    }
}

void AddExp()
{
    int pmax = 65535;
    int amount = CalRNum(0);
    for (int i = 0; i < BRoleAmount; i++)
    {
        int rnum = Brole[i].rnum;
        int basicvalue = Brole[i].ExpGot;
        int p = std::min(Rrole[rnum].Exp + basicvalue, pmax);
        Rrole[rnum].Exp = p;
        p = std::min(Rrole[rnum].ExpForBook + basicvalue / 5 * 4, pmax);
        Rrole[rnum].ExpForBook = p;
        p = std::min(Rrole[rnum].ExpForItem + basicvalue / 5 * 3, pmax);
        Rrole[rnum].ExpForItem = p;

        if (amount > 0)
        {
            basicvalue = WarSta.ExpGot / amount;
        }
        else
        {
            basicvalue = 0;
        }
        basicvalue = (int)(basicvalue * EXP_RATE);
        if (Brole[i].Team == 0 && Brole[i].Dead == 0)
        {
            Redraw();
            p = std::min(Rrole[rnum].Exp + basicvalue, pmax);
            Rrole[rnum].Exp = p;
            p = std::min(Rrole[rnum].ExpForBook + basicvalue / 5 * 4, pmax);
            Rrole[rnum].ExpForBook = p;
            p = std::min(Rrole[rnum].ExpForItem + basicvalue / 5 * 3, pmax);
            Rrole[rnum].ExpForItem = p;
            ShowSimpleStatus(rnum, 100, 50);
            DrawRectangle(screen, 100, 235, 145, 25, 0, ColColor(255), 50);
            std::string str = "得經驗";
            DrawShadowText(screen, str, 103, 237, ColColor(0x23), ColColor(0x21));
            auto buf2 = std::format("{:5d}", Brole[i].ExpGot + basicvalue);
            DrawEngShadowText(screen, buf2, 188, 237, ColColor(0x66), ColColor(0x64));
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            WaitAnyKey();
        }
    }
}

void CheckLevelUp()
{
    Redraw();
    RecordFreshScreen(0, 0, screen->w, screen->h);
    for (int i = 0; i < BRoleAmount; i++)
    {
        int rnum = Brole[i].rnum;
        while ((uint16_t)Rrole[rnum].Exp >= (uint16_t)LevelUpList[Rrole[rnum].Level - 1] && Rrole[rnum].Level < MAX_LEVEL)
        {
            Rrole[rnum].Exp -= LevelUpList[Rrole[rnum].Level - 1];
            Rrole[rnum].Level++;
            LevelUp(i);
        }
    }
}

void LevelUp(int bnum)
{
    int rnum = Brole[bnum].rnum;
    // MaxHP: IncLife * 3 + random(6)
    Rrole[rnum].MaxHP = Rrole[rnum].MaxHP + Rrole[rnum].IncLife * 3 + rand() % 6;
    Rrole[rnum].MaxHP = std::min((int)Rrole[rnum].MaxHP, MAX_HP);
    Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;

    int add = Rrole[rnum].Aptitude / 15 + 1;
    if (MAX_ADD_PRO == 0)
    {
        add = rand() % add + 1;
    }

    // MaxMP: (9 - add) * 3
    Rrole[rnum].MaxMP = Rrole[rnum].MaxMP + (9 - add) * 3;
    Rrole[rnum].MaxMP = std::min((int)Rrole[rnum].MaxMP, MAX_MP);
    Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;

    Rrole[rnum].Attack += add;
    Rrole[rnum].Speed += add;
    Rrole[rnum].Defence += add;

    // 抗性成长 Data[46..54]
    for (int j = 46; j <= 54; j++)
    {
        if (Rrole[rnum].Data[j] > 0)
        {
            Rrole[rnum].Data[j] += rand() % 3 + 1;
        }
    }
    // 属性上限 Data[43..58]
    for (int j = 43; j <= 58; j++)
    {
        Rrole[rnum].Data[j] = std::min((int)Rrole[rnum].Data[j], MaxProList[j]);
    }

    Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
    Rrole[rnum].Hurt = 0;
    Rrole[rnum].Poison = 0;

    if (Brole[bnum].Team == 0)
    {
        ShowStatus(rnum);
        std::string str = "昇級";
        DrawTextWithRect(screen, str, 58, CENTER_Y - 150, 46, ColColor(0x23), ColColor(0x21));
        WaitAnyKey();
    }
}

void CheckBook()
{
    for (int i = 0; i < BRoleAmount; i++)
    {
        int rnum = Brole[i].rnum;
        int inum = Rrole[rnum].PracticeBook;
        if (inum < 0)
        {
            continue;
        }
        int mnum = Ritem[inum].Magic;
        int mlevel = 0;
        if (mnum > 0)
        {
            for (int m = 0; m < 10; m++)
            {
                if (Rrole[rnum].Magic[m] == mnum)
                {
                    mlevel = Rrole[rnum].MagLevel[m] / 100 + 1;
                    break;
                }
            }
        }
        int ap = 7 - Rrole[rnum].Aptitude / 15;
        int times = 0;
        // 如果可以练出武功则计算次数
        if (mnum > 0)
        {
            int p = 0;
            while (mlevel < 10)
            {
                int needexp = mlevel * Ritem[inum].NeedExp * ap;
                if (mlevel == 0)
                {
                    needexp = Ritem[inum].NeedExp * ap;
                }
                if (Rrole[rnum].ExpForBook >= needexp && mlevel < 10)
                {
                    Rrole[rnum].ExpForBook -= needexp;
                    instruct_33(rnum, mnum, 1);
                    mlevel++;
                    times++;
                }
                else
                {
                    break;
                }
                p++;
                if (p >= 10 || mlevel > 10)
                {
                    break;
                }
            }
            if (times > 0)
            {
                Redraw();
                EatOneItem(rnum, inum, times);
                WaitAnyKey();
            }
        }
        else
        {
            // 无武功的书：直接消耗经验吃
            int needexp_val = std::max(1, Ritem[inum].NeedExp * ap);
            times = Rrole[rnum].ExpForBook / needexp_val;
            if (times > 0)
            {
                Redraw();
                int actual = EatOneItem(rnum, inum, times);
                Rrole[rnum].ExpForBook -= Ritem[inum].NeedExp * ap * actual;
                WaitAnyKey();
            }
        }
        // 是否能够炼出物品
        if (Rrole[rnum].ExpForItem >= Ritem[inum].NeedExpForItem
            && Ritem[inum].NeedExpForItem > 0
            && Brole[i].Team == 0)
        {
            Redraw();
            int p2 = 0;
            for (int i2 = 0; i2 < 5; i2++)
            {
                if (Ritem[inum].GetItem[i2] >= 0)
                {
                    p2++;
                }
            }
            p2 = rand() % std::max(1, p2);
            int needitem = Ritem[inum].NeedMaterial;
            if (Ritem[inum].GetItem[p2] >= 0)
            {
                int needitemamount = Ritem[inum].NeedMatAmount[p2];
                int itemamount = 0;
                for (int i2 = 0; i2 < MAX_ITEM_AMOUNT; i2++)
                {
                    if (RItemList[i2].Number == needitem)
                    {
                        itemamount = RItemList[i2].Amount;
                        break;
                    }
                }
                if (needitemamount <= itemamount)
                {
                    ShowSimpleStatus(rnum, 350, 50);
                    DrawRectangle(screen, 115, 63, 145, 25, 0, ColColor(255), 50);
                    std::string str = "製藥成功";
                    DrawShadowText(screen, str, 147, 65, ColColor(0x23), ColColor(0x21));
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                    instruct_2(Ritem[inum].GetItem[p2], 1 + rand() % 5);
                    instruct_32(needitem, -needitemamount);
                    Rrole[rnum].ExpForItem = 0;
                    WaitAnyKey();
                }
            }
        }
    }
}

int CalRNum(int team)
{
    int cnt = 0;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == team && Brole[i].Dead == 0)
        {
            cnt++;
        }
    }
    return cnt;
}

void BattleMenuItem(int bnum)
{
    // Pascal: call MenuItem() UI, then handle CurItem for ItemType 3 (food) and ItemType 4 (hidden weapon)
    if (MenuItem())
    {
        int inum = CurItem;
        int rnum = Brole[bnum].rnum;
        int mode = Ritem[inum].ItemType;
        switch (mode)
        {
        case 3:
            EatOneItem(rnum, inum);
            instruct_32(inum, -1);
            Brole[bnum].Acted = 1;
            WaitAnyKey();
            break;
        case 4:
            UseHiddenWeapon(bnum, inum);
            break;
        }
    }
}

void PlayActionAmination(int bnum, int mode, int mnum)
{
    int rnum = Brole[bnum].rnum;

    // 方向至少朝向一个将被打中的敌人
    int Ax1 = Ax, Ay1 = Ay;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team != Brole[bnum].Team && Brole[i].Dead == 0 && BField[4][Brole[i].X][Brole[i].Y] > 0)
        {
            Ax1 = Brole[i].X;
            Ay1 = Brole[i].Y;
            break;
        }
    }
    int d1 = Ax1 - Bx, d2 = Ay1 - By;
    int dm = abs(d1) - abs(d2);
    if (d1 != 0 || d2 != 0)
    {
        if (dm >= 0)
        {
            if (d1 < 0)
            {
                Brole[bnum].Face = 0;
            }
            else
            {
                Brole[bnum].Face = 3;
            }
        }
        else
        {
            if (d2 < 0)
            {
                Brole[bnum].Face = 2;
            }
            else
            {
                Brole[bnum].Face = 1;
            }
        }
    }

    Redraw();
    if (Rrole[rnum].AmiFrameNum[mode] > 0)
    {
        int beginPic = 0;
        for (int i = 0; i < 5; i++)
        {
            if (i >= mode)
            {
                break;
            }
            beginPic += Rrole[rnum].AmiFrameNum[i] * 4;
        }
        beginPic += Brole[bnum].Face * Rrole[rnum].AmiFrameNum[mode];
        int endPic = beginPic + Rrole[rnum].AmiFrameNum[mode] - 1;
        if (beginPic < 0 || beginPic > endPic)
        {
            beginPic = 0;
            endPic = 0;
        }

        int spic = beginPic + Rrole[rnum].SoundDealy[mode] - 1;

        int p = beginPic;
        while (true)
        {
            CheckBasicEvent();
            DrawBFieldWithAction(bnum, p);
            if (p == spic && mnum >= 0)
            {
                PlaySoundA(Rmagic[mnum].SoundNum, 0);
            }
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            SDL_Delay(BATTLE_SPEED);
            p++;
            if (p > endPic)
            {
                Brole[bnum].Pic = endPic;
                break;
            }
        }
    }
}

void UsePoison(int bnum)
{
    int rnum = Brole[bnum].rnum;
    int poi = Rrole[rnum].UsePoi;
    int step = poi / 15 + 1;
    if (step > 15)
    {
        step = 15;
    }
    CalCanSelect(bnum, 1, step);
    bool select = false;
    if (Brole[bnum].Team == 0 && Brole[bnum].Auto == 0)
    {
        select = SelectAim(bnum, step);
    }
    else
    {
        // AI选择: 选防毒最低且未满毒的敌人
        int minDefPoi = 99;
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (Brole[i].Dead == 0 && Brole[i].Team != Brole[bnum].Team)
            {
                if (Rrole[Brole[i].rnum].DefPoi <= minDefPoi && Rrole[Brole[i].rnum].Poison < 99 && BField[3][Brole[i].X][Brole[i].Y] >= 0)
                {
                    minDefPoi = Rrole[Brole[i].rnum].DefPoi;
                    select = true;
                    Ax = Brole[i].X;
                    Ay = Brole[i].Y;
                }
            }
        }
    }
    if (BField[2][Ax][Ay] >= 0 && select)
    {
        Brole[bnum].Acted = 1;
        Rrole[rnum].PhyPower -= 3;
        int bnum1 = BField[2][Ax][Ay];
        if (Brole[bnum1].Team != Brole[bnum].Team)
        {
            int rnum1 = Brole[bnum1].rnum;
            int addpoi = Rrole[rnum].UsePoi / 3 - Rrole[rnum1].DefPoi / 4;
            if (addpoi < 0)
            {
                addpoi = 0;
            }
            if (addpoi + Rrole[rnum1].Poison > 99)
            {
                addpoi = 99 - Rrole[rnum1].Poison;
            }
            Rrole[rnum1].Poison += addpoi;
            Brole[bnum1].ShowNumber = addpoi;
            Brole[bnum1].ExpGot += addpoi;
            SetAminationPosition(0, 0);
            PlayActionAmination(bnum, 0);
            PlayMagicAmination(bnum, 30, 0, 2);
            ShowHurtValue(2);
        }
    }
}

void Medcine(int bnum)
{
    int rnum = Brole[bnum].rnum;
    int med = Rrole[rnum].Medcine;
    int step = med / 15 + 1;
    if (step > 15)
    {
        step = 15;
    }
    CalCanSelect(bnum, 1, step);
    bool select = false;
    if (Brole[bnum].Team == 0 && Brole[bnum].Auto == 0)
    {
        select = SelectAim(bnum, step);
    }
    else
    {
        if (BField[3][Ax][Ay] >= 0)
        {
            select = true;
        }
    }
    if (BField[2][Ax][Ay] >= 0 && select)
    {
        Brole[bnum].Acted = 1;
        Rrole[rnum].PhyPower -= 5;
        int bnum1 = BField[2][Ax][Ay];
        if (Brole[bnum1].Team == Brole[bnum].Team)
        {
            int rnum1 = Brole[bnum1].rnum;
            int addlife = EffectMedcine(rnum, rnum1);
            Brole[bnum1].ShowNumber = addlife;
            Brole[bnum1].ExpGot += addlife;
            SetAminationPosition(0, 0);
            PlayActionAmination(bnum, 0);
            PlayMagicAmination(bnum, 0, 1, 3);
            ShowHurtValue(3);
        }
    }
}

void MedPoison(int bnum)
{
    int rnum = Brole[bnum].rnum;
    int medpoi = Rrole[rnum].MedPoi;
    int step = medpoi / 15 + 1;
    if (step > 15)
    {
        step = 15;
    }
    CalCanSelect(bnum, 1, step);
    bool select = false;
    if (Brole[bnum].Team == 0 && Brole[bnum].Auto == 0)
    {
        select = SelectAim(bnum, step);
    }
    else
    {
        if (BField[3][Ax][Ay] >= 0)
        {
            select = true;
        }
    }
    if (BField[2][Ax][Ay] >= 0 && select)
    {
        Brole[bnum].Acted = 1;
        Rrole[rnum].PhyPower -= 5;
        int bnum1 = BField[2][Ax][Ay];
        if (Brole[bnum1].Team == Brole[bnum].Team)
        {
            int rnum1 = Brole[bnum1].rnum;
            int minuspoi = EffectMedPoison(rnum, rnum1);
            Brole[bnum1].ShowNumber = minuspoi;
            Brole[bnum1].ExpGot += minuspoi;
            SetAminationPosition(0, 0);
            PlayActionAmination(bnum, 0);
            PlayMagicAmination(bnum, 36, 1, 4);
            ShowHurtValue(4);
        }
    }
}

void UseHiddenWeapon(int bnum, int inum)
{
    int rnum = Brole[bnum].rnum;
    int step = Rrole[rnum].HidWeapon / 15 + 1;
    CalCanSelect(bnum, 1, step);
    if (SelectAim(bnum, step))
    {
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (Brole[i].Dead == 0 && Brole[i].X == Ax && Brole[i].Y == Ay && Brole[i].Team != Brole[bnum].Team)
            {
                int hurt = Ritem[inum].AddAttack + Rrole[Brole[bnum].rnum].Attack / 3;
                Rrole[Brole[i].rnum].CurrentHP -= hurt;
                if (Rrole[Brole[i].rnum].CurrentHP <= 0)
                {
                    Rrole[Brole[i].rnum].CurrentHP = 0;
                    Brole[i].Dead = 1;
                }
                Brole[i].ShowNumber = hurt;
            }
        }
        ShowHurtValue(0);
        instruct_32(inum, -1);
        Brole[bnum].Acted = 1;
    }
}

void Rest(int bnum)
{
    int rnum = Brole[bnum].rnum;
    Rrole[rnum].PhyPower += 5 + rand() % 5;
    if (Rrole[rnum].PhyPower > MAX_PHYSICAL_POWER)
    {
        Rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
    }
    Rrole[rnum].CurrentHP += Rrole[rnum].MaxHP / 15;
    if (Rrole[rnum].CurrentHP > Rrole[rnum].MaxHP)
    {
        Rrole[rnum].CurrentHP = Rrole[rnum].MaxHP;
    }
    Rrole[rnum].CurrentMP += Rrole[rnum].MaxMP / 15;
    if (Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP)
    {
        Rrole[rnum].CurrentMP = Rrole[rnum].MaxMP;
    }
    Brole[bnum].Acted = 1;
}

bool TeamModeMenu(int bnum)
{
    // Pascal: per-character auto mode selection
    int x = 160, y = 82, w = 160;
    std::string modestring[4] = { "手動", "全攻", "平衡", "混子" };
    std::string confirmStr = " 確認";

    // Collect alive team 0 members
    int amount = 0;
    std::vector<std::string> namestr;
    std::vector<int> a;    // brole indices
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == 0 && Brole[i].Dead == 0)
        {
            namestr.push_back(std::string(" ") + cp950toutf8(Rrole[Brole[i].rnum].Name));
            a.push_back(i);
            amount++;
        }
    }
    int h = amount * 22 + 28;

    // Save current modes in case of cancel
    std::vector<int> tempmode(BRoleAmount);
    for (int i = 0; i < BRoleAmount; i++)
    {
        tempmode[i] = Brole[i].AutoMode;
    }

    int menu = 0;

    auto ShowTeamModeMenu = [&]()
    {
        LoadFreshScreen(x, y, w + 1, h + 1);
        DrawRectangle(screen, x, y, w, h, 0, ColColor(255), 50);
        for (int i = 0; i < amount; i++)
        {
            if (i == menu)
            {
                DrawShadowText(namestr[i], x + 3, y + 3 + 22 * i, ColColor(0x64), ColColor(0x66));
                DrawShadowText(modestring[Brole[a[i]].AutoMode], x + 120 - 17, y + 3 + 22 * i, ColColor(0x64), ColColor(0x66));
            }
            else
            {
                DrawShadowText(namestr[i], x + 3, y + 3 + 22 * i, ColColor(0x21), ColColor(0x23));
                DrawShadowText(modestring[Brole[a[i]].AutoMode], x + 120 - 17, y + 3 + 22 * i, ColColor(0x21), ColColor(0x23));
            }
        }
        if (menu == -2)
        {
            DrawShadowText(confirmStr, x + 3, y + 3 + 22 * amount, ColColor(0x64), ColColor(0x66));
        }
        else
        {
            DrawShadowText(confirmStr, x + 3, y + 3 + 22 * amount, ColColor(0x21), ColColor(0x23));
        }
        UpdateScreen(screen, x, y, w + 1, h + 1);
    };

    bool result = true;
    RecordFreshScreen(0, 0, screen->w, screen->h);
    ShowTeamModeMenu();

    SDL_Event e;
    while (SDL_WaitEvent(&e))
    {
        CheckBasicEvent();
        if (e.type == SDL_EVENT_KEY_UP)
        {
            if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE)
            {
                break;
            }
            if (e.key.key == SDLK_ESCAPE)
            {
                result = false;
                break;
            }
            if (e.key.key == SDLK_UP)
            {
                menu--;
                if (menu == -1)
                {
                    menu = -2;
                }
                if (menu == -3)
                {
                    menu = amount - 1;
                }
                ShowTeamModeMenu();
            }
            if (e.key.key == SDLK_DOWN)
            {
                menu++;
                if (menu == amount)
                {
                    menu = -2;
                }
                if (menu == -1)
                {
                    menu = 0;
                }
                ShowTeamModeMenu();
            }
            if (e.key.key == SDLK_LEFT && menu >= 0 && menu < amount)
            {
                Brole[a[menu]].AutoMode--;
                if (Brole[a[menu]].AutoMode < 0)
                {
                    Brole[a[menu]].AutoMode = 3;
                }
                ShowTeamModeMenu();
            }
            if (e.key.key == SDLK_RIGHT && menu >= 0 && menu < amount)
            {
                Brole[a[menu]].AutoMode++;
                if (Brole[a[menu]].AutoMode > 3)
                {
                    Brole[a[menu]].AutoMode = 0;
                }
                ShowTeamModeMenu();
            }
        }
        else if (e.type == SDL_EVENT_MOUSE_BUTTON_UP)
        {
            if (e.button.button == SDL_BUTTON_LEFT)
            {
                int xm, ym;
                if (MouseInRegion(x, y, w, amount * 22 + 28, xm, ym))
                {
                    if (menu >= 0 && menu < amount)
                    {
                        Brole[a[menu]].AutoMode++;
                        if (Brole[a[menu]].AutoMode > 3)
                        {
                            Brole[a[menu]].AutoMode = 0;
                        }
                        ShowTeamModeMenu();
                    }
                    else if (menu == -2)
                    {
                        break;
                    }
                }
            }
            if (e.button.button == SDL_BUTTON_RIGHT)
            {
                result = false;
                break;
            }
        }
        else if (e.type == SDL_EVENT_MOUSE_MOTION)
        {
            int xm, ym;
            if (MouseInRegion(x, y, w, amount * 22 + 28, xm, ym))
            {
                int menup = menu;
                menu = (ym - y) / 22;
                if (menu < 0)
                {
                    menu = 0;
                }
                if (menu >= amount)
                {
                    menu = -2;
                }
                if (menup != menu)
                {
                    ShowTeamModeMenu();
                }
            }
        }
    }

    Redraw();
    if (!result)
    {
        for (int i = 0; i < BRoleAmount; i++)
        {
            Brole[i].AutoMode = tempmode[i];
        }
    }
    return result;
}

// ---- AI ----

void AutoBattle(int bnum)
{
    int rnum = Brole[bnum].rnum;
    // 简单AI: 找最近敌人，移动并攻击
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int bestTarget = -1, bestDist = 9999;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0)
        {
            int dist = abs(Brole[i].X - Brole[bnum].X) + abs(Brole[i].Y - Brole[bnum].Y);
            if (dist < bestDist)
            {
                bestDist = dist;
                bestTarget = i;
            }
        }
    }
    if (bestTarget < 0)
    {
        return;
    }

    // 移动
    CalCanSelect(bnum, 0, Brole[bnum].Step);
    int Mx1 = Brole[bnum].X, My1 = Brole[bnum].Y;
    NearestMove(Mx1, My1, bnum);
    Ax = Mx1;
    Ay = My1;
    MoveAmination(bnum);

    // 尝试攻击
    if (Rrole[rnum].PhyPower >= 10)
    {
        int bestMagic = -1, bestLevel = 0;
        for (int m = 0; m < 10; m++)
        {
            if (Rrole[rnum].Magic[m] > 0)
            {
                int mnum = Rrole[rnum].Magic[m];
                int level = std::min(10, Rrole[rnum].MagLevel[m] / 100 + 1);
                if (Rrole[rnum].CurrentMP >= Rmagic[mnum].NeedMP)
                {
                    if (bestMagic < 0)
                    {
                        bestMagic = mnum;
                        bestLevel = level;
                    }
                }
            }
        }
        if (bestMagic >= 0)
        {
            int step = Rmagic[bestMagic].MoveDistance[bestLevel - 1];
            int dist = abs(Brole[bestTarget].X - Brole[bnum].X) + abs(Brole[bestTarget].Y - Brole[bnum].Y);
            if (dist <= step)
            {
                Ax = Brole[bestTarget].X;
                Ay = Brole[bestTarget].Y;
                SetAminationPosition(Rmagic[bestMagic].AttAreaType, step, Rmagic[bestMagic].AttDistance[bestLevel - 1]);
                ShowMagicName(bestMagic);
                PlayActionAmination(bnum, Rmagic[bestMagic].MagicType, bestMagic);
                PlayMagicAmination(bnum, Rmagic[bestMagic].AmiNum);
                CalHurtRole(bnum, bestMagic, bestLevel);
                ShowHurtValue(Rmagic[bestMagic].HurtType);
            }
        }
    }
}

void AutoUseItem(int bnum, int list)
{
    // AI使用物品 - 简化
    BattleMenuItem(bnum);
}

void TryMoveAttack(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int bnum, int mnum, int level)
{
    int AreaType = Rmagic[mnum].AttAreaType;
    switch (AreaType)
    {
    case 0: CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
    case 1: calline(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
    case 2: calcross(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
    case 3: CalArea(Mx1, My1, Ax1, Ay1, tempmaxhurt, Brole[bnum].X, Brole[bnum].Y, bnum, mnum, level); break;
    }
}

void CalPoint(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level)
{
    int step = Rmagic[mnum].MoveDistance[level - 1];
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0)
        {
            int dist = abs(Brole[i].X - curX) + abs(Brole[i].Y - curY);
            if (dist <= step)
            {
                int hurt = CalHurtValue2(bnum, i, mnum, level);
                if (hurt > tempmaxhurt)
                {
                    tempmaxhurt = hurt;
                    Mx1 = curX;
                    My1 = curY;
                    Ax1 = Brole[i].X;
                    Ay1 = Brole[i].Y;
                }
            }
        }
    }
}

void calline(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level)
{
    CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
}

void calcross(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level)
{
    CalPoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
}

void CalArea(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level)
{
    int step = Rmagic[mnum].MoveDistance[level - 1];
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int totalHurt = 0;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0)
        {
            int dist = abs(Brole[i].X - curX) + abs(Brole[i].Y - curY);
            if (dist <= step)
            {
                totalHurt += CalHurtValue2(bnum, i, mnum, level);
            }
        }
    }
    if (totalHurt > tempmaxhurt)
    {
        tempmaxhurt = totalHurt;
        Mx1 = curX;
        My1 = curY;
        Ax1 = curX;
        Ay1 = curY;
    }
}

void NearestMove(int& Mx1, int& My1, int bnum)
{
    int targetTeam = (Brole[bnum].Team == 0) ? 1 : 0;
    int bestDist = 9999;
    int tx = -1, ty = -1;
    for (int i = 0; i < BRoleAmount; i++)
    {
        if (Brole[i].Team == targetTeam && Brole[i].Dead == 0)
        {
            int dist = abs(Brole[i].X - Brole[bnum].X) + abs(Brole[i].Y - Brole[bnum].Y);
            if (dist < bestDist)
            {
                bestDist = dist;
                tx = Brole[i].X;
                ty = Brole[i].Y;
            }
        }
    }
    if (tx < 0)
    {
        return;
    }
    // 在可移动范围内找最接近目标的位置
    int bestMDist = 9999;
    for (int i = 0; i < 64; i++)
    {
        for (int j = 0; j < 64; j++)
        {
            if (BField[3][i][j] >= 0 && (BField[2][i][j] == -1 || (i == Brole[bnum].X && j == Brole[bnum].Y)))
            {
                int dist = abs(i - tx) + abs(j - ty);
                if (dist < bestMDist)
                {
                    bestMDist = dist;
                    Mx1 = i;
                    My1 = j;
                }
            }
        }
    }
}

void NearestMoveByPro(int& Mx1, int& My1, int& Ax1, int& Ay1, int bnum, int TeamMate, int KeepDis, int Prolist, int MaxMinPro, int mode)
{
    NearestMove(Mx1, My1, bnum);
    Ax1 = Mx1;
    Ay1 = My1;
}
