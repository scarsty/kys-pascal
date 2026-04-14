// kys_draw.cpp - 高层绘图实现
// 对应 kys_draw.pas

#include "kys_draw.h"
#include "kys_engine.h"
#include "filefunc.h"
#include "kys_main.h"
#include "kys_type.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <vector>

// ---- 贴图绘制包装 ----

void DrawTitlePic(int num, int px, int py)
{
    // 主标题图使用 smp 贴图
    if (num < 0 || num >= SPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, TitleIdx.data(), TitlePic.data(),
        nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawMPic(int num, int px, int py)
{
    DrawMPic(num, px, py, 0, 0, 0, 0);
}

void DrawMPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    DrawMPic(num, px, py, shadow, alpha, mixColor, mixAlpha, 0);
}

void DrawMPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha, int totalpix)
{
    if (num < 0 || num >= MPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, MIdx.data(), MPic.data(),
        nullptr, nullptr, 0, 0, 0, shadow, alpha,
        nullptr, nullptr, 0, 0, 0, 4096, mixColor, mixAlpha, totalpix);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh)
{
    DrawSPic(num, px, py, xx, yy, xw, yh, 0, 0, 0, 0);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha)
{
    DrawSPic(num, px, py, xx, yy, xw, yh, shadow, alpha, 0, 0);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    if (num < 0 || num >= SPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
        nullptr, screen, screen->w, screen->h, screen->pitch,
        shadow, alpha, nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void DrawSPic(int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha)
{
    if (num < 0 || num >= SPicAmount)
    {
        return;
    }
    if (num == 1941)
    {
        num = 0;
        py -= 50;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
        nullptr, nullptr, 0, 0, 0, shadow, alpha,
        (char*)BlockImg.data(), (const char*)&BlockScreen,
        ImageWidth, ImageHeight, (int)sizeof(int16_t), depth, mixColor, mixAlpha);
}

void InitialSPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI,
    char* blockW, int widthW, int heightW, int depth, uint32_t mixColor, int mixAlpha)
{
    if (num < 0 || num >= SPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
        nullptr, img, widthI, heightI, (int)sizeof(int16_t),
        0, 0, blockW, nullptr, widthW, heightW, 0, depth, mixColor, mixAlpha);
}

// 带裁剪区域的InitialSPic - 匹配Pascal版 InitialSPic(num, px, py, x, y, w, h, needBlock, depth, temp)
void InitialSPic(int num, int px, int py, int areaX, int areaY, int areaW, int areaH,
    int needBlock, int depth, int temp)
{
    if (num < 0 || num >= SPicAmount)
    {
        return;
    }
    SDL_Surface* pImg = (temp == 0) ? ImgScene : ImgSceneBack;
    char* pBlock = (temp == 0) ? (char*)BlockImg.data() : (char*)BlockImg2.data();
    if (!pImg)
    {
        return;
    }
    if (areaX + areaW > ImageWidth)
    {
        areaW = ImageWidth - areaX - 1;
    }
    if (areaY + areaH > ImageHeight)
    {
        areaH = ImageHeight - areaY - 1;
    }
    SDL_Rect area = { areaX, areaY, areaW, areaH };
    if (num == 1941)
    {
        num = 0;
        py -= 50;
    }
    if (needBlock != 0)
    {
        DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
            (const char*)&area, pImg, ImageWidth, ImageHeight, (int)sizeof(int16_t),
            0, 0, pBlock, nullptr, 0, 0, 0, depth, 0, 0);
    }
    else
    {
        DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
            (const char*)&area, pImg, ImageWidth, ImageHeight, (int)sizeof(int16_t),
            0);
    }
}

void DrawHeadPic(int num, int px, int py)
{
    DrawHeadPic(num, px, py, 0, 0, 0, 0, 0);
}

void DrawHeadPic(int num, int px, int py, SDL_Surface* scr)
{
    if (num < 0 || !scr)
    {
        return;
    }
    std::string str = AppPath + "head/" + std::to_string(num) + ".png";
    if (filefunc::fileExist(str))
    {
        SDL_Surface* image = (num < (int)HeadSurface.size()) ? HeadSurface[num] : nullptr;
        if (!image)
        {
            image = LoadSurfaceFromFile(str);
            if (num < (int)HeadSurface.size())
            {
                HeadSurface[num] = image;
            }
        }
        if (image)
        {
            SDL_Rect dest = { px, py, image->w, image->h };
            SDL_BlitSurface(image, nullptr, scr, &dest);
        }
    }
    else
    {
        if (num >= 0 && num < HPicAmount && !HPic.empty())
        {
            int offset = (num > 0) ? HIdx[num - 1] : 0;
            int16_t ys = *(const int16_t*)(&HPic[offset + 6]);
            SDL_Rect area = { 0, 0, scr->w, scr->h };
            DrawRLE8Pic((const char*)ACol1, num, px, py + ys, HIdx.data(), HPic.data(),
                (const char*)&area, scr, scr->w, scr->h, 0, 0, 0,
                nullptr, nullptr, 0, 0, 0, 0, 0, 0);
        }
    }
}

