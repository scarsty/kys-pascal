#pragma once
// kys_engine.h - 基础引擎：音频、文件IO、绘图、文字、屏幕管理
// 对应 kys_engine.pas

#include "kys_type.h"
#include <string>

// 音频
void InitialMusic();
void PlayMP3(int MusicNum, int times, int frombeginning = 1);
void PlayMP3(const char* filename, int times);
void StopMP3(int frombeginning = 1);
void PlaySoundE(int SoundNum, int times);
void PlaySoundE(int SoundNum);
void PlaySoundE(int SoundNum, int times, int x, int y, int z);
void PlaySoundA(int SoundNum, int times);

// 文件读取
void ReadTiles();
char* ReadFileToBuffer(char* p, const std::string& filename, int size, int malloc_flag);
void FreeFileBuffer(char*& p);
int LoadIdxGrp(const std::string& stridx, const std::string& strgrp,
    std::vector<int>& idxarray, std::vector<uint8_t>& grparray);
SDL_Surface* LoadSurfaceFromFile(const std::string& filename);
SDL_Surface* LoadSurfaceFromMem(const char* p, int len);
void FreeAllSurface();

// 基本绘图
uint32_t GetPixel(SDL_Surface* surface, int x, int y);
void PutPixel(SDL_Surface* surface, int x, int y, uint32_t pixel);
void display_img(const char* file_name, int x, int y);
uint32_t ColColor(uint8_t num);
void DrawRectangle(SDL_Surface* sur, int x, int y, int w, int h,
    int colorin, uint32_t colorframe, int alpha);
void DrawRectangleWithoutFrame(SDL_Surface* sur, int x, int y, int w, int h,
    uint32_t colorin, int alpha);

// RLE8绘图
bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys);
bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys,
    int xx, int yy, int xw, int yh);
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI, int shadow);
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI,
    int shadow, int alpha);
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI,
    int shadow, int alpha,
    char* BlockImageW, const char* BlockPosition,
    int widthW, int heightW, int sizeW,
    int depth, uint32_t mixColor, int mixAlpha,
    int totalpix = 0);
TPosition GetPositionOnScreen(int x, int y, int CenterX, int CenterY);

// 文字
std::string cp950toutf8(const char* str, int len = -1);
std::string utf8tocp950(const std::string& str);
void DrawText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color);
void DrawEngText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color);
void DrawShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2);
void DrawShadowText(const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2);
void DrawEngShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2);
void DrawBig5Text(SDL_Surface* sur, const char* str, int x_pos, int y_pos, uint32_t color);
void DrawBig5ShadowText(SDL_Surface* sur, const char* word, int x_pos, int y_pos, uint32_t color1, uint32_t color2);
void DrawTextWithRect(const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2);
void DrawTextWithRect(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2);
void DrawTextWithRectNoUpdate(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2);

// 系统
void ChangeCol();
void UpdateScreen(SDL_Surface* scr1, int x, int y, int w, int h);
void SDL_GetMouseState2(int& x, int& y);
void ResizeWindow(int w, int h);
void SwitchFullscreen();
void QuitConfirm();
uint32_t CheckBasicEvent();
int AngleToDirection(double y, double x);
void UpdateAllScreen();
void TransBlackScreen();
void CleanKeyValue();
void GetMousePosition(int& x, int& y, int x0, int y0, int yp = 0);
bool MouseInRegion(int x, int y, int w, int h);
bool MouseInRegion(int x, int y, int w, int h, int& x1, int& y1);
int RegionParameter(int x, int x1, int x2);
void QuickSortB(TBuildInfo* a, int l, int r);

// 文字辅助
int DrawLength(const std::string& str);
int DrawLength(const char* p);
int utf8follow(char c1);
void swap(uint32_t& x, uint32_t& y);

// 简繁转换
std::string Simplified2Traditional(const std::string& str);
std::string Traditional2Simplified(const std::string& str);

// 调试
void tic();
void toc();
void kyslog(const char* fmt, ...);

std::string checkFileName(const std::string& f);
bool InRegion(int x1, int y1, int x, int y, int w, int h);

bool EventFilter(void* p, SDL_Event* e);
