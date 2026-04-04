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
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
                nullptr, nullptr, 0, 0, 0, 0, 0);
}

void DrawMPic(int num, int px, int py) {
    if (num < 0 || num >= MPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, MIdx.data(), MPic.data(),
                nullptr, nullptr, 0, 0, 0, 0, 0);
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
    // 物品图使用 smp 偏移
    int pic = ITEM_BEGIN_PIC + num;
    DrawSPic(pic, px, py, 0, 0, screen->w, screen->h);
}

void DrawBPic(int num, int px, int py, int shadow) {
    DrawBPic(num, px, py, shadow, 0, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha) {
    DrawBPic(num, px, py, shadow, alpha, 0, 0);
}

void DrawBPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha) {
    // 战斗人物图使用 smp
    if (num < 0 || num >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
                nullptr, screen, screen->w, screen->h, screen->pitch,
                shadow, alpha, nullptr, nullptr, 0, 0, 0, 0, mixColor, mixAlpha);
}

void InitialBPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI,
                  char* blockW, int widthW, int heightW, int depth, uint32_t mixColor, int mixAlpha) {
    if (num < 0 || num >= SPicAmount) return;
    DrawRLE8Pic((const char*)ACol, num, px, py, SIdx.data(), SPic.data(),
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
        case 3: display_img("end.png", 0, 0); break;
        case 4: display_img("pic/fail.png", 0, 0); break;
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

    int cx = CENTER_X, cy = CENTER_Y;
    std::vector<TBuildInfo> buildArray;

    // 遍历可见区域
    for (int j = Mx - 16; j <= Mx + 16; j++) {
        for (int i = My - 16; i <= My + 16; i++) {
            int mx2 = j, my2 = i;
            if (mx2 < 0 || mx2 >= 480 || my2 < 0 || my2 >= 480) continue;

            TPosition pos = GetPositionOnScreen(mx2 - Mx, my2 - My, cx, cy);
            int px = pos.x, py = pos.y;

            // Earth层
            int earthPic = Earth[mx2][my2] / 2;
            if (earthPic > 0 && earthPic < MPicAmount)
                DrawMPic(earthPic, px, py);

            // Surface层
            int surfPic = Surface[mx2][my2] / 2;
            if (surfPic > 0 && surfPic < MPicAmount)
                DrawMPic(surfPic, px, py);

            // Building层 - 收集用于排序
            int buildPic = Building[mx2][my2] / 2;
            if (buildPic > 0) {
                TBuildInfo bi;
                bi.b = buildPic;
                bi.x = px;
                bi.y = py;
                bi.c = mx2 + my2;
                buildArray.push_back(bi);
            }
        }
    }

    // 按深度排序后绘制建筑
    if (!buildArray.empty()) {
        QuickSortB(buildArray.data(), 0, (int)buildArray.size() - 1);
        for (auto& b : buildArray) {
            if (b.b < MPicAmount)
                DrawMPic(b.b, b.x, b.y);
        }
    }

    DrawClouds();
    if (CellPhone) DrawVirtualKey();
}

// ---- 场景绘制 ----

TPosition CalPosOnImage(int x, int y) {
    int imgCX = ImageWidth / 2;
    int imgCY = 2 * 9;
    return GetPositionOnScreen(x, y, imgCX, imgCY);
}

TPosition CalLTPosOnImageByCenter(int cx, int cy) {
    TPosition p = CalPosOnImage(cx, cy);
    p.x -= CENTER_X;
    p.y -= CENTER_Y;
    return p;
}

void DrawScene() {
    DrawSceneWithoutRole();
    DrawRoleOnScene();
}

void DrawSceneWithoutRole() {
    if (!ImgScene) return;
    LoadScenePart(Sx, Sy);
}

void DrawSceneWithoutRole(int cx, int cy) {
    int oldSx = Sx, oldSy = Sy;
    Sx = cx; Sy = cy;
    DrawSceneWithoutRole();
    Sx = oldSx; Sy = oldSy;
}

void DrawRoleOnScene() {
    // 绘制角色在场景上
    TPosition pos = GetPositionOnScreen(0, 0, CENTER_X, CENTER_Y);
    int pic = BEGIN_WALKPIC + SFace * 7;
    DrawSPic(pic, pos.x, pos.y, 0, 0, screen->w, screen->h);
}

void DrawRoleOnScene(int cx, int cy) {
    int oldSx = Sx, oldSy = Sy;
    Sx = cx; Sy = cy;
    DrawRoleOnScene();
    Sx = oldSx; Sy = oldSy;
}

void InitialScene() {
    InitialScene(0);
}

void InitialScene(int onlyvisible) {
    if (!ImgScene) return;
    SDL_FillSurfaceRect(ImgScene, nullptr, 0);
    if (BlockImg.size() > 0)
        memset(BlockImg.data(), 0, BlockImg.size() * sizeof(int16_t));

    // 遍历场景所有格子
    for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
            InitialSceneOnePosition(x, y, ImgScene, ImageWidth, ImageHeight,
                                    (char*)BlockImg.data(), ImageWidth, ImageHeight);
        }
    }
}