void DrawHeadPic(int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha)
{
    if (num < 0)
    {
        return;
    }
    std::string str = AppPath + "head/" + std::to_string(num) + ".png";
    if (filefunc::fileExist(str))
    {
        SDL_Surface* image = (num < (int)HeadSurface.size()) ? HeadSurface[num] : nullptr;
        if (!image)
        {
            image = LoadSurfaceFromFile(str);
            if (num < (int)HeadSurface.size())
            {
                HeadSurface[num] = image;
            }
        }
        if (image)
        {
            SDL_Rect dest = { px, py - 60, image->w, image->h };
            SDL_BlitSurface(image, nullptr, screen, &dest);
        }
    }
    else
    {
        if (num >= 0 && num < HPicAmount && !HPic.empty())
        {
            DrawRLE8Pic((const char*)ACol1, num, px, py, HIdx.data(), HPic.data(),
                nullptr, nullptr, 0, 0, 0, shadow, alpha,
                nullptr, nullptr, 0, 0, 0, depth, mixColor, mixAlpha);
        }
    }
}

void DrawIPic(int num, int px, int py)
{
    DrawIPic(num, px, py, 0, 0, 0, 0);
}

void DrawIPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    if (num < 0)
    {
        return;
    }
    std::string str = AppPath + "item/" + std::to_string(num) + ".png";
    if (filefunc::fileExist(str))
    {
        SDL_Surface* image = (num < (int)ItemSurface.size()) ? ItemSurface[num] : nullptr;
        if (!image)
        {
            image = LoadSurfaceFromFile(str);
            if (num < (int)ItemSurface.size())
            {
                ItemSurface[num] = image;
            }
        }
        if (image)
        {
            SDL_Rect dest = { px, py, image->w, image->h };
            SDL_BlitSurface(image, nullptr, screen, &dest);
        }
    }
    else
    {
        DrawMPic(ITEM_BEGIN_PIC + num, px, py, shadow, alpha, mixColor, mixAlpha);
    }
}

void DrawBPic(int num, int px, int py, int shadow)
{
    DrawBPic(num, px, py, shadow, 0, 0, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha)
{
    DrawBPic(num, px, py, shadow, alpha, 0, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    DrawBPic(num, px, py, shadow, alpha, 0, mixColor, mixAlpha);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha)
{
    // 战斗图使用 WIdx/WPic (wdx/wmp), 严格按Pascal版
    if (num <= 0 || num >= BPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, WIdx.data(), WPic.data(),
        nullptr, nullptr, 0, 0, 0,
        shadow, alpha,
        (char*)BlockImg2.data(), (const char*)&BlockScreen,
        ImageWidth, ImageHeight, sizeof(int16_t),
        depth, mixColor, mixAlpha);
}

void InitialBPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI,
    char* blockW, int widthW, int heightW, int depth, uint32_t mixColor, int mixAlpha)
{
    if (num <= 0 || num >= BPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, WIdx.data(), WPic.data(),
        nullptr, img, widthI, heightI, (int)sizeof(int16_t),
        0, 0, blockW, nullptr, widthW, heightW, 0, depth, mixColor, mixAlpha);
}

void DrawEPic(int num, int px, int py)
{
    if (num < 0 || num >= EPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, EIdx.data(), EPic.data(),
        nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawEPic(int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha)
{
    if (num < 0 || num >= EPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, EIdx.data(), EPic.data(),
        nullptr, screen, screen->w, screen->h, screen->pitch,
        shadow, alpha,
        (char*)BlockImg2.data(), (const char*)&BlockScreen,
        ImageWidth, ImageHeight, sizeof(int16_t),
        depth, mixColor, mixAlpha);
}

void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha)
{
    DrawFPic(headnum, num, px, py, shadow, alpha, 0, 0, 0);
}

void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    DrawFPic(headnum, num, px, py, shadow, alpha, 0, mixColor, mixAlpha);
}

void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha)
{
    if (headnum < 0 || headnum >= 1000)
    {
        return;
    }
    if (FPic[headnum].empty())
    {
        return;
    }
    if (num < 0 || num >= (int)FIdx[headnum].size())
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, FIdx[headnum].data(), FPic[headnum].data(),
        nullptr, screen, screen->w, screen->h, screen->pitch,
        shadow, alpha,
        (char*)BlockImg2.data(), (const char*)&BlockScreen,
        ImageWidth, ImageHeight, sizeof(int16_t),
        depth, mixColor, mixAlpha);
}

void DrawCPic(int num, int px, int py, int shadow, int alpha)
{
    if (num < 0 || num >= CPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, CIdx.data(), CPic.data(),
        nullptr, nullptr, 0, 0, 0, shadow, alpha);
}

void DrawCPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha)
{
    if (num < 0 || num >= CPicAmount)
    {
        return;
    }
    DrawRLE8Pic((const char*)ACol, num, px, py, CIdx.data(), CPic.data(),
        nullptr, nullptr, 0, 0, 0, shadow, alpha,
        nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void GetPicSize(int num, const int* pidx, const uint8_t* ppic, int& w, int& h, int& xs, int& ys)
{
    w = 0;
    h = 0;
    xs = 0;
    ys = 0;
    if (!pidx || !ppic || num < 0)
    {
        return;
    }
    int offset = (num == 0) ? 0 : pidx[num - 1];
    const uint8_t* p = ppic + offset;
    w = *(int16_t*)(p);
    h = *(int16_t*)(p + 2);
    xs = *(int16_t*)(p + 4);
    ys = *(int16_t*)(p + 6);
}

// ---- 主绘制调度 ----

void Redraw()
{
    switch (Where)
    {
    case 0: DrawMMap(); break;
    case 1: DrawScene(); break;
    case 2: DrawBField(); break;
    case 3:
        SDL_FillSurfaceRect(screen, nullptr, 0xff000000);
        display_img("resource/open.png", OpenPicPosition.x, OpenPicPosition.y);
        DrawVirtualKey();
        break;
    case 4:
        SDL_FillSurfaceRect(screen, nullptr, 0xff000000);
        display_img("resource/dead.png", OpenPicPosition.x, OpenPicPosition.y);
        break;
    }
}

void RecordFreshScreen(int x, int y, int w, int h)
{
    if (!screen || !freshscreen)
    {
        return;
    }
    if (w == 0)
    {
        w = screen->w;
    }
    if (h == 0)
    {
        h = screen->h;
    }
    SDL_Rect r = { x, y, w, h };
    SDL_BlitSurface(screen, &r, freshscreen, &r);
}

void LoadFreshScreen(int x, int y, int w, int h)
{
    if (!screen || !freshscreen)
    {
        return;
    }
    if (w == 0)
    {
        w = screen->w;
    }
    if (h == 0)
    {
        h = screen->h;
    }
    SDL_Rect r = { x, y, w, h };
    SDL_BlitSurface(freshscreen, &r, screen, &r);
}

// ---- 大地图绘制 ----

void DrawMMap()
{
    if (!screen)
    {
        return;
    }
    SDL_FillSurfaceRect(screen, nullptr, 0);

    const int MAX_BUILD = 2001;
    TBuildInfo BuildArray[2001];
    int k = 0;
    int widthregion = CENTER_X / 36 + 3;
    int sumregion = CENTER_Y / 9 + 2;

    for (int sum = -sumregion; sum <= sumregion + 15; sum++)
    {
        for (int i = -widthregion; i <= widthregion; i++)
        {
            if (k >= MAX_BUILD)
            {
                break;
            }
            int i1 = Mx + i + (sum / 2);
            int i2 = My - i + (sum - sum / 2);
            TPosition pos = GetPositionOnScreen(i1, i2, Mx, My);

            if (i1 >= 0 && i1 < 480 && i2 >= 0 && i2 < 480)
            {
                if (BIG_PNG_TILE == 0)
                {
                    DrawMPic(Earth[i1][i2] / 2, pos.x, pos.y);
                    if (Surface[i1][i2] > 0)
                    {
                        DrawMPic(Surface[i1][i2] / 2, pos.x, pos.y);
                    }
                }

                int num = Building[i1][i2] / 2;
                // 在玩家位置替换为角色图
                if (i1 == Mx && i2 == My)
                {
                    if (InShip == 0)
                    {
                        if (MainMapStill == 0)
                        {
                            num = 2501 + MFace * 7 + MainMapStep;
                        }
                        else
                        {
                            num = 2528 + MFace * 6 + MainMapStep;
                        }
                    }
                    else
                    {
                        num = 3715 + MFace * 4 + (MainMapStep + 1) / 2;
                    }
                }

                if (num > 0 && num < MPicAmount)
                {
                    BuildArray[k].x = i1;
                    BuildArray[k].y = i2;
                    BuildArray[k].b = num;

                    // 按Pascal版计算排序深度
                    int16_t Width = *(int16_t*)(&MPic[MIdx[num - 1]]);
                    int16_t Height = *(int16_t*)(&MPic[MIdx[num - 1] + 2]);
                    int16_t xoffset = *(int16_t*)(&MPic[MIdx[num - 1] + 4]);
                    int16_t yoffset = *(int16_t*)(&MPic[MIdx[num - 1] + 6]);
                    BuildArray[k].c = ((i1 + i2) - (Width + 35) / 36 - (yoffset - Height + 1) / 9) * 1024 + i2;
                    if (i1 == Mx && i2 == My)
                    {
                        BuildArray[k].c = (i1 + i2) * 1024 + i2;
                    }
                    k++;
                }
            }
            else
            {
                DrawMPic(0, pos.x, pos.y);
            }
        }
    }

    QuickSortB(BuildArray, 0, k - 1);
    for (int i = 0; i < k; i++)
    {
        TPosition pos = GetPositionOnScreen(BuildArray[i].x, BuildArray[i].y, Mx, My);
        DrawMPic(BuildArray[i].b, pos.x, pos.y);
    }

    DrawClouds();
    DrawVirtualKey();
}

// ---- 场景绘制 ----

TPosition CalPosOnImage(int x, int y)
{
    TPosition p;
    p.x = -x * 18 + y * 18 + ImageWidth / 2;
    p.y = x * 9 + y * 9 + 9 + CENTER_Y;
    return p;
}

TPosition CalLTPosOnImageByCenter(int cx, int cy)
{
    TPosition p;
    p.x = -cx * 18 + cy * 18 + ImageWidth / 2 - CENTER_X;
    p.y = cx * 9 + cy * 9 + 9;
    return p;
}

void DrawScene()
{
    if (CurEvent < 0)
    {
        DrawSceneWithoutRole(Sx, Sy);
        SceneRolePic = BEGIN_WALKPIC + SFace * 7 + SStep;
        DrawRoleOnScene(Sx, Sy);
    }
    else
    {
        DrawSceneWithoutRole(Cx, Cy);
        if (DData[CurScene][CurEvent][10] == Sx && DData[CurScene][CurEvent][9] == Sy)
        {
            if (DData[CurScene][CurEvent][5] <= 0)
            {
                DrawRoleOnScene(Cx, Cy);
            }
        }
        else
        {
            DrawRoleOnScene(Cx, Cy);
        }
    }
    DrawVirtualKey();
}

void DrawSceneWithoutRole()
{
    DrawSceneWithoutRole(Sx, Sy);
}

void DrawSceneWithoutRole(int cx, int cy)
{
    if (!ImgScene)
    {
        return;
    }
    TPosition lt = CalLTPosOnImageByCenter(cx, cy);
    LoadScenePart(lt.x, lt.y);
}

void DrawRoleOnScene()
{
    DrawRoleOnScene(Sx, Sy);
}

void DrawRoleOnScene(int cx, int cy)
{
    TPosition pos = GetPositionOnScreen(Sx, Sy, cx, cy);
    int pic = SceneRolePic;
    if (pic <= 0)
    {
        pic = BEGIN_WALKPIC + SFace * 7 + SStep;
    }
    DrawSPic(pic, pos.x, pos.y - SData[CurScene][4][Sx][Sy], 0, 100, CalBlock(Sx, Sy), 0, 0);
}

void InitialScene()
{
    InitialScene(0);
}

void InitialScene(int onlyvisible)
{
    if (!ImgScene)
    {
        return;
    }

    SDL_LockMutex(mutex);
    LoadingScene = true;

    int x1 = 0, y1 = 0, w = ImageWidth, h = ImageHeight;

    if (onlyvisible == 0)
    {
        SDL_FillSurfaceRect(ImgScene, nullptr, 0xFF000000);
        if (ImgSceneBack)
        {
            SDL_FillSurfaceRect(ImgSceneBack, nullptr, 1);
        }
        ExpandGroundOnImg(ImgScene, ImageWidth, ImageHeight);
    }
    else
    {
        TPosition lt;
        if (CurEvent >= 0)
        {
            lt = CalLTPosOnImageByCenter(Cx, Cy);
        }
        else
        {
            lt = CalLTPosOnImageByCenter(Sx, Sy);
        }
        x1 = lt.x;
        y1 = lt.y;
        w = screen->w;
        h = screen->h;
    }

    int onback = (onlyvisible > 0 && Where == 1) ? 1 : 0;

    // 先绘制地面层（SData[4] <= 0）
    for (int i1 = 0; i1 < 64; i1++)
    {
        for (int i2 = 0; i2 < 64; i2++)
        {
            if (CurScene >= 0 && SData[CurScene][4][i1][i2] <= 0)
            {
                int num = SData[CurScene][0][i1][i2] / 2;
                if (num > 0)
                {
                    TPosition pos = CalPosOnImage(i1, i2);
                    InitialSPic(num, pos.x, pos.y, x1, y1, w, h, 1, 0, onback);
                }
            }
        }
    }

    // 按对角线顺序绘制建筑层（保证正确遮挡）
    for (int mini = 0; mini < 64; mini++)
    {
        InitialSceneOnePosition(mini, mini, x1, y1, w, h, CalBlock(mini, mini), onback);
        for (int maxi = mini + 1; maxi < 64; maxi++)
        {
            InitialSceneOnePosition(maxi, mini, x1, y1, w, h, CalBlock(maxi, mini), onback);
            InitialSceneOnePosition(mini, maxi, x1, y1, w, h, CalBlock(mini, maxi), onback);
        }
    }

    if (onlyvisible > 0 && Where == 1 && x1 >= 0 && y1 >= 0)
    {
        // 遮挡值仅更新主角附近的即可
        TPosition spos = CalPosOnImage(Sx, Sy);
        int bx = spos.x - 36;
        int by = spos.y - 100;
        for (int i1 = bx; i1 <= bx + 72; i1++)
        {
            if (i1 >= 0 && i1 < ImageWidth)
            {
                int num = i1 * ImageHeight + by;
                if (by >= 0 && num >= 0 && num + 200 <= (int)BlockImg.size())
                {
                    memcpy(&BlockImg[num], &BlockImg2[num], 200 * sizeof(int16_t));
                }
            }
        }
        // 将ImgSceneBack的可见区域拷贝到ImgScene
        if (ImgSceneBack)
        {
            SDL_Rect rect = { x1, y1, w, h };
            SDL_BlitSurface(ImgSceneBack, &rect, ImgScene, &rect);
        }
    }

    LoadingScene = false;
    SDL_UnlockMutex(mutex);
}

// 匹配Pascal版: InitialSceneOnePosition(i1, i2, x1, y1, w, h, depth, temp)
void InitialSceneOnePosition(int x, int y, int x1, int y1, int w, int h, int depth, int temp)
{
    if (CurScene < 0)
    {
        return;
    }
    TPosition pos = CalPosOnImage(x, y);

    // 地面层（当 SData[4] > 0 时也在此绘制）
    if (SData[CurScene][4][x][y] > 0)
    {
        int num = SData[CurScene][0][x][y] / 2;
        InitialSPic(num, pos.x, pos.y, x1, y1, w, h, 1, depth, temp);
    }

    // 建筑层1 (偏移 SData[4])
    if (SData[CurScene][1][x][y] > 0)
    {
        int num = SData[CurScene][1][x][y] / 2;
        InitialSPic(num, pos.x, pos.y - SData[CurScene][4][x][y], x1, y1, w, h, 1, depth, temp);
    }

    // 建筑层2 (偏移 SData[5])
    if (SData[CurScene][2][x][y] > 0)
    {
        int num = SData[CurScene][2][x][y] / 2;
        InitialSPic(num, pos.x, pos.y - SData[CurScene][5][x][y], x1, y1, w, h, 1, depth, temp);
    }

    // 事件图 (偏移 SData[4])
    if (SData[CurScene][3][x][y] >= 0)
    {
        int eventIdx = SData[CurScene][3][x][y];
        int num = DData[CurScene][eventIdx][5] / 2;
        if (num > 0)
        {
            if (SCENEAMI == 2)
            {
                InitialSPic(num, pos.x, pos.y - SData[CurScene][4][x][y], x1, y1, w, h, 1, depth, temp);
            }
        }
    }
}

int CalBlock(int x, int y)
{
    return 128 * (x + y) + y;
}

void ExpandGroundOnImg(SDL_Surface* img, int imgW, int imgH)
{
    // 扩展地面到 64x64 外避免黑边 - 简化实现
}

void UpdateScene()
{
    // 无参版 - 由定时器回调, 仿照Pascal调用 InitialScene(2)
    if (CurEvent < 0 && !LoadingScene && NeedRefreshScene != 0)
    {
        InitialScene(2);
    }
}

// 匹配Pascal版: UpdateScene(xs, ys) - 增量更新场景映像中指定位置附近的帧
void UpdateScene(int xs, int ys)
{
    int xp = -xs * 18 + ys * 18 + 1151;
    int yp = xs * 9 + ys * 9 + 250;
    int w, h;
    int num = 0;
    // 如在事件外，根据事件精灵尺寸确定更新区域
    if (CurEvent < 0)
    {
        num = DData[CurScene][SData[CurScene][3][xs][ys]][5] / 2;
        if (num > 0)
        {
            int offset = SIdx[num - 1];
            xp = xp - (SPic[offset + 4] + 256 * SPic[offset + 5]) - 3;
            yp = yp - (SPic[offset + 6] + 256 * SPic[offset + 7]) - 3 - SData[CurScene][4][xs][ys];
            w = (SPic[offset] + 256 * SPic[offset + 1]) + 20;
            h = (SPic[offset + 2] + 256 * SPic[offset + 3]) + 6;
        }
    }
    if (CurEvent >= 0 || num <= 0)
    {
        xp = xp - 30;
        yp = yp - 120;
        w = 100;
        h = 130;
    }
    int rangeOffset = std::max(h / 18, w / 36);
    for (int i1 = xs - rangeOffset; i1 <= xs + 5; i1++)
    {
        for (int i2 = ys - rangeOffset; i2 <= ys + 5; i2++)
        {
            int x = -i1 * 18 + i2 * 18 + 1151;
            int y = i1 * 9 + i2 * 9 + 9 + 250;
            InitialSPic(SData[CurScene][0][i1][i2] / 2, x, y, xp, yp, w, h);
            if (i1 < 0 || i2 < 0 || i1 > 63 || i2 > 63)
            {
                InitialSPic(0, x, y, xp, yp, w, h);
            }
            else
            {
                if (SData[CurScene][1][i1][i2] > 0)
                {
                    InitialSPic(SData[CurScene][1][i1][i2] / 2, x, y - SData[CurScene][4][i1][i2], xp, yp, w, h);
                }
                if (SData[CurScene][2][i1][i2] > 0)
                {
                    InitialSPic(SData[CurScene][2][i1][i2] / 2, x, y - SData[CurScene][5][i1][i2], xp, yp, w, h);
                }
                if (SData[CurScene][3][i1][i2] >= 0 && DData[CurScene][SData[CurScene][3][i1][i2]][5] > 0)
                {
                    InitialSPic(DData[CurScene][SData[CurScene][3][i1][i2]][5] / 2, x, y - SData[CurScene][4][i1][i2], xp, yp, w, h);
                }
            }
        }
    }
}

void LoadScenePart(int x1, int y1)
{
    if (!ImgScene || !screen)
    {
        return;
    }
    BlockScreen.x = x1;
    BlockScreen.y = y1;
    SDL_Rect src = { x1, y1, CENTER_X * 2, CENTER_Y * 2 };
    SDL_Rect dst = { 0, 0, CENTER_X * 2, CENTER_Y * 2 };
    SDL_BlitSurface(ImgScene, &src, screen, &dst);
}

// ---- 战场绘制 ----

// 严格按Pascal版: 遍历64x64地图, 按坐标顺序绘制角色以保证遮挡正确
void DrawBField(int needProgress)
{
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0)
            {
                DrawRoleOnBfield(i1, i2);
            }
        }
    }
    if (needProgress == 1)
    {
        DrawProgress();
    }
    DrawVirtualKey();
}

