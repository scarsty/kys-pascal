/*******************************************************************************
* game.h                                                    fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __GAME_H__
#define __GAME_H__

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include <stdio.h>

#include <stdio.h>
#include <limits.h>
#include <time.h>

#include <SDL/SDL.h>
#include <SDL/SDL_events.h>
#include <SDL/SDL_mixer.h>

#include "const.h"
#include "typedef.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

extern bool g_fullScreen;

extern T_RoleData g_roleData;
#define g_hero (g_roleData.roles[0])

extern EmInGame g_inGame;

extern int g_curScence;
extern int g_curEvent;
extern int g_usingItem;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void* LoadFile(char* filename, void* buffer, size_t size);

void RedrawWithoutUpdate();
void Redraw();

int WaitKey();
int PollKey();

bool ShowYesNoBox(char* boxString[2]);

int InScence(int scence, EmInScence inScence);

#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) > (b) ? (a) : (b))

#endif //__GAME_H__
