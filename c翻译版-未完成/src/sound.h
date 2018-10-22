/*******************************************************************************
* sound.h                                                   fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __SOUND_H__
#define __SOUND_H__

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

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void InitialAudio();
void CloseAudio();

void PlayXMI(int index, int times);
void StopXMI();
void PlayWAV(int index, int times);
void PlayWAVFile(char* filename, int times);

#endif //__SOUND_H__