void DrawBfieldWithoutRole()
{
    if (!ImgBField)
    {
        return;
    }
    LoadBfieldPart(Bx, By);
}

// 严格按Pascal版: 按地图坐标(x,y)绘制角色, 包含depth遮挡
void DrawRoleOnBfield(int x, int y, uint32_t mixColor, int mixAlpha, int alpha_)
{
    if (BField[2][x][y] < 0)
    {
        return;
    }
    int roleIdx = BField[2][x][y];
    TPosition pos = GetPositionOnScreen(x, y, Bx, By);
    int depth = CalBlock(x, y);
    int rnum = Brole[roleIdx].rnum;
    int headnum = Rrole[rnum].HeadNum;
    if (WMP_4_PIC != 0)
    {
        int pic = BEGIN_BATTLE_ROLE_PIC + headnum * 4 + Brole[roleIdx].Face;
        DrawBPic(pic, pos.x, pos.y, 0, alpha_, depth, mixColor, mixAlpha);
    }
    else
    {
        int num = 0;
        for (int i = 0; i < 5; i++)
        {
            if (Rrole[rnum].AmiFrameNum[i] > 0)
            {
                num = Brole[roleIdx].Face * Rrole[rnum].AmiFrameNum[i];
                break;
            }
        }
        DrawFPic(headnum, num, pos.x, pos.y, 0, alpha_, depth, mixColor, mixAlpha);
    }
}

