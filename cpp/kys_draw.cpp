// kys_draw.cpp - 高层绘图实现
// 对应 kys_draw.pas

#include "kys_draw.h"
#include "kys_engine.h"
#include "kys_main.h"
#include "kys_type.h"

#include <cstring>
#include <cstdio>
#include <algorithm>
#include <vector>

// ---- 贴图绘制包装 ----

void DrawTitlePic(int num, int px, int py) {
    // 主标题图使用 smp 贴图
    if (num < 0 || num >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, TitleIdx.data(), TitlePic.data(),
                nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawMPic(int num, int px, int py) {
    DrawMPic(num, px, py, 0, 0, 0, 0);
}

void DrawMPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    if (num < 0 || num >= MPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, MIdx.data(), MPic.data(),
                nullptr, nullptr, 0, 0, 0, shadow, alpha,
                nullptr, nullptr, 0, 0, 0, 4096, mixColor, mixAlpha);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh) {
    DrawSPic(num, px, py, xx, yy, xw, yh, 0, 0, 0, 0);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha) {
    DrawSPic(num, px, py, xx, yy, xw, yh, shadow, alpha, 0, 0);
}

void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    if (num < 0 || num >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
                nullptr, screen, screen->w, screen->h, screen->pitch,
                shadow, alpha, nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void InitialSPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI,
                  char* blockW, int widthW, int heightW, int depth, uint32_t mixColor, int mixAlpha) {
    if (num < 0 || num >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
                nullptr, img, widthI, heightI, img ? img->pitch : 0,
                0, 0, blockW, nullptr, widthW, heightW, 0, depth, mixColor, mixAlpha);
}

void DrawHeadPic(int num, int px, int py) {
    if (num < 0 || (int)HPic.size() == 0) return;
    int idx = num * 4; // 4帧头像
    if (idx >= HPicAmount) idx = 0;
    DrawRLE8Pic((const char*)ACol, idx, px, py, HIdx.data(), HPic.data(),
                nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawHeadPic(int num, int px, int py, SDL_Surface* scr) {
    // 在指定表面上绘制头像（当前实现等同于默认screen）
    DrawHeadPic(num, px, py);
}

void DrawIPic(int num, int px, int py) {
    DrawIPic(num, px, py, 0, 0, 0, 0);
}

void DrawIPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    int pic = ITEM_BEGIN_PIC + num;
    if (pic < 0 || pic >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, pic, px, py, SIdx.data(), SPic.data(),
                nullptr, screen, screen->w, screen->h, screen->pitch,
                shadow, alpha, nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void DrawBPic(int num, int px, int py, int shadow) {
    DrawBPic(num, px, py, shadow, 0, 0, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha) {
    DrawBPic(num, px, py, shadow, alpha, 0, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    DrawBPic(num, px, py, shadow, alpha, 0, mixColor, mixAlpha);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha, int depth, uint32_t mixColor, int mixAlpha) {
    // 战斗图使用 WIdx/WPic (wdx/wmp), 严格按Pascal版
    if (num <= 0 || num >= BPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, WIdx.data(), WPic.data(),
                nullptr, nullptr, 0, 0, 0,
                shadow, alpha,
                (char*)BlockImg2.data(), (const char*)&BlockScreen,
                ImageWidth, ImageHeight, sizeof(int16_t),
                depth, mixColor, mixAlpha);
}

void InitialBPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI,
                  char* blockW, int widthW, int heightW, int depth, uint32_t mixColor, int mixAlpha) {
    if (num <= 0 || num >= BPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, WIdx.data(), WPic.data(),
                nullptr, img, widthI, heightI, img ? img->pitch : 0,
                0, 0, blockW, nullptr, widthW, heightW, 0, depth, mixColor, mixAlpha);
}

void DrawEPic(int num, int px, int py) {
    if (num < 0 || num >= EPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, EIdx.data(), EPic.data(),
                nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha) {
    DrawFPic(headnum, num, px, py, shadow, alpha, 0, 0);
}

void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    if (headnum < 0 || headnum >= 1000) return;
    if (FPic[headnum].empty()) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, FIdx[headnum].data(), FPic[headnum].data(),
                nullptr, screen, screen->w, screen->h, screen->pitch,
                shadow, alpha, nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void DrawCPic(int num, int px, int py, int shadow, int alpha) {
    if (num < 0 || num >= CPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, CIdx.data(), CPic.data(),
                nullptr, nullptr, 0, 0, 0, shadow, alpha);
}

void DrawCPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    if (num < 0 || num >= CPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, CIdx.data(), CPic.data(),
                nullptr, nullptr, 0, 0, 0, shadow, alpha,
                nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void GetPicSize(int num, const int* pidx, const uint8_t* ppic, int& w, int& h, int& xs, int& ys) {
    w = 0; h = 0; xs = 0; ys = 0;
    if (!pidx || !ppic || num < 0) return;
    int offset = (num == 0) ? 0 : pidx[num - 1];
    const uint8_t* p = ppic + offset;
    w = *(int16_t*)(p);
    h = *(int16_t*)(p + 2);
    xs = *(int16_t*)(p + 4);
    ys = *(int16_t*)(p + 6);
}

// ---- 主绘制调度 ----

void Redraw() {
    switch (Where) {
        case 0: DrawMMap(); break;
        case 1: DrawScene(); break;
        case 2: DrawBField(); break;
        case 3: display_img("resource/open.png", 0, 0); break;
        case 4: display_img("resource/end.png", 0, 0); break;
    }
}

void RecordFreshScreen(int x, int y, int w, int h) {
    if (!screen || !freshscreen) return;
    if (w == 0) w = screen->w;
    if (h == 0) h = screen->h;
    SDL_Rect r = {x, y, w, h};
    SDL_BlitSurface(screen, &r, freshscreen, &r);
}

void LoadFreshScreen(int x, int y, int w, int h) {
    if (!screen || !freshscreen) return;
    if (w == 0) w = screen->w;
    if (h == 0) h = screen->h;
    SDL_Rect r = {x, y, w, h};
    SDL_BlitSurface(freshscreen, &r, screen, &r);
}

// ---- 大地图绘制 ----

void DrawMMap() {
    if (!screen) return;
    SDL_FillSurfaceRect(screen, nullptr, 0);

    const int MAX_BUILD = 2001;
    TBuildInfo BuildArray[2001];
    int k = 0;
    int widthregion = CENTER_X / 36 + 3;
    int sumregion = CENTER_Y / 9 + 2;

    for (int sum = -sumregion; sum <= sumregion + 15; sum++) {
        for (int i = -widthregion; i <= widthregion; i++) {
            if (k >= MAX_BUILD) break;
            int i1 = Mx + i + (sum / 2);
            int i2 = My - i + (sum - sum / 2);
            TPosition pos = GetPositionOnScreen(i1, i2, Mx, My);

            if (i1 >= 0 && i1 < 480 && i2 >= 0 && i2 < 480) {
                if (BIG_PNG_TILE == 0) {
                    DrawMPic(Earth[i1][i2] / 2, pos.x, pos.y);
                    if (Surface[i1][i2] > 0)
                        DrawMPic(Surface[i1][i2] / 2, pos.x, pos.y);
                }

                int num = Building[i1][i2] / 2;
                // 在玩家位置替换为角色图
                if (i1 == Mx && i2 == My) {
                    if (InShip == 0) {
                        if (MainMapStill == 0)
                            num = 2501 + MFace * 7 + MainMapStep;
                        else
                            num = 2528 + MFace * 6 + MainMapStep;
                    } else {
                        num = 3715 + MFace * 4 + (MainMapStep + 1) / 2;
                    }
                }

                if (num > 0 && num < MPicAmount) {
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
                        BuildArray[k].c = (i1 + i2) * 1024 + i2;
                    k++;
                }
            } else {
                DrawMPic(0, pos.x, pos.y);
            }
        }
    }

    QuickSortB(BuildArray, 0, k - 1);
    for (int i = 0; i < k; i++) {
        TPosition pos = GetPositionOnScreen(BuildArray[i].x, BuildArray[i].y, Mx, My);
        DrawMPic(BuildArray[i].b, pos.x, pos.y);
    }

    DrawClouds();
    DrawVirtualKey();
}

// ---- 场景绘制 ----

TPosition CalPosOnImage(int x, int y) {
    TPosition p;
    p.x = -x * 18 + y * 18 + ImageWidth / 2;
    p.y = x * 9 + y * 9 + 9 + CENTER_Y;
    return p;
}

TPosition CalLTPosOnImageByCenter(int cx, int cy) {
    TPosition p;
    p.x = -cx * 18 + cy * 18 + ImageWidth / 2 - CENTER_X;
    p.y = cx * 9 + cy * 9 + 9;
    return p;
}

void DrawScene() {
    if (CurEvent < 0) {
        DrawSceneWithoutRole(Sx, Sy);
        SceneRolePic = BEGIN_WALKPIC + SFace * 7 + SStep;
        DrawRoleOnScene(Sx, Sy);
    } else {
        DrawSceneWithoutRole(Cx, Cy);
        if (DData[CurScene][CurEvent][10] == Sx && DData[CurScene][CurEvent][9] == Sy) {
            if (DData[CurScene][CurEvent][5] <= 0) {
                DrawRoleOnScene(Cx, Cy);
            }
        } else {
            DrawRoleOnScene(Cx, Cy);
        }
    }
    DrawVirtualKey();
}

void DrawSceneWithoutRole() {
    DrawSceneWithoutRole(Sx, Sy);
}

void DrawSceneWithoutRole(int cx, int cy) {
    if (!ImgScene) return;
    TPosition lt = CalLTPosOnImageByCenter(cx, cy);
    LoadScenePart(lt.x, lt.y);
}

void DrawRoleOnScene() {
    DrawRoleOnScene(Sx, Sy);
}

void DrawRoleOnScene(int cx, int cy) {
    // 角色始终渲染在屏幕中央
    TPosition pos = GetPositionOnScreen(0, 0, CENTER_X, CENTER_Y);
    int pic = SceneRolePic;
    if (pic <= 0) pic = BEGIN_WALKPIC + SFace * 7 + SStep;
    DrawSPic(pic, pos.x, pos.y, 0, 0, screen->w, screen->h);
}

void InitialScene() {
    InitialScene(0);
}

void InitialScene(int onlyvisible) {
    if (!ImgScene) return;

    SDL_LockMutex(mutex);
    LoadingScene = true;

    int x1 = 0, y1 = 0, w = ImageWidth, h = ImageHeight;

    if (onlyvisible == 0) {
        SDL_FillSurfaceRect(ImgScene, nullptr, 0xFF000000);
        SDL_FillSurfaceRect(ImgSceneBack, nullptr, 1);
        ExpandGroundOnImg(ImgScene, ImageWidth, ImageHeight);
    } else {
        TPosition lt;
        if (CurEvent >= 0) {
            lt = CalLTPosOnImageByCenter(Cx, Cy);
        } else {
            lt = CalLTPosOnImageByCenter(Sx, Sy);
        }
        x1 = lt.x;
        y1 = lt.y;
        w = screen->w;
        h = screen->h;
    }

    int onback = (onlyvisible > 0 && Where == 1) ? 1 : 0;

    // 先绘制地面层（SData[4] <= 0）
    for (int i1 = 0; i1 < 64; i1++) {
        for (int i2 = 0; i2 < 64; i2++) {
            if (CurScene >= 0 && SData[CurScene][4][i1][i2] <= 0) {
                int num = SData[CurScene][0][i1][i2] / 2;
                if (num > 0) {
                    TPosition pos = CalPosOnImage(i1, i2);
                    InitialSPic(num, pos.x, pos.y, ImgScene, ImageWidth, ImageHeight,
                                nullptr, 0, 0, 0);
                }
            }
        }
    }

    // 按对角线顺序绘制建筑层（保证正确遮挡）
    for (int mini = 0; mini < 64; mini++) {
        InitialSceneOnePosition(mini, mini, ImgScene, ImageWidth, ImageHeight,
                                (char*)BlockImg.data(), ImageWidth, ImageHeight);
        for (int maxi = mini + 1; maxi < 64; maxi++) {
            InitialSceneOnePosition(maxi, mini, ImgScene, ImageWidth, ImageHeight,
                                    (char*)BlockImg.data(), ImageWidth, ImageHeight);
            InitialSceneOnePosition(mini, maxi, ImgScene, ImageWidth, ImageHeight,
                                    (char*)BlockImg.data(), ImageWidth, ImageHeight);
        }
    }

    LoadingScene = false;
    SDL_UnlockMutex(mutex);
}

void InitialSceneOnePosition(int x, int y, SDL_Surface* img, int imgW, int imgH,
                               char* blockW, int blockWW, int blockWH) {
    if (CurScene < 0) return;
    TPosition pos = CalPosOnImage(x, y);
    int depth = CalBlock(x, y);

    // 地面层（当 SData[4] > 0 时也在此绘制）
    if (SData[CurScene][4][x][y] > 0) {
        int num = SData[CurScene][0][x][y] / 2;
        if (num > 0)
            InitialSPic(num, pos.x, pos.y, img, imgW, imgH, nullptr, 0, 0, depth);
    }

    // 建筑层1 (偏移 SData[4])
    if (SData[CurScene][1][x][y] > 0) {
        int num = SData[CurScene][1][x][y] / 2;
        InitialSPic(num, pos.x, pos.y - SData[CurScene][4][x][y], img, imgW, imgH,
                     blockW, blockWW, blockWH, depth);
    }

    // 建筑层2 (偏移 SData[5])
    if (SData[CurScene][2][x][y] > 0) {
        int num = SData[CurScene][2][x][y] / 2;
        InitialSPic(num, pos.x, pos.y - SData[CurScene][5][x][y], img, imgW, imgH,
                     blockW, blockWW, blockWH, depth);
    }

    // 事件图 (偏移 SData[4])
    if (SData[CurScene][3][x][y] >= 0) {
        int eventIdx = SData[CurScene][3][x][y];
        int num = DData[CurScene][eventIdx][5] / 2;
        if (num > 0) {
            if (SCENEAMI == 2)
                InitialSPic(num, pos.x, pos.y - SData[CurScene][4][x][y], img, imgW, imgH,
                             blockW, blockWW, blockWH, depth);
        }
    }
}

int CalBlock(int x, int y) {
    return x + y;
}

void ExpandGroundOnImg(SDL_Surface* img, int imgW, int imgH) {
    // 扩展地面到 64x64 外避免黑边 - 简化实现
}

void UpdateScene() {
    // 增量更新场景图 - 动画帧
}

void LoadScenePart(int x1, int y1) {
    if (!ImgScene || !screen) return;
    SDL_Rect src = {x1, y1, CENTER_X * 2, CENTER_Y * 2};
    SDL_Rect dst = {0, 0, CENTER_X * 2, CENTER_Y * 2};
    SDL_BlitSurface(ImgScene, &src, screen, &dst);
}

// ---- 战场绘制 ----

// 严格按Pascal版: 遍历64x64地图, 按坐标顺序绘制角色以保证遮挡正确
void DrawBField(int needProgress) {
    DrawBfieldWithoutRole();
    for (int i1 = 0; i1 <= 63; i1++)
        for (int i2 = 0; i2 <= 63; i2++)
            if (BField[2][i1][i2] >= 0 && Brole[BField[2][i1][i2]].Dead == 0)
                DrawRoleOnBfield(i1, i2);
    if (needProgress == 1) DrawProgress();
    DrawVirtualKey();
}

void DrawBfieldWithoutRole() {
    if (!ImgBField) return;
    LoadBfieldPart(Bx, By);
}

// 严格按Pascal版: 按地图坐标(x,y)绘制角色, 包含depth遮挡
void DrawRoleOnBfield(int x, int y, uint32_t mixColor, int mixAlpha, int alpha_) {
    if (BField[2][x][y] < 0) return;
    int roleIdx = BField[2][x][y];
    TPosition pos = GetPositionOnScreen(x, y, Bx, By);
    int depth = CalBlock(x, y);
    int rnum = Brole[roleIdx].rnum;
    int headnum = Rrole[rnum].HeadNum;
    // Pascal: HeadNum * 4 + Face + BEGIN_BATTLE_ROLE_PIC
    int pic = BEGIN_BATTLE_ROLE_PIC + headnum * 4 + Brole[roleIdx].Face;
    DrawBPic(pic, pos.x, pos.y, 0, alpha_, depth, mixColor, mixAlpha);
}

void InitialBFieldImage() {
    if (!ImgBField) return;
    SDL_FillSurfaceRect(ImgBField, nullptr, 0);
    if (!BlockImg2.empty())
        memset(BlockImg2.data(), 0, BlockImg2.size() * sizeof(int16_t));

    for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
            InitialBFieldPosition(x, y);
        }
    }
}

void InitialBFieldPosition(int x, int y) {
    TPosition pos = CalPosOnImage(x, y);
    int groundPic = BField[0][x][y] / 2;
    if (groundPic > 0)
        InitialBPic(groundPic, pos.x, pos.y, ImgBField, ImageWidth, ImageHeight, nullptr, 0, 0, 0);

    int buildPic = BField[1][x][y] / 2;
    if (buildPic > 0) {
        int depth = x + y;
        InitialBPic(buildPic, pos.x, pos.y, ImgBField, ImageWidth, ImageHeight,
                     (char*)BlockImg2.data(), ImageWidth, ImageHeight, depth);
    }
}

void LoadBfieldPart(int cx, int cy) {
    if (!ImgBField || !screen) return;
    TPosition lt = CalLTPosOnImageByCenter(cx, cy);
    SDL_Rect src = {lt.x, lt.y, CENTER_X * 2, CENTER_Y * 2};
    SDL_Rect dst = {0, 0, CENTER_X * 2, CENTER_Y * 2};
    SDL_BlitSurface(ImgBField, &src, screen, &dst);
}

void LoadBFieldPart2(int cx, int cy) {
    LoadBfieldPart(cx, cy);
}

void DrawBFieldWithCursor(int bnum) {
    DrawBField();
    // 绘制选择光标
    TPosition pos = GetPositionOnScreen(Ax - Bx, Ay - By, CENTER_X, CENTER_Y);
    DrawRectangle(screen, pos.x - 16, pos.y - 8, 36, 18, ColColor(0x50), ColColor(0xFF), 30);
}

void DrawBFieldWithEft(int bnum, int eftnum) {
    DrawBFieldWithEft(bnum, eftnum, 0, 0);
}

void DrawBFieldWithEft(int bnum, int eftnum, int frame) {
    DrawBFieldWithEft(bnum, eftnum, frame, 0);
}

void DrawBFieldWithEft(int bnum, int eftnum, int frame, int allframe) {
    DrawBField();
    // 绘制特效层
    for (int x = 0; x < 64; x++) {
        for (int y = 0; y < 64; y++) {
            if (BField[4][x][y] > 0) {
                TPosition pos = GetPositionOnScreen(x - Bx, y - By, CENTER_X, CENTER_Y);
                int eft = eftnum + frame;
                DrawEPic(eft, pos.x, pos.y);
            }
        }
    }
}

void DrawBFieldWithAction(int bnum, int actionnum) {
    DrawBField();
    // 绘制动作动画
    if (bnum < 0 || bnum >= BRoleAmount) return;
    int rnum = Brole[bnum].rnum;
    int headnum = Rrole[rnum].HeadNum;
    TPosition pos = GetPositionOnScreen(Brole[bnum].X - Bx, Brole[bnum].Y - By, CENTER_X, CENTER_Y);
    DrawFPic(headnum, actionnum, pos.x, pos.y, 0, 0);
}

// ---- 云、进度条、虚拟按键 ----

void DrawClouds() {
    for (int i = 0; i < CLOUD_AMOUNT && i < (int)Cloud.size(); i++) {
        if (Cloud[i].Picnum >= 0 && Cloud[i].Picnum < CPicAmount) {
            int x = Cloud[i].Positionx - (-Mx * 18 + My * 18 + 8640 - CENTER_X);
            int y = Cloud[i].Positiony - (Mx * 9 + My * 9 + 9 - CENTER_Y);
            DrawCPic(Cloud[i].Picnum, x, y, Cloud[i].Shadow, Cloud[i].Alpha,
                     Cloud[i].mixColor, Cloud[i].mixAlpha);
        }
    }
}

void DrawProgress() {
    // 绘制半即时制进度条
    int barX = 10, barY = screen->h - 30;
    int barW = screen->w - 20, barH = 20;
    DrawRectangle(screen, barX, barY, barW, barH, 0, ColColor(0xFF), 40);
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead) continue;
        int progress = Brole[i].RealProgress;
        int px = barX + progress * barW / 10000;
        int headnum = Rrole[Brole[i].rnum].HeadNum;
        DrawHeadPic(headnum, px - 15, barY - 40);
    }
}

void DrawVirtualKey() {
    // 绘制虚拟方向键 (手机用)
    if (ShowVirtualKey == 0) return;
    if (VirtualKeyU) { SDL_Rect dst = {VirtualCrossX, VirtualCrossY - 50, 50, 50}; SDL_BlitSurface(VirtualKeyU, nullptr, screen, &dst); }
    if (VirtualKeyD) { SDL_Rect dst = {VirtualCrossX, VirtualCrossY + 50, 50, 50}; SDL_BlitSurface(VirtualKeyD, nullptr, screen, &dst); }
    if (VirtualKeyL) { SDL_Rect dst = {VirtualCrossX - 50, VirtualCrossY, 50, 50}; SDL_BlitSurface(VirtualKeyL, nullptr, screen, &dst); }
    if (VirtualKeyR) { SDL_Rect dst = {VirtualCrossX + 50, VirtualCrossY, 50, 50}; SDL_BlitSurface(VirtualKeyR, nullptr, screen, &dst); }
    if (VirtualKeyA) { SDL_Rect dst = {VirtualAX, VirtualAY, 50, 50}; SDL_BlitSurface(VirtualKeyA, nullptr, screen, &dst); }
    if (VirtualKeyB) { SDL_Rect dst = {VirtualBX, VirtualBY, 50, 50}; SDL_BlitSurface(VirtualKeyB, nullptr, screen, &dst); }
}
