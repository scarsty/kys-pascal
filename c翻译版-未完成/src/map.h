/*******************************************************************************
* map.h                                                     fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __MAP_H__
#define __MAP_H__

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include <stdio.h>

#include "const.h"
#include "typedef.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

//贴图的内容及索引
extern uint32* g_mapIdxBuff;
extern byte* g_mapPicBuff;

//主地图数据
extern sint16 g_map[MAP_WIDTH][MAP_HEIGHT];
extern sint16 g_ground[MAP_WIDTH][MAP_HEIGHT];
extern sint16 g_building[MAP_WIDTH][MAP_HEIGHT];
extern sint16 g_buildingX[MAP_WIDTH][MAP_HEIGHT];
extern sint16 g_buildingY[MAP_WIDTH][MAP_HEIGHT];

//主地图坐标, 方向
#define g_mx	(g_roleData.common.mx)
#define g_my	(g_roleData.common.my)
#define g_mFace	(g_roleData.common.mFace)

//步数，休息动画，船动画
//extern int g_mStep;
//extern int g_mRest;
//extern int g_mShip;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void DrawMapWithoutUpdate();

void InitialMapEntrances();
void InMap();

#endif //__MAP_H__