void InitialBFieldImage()
{
    if (!ImgBField)
    {
        return;
    }
    SDL_FillSurfaceRect(ImgBField, nullptr, 0);
    if (ImgBBuild)
    {
        SDL_FillSurfaceRect(ImgBBuild, nullptr, SDL_MapSurfaceRGBA(ImgBBuild, 0, 0, 0, 1));
    }
    if (!BlockImg2.empty())
    {
        memset(BlockImg2.data(), 0, BlockImg2.size() * sizeof(int16_t));
    }

    // Pascal: diagonal order for sumi=0..126, i1=63 downto 0, i2=sumi-i1
    for (int sumi = 0; sumi <= 126; sumi++)
    {
        for (int i1 = 63; i1 >= 0; i1--)
        {
            int i2 = sumi - i1;
            if (i2 >= 0 && i2 <= 63)
            {
                InitialBFieldPosition(i1, i2);
            }
        }
    }
}

void InitialBFieldPosition(int x, int y)
{
    TPosition pos = CalPosOnImage(x, y);
    int groundPic = BField[0][x][y] / 2;
    if (groundPic > 0)
    {
        InitialBPic(groundPic, pos.x, pos.y, ImgBField, ImageWidth, ImageHeight, nullptr, 0, 0, 0);
    }

    int buildPic = BField[1][x][y] / 2;
    if (buildPic > 0)
    {
        int depth = x + y;
        // Pascal: buildings go to ImgBBuild (needBlock=1)
        InitialBPic(buildPic, pos.x, pos.y, ImgBBuild, ImageWidth, ImageHeight,
            (char*)BlockImg2.data(), ImageWidth, ImageHeight, depth);
    }
}

