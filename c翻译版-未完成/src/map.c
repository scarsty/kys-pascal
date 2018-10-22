/*******************************************************************************
* map.c                                                     fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "draw.h"
#include "game.h"
#include "cmd.h"

#include "map.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

//贴图的内容及索引
uint32* g_mapIdxBuff = NULL;
byte* g_mapPicBuff = NULL;

//主地图数据
sint16 g_map[MAP_WIDTH][MAP_HEIGHT] = {{0}};
sint16 g_ground[MAP_WIDTH][MAP_HEIGHT] = {{0}};
sint16 g_building[MAP_WIDTH][MAP_HEIGHT] = {{0}};
sint16 g_buildingX[MAP_WIDTH][MAP_HEIGHT] = {{0}};
sint16 g_buildingY[MAP_WIDTH][MAP_HEIGHT] = {{0}};

sint16 g_entrances[MAP_WIDTH][MAP_HEIGHT] = {{0}};

//步数，休息动画，船动画
int g_mStep = 0;
int g_mRest = 0;
int g_mShip = 0;

bool g_ship = FALSE;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//显示主地图贴图
#define DrawMapPic(index, x, y) \
	DrawPicOnScreen(index, x, y, g_mapIdxBuff, g_mapPicBuff, 0);

void DrawMapWithoutUpdate()
{
	int mx;
	int my;
	int cx = g_mx;
	int cy = g_my;

	//清屏
	DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0xff);

	int minMx = ScreenXYToMapScencePos(PIC_POS_MAX_X, PIC_POS_MIN_Y, cx, cy).x;
	if (minMx < 0) minMx = 0;
	int minMy = ScreenXYToMapScencePos(PIC_POS_MIN_X, PIC_POS_MIN_Y, cx, cy).y;
	if (minMy < 0) minMy = 0;
	int maxMx = ScreenXYToMapScencePos(PIC_POS_MIN_X, PIC_POS_MAX_Y, cx, cy).x;
	if (maxMx > MAP_WIDTH) maxMx = MAP_WIDTH;
	int maxMy = ScreenXYToMapScencePos(PIC_POS_MAX_X, PIC_POS_MAX_Y, cx, cy).y;
	if (maxMy > MAP_HEIGHT) maxMy = MAP_HEIGHT;

		for (mx = minMx; mx < maxMx; mx++) {
	for (my = minMy; my < maxMy; my++) {
			T_Position pos = MapScenceXYToScreenPos(mx, my, cx, cy);
			if ((pos.x >= PIC_POS_MIN_X && pos.x < PIC_POS_MAX_X)
				&& (pos.y >= PIC_POS_MIN_Y && pos.y < PIC_POS_MAX_Y)) {
				DrawMapPic(g_map[mx][my] / 2, pos.x, pos.y);

				if (g_ground[mx][my] > 0) {
					DrawMapPic(g_ground[mx][my] / 2, pos.x, pos.y);
				}
			}
		//}
	//}

		//for (mx = minMx; mx < maxMx; mx++) {
	//for (my = minMy; my < maxMy; my++) {
			//s.weyl说游戏中xy是反的，开始没在意，现在终于信了。
			int by = g_buildingX[mx][my];
			int bx = g_buildingY[mx][my];
			T_Position bPos = MapScenceXYToScreenPos(bx, by, cx, cy);
			if ((bPos.x >= PIC_POS_MIN_X && bPos.x < PIC_POS_MAX_X)
				&& (bPos.y >= PIC_POS_MIN_Y && bPos.y < PIC_POS_MAX_Y)) {
				if (g_building[bx][by] > 0 && g_buildingX[mx + 1][my] != bx && g_buildingX[mx][my + 1] != by) {
					DrawMapPic(g_building[bx][by] / 2, bPos.x, bPos.y);
				}
			}

			//pos = MapScenceXYToScreenPos(mx, my, cx, cy);
			if (mx == g_mx && my == g_my) {
				if (g_ship) {
					DrawMapPic(SHIP_PIC_OFFSET + g_mFace * SHIP_PIC_NUM + g_mShip, pos.x, pos.y);
				} else if (g_mStep || !g_mRest) {
					DrawMapPic(WALK_PIC_OFFSET + g_mFace * WALK_PIC_NUM + g_mStep, pos.x, pos.y);
				} else {
					DrawMapPic(REST_PIC_OFFSET + g_mFace * REST_PIC_NUM + (g_mRest - 1), pos.x, pos.y);
				}
			}
		}
	}
}

//显示主地图场景于屏幕
static void DrawMap()
{
	DrawMapWithoutUpdate();
	UpdateScreen();
}

//初始化入口
void InitialMapEntrances()
{
	memset(g_entrances, 0xff, sizeof(g_entrances));
	int i;
	for (i = 0; i < SCENCE_NUM; i++) {
		g_entrances[g_roleData.scences[i].mapEntrance1X][g_roleData.scences[i].mapEntrance1Y] = i;
		g_entrances[g_roleData.scences[i].mapEntrance2X][g_roleData.scences[i].mapEntrance2Y] = i;
	}
}

//判定主地图某个位置能否行走, 是否变成船
static bool GoThroughMap(int mx, int my)
{
	bool GoThroughMap = FALSE;

	if (mx >= 0 && mx < MAP_WIDTH && my >= 0 && my < MAP_HEIGHT) {
		GoThroughMap = g_buildingX[mx][my] == 0;
		GoThroughMap &= g_map[mx][my] != 838;
		GoThroughMap &= g_map[mx][my] < 621 || g_map[mx][my] > 670;
	}

	g_ship = g_map[mx][my] >= 358 && g_map[mx][my] <= 362;
	g_ship |= g_map[mx][my] >= 506 && g_map[mx][my] <= 670;
	g_ship |= g_map[mx][my] >= 1016 && g_map[mx][my] <= 1022;

	return GoThroughMap;
}

//检测是否处于某入口, 并是否达成进入条件
static bool GoIn(int mx, int my)
{
	bool goIn = FALSE;

	int scence = -1;
	if (mx >= 0 && mx <MAP_WIDTH
		&& my >= 0 && my < MAP_HEIGHT) {
		if ((scence = g_entrances[mx][my] >= 0)) {
			if ((g_roleData.scences[scence].enCondition == 0)) {
				goIn = TRUE;
			} else if ((g_roleData.scences[scence].enCondition == 2)) { //是否有人轻功超过70
				int i;
				for (i = 0; i < MAX_TEAM_ROLE; i++) {
					if (g_roleData.common.team[i] >= 0 && g_roleData.roles[g_roleData.common.team[i]].speed > 70) {
						goIn = TRUE;
						break;
					}
				}
			}
		}
	}

	return goIn;
}

//于主地图行走
void InMap()
{
	char* aaa[] = {
		"過招嗎？",
		"過招",
		"罷了"
	};
	printf("%s\n", ShowYesNoBox(aaa) ? "過招" : "罷了");

	uint32 next_time = SDL_GetTicks() + 3000;
	g_inGame = EmInGameMap;

	g_mStep = 0;
	g_mRest = 0;
	g_mShip = 0;

	CmdScreenFadeIn(NULL);

	WaitKey();

	//PlayMp3(16, -1);

	//事件轮询(并非等待)
	SDL_EnableKeyRepeat(KEY_REPEAT_DELAY, KEY_REPEAT);
	while (TRUE) {
		//如果当前处于标题画面, 则退出, 用于战斗失败
		//***********

		int mx = g_mx;
		int my = g_my;
		switch (g_mFace) {
			case 0:
				mx--;
				break;
			case 1:
				my++;
				break;
			case 2:
				my--;
				break;
			case 3:
				mx++;
				break;
			default:
				break;
		}

		if (GoIn(mx, my)) {
			CmdScreenFadeOut(NULL);
			InScence(g_entrances[mx][my], EmInScenceEnter);
			g_inGame = EmInGameMap;

			g_mStep = 0;
			g_mRest = 0;
			g_mShip = 0;

			CmdScreenFadeIn(NULL);
		}

		//主地图动态效果, 实际仅有主角的动作
		uint32 now = SDL_GetTicks();
		if (g_mStep) {
			g_mRest = 0;
			next_time = now + 3000;
		} else if (now > next_time) {
			if (++g_mRest >= REST_PIC_NUM + 1) {
				g_mRest = 0;
				next_time = now + 3000;
			} else {
				next_time = now + 500;
			}
		}

		DrawMap();

		int key = PollKey();
		switch (key) {
			case KEYUP:
				g_mStep = 0;
				g_mShip = 0;
				break;
			case SDLK_UP:
				g_mFace = 0;
				if (++g_mStep >= WALK_PIC_NUM) g_mStep = 1;
				if (++g_mShip >= SHIP_PIC_NUM) g_mShip = 1;

				if (GoThroughMap(g_mx - 1, g_my)) {
					g_mx--;
				}
				break;
			case SDLK_RIGHT:
				g_mFace = 1;
				if (++g_mStep >= WALK_PIC_NUM) g_mStep = 1;
				if (++g_mShip >= SHIP_PIC_NUM) g_mShip = 1;

				if (GoThroughMap(g_mx, g_my + 1)) {
					g_my++;
				}
				break;
			case SDLK_LEFT:
				g_mFace = 2;
				if (++g_mStep >= WALK_PIC_NUM) g_mStep = 1;
				if (++g_mShip >= SHIP_PIC_NUM) g_mShip = 1;

				if (GoThroughMap(g_mx, g_my - 1)) {
					g_my--;
				}
				break;
			case SDLK_DOWN:
				g_mFace = 3;
				if (++g_mStep >= WALK_PIC_NUM) g_mStep = 1;
				if (++g_mShip >= SHIP_PIC_NUM) g_mShip = 1;

				if (GoThroughMap(g_mx + 1, g_my)) {
					g_mx++;
				}
				break;
			case SDLK_ESCAPE:
				//***MenuEsc;
				break;
			default:
				break;
		}
	}
}
