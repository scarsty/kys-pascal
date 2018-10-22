/*******************************************************************************
* scence.c                                                  fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "draw.h"
#include "sound.h"
#include "game.h"
#include "map.h"
#include "cmd.h"

#include "scence.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

//贴图的内容及索引
uint32* g_scenceIdxBuff = NULL;
byte* g_scencePicBuff = NULL;

int g_sFace = 0;
int g_sStep = 0;
int g_curScence = 0;
int g_curEvent = 0;

//S, D文件数据
sint16 g_scenceData[SCENCE_NUM][SCENCE_LAYER_NUM][SCENCE_WIDTH][SCENCE_HEIGHT] = {{{{0}}}};

T_Event g_scenceEventData[SCENCE_NUM][SCENCE_EVENT_NUM];

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//显示场景图片
#define DrawScencePic(index, x, y) \
	DrawPicOnScreen(index, x, y, g_scenceIdxBuff, g_scencePicBuff, 0);

//生成场景映像
void DrawScenceWithoutUpdate()
{
	int sx;
	int sy;
	int cx;
	int cy;

	//清屏
	DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0xff);

	//如在事件中, 则以g_ex, g_ey为中心, 否则以主角坐标为中心
	if (g_curEvent != EVENT_NOTHING) {
		cx = g_ex;
		cy = g_ey;
	} else {
		cx = g_sx;
		cy = g_sy;
	}


	int minSx = ScreenXYToMapScencePos(PIC_POS_MAX_X, PIC_POS_MIN_Y, cx, cy).x;
	if (minSx < 0) minSx = 0;
	int minSy = ScreenXYToMapScencePos(PIC_POS_MIN_X, PIC_POS_MIN_Y, cx, cy).y;
	if (minSy < 0) minSy = 0;
	int maxSx = ScreenXYToMapScencePos(PIC_POS_MIN_X, PIC_POS_MAX_Y, cx, cy).x;
	if (maxSx > MAP_WIDTH) maxSx = MAP_WIDTH;
	int maxSy = ScreenXYToMapScencePos(PIC_POS_MAX_X, PIC_POS_MAX_Y, cx, cy).y;
	if (maxSy > MAP_HEIGHT) maxSy = MAP_HEIGHT;

	for (sy = minSy; sy < maxSy; sy++) {
		for (sx = minSx; sx < maxSx; sx++) {
			T_Position pos = MapScenceXYToScreenPos(sx, sy, cx, cy);
			if ((pos.x >= PIC_POS_MIN_X && pos.x < PIC_POS_MAX_X)
				&& (pos.y >= PIC_POS_MIN_Y && pos.y < PIC_POS_MAX_Y)) {
				DrawScencePic(g_curScenceData[EmScenceLayerGround][sx][sy] / 2, pos.x, pos.y);

				if (g_curScenceData[EmScenceLayerBuilding][sx][sy] > 0) {
					DrawScencePic(g_curScenceData[EmScenceLayerBuilding][sx][sy] / 2,
						pos.x, pos.y - g_curScenceData[EmScenceLayerBuildingOffset][sx][sy]);
				}

					//画主角
				if (sx == g_sx && sy == g_sy									//主角位置
					&& (g_curEvent == EVENT_NOTHING								//没有Event
						|| g_curEventData.x != g_sx || g_curEventData.y != g_sy	//不在Event位置
						|| g_curEventData.pic1 <= 0)) {							//Event没有图片
					DrawScencePic(WALK_PIC_OFFSET + g_sFace * (WALK_PIC_NUM) + g_sStep, pos.x, pos.y - g_curScenceData[EmScenceLayerEvent][g_sx][g_sy]);
				}

				if (g_curScenceData[EmScenceLayerSky][sx][sy] > 0) {
					DrawScencePic(g_curScenceData[EmScenceLayerSky][sx][sy] / 2,
						pos.x, pos.y - g_curScenceData[EmScenceLayerSkyOffset][sx][sy]);
				}

				if (g_curScenceData[EmScenceLayerEvent][sx][sy] >= 0 && CurScenceXYEventData(sx, xy).pic1 > 0) {
					DrawScencePic(CurScenceXYEventData(sx, xy).pic1 / 2,
						pos.x, pos.y - g_curScenceData[EmScenceLayerBuildingOffset][sx][sy]);
				}
			}
		}
	}
}

//画场景到屏幕
static void DrawScence()
{
	DrawScenceWithoutUpdate();
	UpdateScreen();
}

static void ShowScenceName(int scence)
{
	//显示场景名
	DrawFrameText(Big5ToUtf8(g_roleData.scences[scence].name), TEXT_NORMAL_COLOR, TEXT_COLOR);
	UpdateScreen();

	WaitKey();
}

//判定场景内某个位置能否行走
static bool GoThroughScence(int sx, int sy)
{
	bool goThroughScence = FALSE;

	if (sx >= 0 && sx < SCENCE_WIDTH && sy >= 0 && sy < SCENCE_HEIGHT) {
		goThroughScence = g_curScenceData[EmScenceLayerBuilding][sx][sy] == 0;
		goThroughScence &= g_curScenceData[EmScenceLayerEvent][sx][sy] < 0
			|| !CurScenceXYEventData(sx, sy).block;

		goThroughScence &= g_curScenceData[EmScenceLayerGround][sx][sy]
			< 358 || g_curScenceData[EmScenceLayerGround][sx][sy] > 362;
		goThroughScence &= g_curScenceData[EmScenceLayerGround][sx][sy]
			< 522 || g_curScenceData[EmScenceLayerGround][sx][sy] > 1022;
		goThroughScence &= g_curScenceData[EmScenceLayerGround][sx][sy]
			< 1324 || g_curScenceData[EmScenceLayerGround][sx][sy] > 1330;
		goThroughScence &= g_curScenceData[EmScenceLayerGround][sx][sy] != 1348;
	}

	return goThroughScence;
}

//在内场景行走, 如参数为1表示新游戏
int InScence(int scence, EmInScence inScence)
{
	int ret = 0;

	int lastSx = g_sx;
	int lastSy = g_sy;
	uint32* lastIdxBuff = g_scenceIdxBuff;
	byte* lastPicBuff = g_scencePicBuff;

	//uint32 next_time = SDL_GetTicks();

	g_curEvent = EVENT_NOTHING;
	g_inGame = EmInGameScence;
	g_curScence = scence;
	g_sFace = g_mFace;
	g_sStep = 0;

	char smpFilename[PATH_MAX];
	char sdxFilename[PATH_MAX];
	sprintf(smpFilename, "smp%03d", g_curScence);
	sprintf(sdxFilename, "sdx%03d", g_curScence);

	if ((g_scenceIdxBuff = LoadFile(sdxFilename, NULL, 0)) && (g_scencePicBuff = LoadFile(smpFilename, NULL, 0))) {
		//改变音乐
		if (g_roleData.scences[g_curScence].entranceMusic >= 0) {
			StopXMI();
			PlayXMI(g_roleData.scences[g_curScence].entranceMusic, -1);
		}

		switch (inScence) {
			case EmInScenceStart:
				g_sx = GAME_START_SX;
				g_sy = GAME_START_SY;
				g_ex = g_sx;
				g_ey = g_sy;
				break;
			case EmInScenceJump:
				g_sx = g_roleData.scences[g_curScence].jumpEntranceX;
				g_sy = g_roleData.scences[g_curScence].jumpEntranceY;
				break;
			case EmInScenceEnter:
			default:
				g_sx = g_roleData.scences[g_curScence].entranceX;
				g_sy = g_roleData.scences[g_curScence].entranceY;
				break;
		}

		CmdScreenFadeIn(NULL);

		if (inScence == EmInScenceStart) {
			g_curEvent = EVENT_GAME_START;
			//**Callevent(EVENT_GAME_START);
			g_curEvent = EVENT_NOTHING;
		} else {
			ShowScenceName(g_curScence);
		}

			//是否有第3类事件位于场景入口
			//***CheckEvent3;

		SDL_EnableKeyRepeat(KEY_REPEAT_DELAY, KEY_REPEAT);
		while (TRUE) {
			//检查是否位于出口
			if ((g_sx == g_roleData.scences[g_curScence].exitX[0] && g_sy == g_roleData.scences[g_curScence].exitY[0])
					|| (g_sx == g_roleData.scences[g_curScence].exitX[1] && g_sy == g_roleData.scences[g_curScence].exitY[1])
					|| (g_sx == g_roleData.scences[g_curScence].exitX[2] && g_sy == g_roleData.scences[g_curScence].exitY[2])) {
				ret = -1;
				break;
			}

			//检查是否跳转
			if (g_sx == g_roleData.scences[g_curScence].jumpX && g_sy == g_roleData.scences[g_curScence].jumpY && g_roleData.scences[g_curScence].jumpScence >= 0) {
				CmdScreenFadeOut(NULL);

				EmInScence jumpInScence =
					g_roleData.scences[g_curScence].mapEntrance1X
					? EmInScenceEnter : EmInScenceJump;
				InScence(g_roleData.scences[g_curScence].jumpScence, jumpInScence);

				g_curScence = scence;
				g_sStep = 0;

				//InitialScence(g_curScence);
				CmdScreenFadeIn(NULL);

				ShowScenceName(g_curScence);
			}

			DrawScence();

			//场景内动态效果
			/*
			now = SDL_GetTicks();
			if (now > next_time) {
				for (i = 0; i < SCENCE_EVENT_NUM; i++) {
					if (g_curScenceEventData[i].fps > 0 || g_curScenceEventData[i].pic3 < g_curScenceEventData[i].pic2) {
						//屏蔽了旗子的动态效果, 因贴图太大不好处理
						if (g_curScenceEventData[i].pic1 < 5498 || g_curScenceEventData[i].pic1 > 5692) {
							g_curScenceEventData[i].pic1 = g_curScenceEventData[i].pic1 + 2;
							if (g_curScenceEventData[i].pic1 > g_curScenceEventData[i].pic2) {
								g_curScenceEventData[i].pic1 = g_curScenceEventData[i].pic3;
							}

							updatescence(g_curScenceEventData[ i, 10], g_curScenceEventData[ i, 9]);
						}
					}
					next_time = now + 200;
					DrawScence;
					SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
			}
			*/

			int sx = g_sx;
			int sy = g_sy;
			int key = PollKey();
			switch (key) {
				case KEYUP:
					g_sStep = 0;
					break;
				case SDLK_ESCAPE:
					//*********MenuEsc;
					break;
				case SDLK_RETURN:
				case SDLK_SPACE:
					sx = g_sx;
					sy = g_sy;
					switch (g_sFace) {
						case 0:
							sx--;
							break;
						case 1:
							sy++;
							break;
						case 2:
							sy--;
							break;
						case 3:
							sx++;
							break;
						default:
							break;
					}

					//如有则调用事件
					if (g_curScenceData[EmScenceLayerEvent][sx][sy] >= 0) {
						g_curEvent = g_curScenceData[EmScenceLayerEvent][sx][sy];
						if (g_curEventData.actionEvent >= 0) {
							//CallEvent(CurScenceXYEventData(sx, sy).g_curEventData.actionEvent);
						}
						g_curEvent = EVENT_NOTHING;
					}
					break;
				case SDLK_UP:
					g_sFace = 0;
					if (++g_sStep >= WALK_PIC_NUM) g_sStep = 1;
					if (GoThroughScence(g_sx - 1, g_sy)) {
						g_sx--;
					}
					break;
				case SDLK_RIGHT:
					g_sFace = 1;
					if (++g_sStep >= WALK_PIC_NUM) g_sStep = 1;
					if (GoThroughScence(g_sx, g_sy + 1)) {
						g_sy++;
					}
					break;
				case SDLK_LEFT:
					g_sFace = 2;
					if (++g_sStep >= WALK_PIC_NUM) g_sStep = 1;
					if (GoThroughScence(g_sx, g_sy - 1)) {
						g_sy--;
					}
					break;
				case SDLK_DOWN:
					g_sFace = 3;
					if (++g_sStep >= WALK_PIC_NUM) g_sStep = 1;
					if (GoThroughScence(g_sx + 1, g_sy)) {
						g_sx++;
					}
					break;
				default:
					break;
			}
		}

		if (g_roleData.scences[g_curScence].exitMusic >= 0) {
			StopXMI();
			PlayXMI(g_roleData.scences[g_curScence].exitMusic, -1);
		}

		CmdScreenFadeOut(NULL);
		free(g_scenceIdxBuff);
		free(g_scencePicBuff);
	}


	g_sx = lastSx;
	g_sy = lastSy;
	g_scenceIdxBuff = lastIdxBuff;
	g_scencePicBuff = lastPicBuff;

	g_mFace = g_sFace;// = 3 - g_sFace;

	return ret;
}