void LoadBfieldPart(int cx, int cy, int noBuild)
{
    if (!ImgBField || !screen)
    {
        return;
    }
    TPosition lt = CalLTPosOnImageByCenter(cx, cy);
    BlockScreen.x = lt.x;
    BlockScreen.y = lt.y;
    SDL_Rect src = { lt.x, lt.y, CENTER_X * 2, CENTER_Y * 2 };
    SDL_Rect dst = { 0, 0, CENTER_X * 2, CENTER_Y * 2 };
    SDL_BlitSurface(ImgBField, &src, screen, &dst);
    if (noBuild == 0)
    {
        LoadBFieldPart2(lt.x, lt.y, 0);
    }
}

void LoadBFieldPart2(int x, int y, int alpha)
{
    if (!ImgBBuild || !screen)
    {
        return;
    }
    SDL_Rect src = { x, y, CENTER_X * 2, CENTER_Y * 2 };
    SDL_Rect dst = { 0, 0, CENTER_X * 2, CENTER_Y * 2 };
    SDL_SetSurfaceAlphaMod(ImgBBuild, 255 - alpha * 255 / 100);
    SDL_BlitSurface(ImgBBuild, &src, screen, &dst);
}

void DrawBFieldWithCursor(int step)
{
    // Pascal: LoadBfieldPart(x, y, 1) — ground only, no buildings
    TPosition lt = CalLTPosOnImageByCenter(Bx, By);
    int x = lt.x, y = lt.y;
    // Blit ground without building layer
    if (ImgBField && screen)
    {
        BlockScreen.x = x;
        BlockScreen.y = y;
        SDL_Rect src = { x, y, CENTER_X * 2, CENTER_Y * 2 };
        SDL_Rect dst = { 0, 0, CENTER_X * 2, CENTER_Y * 2 };
        SDL_BlitSurface(ImgBField, &src, screen, &dst);
    }
    // Dim the entire screen
    TransBlackScreen();
    // Draw ground tiles: BField[4]>0 gets shadow=1 (highlight), BField[3]>=0 in step range gets shadow=0
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            if (BField[0][i1][i2] > 0)
            {
                TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
                if (BField[4][i1][i2] > 0)
                {
                    DrawBPic(BField[0][i1][i2] / 2, pos.x, pos.y, 1);
                }
                else if (BField[3][i1][i2] >= 0 && abs(i1 - Bx) + abs(i2 - By) <= step)
                {
                    DrawBPic(BField[0][i1][i2] / 2, pos.x, pos.y, 0);
                }
            }
        }
    }
    // Overlay building layer with alpha
    LoadBFieldPart2(x, y, 35);
    // Draw roles with highlight for enemies in BField[4] area
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            int bnum2 = BField[2][i1][i2];
            if (bnum2 >= 0 && Brole[bnum2].Dead == 0)
            {
                uint32_t mixcolor = 0;
                int mixalpha = 0;
                if (Brole[bnum2].Team != Brole[BField[2][Bx][By]].Team && BField[4][i1][i2] > 0)
                {
                    mixcolor = 0xFFFFFFFF;
                    mixalpha = 20;
                }
                TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
                int depth = CalBlock(i1, i2);
                int rnum = Brole[bnum2].rnum;
                int headnum = Rrole[rnum].HeadNum;
                if (WMP_4_PIC != 0)
                {
                    DrawBPic(headnum * 4 + Brole[bnum2].Face + BEGIN_BATTLE_ROLE_PIC,
                        pos.x, pos.y, 0, 75, depth, mixcolor, mixalpha);
                }
                else
                {
                    int num = 0;
                    for (int i = 0; i < 5; i++)
                    {
                        if (Rrole[rnum].AmiFrameNum[i] > 0)
                        {
                            num = Brole[bnum2].Face * Rrole[rnum].AmiFrameNum[i];
                            break;
                        }
                    }
                    DrawFPic(headnum, num, pos.x, pos.y, 0, 75, depth, mixcolor, mixalpha);
                }
            }
        }
    }
    DrawProgress();
    DrawVirtualKey();
}