void InitialSceneOnePosition(int x, int y, SDL_Surface* img, int imgW, int imgH,
                               char* blockW, int blockWW, int blockWH) {
    TPosition pos = CalPosOnImage(x, y);

    // 地面层
    int groundPic = SData[CurScene][0][x][y] / 2;
    if (groundPic > 0)
        InitialSPic(groundPic, pos.x, pos.y, img, imgW, imgH, nullptr, 0, 0, 0);

    // 建筑层1
    int build1Pic = SData[CurScene][1][x][y] / 2;
    if (build1Pic > 0) {
        int depth = CalBlock(x, y);
        InitialSPic(build1Pic, pos.x, pos.y, img, imgW, imgH, blockW, blockWW, blockWH, depth);
    }

    // 建筑层2
    int build2Pic = SData[CurScene][2][x][y] / 2;
    if (build2Pic > 0) {
        int depth = CalBlock(x, y);
        InitialSPic(build2Pic, pos.x, pos.y, img, imgW, imgH, blockW, blockWW, blockWH, depth);
    }

    // 事件图
    int eventIdx = SData[CurScene][3][x][y];
    if (eventIdx >= 0 && eventIdx < 200) {
        int eventPic = DData[CurScene][eventIdx][5] / 2;
        if (eventPic > 0) {
            int depth = CalBlock(x, y);
            InitialSPic(eventPic, pos.x, pos.y, img, imgW, imgH, blockW, blockWW, blockWH, depth);
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

void LoadScenePart(int cx, int cy) {
    if (!ImgScene || !screen) return;
    TPosition lt = CalLTPosOnImageByCenter(cx, cy);
    SDL_Rect src = {lt.x, lt.y, CENTER_X * 2, CENTER_Y * 2};
    SDL_Rect dst = {0, 0, CENTER_X * 2, CENTER_Y * 2};
    SDL_BlitSurface(ImgScene, &src, screen, &dst);
}

// ---- 战场绘制 ----

void DrawBField(int needProgress) {
    DrawBfieldWithoutRole();
    DrawRoleOnBfield();
    if (CellPhone) DrawVirtualKey();
    if (needProgress) DrawProgress();
}

void DrawBfieldWithoutRole() {
    if (!ImgBField) return;
    LoadBfieldPart(Bx, By);
}

void DrawRoleOnBfield(int mixColor, int mixAlpha, int alpha_) {
    if (!screen) return;
    for (int i = 0; i < BRoleAmount; i++) {
        if (Brole[i].Dead != 0) continue;
        int bx = Brole[i].X, by = Brole[i].Y;
        TPosition pos = GetPositionOnScreen(bx - Bx, by - By, CENTER_X, CENTER_Y);
        int rnum = Brole[i].rnum;
        int headnum = Rrole[rnum].HeadNum;
        int pic = Brole[i].Pic;
        if (pic < 0) pic = BEGIN_BATTLE_ROLE_PIC + headnum * 5 + Brole[i].Face;
        DrawBPic(pic, pos.x, pos.y, 0, alpha_, mixColor, mixAlpha);
    }
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
            Cloud[i].Positionx += Cloud[i].Speedx;
            Cloud[i].Positiony += Cloud[i].Speedy;
            DrawCPic(Cloud[i].Picnum, Cloud[i].Positionx, Cloud[i].Positiony,
                     Cloud[i].Shadow, Cloud[i].Alpha);
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
