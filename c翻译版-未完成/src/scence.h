/*******************************************************************************
* scence.h                                                  fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __SCENCE_H__
#define __SCENCE_H__

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include <stdio.h>
#include <limits.h>

#include "const.h"
#include "typedef.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

#define g_sx	(g_roleData.common.sx)
#define g_sy	(g_roleData.common.sy)

extern sint16 g_scenceData[SCENCE_NUM][SCENCE_LAYER_NUM][SCENCE_WIDTH][SCENCE_HEIGHT];
#define g_curScenceData		(g_scenceData[g_curScence])

extern T_Event g_scenceEventData[SCENCE_NUM][SCENCE_EVENT_NUM];
#define g_curScenceEventData			(g_scenceEventData[g_curScence])
#define g_curEventData					(g_curScenceEventData[g_curEvent])
#define CurScenceXYEventData(sx, xy)	(g_curScenceEventData[g_curScenceData[EmScenceLayerEvent][(sx)][(sy)]])

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void DrawScenceOnScreen(int x, int y);
void DrawScenceWithoutUpdate();

#endif //__SCENCE_H__