// Pascal overload 1: 简单效果 DrawBFieldWithEft(Epicnum)
void DrawBFieldWithEft(int Epicnum)
{
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
            if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0)
            {
                DrawRoleOnBfield(i1, i2);
            }
            if (BField[4][i1][i2] > 0)
            {
                DrawEPic(Epicnum, pos.x, pos.y, 0, 25, 0, 0, 0);
            }
        }
    }
    DrawProgress();
}

// Pascal overload 2: 带帧范围 DrawBFieldWithEft(Epicnum, beginpic, endpic, bnum, mixColor)
void DrawBFieldWithEft(int Epicnum, int beginpic, int endpic, int bnum, uint32_t mixColor)
{
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
            if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0)
            {
                DrawRoleOnBfield(i1, i2, 0, 50);
            }
            if (BField[4][i1][i2] > 0)
            {
                int eft = Epicnum - BField[4][i1][i2] + 1;
                if (eft >= beginpic && eft <= endpic)
                {
                    DrawEPic(eft, pos.x, pos.y, 0, 25, 0, 0, 0);
                }
            }
        }
    }
    DrawProgress();
}

// Pascal overload 3: 完整效果 DrawBFieldWithEft(Epicnum, beginpic, endpic, curlevel, bnum, forteam, flash, mixColor)
void DrawBFieldWithEft(int Epicnum, int beginpic, int endpic, int curlevel, int bnum, int forteam, int flash, uint32_t mixColor)
{
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
            int k = BField[2][i1][i2];
            if (k >= 0 && Brole[k].Dead == 0)
            {
                int curflash = 0;
                if (BField[4][Brole[k].X][Brole[k].Y] > 0)
                {
                    if (forteam == 0)
                    {
                        if (Brole[bnum].Team != Brole[k].Team)
                        {
                            curflash = 1;
                        }
                    }
                    else
                    {
                        if (Brole[bnum].Team == Brole[k].Team)
                        {
                            curflash = 1;
                        }
                    }
                }
                // 行动人物保持最后一帧
                if (bnum == k && Brole[bnum].Pic > 0)
                {
                    DrawFPic(Rrole[Brole[bnum].rnum].HeadNum, Brole[bnum].Pic, pos.x, pos.y, 0, 75, CalBlock(i1, i2), mixColor, curflash * (10 + rand() % 40));
                }
                else
                {
                    DrawRoleOnBfield(i1, i2, mixColor, curflash * (10 + rand() % 40));
                }
            }
            if (BField[4][i1][i2] > 0)
            {
                int eft = Epicnum + curlevel - BField[4][i1][i2];
                if (eft >= beginpic && eft <= endpic)
                {
                    DrawEPic(eft, pos.x, pos.y, 0, 25, CalBlock(i1, i2), 0, 0);
                }
            }
        }
    }
    DrawProgress();
}

