#pragma once
// kys_draw.h - 高层绘图：贴图、场景、战场
// 对应 kys_draw.pas

#include "kys_type.h"
#include <string>

// 各类贴图绘制
void DrawTitlePic(int num, int px, int py);
void DrawMPic(int num, int px, int py);
void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh);
void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha);
void DrawSPic(int num, int px, int py, int xx, int yy, int xw, int yh, int shadow, int alpha, uint32_t mixColor, int mixAlpha);
void InitialSPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI, char* blockW, int widthW, int heightW, int depth, uint32_t mixColor = 0, int mixAlpha = 0);
void DrawHeadPic(int num, int px, int py);
void DrawHeadPic(int num, int px, int py, SDL_Surface* scr);
void DrawIPic(int num, int px, int py);
void DrawBPic(int num, int px, int py, int shadow);
void DrawBPic(int num, int px, int py, int shadow, int alpha);
void DrawBPic(int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha);
void InitialBPic(int num, int px, int py, SDL_Surface* img, int widthI, int heightI, char* blockW, int widthW, int heightW, int depth, uint32_t mixColor = 0, int mixAlpha = 0);
void DrawEPic(int num, int px, int py);
void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha);
void DrawFPic(int headnum, int num, int px, int py, int shadow, int alpha, uint32_t mixColor, int mixAlpha);
void DrawCPic(int num, int px, int py, int shadow, int alpha);

void GetPicSize(int num, const int* pidx, const uint8_t* ppic, int& w, int& h, int& xs, int& ys);

// 主绘制调度
void Redraw();
void RecordFreshScreen(int x = 0, int y = 0, int w = 0, int h = 0);
void LoadFreshScreen(int x = 0, int y = 0, int w = 0, int h = 0);

// 大地图
void DrawMMap();

// 场景
void DrawScene();
void DrawSceneWithoutRole();
void DrawSceneWithoutRole(int cx, int cy);
void DrawRoleOnScene();
void DrawRoleOnScene(int cx, int cy);
void InitialScene();
void InitialScene(int onlyvisible);
void ExpandGroundOnImg(SDL_Surface* img, int imgW, int imgH);
void UpdateScene();
void LoadScenePart(int cx, int cy);
TPosition CalPosOnImage(int x, int y);
TPosition CalLTPosOnImageByCenter(int cx, int cy);

// 战场
void DrawBField(int needProgress = 1);
void DrawBfieldWithoutRole();
void DrawRoleOnBfield(int mixColor = 0, int mixAlpha = 0, int alpha_ = 0);
void InitialBFieldImage();
void InitialBFieldPosition(int x, int y);
void LoadBfieldPart(int cx, int cy);
void LoadBFieldPart2(int cx, int cy);
void DrawBFieldWithCursor(int bnum);
void DrawBFieldWithEft(int bnum, int eftnum);
void DrawBFieldWithEft(int bnum, int eftnum, int frame);
void DrawBFieldWithEft(int bnum, int eftnum, int frame, int allframe);
void DrawBFieldWithAction(int bnum, int actionnum);

// 云、进度条、虚拟按键
void DrawClouds();
void DrawProgress();
void DrawVirtualKey();

// 初始化一个位置
void InitialSceneOnePosition(int x, int y, SDL_Surface* img, int imgW, int imgH, char* blockW, int blockWW, int blockWH);

int CalBlock(int x, int y);
