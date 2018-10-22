/*******************************************************************************
* draw.h                                                    fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __DRAW_H__
#define __DRAW_H__

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include <stdio.h>
#include <iconv.h>

#include <SDL/SDL_ttf.h>
#include <SDL/SDL_video.h>
#include <SDL/SDL_rotozoom.h>
#include <SDL/SDL_gfxPrimitives.h>

#include "const.h"
#include "typedef.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

//默认调色板数据
extern T_RGB g_palette[256];
extern SDL_Surface* g_screenSurface;
extern uint32* g_faceIdxBuff;
extern byte* g_facePicBuff;

extern TTF_Font* g_HanFont;

extern iconv_t g_utf8ToBig5;
extern iconv_t g_big5ToUtf8;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void InitialVedio();
void CloseVedio();

void DrawRectangle(int x, int y, int w, int h, uint8 color, uint8 alpha);
void DrawFrameRectangle(int x, int y, int w, int h, uint8 frmColor, uint8 insColor, uint8 alpha);

void DrawPic(SDL_Surface* destSurface, int index, int x, int y, uint32* idxBuffer, byte* picBuffer, int highlight);
#define DrawPicOnScreen(index, x, y, idxBuffer, picBuffer, highlight) \
	DrawPic(g_screenSurface, (index), (x), (y), (idxBuffer), (picBuffer), (highlight))
void DrawFacePic(int index, int x, int y);
void DrawBigPicOnScreen(int index, byte* buffer);

T_Position MapScenceXYToScreenPos(int mx, int my, int cx, int cy);
T_Position ScreenXYToMapScencePos(int x, int y, int cx, int cy);

void UpdateScreen();

void InitialFont();
T_Position DrawShadowText(char* str, int x, int y, uint8 color);
T_Position DrawBig5ShadowText(char* big5, int x, int y, uint8 color);
void DrawFrameText(char* str, uint8 txtColor, uint8 frmColor);
void DrawYesNoBox(char* boxStr[2], bool yesNo);
T_Position DrawBig5Text(char* big5, int x, int y, uint8 color);

void DrawTalk(char* str, int x, int y, int w, int h, int face, int fx, int fy, int tx, int ty, int tw, int th);

char* Utf8ToBig5(char* utf8);
char* Big5ToUtf8(char* big5);

#endif //__DRAW_H__