// 画带人物动作的战场
void DrawBFieldWithAction(int bnum, int Apicnum)
{
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
    {
        for (int i2 = 0; i2 <= 63; i2++)
        {
            if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0 && BField[2][i1][i2] != bnum)
            {
                DrawRoleOnBfield(i1, i2);
            }
            if (BField[2][i1][i2] == bnum)
            {
                TPosition pos = GetPositionOnScreen(i1, i2, Bx, By);
                DrawFPic(Rrole[Brole[bnum].rnum].HeadNum, Apicnum, pos.x, pos.y, 0, 75, CalBlock(i1, i2), 0, 0);
            }
        }
    }
    DrawProgress();
}

// ---- 云、进度条、虚拟按键 ----

void DrawClouds()
{
    for (int i = 0; i < CLOUD_AMOUNT && i < (int)Cloud.size(); i++)
    {
        if (Cloud[i].Picnum >= 0 && Cloud[i].Picnum < CPicAmount)
        {
            int x = Cloud[i].Positionx - (-Mx * 18 + My * 18 + 8640 - CENTER_X);
            int y = Cloud[i].Positiony - (Mx * 9 + My * 9 + 9 - CENTER_Y);
            DrawCPic(Cloud[i].Picnum, x, y, Cloud[i].Shadow, Cloud[i].Alpha,
                Cloud[i].mixColor, Cloud[i].mixAlpha);
        }
    }
}

void DrawProgress()
{
    // 绘制半即时制进度条 - 匹配Pascal版
    if (SEMIREAL != 1)
    {
        return;
    }
    int x = 50;
    int y = CENTER_Y * 2 - 80;
    DrawRectangleWithoutFrame(screen, 0, CENTER_Y * 2 - 50, CENTER_X * 2, 50, 0, 50);
    if ((int)BHead.size() == BRoleAmount && BRoleAmount > 0)
    {
        std::vector<int> range(BRoleAmount), p(BRoleAmount);
        for (int i = 0; i < BRoleAmount; i++)
        {
            range[i] = i;
            p[i] = Brole[i].RealProgress * 500 / 10000;
        }
        // 冒泡排序: 按进度从高到低
        for (int i = 0; i < BRoleAmount - 1; i++)
        {
            for (int j = i + 1; j < BRoleAmount; j++)
            {
                if (p[i] <= p[j])
                {
                    std::swap(p[i], p[j]);
                    std::swap(range[i], range[j]);
                }
            }
        }
        for (int i = 0; i < BRoleAmount; i++)
        {
            if (Brole[range[i]].Dead == 0)
            {
                SDL_Rect dest = { p[i] + x, y, 0, 0 };
                int bhead = Brole[range[i]].BHead;
                if (bhead >= 0 && bhead < (int)BHead.size() && BHead[bhead])
                {
                    SDL_BlitSurface(BHead[bhead], nullptr, screen, &dest);
                }
            }
        }
    }
}

void DrawVirtualKey()
{
    if (ShowVirtualKey == 0 || !render)
    {
        return;
    }

    if (!screen || screen->w <= 0 || screen->h <= 0)
    {
        return;
    }

    auto drawOverlay = [&](SDL_Surface* surf, int x, int y, int alpha)
        {
            if (!surf)
            {
                return;
            }
            SDL_Texture* tex = SDL_CreateTextureFromSurface(render, surf);
            if (!tex)
            {
                return;
            }
            SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
            SDL_SetTextureAlphaMod(tex, (uint8_t)std::clamp(alpha, 0, 255));
            SDL_FRect dst;
            dst.x = (float)x;
            dst.y = (float)y;
            dst.w = (float)surf->w;
            dst.h = (float)surf->h;
            SDL_RenderTexture(render, tex, nullptr, &dst);
            SDL_DestroyTexture(tex);
        };

    int u = 128, d = 128, l = 128, r = 128;
    switch (VirtualKeyValue)
    {
    case SDLK_UP: u = 0; break;
    case SDLK_LEFT: l = 0; break;
    case SDLK_DOWN: d = 0; break;
    case SDLK_RIGHT: r = 0; break;
    }

    drawOverlay(VirtualKeyU, VirtualCrossX, VirtualCrossY, 255 - u);
    drawOverlay(VirtualKeyL, VirtualCrossX - VirtualKeySize, VirtualCrossY + VirtualKeySize, 255 - l);
    drawOverlay(VirtualKeyD, VirtualCrossX, VirtualCrossY + VirtualKeySize * 2, 255 - d);
    drawOverlay(VirtualKeyR, VirtualCrossX + VirtualKeySize, VirtualCrossY + VirtualKeySize, 255 - r);
    drawOverlay(VirtualKeyA, VirtualAX, VirtualAY, 128);
    drawOverlay(VirtualKeyB, VirtualBX, VirtualBY, 128);
}
