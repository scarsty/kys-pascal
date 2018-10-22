/*******************************************************************************
* game.c                                                    fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "../config.h"

#include "draw.h"
#include "sound.h"
#include "map.h"
#include "scence.h"
#include "cmd.h"

#include "game.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

//最大攻击值~最大左右互博值 43~58
const uint8 MAX_PRO_LIST[58 - 43 + 1] = {
	100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 1};

uint32* g_bfIdxBuff = NULL;
byte* g_bfPicBuff = NULL;

uint32* g_effIdxBuff = NULL;
byte* g_effectBuff = NULL;

uint32* g_actIdxBuff = NULL;
byte* g_actionBuff = NULL;

int g_usingItem = 0;
int currentBattle = 0;
EmInGame g_inGame = 0;
//当前场景, 事件(在场景中的事件号), 使用物品, 战斗
//g_inGame: 0-主地图, 1-场景, 2-战场, 3-开头画面

T_RoleData g_roleData;

//战场数据
////0-地面, 1-建筑, 2-人物, 3-可否被选中, 4-攻击范围, 5, 6 ,7-未使用
sint16 bField[8][64][64];

//sint16 warSta[0x5e];
//战场数据, 即war.sta文件的映像
//T_BattleRole bRole[100];

//战场人物属性
//0-人物序号, 1-敌我, 2, 3-坐标, 4-面对方向, 5-是否仍在战场, 6-可移动步数, 7-是否行动完毕,
//8-贴图(未使用), 9-头上显示数字, 10, 11, 12-未使用, 13-已获得经验, 14-是否自动战斗
int bRoleAmount = 0;
//战场人物总数
int bx = 0;
int by = 0;
int ax = 0;
int ay = 0;
//当前人物坐标, 选择目标的坐标
int bStatus = 0;
//战斗状态, 0-继续, 1-胜利, 2-失败

int g_leaveList[100] = {0};
int g_effectList[200] = {0};
int g_levelupList[100] = {0};
int g_matchList[100][3] = {{0}};
//各类列表, 前四个从文件读入

//是否全屏
bool g_fullScreen = FALSE;

//选单所使用的字符串
char menuString[1024] = {0};
char menuEngString[1024] = {0};

//扩充指令50所使用的变量 0x7FFF~-0x8000
int x50[0x7FFF - -0x8000 + 1] = {0};
#define X50_OFFSET (-0x8000)

/*******************************************************************************
* Static Function Declare                                                      *
*******************************************************************************/

static void InitialRole();
static void ShowStatus(int role);

static void Start();
static void InGame(bool start);
static void Quit();

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//初始化字体, 音效, 视频, 启动游戏
#ifdef WIN32
#include <windows.h>
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
#else
int main(int argc, char* argv[])
#endif
{
	srand(clock());

	InitialFont();
	InitialVedio();
	InitialAudio();

	Start();

	Quit();

	return 0;
}

//关闭所有已打开的资源, 退出
static void Quit()
{
	CloseVedio();
	SDL_Quit();

	exit(0);
}

//读入存档, 如为0则读入起始存档
void LoadGame(int slot)
{
	char grpName[PATH_MAX];

	if (slot) {
		sprintf(grpName, "r%d.grp", slot);
	} else {
		strcpy(grpName, "ranger.grp");
	}

	LoadFile(grpName, &g_roleData, sizeof(T_RoleData));

	InitialMapEntrances();

	if (slot) {
		grpName[0] = 's';
	} else {
		strcpy(grpName, "allsin.grp");
	}

	LoadFile(grpName, g_scenceData, sizeof(g_scenceData));

	if (slot) {
		grpName[0] = 'd';
	} else {
		strcpy(grpName, "alldef.grp");
	}

	LoadFile(grpName, g_scenceEventData, sizeof(g_scenceEventData));
}

//存档
void SaveGame(int slot)
{
	char grpName[PATH_MAX];
	FILE*  grp = 0;

	if (slot) {
		sprintf(grpName, "r%d.grp", slot);
	} else {
		strcpy(grpName, "ranger.grp");
	}

	if ((grp = fopen(grpName, "w"))) {
		fwrite(&g_roleData, sizeof(T_RoleData), 1, grp);
		fclose(grp);
	} else {
		printf("Open R file failed, slot = %d\n", slot);
		return;
	}

	if (slot) {
		grpName[0] = 'S';
	} else {
		strcpy(grpName, "allsin.grp");
	}

	if ((grp = fopen(grpName, "w"))) {
		fwrite(g_scenceData, sizeof(g_scenceData), 1, grp);
		fclose(grp);
	} else {
		printf("Open S file failed, slot = %d\n", slot);
		return;
	}

	if (slot) {
		grpName[0] = 'D';
	} else {
		strcpy(grpName, "alldef.grp");
	}

	if ((grp = fopen(grpName, "w"))) {
		fwrite(g_scenceEventData, sizeof(g_scenceEventData), 1, grp);
		fclose(grp);
	} else {
		printf("Open D file failed, slot = %d\n", slot);
		return;
	}
}

int PollKey()
{
	int key = 0;

	SDL_Event event;
	if (SDL_PollEvent(&event)) {
		switch (event.type) {
			case SDL_QUIT:
				Quit();
				break;
			case SDL_KEYDOWN:
				if (event.key.keysym.sym) {
					key = event.key.keysym.sym;
				}
				break;
			case SDL_KEYUP:
				key = -1;
				break;
			default:
				break;
		}
	}

	return key;
}

//等待任意按键
int WaitKey()
{
	int key = 0;

	SDL_Event event;
	while (SDL_WaitEvent(&event)) {
		if (event.type == SDL_QUIT) {
			Quit();
		} else if (event.type == SDL_KEYDOWN) {
			if (event.key.keysym.sym) {
				key = event.key.keysym.sym;
				break;
			}
			printf("key down!!\n");
		} else if (event.type == SDL_KEYUP) {
			key = -1;
		}
	}

	return key;
}

//重画屏幕
void RedrawWithoutUpdate()
{
	switch (g_inGame) {
		case EmInGameMap:
			DrawMapWithoutUpdate();
			break;
		case EmInGameScence:
			DrawScenceWithoutUpdate();
			break;
		case EmInGameBattleField:
			//*DrawWholeBField();
			break;
		case EmInGameTitle:
		default:
			break;
	}
}

void Redraw()
{
	RedrawWithoutUpdate();
	UpdateScreen();
}

#if 0
//画不含主角的战场
void DrawBFieldWithoutRole(x, int y = 0)()
	var
	int   i1 = 0;
	int  i2 = 0;
	int  xpoint = 0;
	int ypoint = 0;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}

	DrawBFieldOnScreen(-x * 18 + y * 18 + 1151 - SCREEN_CENTER_X, x * 9 + y * 9 + 9 - SCREEN_CENTER_Y);

	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}
	//SDL_UpdateRect(g_screenSurface, 0,0,g_screenSurface.w,g_screenSurface.h);

}
#endif

#if 0
//更改场景映像, 用于动画, 场景内动态效果
void UpdateScence(int sx, int sy)
{
	T_Position pos = GetScenceBufferXpos.Yos(sx, xy);
	int pic = -1;

	//如在事件中, 直接给定更新范围
	pic = CurScenceXYEventData(sx, sy).pic1 / 2;
	if (g_curEvent == EVENT_NOTHING && pic > 0) {
		int offset = g_scenceIdxBuff[pic - 1];
		pos.x = pos.x - (g_scencePicBuff[offset + 4] + 256 * g_scencePicBuff[offset + 5]) - 3;
		pos.y = pos.y - (g_scencePicBuff[offset + 6] + 256 * g_scencePicBuff[offset + 7]) - 3 - g_curScenceData[ 4, xs, ys];
		w = (g_scencePicBuff[offset] + 256 * g_scencePicBuff[offset + 1]) + 20;
		h = (g_scencePicBuff[offset + 2] + 256 * g_scencePicBuff[offset + 3]) + 6;

	} else {
		pos.x = pos.x - 30;
		pos.y = pos.y - 120;
		w = 100;
		h = 130;
	}
	//计算贴图高度和宽度, 作为更新范围
	offset = max(h / 18, w / 36);
	for i1 = xs - offset to xs + 5 do
		for i2 = ys - offset to ys + 5 do
		{
			x = -i1 * 18 + i2 * 18 + 1151;
			y = i1 * 9 + i2 * 9 + 9;
			InitialScenceLayer(g_curScenceData[ 0, i1, i2] / 2, x, y, pos.x, pos.y, w, h);
			if ((i1 < 0) || (i2 < 0) || (i1 > 63) || (i2 > 63)) InitialScenceLayer(0, x, y, pos.x, pos.y, w, h)
			else {
				//InitialScenceLayer(g_curScenceData[ 0, i1,i2] / 2,x,y,pos.x,pos.y,w,h);
				if ((g_curScenceData[ 1, i1, i2] > 0))
					InitialScenceLayer(g_curScenceData[ 1, i1, i2] / 2, x, y - g_curScenceData[ 4, i1, i2], pos.x, pos.y, w, h);
				//if ((i1=Sx) && (i2=Sy))
				//InitialScenceLayer(WALK_PIC_OFFSET+g_sFace*WALK_PIC_pic+g_sStep,x,y-g_curScenceData[ 4, i1,i2],0,0,2304,1152);
				if ((g_curScenceData[ 2, i1, i2] > 0))
					InitialScenceLayer(g_curScenceData[ 2, i1, i2] / 2, x, y - g_curScenceData[ 5, i1, i2], pos.x, pos.y, w, h);
				if ((g_curScenceData[ 3, i1, i2] >= 0) && (g_curScenceEventData[ g_curScenceData[ 3, i1, i2], 5] > 0))
					InitialScenceLayer(g_curScenceEventData[ g_curScenceData[ 3, i1, i2], 5] / 2, x, y - g_curScenceData[ 4, i1, i2], pos.x, pos.y, w, h);
				//if ((i1=RScence[g_curScence*26+15]) && (i2=RScence[g_curScence*26+14]))
				//DrawScencePic(0,-(i1-Sx)*18+(i2-Sy)*18+SCREEN_CENTER_X,(i1-Sx)*9+(i2-Sy)*9+SCREEN_CENTER_Y);
				//if ((i1=Sx) && (i2=Sy)) DrawScencePic(WALK_PIC_OFFSET+g_sFace*WALK_PIC_pic+g_sStep,SCREEN_CENTER_X,SCREEN_CENTER_Y-g_curScenceData[ 4, i1,i2]);
			}
		}

}

/*
   Filename = ExtractFilePath(Paramstr(0)) + "kysmod.ini";
   Kys_ini = TIniFile.Create(filename);

   ITEM_BEGIN_PIC = Kys_ini.ReadInteger("constant", "ITEM_BEGIN_PIC", 3501);
   MAX_HEAD_NUM = Kys_ini.ReadInteger("constant", "MAX_HEAD_NUM", 189);
   BEGIN_EVENT = Kys_ini.ReadInteger("constant", "BEGIN_EVENT", 691);
   BEGIN_SCENCE = Kys_ini.ReadInteger("constant", "BEGIN_SCENCE", 70);
   BEGIN_Sx = Kys_ini.ReadInteger("constant", "BEGIN_Sx", 20);
   BEGIN_Sy = Kys_ini.ReadInteger("constant", "BEGIN_Sy", 19);
   SOFTSTAR_BEGIN_TALK = Kys_ini.ReadInteger("constant", "SOFTSTAR_BEGIN_TALK", 2547);
   SOFTSTAR_NUM_TALK = Kys_ini.ReadInteger("constant", "SOFTSTAR_NUM_TALK", 18);
   MAX_PHYSICAL_POWER = Kys_ini.ReadInteger("constant", "MAX_PHYSICAL_POWER", 100);
   BEGIN_WALKPIC = Kys_ini.ReadInteger("constant", "WALK_PIC_OFFSET", 2500);
   MONEY_ID = Kys_ini.ReadInteger("constant", "MONEY_ID", 174);
   COMPASS_ID = Kys_ini.ReadInteger("constant", "COMPASS_ID", 182);
   BEGIN_LEAVE_EVENT = Kys_ini.ReadInteger("constant", "BEGIN_LEAVE_EVENT", 950);
   BEGIN_BATTLE_ROLE_PIC = Kys_ini.ReadInteger("constant", "BEGIN_BATTLE_ROLE_PIC", 2553);
   MAX_LEVEL = Kys_ini.ReadInteger("constant", "MAX_LEVEL", 30);
   MAX_WEAPON_MATCH = Kys_ini.ReadInteger("constant", "MAX_WEAPON_MATCH", 7);
   MIN_KNOWLEDGE = Kys_ini.ReadInteger("constant", "MIN_KNOWLEDGE", 80);
   MAX_HP = Kys_ini.ReadInteger("constant", "MAX_HP", 999);
   MAX_MP = Kys_ini.ReadInteger("constant", "MAX_MP", 999);
   LIFE_HURT = Kys_ini.ReadInteger("constant", "LIFE_HURT", 10);
   NOVEL_BOOK = Kys_ini.ReadInteger("constant", "NOVEL_BOOK", 144);

   for ( i = 43 to 58 do) {
   MAX_PRO_LIST[i] = Kys_ini.ReadInteger("constant", "MAX_PRO_LIST" + inttostr(i), 100);
   }

   finally;
   Kys_ini.Free;
//showmessage(booltostr(fileexists(filename)));
//showmessage(inttostr(max_level));
*/

#endif

void* LoadFile(char* filename, void* buffer, size_t size)
{
	FILE* file = NULL;
	char path[PATH_MAX] = PKGDATADIR "game/";

	if (filename) {
		strcat(path, filename);
		if ((file = fopen(path, "rb"))) {
			if (size == 0) {
				fseek(file, 0, SEEK_END);
				size = ftell(file);
				rewind(file);
			}

			if (buffer == NULL) {
				buffer = malloc(size);
			}

			if (buffer) {
				fread(buffer, size, 1, file);

				fclose(file);
			}
		} else {
			printf("LoadFile: Failed to load \"%s\"\n", path);
			Quit();
		}
	}

	return buffer;
}

//读取必须的文件
void ReadFiles()
{
	LoadFile("mmap.col", g_palette, sizeof(g_palette));

	if (g_mapIdxBuff) {
		free(g_mapIdxBuff);
		g_mapIdxBuff = NULL;
	}
	g_mapIdxBuff = LoadFile("mmap.idx", NULL, 0);
	if (g_mapPicBuff) {
		free(g_mapPicBuff);
		g_mapPicBuff = NULL;
	}
	g_mapPicBuff = LoadFile("mmap.grp", NULL, 0);

	if (g_cmdIdxBuff) {
		free(g_cmdIdxBuff);
		g_cmdIdxBuff = NULL;
	}
	g_cmdIdxBuff = LoadFile("kdef.idx", NULL, 0);
	if (g_cmdGrpBuff) {
		free(g_cmdGrpBuff);
		g_cmdGrpBuff = NULL;
	}
	g_cmdGrpBuff = LoadFile("kdef.grp", NULL, 0);

	if (g_effIdxBuff) {
		free(g_effIdxBuff);
		g_effIdxBuff = NULL;
	}
	g_effIdxBuff = LoadFile("eft.idx", NULL, 0);
	if (g_effectBuff) {
		free(g_effectBuff);
		g_effectBuff = NULL;
	}
	g_effectBuff = LoadFile("eft.grp", NULL, 0);

	if (g_faceIdxBuff) {
		free(g_faceIdxBuff);
		g_faceIdxBuff = NULL;
	}
	g_faceIdxBuff = LoadFile("hdgrp.idx", NULL, 0);
	if (g_facePicBuff) {
		free(g_facePicBuff);
		g_facePicBuff = NULL;
	}
	g_facePicBuff = LoadFile("hdgrp.grp", NULL, 0);

	if (g_talkIdxBuff) {
		free(g_talkIdxBuff);
		g_talkIdxBuff = NULL;
	}
	g_talkIdxBuff = LoadFile("talk.idx", NULL, 0);
	if (g_talkBuff) {
		free(g_talkBuff);
		g_talkBuff = NULL;
	}
	g_talkBuff = LoadFile("talk.grp", NULL, 0);

	LoadFile("earth.002", g_map, sizeof(g_map));

	LoadFile("surface.002", g_ground, sizeof(g_ground));

	LoadFile("building.002", g_building, sizeof(g_building));

	LoadFile("buildx.002", g_buildingX, sizeof(g_buildingX));

	LoadFile("buildy.002", g_buildingY, sizeof(g_buildingY));

	/*
   LoadFile("leave.bin", g_levelupList, sizeof(g_levelupList));

   LoadFile("effect.bin", g_effectList, sizeof(g_effectList));

   LoadFile("levelup.bin", g_levelupList, sizeof(g_levelupList));

   LoadFile("match.bin", g_matchList, sizeof(g_matchList));
   */
}

void UpdateScreen()
{
	SDL_UpdateRect(g_screenSurface, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
}

//显示开头画面
static void Start()
{
	ReadFiles();

	g_fullScreen = FALSE;
	EmMainMenu menu = EmMainMenuNew;

	byte* bigBuffer = NULL;
	uint32* idxBuffer = NULL;
	byte* grpBuffer = NULL;

	bigBuffer = LoadFile("title.big", NULL, 0);
	idxBuffer = LoadFile("title.idx", NULL, 0);
	grpBuffer = LoadFile("title.grp", NULL, 0);

	//DrawRectangle(270, 150, 100, 70, 0, 20);

	UpdateScreen();

	//PlayMp3(1, -1);

	//事件等待
	//SDL_Event event;			//事件
	int key;
	//while (SDL_WaitEvent(&event) >= 0) {
	SDL_EnableKeyRepeat(KEY_REPEAT_DELAY_MENU, KEY_REPEAT_MENU);
	while (TRUE) {
		DrawBigPicOnScreen(0, bigBuffer);
		DrawPicOnScreen(0, 275, 250, idxBuffer, grpBuffer, 0);
		DrawPicOnScreen(menu + 1, 275, 250 + menu * 20, idxBuffer, grpBuffer, 0);
		UpdateScreen();

		key = WaitKey();
		switch (key) {
			case SDLK_RETURN:
			case SDLK_SPACE:
				switch (menu) {
					case EmMainMenuNew:
						LoadGame(0);
						//显示输入姓名的对话框
						//form1.ShowModal;
						//str = form1.edit1.text;
						//str = "請以繁體中文輸入主角之姓名，選定屬性後按Esc              ";
						//name = InputBox("Enter name", str, "我是主角");

						SDL_EnableKeyRepeat(KEY_REPEAT_DELAY_MENU, KEY_REPEAT_MENU);
						while(TRUE) {
							DrawBigPicOnScreen(0, bigBuffer);

							InitialRole();
							ShowStatus(0);

							key = WaitKey();
							if (key == SDLK_y || key == SDLK_ESCAPE) {
								break;
							}
						}

						if (key == SDLK_y) {
							InGame(TRUE);
						}
						break;
					case EmMainMenuLoad: //选择第一项, 读入进度
						DrawBigPicOnScreen(0, bigBuffer);
						//LoadGame(1);
						//******menuloadAtBeginning;
						//****redraw();
						UpdateScreen();
						//***g_curEvent = -1; //when g_curEvent=-1, Draw scence by Sx, Sy. || by g_ex, g_ey.
						//***Walk();
						break;
					case EmMainMenuExit: //如选择第2项, 则退出(所有编号从0开始)
						free(bigBuffer);
						free(idxBuffer);
						free(grpBuffer);
						Quit();
						break;
					default:
						break;
				}
				UpdateScreen();
				break;
			case SDLK_UP: //按下方向键上
				if (menu-- <= 0) menu = EmMainMenuExit;
				break;
			case SDLK_DOWN: //按下方向键下
				if (menu++ >= EmMainMenuExit) menu = 0;
				break;
			default:
				break;
		}
	}
}

sint32 Random(sint32 a, sint32 b)
{
	b++;
	return rand() % (b - a) + a;
}

//初始化主角属性
static void InitialRole()
{
	strcpy(g_hero.name, Utf8ToBig5("江湖小蝦米"));
	g_hero.maxLife = Random(25, 50);
	g_hero.maxNeili = Random(25, 50);
	g_hero.neiliType = Random(0, 2);
	g_hero.incLife = Random(1, 10);
	g_hero.attack = Random(25, 30);
	g_hero.speed = Random(25, 30);
	g_hero.defence = Random(25, 30);
	g_hero.medcine = Random(25, 30);
	g_hero.usePoi = Random(25, 30);
	g_hero.medPoi = Random(25, 30);
	g_hero.fist = Random(25, 30);
	g_hero.sword = Random(25, 30);
	g_hero.blade = Random(25, 30);
	g_hero.unusual = Random(25, 30);
	g_hero.hidWeapon = Random(25, 30);
	g_hero.aptitude = Random(1, 100);

	g_hero.life = g_hero.maxLife;
	g_hero.neili = g_hero.maxNeili;
	g_hero.phyPower = MAX_PHYSICAL_POWER;
}

#if 0

	void UpdateScenceAmi()
		var
		now, next_time: uint32;
	int i = 0;
	{

		next_time=sdl_getticks;
		now=sdl_getticks;
		while true do
		{
			now=sdl_getticks;
			if (now>=next_time)
			{
				LockScence=true;
				for i=0 to 199 do
					if (g_curScenceEventData[ i,6]<>g_curScenceEventData[ i,7])
					{
						if ((g_curScenceEventData[ i,5]<5498) || (g_curScenceEventData[ i,5]>5692))
						{
							g_curScenceEventData[ i,5]=g_curScenceEventData[ i,5]+2;
							if (g_curScenceEventData[ i,5]>g_curScenceEventData[ i,6]) g_curScenceEventData[ i,5]=g_curScenceEventData[ i,7];
							updatescence(g_curScenceEventData[ i,10],g_curScenceEventData[ i,9]);
						}
					}
				//initialscence;
				sdl_delay(10);
				next_time=next_time+200;
				LockScence=false;
			}
		}

	}}

#endif

static void InGame(bool start)
{
	if (start) {
		//InScence(SCENCE_HOME, EmInScenceStart);

		g_mx = g_roleData.scences[SCENCE_HOME].mapEntrance1X;
		g_my = g_roleData.scences[SCENCE_HOME].mapEntrance1Y + 1;
		g_mFace = 1;
	}

	InMap();
}

#if 0
//检查是否有第3类事件, 如有则调用

void CheckEvent3()
	var
	int enum = 0;
{
	enum = g_curScenceData[ 3, Sx, Sy];
	if ((g_curScenceEventData[ enum, 4] > 0) && (enum >= 0))
	{
		g_curEvent = enum;
		WaitKey;
		callevent(g_curScenceEventData[ enum, 4]);
		g_curEvent = -1;
	}
}

//Menus.
//通用选单, (位置(x, y), 宽度, 最大选项(编号均从0开始))
//使用前必须设置选单使用的字符串组才有效, 字符串组不可越界使用

int function CommonMenu(x = 0;
		int  y = 0;
		int  w = 0;
		int max = 0int ) = 0;
var
int   menu = 0;
int menup = 0;
{
	menu = 0;
	//DrawMMap;
	showcommonMenu(x, y, w, max, menu);
	SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > max) menu = 0;
					showcommonMenu(x, y, w, max, menu);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = max;
					showcommonMenu(x, y, w, max, menu);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
				}
				if (((event.key.keysym.sym == sdlk_escape)) && (g_inGame <= 2))
				{
					result = -1;
					ReDraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
					break;
				}
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					result = menu;
					Redraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
					break;
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_right) && (g_inGame <= 2))
				{
					result = -1;
					ReDraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
					break;
				}
				if ((event.button.button == sdl_button_left))
				{
					result = menu;
					Redraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
					break;
				}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= x) && (event.button.x < x + w) && (event.button.y > y) && (event.button.y < y + max * 22 + 29))
				{
					menup = menu;
					menu = (event.button.y - y - 2) / 22;
					if (menu > max) menu = max;
					if (menu < 0) menu = 0;
					if (menup <> menu)
					{
						showcommonMenu(x, y, w, max, menu);
						SDL_UpdateRect(g_screenSurface, x, y, w + 1, max * 22 + 29);
					}
				}
			}
		}
	}
	//清空键盘键和鼠标键值, 避免影响其余部分
	event.key.keysym.sym = 0;
	event.button.button = 0;

}

//显示通用选单(位置, 宽度, 最大值)
//这个通用选单包含两个字符串组, 可分别显示中文和英文

void ShowCommonMenu(x, y, w, max, int menu = 0)()
	var
	int   i = 0;
	int p = 0;
{
	redraw;
	DrawFrameRectangle(x, y, w, max * 22 + 28, 0, COLOR(255), 30);
	if (length(Menuengstring) > 0) p = 1 else p = 0;
	for i = 0 to max do
		if (i == menu)
		{
			drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, COLOR(0x66), COLOR(0x64));
			if (p == 1)
				drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, COLOR(0x66), COLOR(0x64));
		}
		else {
			drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, COLOR(0x7), COLOR(0x5));
			if (p == 1)
				drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, COLOR(0x7), COLOR(0x5));
		}

}

//卷动选单

int function CommonScrollMenu(x = 0;
		int  y = 0;
		int  w = 0;
		int  max = 0;
		int maxshow = 0int ) = 0;
var
int   menu = 0;
int  menup = 0;
int menutop = 0;
{
	menu = 0;
	menutop = 0;
	//DrawMMap;
	showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
	SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu - menutop >= maxshow)
					{
						menutop = menutop + 1;
					}
					if (menu > max)
					{
						menu = 0;
						menutop = 0;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu <= menutop)
					{
						menutop = menu;
					}
					if (menu < 0)
					{
						menu = max;
						menutop = menu - maxshow + 1;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
				if ((event.key.keysym.sym == sdlk_pagedown))
				{
					menu = menu + maxshow;
					menutop = menutop + maxshow;
					if (menu > max)
					{
						menu = max;
					}
					if (menutop > max - maxshow + 1)
					{
						menutop = max - maxshow + 1;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
				if ((event.key.keysym.sym == sdlk_pageup))
				{
					menu = menu - maxshow;
					menutop = menutop - maxshow;
					if (menu < 0)
					{
						menu = 0;
					}
					if (menutop < 0)
					{
						menutop = 0;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
				if (((event.key.keysym.sym == sdlk_escape)) && (g_inGame <= 2))
				{
					result = -1;
					ReDraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
					break;
				}
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					result = menu;
					Redraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
					break;
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_right) && (g_inGame <= 2))
				{
					result = -1;
					ReDraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
					break;
				}
				if ((event.button.button == sdl_button_left))
				{
					result = menu;
					Redraw;
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
					break;
				}
				if ((event.button.button == sdl_button_wheeldown))
				{
					menu = menu + 1;
					if (menu - menutop >= maxshow)
					{
						menutop = menutop + 1;
					}
					if (menu > max)
					{
						menu = 0;
						menutop = 0;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
				if ((event.button.button == sdl_button_wheelup))
				{
					menu = menu - 1;
					if (menu <= menutop)
					{
						menutop = menu;
					}
					if (menu < 0)
					{
						menu = max;
						menutop = menu - maxshow + 1;
					}
					showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
					SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
				}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= x) && (event.button.x < x + w) && (event.button.y > y) && (event.button.y < y + max * 22 + 29))
				{
					menup = menu;
					menu = (event.button.y - y - 2) / 22 + menutop;
					if (menu > max) menu = max;
					if (menu < 0) menu = 0;
					if (menup <> menu)
					{
						showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
						SDL_UpdateRect(g_screenSurface, x, y, w + 1, maxshow * 22 + 29);
					}
				}
			}
		}
	}
	//清空键盘键和鼠标键值, 避免影响其余部分
	event.key.keysym.sym = 0;
	event.button.button = 0;

}


void ShowCommonScrollMenu(x, y, w, max, maxshow, menu, int menutop = 0)()
	var
	int   i = 0;
	int p = 0;
{
	redraw;
	//showmessage(inttostr(y));
	if (max + 1 < maxshow) maxshow = max + 1;
	DrawFrameRectangle(x, y, w, maxshow * 22 + 6, 0, COLOR(255), 30);
	if (length(Menuengstring) > 0) p = 1 else p = 0;
	for i = menutop to menutop + maxshow - 1 do
		if (i == menu)
		{
			drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), COLOR(0x66), COLOR(0x64));
			if (p == 1)
				drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), COLOR(0x66), COLOR(0x64));
		}
		else {
			drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), COLOR(0x7), COLOR(0x5));
			if (p == 1)
				drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), COLOR(0x7), COLOR(0x5));
		}

}
#endif

//仅有两个选项的横排选单, 为美观使用横排
//此类选单中每个选项限制为两个中文字, 仅适用于提问"继续", "取消"的情况

bool ShowYesNoBox(char* boxString[2])
{
	bool yesNo = FALSE;

	char str[TEXT_UTF8_LEN];
	sprintf(str, "%s / %s", boxString[0], boxString[1]);

	bool loop = TRUE;
	SDL_EnableKeyRepeat(KEY_REPEAT_DELAY_MENU, KEY_REPEAT_MENU);
	while (loop) {
		DrawYesNoBox(boxString, yesNo);
		UpdateScreen();

		switch (WaitKey()) {
			case SDLK_RETURN:
			case SDLK_SPACE:
				loop = FALSE;
				break;
			case SDLK_LEFT:
				yesNo = TRUE;
				break;
			case SDLK_RIGHT:
				yesNo = FALSE;
				break;
			default:
				break;
		}

		RedrawWithoutUpdate();
	}

	return yesNo;
}
#if 0

//显示仅有两个选项的横排选单

void ShowCommonMenu2(x, y, w, int menu = 0)()
	var
	int   i = 0;
	int p = 0;
{
	redraw;
	DrawFrameRectangle(x, y, w, 28, 0, COLOR(255), 30);
	//if (length(Menuengstring) > 0) p = 1 else p = 0;
	for i = 0 to 1 do
		if (i == menu)
		{
			drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, COLOR(0x66), COLOR(0x64));
		}
		else {
			drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, COLOR(0x7), COLOR(0x5));
		}

}


//选择一名队员, 可以附带两个属性显示

int function SelectOneTeamMember(x = 0;
		int  int y = 0; str: string; list1 = 0;
		int list2 = 0int ) = 0;
var
int   i = 0;
int amount = 0;
{
	setlength(Menustring, 6);
	if (str <> "") setlength(Menuengstring, 6) else setlength(Menuengstring, 0);
	amount = 0;

	for i = 0 to 5 do
	{
		if (Teamlist[i] >= 0)
		{
			menustring[i] = Big5toUTF8(@RRole[Teamlist[i]].Name);
			if (str <> "")
			{
				menuengstring[i] = format(str, [Rrole[teamlist[i]].data[list1], Rrole[teamlist[i]].data[list2]]);
			}
			amount = amount + 1;
		}
	}
	if (str == "") result = commonmenu(x, y, 85, amount - 1)
	else result = commonmenu(x, y, 85 + length(menuengstring[0]) * 10, amount - 1);

}

//主选单

void MenuEsc()
	var
	int   menu = 0;
	int menup = 0;
{
	menu = 0;
	//DrawMMap;
	showMenu(menu);
	//SDL_EventState(SDL_KEYDOWN,SDL_IGNORE);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		if (g_inGame >= 3)
		{
			break;
		}
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > 5 - g_inGame * 2) menu = 0;
					showMenu(menu);
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = 5 - g_inGame * 2;
					showMenu(menu);
				}
				if ((event.key.keysym.sym == sdlk_escape))
				{
					ReDraw;
					SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					break;
				}
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					switch (menu) {
0: MenuMedcine;
1: MenuMedPoision;
2: MenuItem;
5: MenuSystem;
4: MenuLeave;
3: MenuStatus;
					}
					showmenu(menu);
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if (event.button.button == sdl_button_right)
				{
					ReDraw;
					SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					break;
				}
				if (event.button.button == sdl_button_left)
				{
					if ((event.button.y > 32) && (event.button.y < 32 + 22 * (6 - g_inGame * 2)) && (event.button.x > 27) && (event.button.x < 27 + 46))
					{
						showmenu(menu);
						switch (menu) {
0: MenuMedcine;
1: MenuMedPoision;
2: MenuItem;
5: MenuSystem;
4: MenuLeave;
3: MenuStatus;
						}
						showmenu(menu);
					}
				}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.y > 32) && (event.button.y < 32 + 22 * 6) && (event.button.x > 27) && (event.button.x < 27 + 46))
				{
					menup = menu;
					menu = (event.button.y - 32) / 22;
					if (menu > 5 - g_inGame * 2) menu = 5 - g_inGame * 2;
					if (menu < 0) menu = 0;
					if (menup <> menu) showmenu(menu);
				}
			}

		}
	}
	event.key.keysym.sym = 0;
	event.button.button = 0;

}

//显示主选单

void int ShowMenu(menu = 0)()
	var
	word: array[0..5] of Widestring;
	int   i = 0;
	int max = 0;
{
	Word[0] = " 醫療";
	Word[1] = " 解毒";
	Word[2] = " 物品";
	Word[3] = " 狀態";
	Word[4] = " 離隊";
	Word[5] = " 系統";
	if (g_inGame == 0) max = 5 else max = 3;
	ReDraw;
	DrawFrameRectangle(27, 30, 46, max * 22 + 28, 0, COLOR(255), 30);
	//当前所在位置用白色, 其余用黄色
	for i = 0 to max do
		if (i == menu)
		{
			drawtext(g_screenSurface, @word[i][1], 11, 32 + 22 * i, COLOR(0x64));
			drawtext(g_screenSurface, @word[i][1], 10, 32 + 22 * i, COLOR(0x66));
		}
		else {
			drawtext(g_screenSurface, @word[i][1], 11, 32 + 22 * i, COLOR(0x5));
			drawtext(g_screenSurface, @word[i][1], 10, 32 + 22 * i, COLOR(0x7));
		}
	SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}

//医疗选单, 需两次选择队员

void MenuMedcine()
	var
	int   role1 = 0;
	int  role2 = 0;
	int menu = 0;
str: widestring;
{
	str = " 隊員醫療能力";
	drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
	menu = SelectOneTeamMember(80, 65, "%3d", 46, 0);
	showmenu(0);
	SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	if (menu >= 0)
	{
		role1 = TeamList[menu];
		str = " 隊員目前生命";
		drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
		menu = SelectOneTeamMember(80, 65, "%4d/%4d", 17, 18);
		role2 = TeamList[menu];
		if (menu >= 0)
			EffectMedcine(role1, role2);
	}
	//WaitKey;
	redraw;
	//SDL_UpdateRect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);

}

//解毒选单

void MenuMedPoision()
	var
	int   role1 = 0;
	int  role2 = 0;
	int menu = 0;
str: widestring;
{
	str = " 隊員解毒能力";
	drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
	menu = SelectOneTeamMember(80, 65, "%3d", 48, 0);
	showmenu(1);
	SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	if (menu >= 0)
	{
		role1 = TeamList[menu];
		str = " 隊員中毒程度";
		drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
		menu = SelectOneTeamMember(80, 65, "%3d", 20, 0);
		role2 = TeamList[menu];
		if (menu >= 0)
			EffectMedPoision(role1, role2);
	}
	//WaitKey;
	redraw;
	//showmenu(1);
	//SDL_UpdateRect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);

}

//物品选单

function MenuItem: boolean;
var
int   point = 0;
int  atlu = 0;
int  x = 0;
int  y = 0;
int  col = 0;
int  row = 0;
int  xp = 0;
int  yp = 0;
int  iamount = 0;
int  menu = 0;
int max = 0;
//point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
//col, row为总列数和行数
{
	col = 9;
	row = 5;
	x = 0;
	y = 0;
	atlu = 0;
	setlength(Menuengstring, 0);
	switch (g_inGame) {
		0, 1:
		{
			max = 5;
			setlength(menustring, max + 1);
			menustring[0] = " 全部物品";
			menustring[1] = " 劇情物品";
			menustring[2] = " 神兵寶甲";
			menustring[3] = " 武功秘笈";
			menustring[4] = " 靈丹妙藥";
			menustring[5] = " 傷人暗器";
			menu = commonmenu(80, 30, 87, max);
			if (menu == 0) menu = 101;
			menu = menu - 1;
		}
2:
		{
			max = 1;
			setlength(menustring, max + 1);
			menustring[0] = " 靈丹妙藥";
			menustring[1] = " 傷人暗器";
			menu = commonmenu(150, 150, 87, max);
			if (menu >= 0) menu = menu + 3;
		}
	}

	if (menu < 0) result = false;

	if (menu >= 0)
	{
		iamount = ReadItemList(menu);
		showMenuItem(row, col, x, y, atlu);
		SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		while (SDL_WaitEvent(@event) >= 0) do
		{
			switch (event.type) {
SDL_QUITEV:
				if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
				{
					if ((event.key.keysym.sym == sdlk_down))
					{
						y = y + 1;
						if (y < 0) y = 0;
						if ((y >= row))
						{
							if ((ItemList[atlu + col * row] >= 0)) atlu = atlu + col;
							y = row - 1;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_up))
					{
						y = y - 1;
						if (y < 0)
						{
							y = 0;
							if (atlu > 0) atlu = atlu - col;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_pagedown))
					{
						//y = y + row;
						atlu = atlu + col * row;
						if (y < 0) y = 0;
						if ((ItemList[atlu + col * row] < 0) && (iamount > col * row))
						{
							y = y - (iamount - atlu) / col - 1 + row;
							atlu = (iamount / col - row + 1) * col;
							if (y >= row) y = row - 1;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_pageup))
					{
						//y = y - row;
						atlu = atlu - col * row;
						if (atlu < 0)
						{
							y = y + atlu / col;
							atlu = 0;
							if (y < 0) y = 0;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_right))
					{
						x = x + 1;
						if (x >= col) x = 0;
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_left))
					{
						x = x - 1;
						if (x < 0) x = col - 1;
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.key.keysym.sym == sdlk_escape))
					{
						ReDraw;
						//ShowMenu(2);
						result = false;
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
						break;
					}
					if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
					{
						ReDraw;
						g_usingItem = RItemlist[itemlist[(y * col + x + atlu)]].Number;
						if ((g_inGame <> 2) && (g_usingItem >= 0) && (itemlist[(y * col + x + atlu)] >= 0))
							UseItem(g_usingItem);
						//ShowMenu(2);
						result = true;
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
						break;
					}
				}
SDL_MOUSEBUTTONUP:
				{
					if ((event.button.button == sdl_button_right))
					{
						ReDraw;
						//ShowMenu(2);
						result = false;
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
						break;
					}
					if ((event.button.button == sdl_button_left))
					{
						ReDraw;
						g_usingItem = RItemlist[itemlist[(y * col + x + atlu)]].Number;
						if ((g_inGame <> 2) && (g_usingItem >= 0) && (itemlist[(y * col + x + atlu)] >= 0))
							UseItem(g_usingItem);
						//ShowMenu(2);
						result = true;
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
						break;
					}
					if ((event.button.button == sdl_button_wheeldown))
					{
						y = y + 1;
						if (y < 0) y = 0;
						if ((y >= row))
						{
							if ((ItemList[atlu + col * 5] >= 0)) atlu = atlu + col;
							y = row - 1;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.button.button == sdl_button_wheelup))
					{
						y = y - 1;
						if (y < 0)
						{
							y = 0;
							if (atlu > 0) atlu = atlu - col;
						}
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
				}
SDL_MOUSEMOTION:
				{
					if ((event.button.x >= 110) && (event.button.x < 496) && (event.button.y > 90) && (event.button.y < 308))
					{
						xp = x;
						yp = y;
						x = (event.button.x - 115) / 42;
						y = (event.button.y - 95) / 42;
						if (x >= col) x = col - 1;
						if (y >= row) y = row - 1;
						if (x < 0) x = 0;
						if (y < 0) y = 0;
						//鼠标移动时仅在x, y发生变化时才重画
						if ((x <> xp) || (y <> yp))
						{
							showMenuItem(row, col, x, y, atlu);
							SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
						}
					}
					if ((event.button.x >= 110) && (event.button.x < 496) && (event.button.y > 308))
					{
						//atlu = atlu+col;
						if ((ItemList[atlu + col * 5] >= 0)) atlu = atlu + col;
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
					if ((event.button.x >= 110) && (event.button.x < 496) && (event.button.y < 90))
					{
						if (atlu > 0) atlu = atlu - col;
						showMenuItem(row, col, x, y, atlu);
						SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
					}
				}
			}
		}
	}
	//SDL_UpdateRect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);

}

//读物品列表, 主要是战斗中需屏蔽一部分物品
//利用一个不可能用到的数值（100），表示读取所有物品

function int ReadItemList(ItemType = 0int ) = 0;
var
int   i = 0;
int p = 0;
{
	p = 0;
	for i = 0 to length(ItemList) - 1 do
		ItemList[i] = -1;
	for i = 0 to MAX_ITEM_NUM - 1 do
	{
		if ((RItemlist[i].Number >= 0))
		{
			if ((Ritem[RItemlist[i].Number].ItemType == ItemType) || (ItemType == 100))
			{
				Itemlist[p] = i;
				p = p + 1;
			}
		}
	}
	result = p;

}

//显示物品选单

void ShowMenuItem(row, col, x, y, int atlu = 0)()
	var
	int   item = 0;
	int  i = 0;
	int  i1 = 0;
	int  i2 = 0;
	int  len = 0;
	int  len2 = 0;
	int  len3 = 0;
	int listnum = 0;
str: widestring;
words: array[0..10] of widestring;
words2: array[0..22] of widestring;
words3: array[0..12] of widestring;
p2: array[0..22] of integer;
p3: array[0..12] of integer;
{
	words[0] = " 劇情物品";
	words[1] = " 神兵寶甲";
	words[2] = " 武功秘笈";
	words[3] = " 靈丹妙藥";
	words[4] = " 傷人暗器";
	words2[0] = " 生命"; words2[1] = " 生命"; words2[2] = " 中毒";
	words2[3] = " 體力"; words2[4] = " 內力"; words2[5] = " 內力";
	words2[6] = " 內力"; words2[7] = " 攻擊"; words2[8] = " 輕功";
	words2[9] = " 防禦"; words2[10] = " 醫療"; words2[11] = " 用毒";
	words2[12] = " 解毒"; words2[13] = " 抗毒"; words2[14] = " 拳掌";
	words2[15] = " 御劍"; words2[16] = " 耍刀"; words2[17] = " 特殊";
	words2[18] = " 暗器"; words2[19] = " 武學"; words2[20] = " 品德";
	words2[21] = " 左右"; words2[22] = " 帶毒";

	words3[0] = " 內力"; words3[1] = " 內力"; words3[2] = " 攻擊";
	words3[3] = " 輕功"; words3[4] = " 用毒"; words3[5] = " 醫療";
	words3[6] = " 解毒"; words3[7] = " 拳掌"; words3[8] = " 御劍";
	words3[9] = " 耍刀"; words3[10] = " 特殊"; words3[11] = " 暗器";
	words3[12] = " 資質";


	ReDraw;
	DrawFrameRectangle(110, 30, 386, 25, 0, COLOR(255), 30);
	DrawFrameRectangle(110, 60, 386, 25, 0, COLOR(255), 30);
	DrawFrameRectangle(110, 90, 386, 218, 0, COLOR(255), 30);
	DrawFrameRectangle(110, 313, 386, 25, 0, COLOR(255), 30);
	//i=0;
	for i1 = 0 to row - 1 do
		for i2 = 0 to col - 1 do
		{
			listnum = ItemList[i1 * col + i2 + atlu];
			if ((RItemlist[listnum].Number >= 0) && (listnum < MAX_ITEM_NUM) && (listnum >= 0))
			{
				DrawMapPic(ITEM_BEGIN_PIC + RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95);
			}
		}
	listnum = itemlist[y * col + x + atlu];
	item = RItemlist[listnum].Number;

	if ((RItemlist[listnum].Amount > 0) && (listnum < MAX_ITEM_NUM) && (listnum >= 0))
	{
		str = format("%5d", [RItemlist[listnum].Amount]);
		DrawAlphnumText(g_screenSurface, @str[1], 431, 32, COLOR(0x64));
		DrawAlphnumText(g_screenSurface, @str[1], 430, 32, COLOR(0x66));
		len = length(pchar(@Ritem[item].Name));
		drawbig5text(g_screenSurface, @RItem[item].Name, 296 - len * 5, 32, COLOR(0x21));
		drawbig5text(g_screenSurface, @RItem[item].Name, 295 - len * 5, 32, COLOR(0x23));
		len = length(pchar(@Ritem[item].Introduction));
		drawbig5text(g_screenSurface, @RItem[item].Introduction, 296 - len * 5, 62, COLOR(0x5));
		drawbig5text(g_screenSurface, @RItem[item].Introduction, 295 - len * 5, 62, COLOR(0x7));
		drawshadowtext(@words[Ritem[item].ItemType, 1], 97, 315, COLOR(0x23), COLOR(0x21));
		//如有人使用则显示
		if (RItem[item].User >= 0)
		{
			str = " 使用人：";
			drawshadowtext(@str[1], 187, 315, COLOR(0x23), COLOR(0x21));
			drawbig5shadowtext(@rrole[RItem[item].User].Name, 277, 315, COLOR(0x66), COLOR(0x64));
		}
		//如是罗盘则显示坐标
		if (item == COMPASS_ID)
		{
			str = " 你的位置：";
			drawshadowtext(@str[1], 187, 315, COLOR(0x23), COLOR(0x21));
			str = format("%3d, %3d", [My, Mx]);
			drawengshadowtext(@str[1], 317, 315, COLOR(0x66), COLOR(0x64));
		}
	}


	if ((item >= 0) && (ritem[item].ItemType > 0))
	{
		len2 = 0;
		for i = 0 to 22 do
		{
			p2[i] = 0;
			if ((ritem[item].Data[45 + i] <> 0) && (i <> 4))
			{
				p2[i] = 1;
				len2 = len2 + 1;
			}
		}
		if (ritem[item].ChangeMPType == 2)
		{
			p2[4] = 1;
			len2 = len2 + 1;
		}

		len3 = 0;
		for i = 0 to 12 do
		{
			p3[i] = 0;
			if ((ritem[item].Data[69 + i] <> 0) && (i <> 0))
			{
				p3[i] = 1;
				len3 = len3 + 1;
			}
		}
		if ((ritem[item].NeedMPType in [0, 1]) && (ritem[item].ItemType <> 3))
		{
			p3[0] = 1;
			len3 = len3 + 1;
		}

		if (len2 + len3 > 0)
			DrawFrameRectangle(110, 344, 386, 20 * ((len2 + 2) / 3 + (len3 + 2) / 3) + 5, 0, COLOR(255), 30);

		i1 = 0;
		for i = 0 to 22 do
		{
			if ((p2[i] == 1))
			{
				str = format("%6d", [ritem[item].Data[45 + i]]);
				if (i == 4)
					switch (ritem[item].ChangeMPType) {
0: str = "    陰";
1: str = "    陽";
2: str = "  調和";
					}

				drawshadowtext(@words2[i][1], 97 + i1 mod 3 * 130, i1 / 3 * 20 + 346, COLOR(0x7), COLOR(0x5));
				drawshadowtext(@str[1], 147 + i1 mod 3 * 130, i1 / 3 * 20 + 346, COLOR(0x66), COLOR(0x64));
				i1 = i1 + 1;
			}
		}

		i1 = 0;
		for i = 0 to 12 do
		{
			if ((p3[i] == 1))
			{
				str = format("%6d", [ritem[item].Data[69 + i]]);
				if (i == 0)
					switch (ritem[item].NeedMPType) {
0: str = "    陰";
1: str = "    陽";
2: str = "  調和";
					}

				drawshadowtext(@words3[i][1], 97 + i1 mod 3 * 130, ((len2 + 2) / 3 + i1 / 3) * 20 + 346, COLOR(0x50), COLOR(0x4E));
				drawshadowtext(@str[1], 147 + i1 mod 3 * 130, ((len2 + 2) / 3 + i1 / 3) * 20 + 346, COLOR(0x66), COLOR(0x64));
				i1 = i1 + 1;
			}
		}
	}

	drawItemframe(x, y);

}

//画白色边框作为物品选单的光标

void DrawItemFrame(x, int y = 0)()
	var
	int i = 0;
{
	for i = 0 to 39 do
	{
		putpixel(g_screenSurface, x * 42 + 116 + i, y * 42 + 96, COLOR(255));
		putpixel(g_screenSurface, x * 42 + 116 + i, y * 42 + 96 + 39, COLOR(255));
		putpixel(g_screenSurface, x * 42 + 116, y * 42 + 96 + i, COLOR(255));
		putpixel(g_screenSurface, x * 42 + 116 + 39, y * 42 + 96 + i, COLOR(255));
	}

}

//使用物品

void int UseItem(inum = 0)()
	var
	int   x = 0;
	int  y = 0;
	int  menu = 0;
	int  rnum = 0;
	int p = 0;
	str, str1: widestring;
{
	g_usingItem = inum;

	switch (RItem[inum].ItemType) {
0: //剧情物品
		{
			//如某属性大于0, 直接调用事件
			if (ritem[inum].UnKnow7 > 0)
				callevent(ritem[inum].UnKnow7)
			else {
				if (g_inGame == 1)
				{
					x = Sx;
					y = Sy;
					switch (g_sFace) {
0: x = x - 1;
1: y = y + 1;
2: y = y - 1;
3: x = x + 1;
					}
					//如面向位置有第2类事件则调用
					if (g_curScenceData[ 3, x, y] >= 0)
					{
						g_curEvent = g_curScenceData[ 3, x, y];
						if (g_curScenceEventData[ g_curScenceData[ 3, x, y], 3] >= 0)
							callevent(g_curScenceEventData[ g_curScenceData[ 3, x, y], 3]);
					}
					g_curEvent = -1;
				}
			}
		}
1: //装备
		{
			menu = 1;
			if (Ritem[inum].User >= 0)
			{
				setlength(menustring, 2);
				menustring[0] = " 取消";
				menustring[1] = " 繼續";
				str = " 此物品正有人裝備，是否繼續？";
				drawtextwithrect(@str[1], 80, 30, 285, COLOR(7), COLOR(5));
				menu = commonmenu(80, 65, 45, 1);
			}
			if (menu == 1)
			{
				str = " 誰要裝備";
				str1 = big5toUTF8(@Ritem[inum].Name);
				drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, COLOR(0x23), COLOR(0x21));
				drawshadowtext(@str1[1], 160, 32, COLOR(0x66), COLOR(0x64));
				SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				menu = SelectOneTeamMember(80, 65, "", 0, 0);
				if (menu >= 0)
				{
					rnum = Teamlist[menu];
					p = Ritem[inum].EquipType;
					if ((p < 0) || (p > 1)) p = 0;
					if (canequip(rnum, inum))
					{
						if (Ritem[inum].User >= 0) Rrole[Ritem[inum].User].Equip[p] = -1;
						if (Rrole[rnum].Equip[p] >= 0) Ritem[RRole[rnum].Equip[p]].User = -1;
						Rrole[rnum].Equip[p] = inum;
						Ritem[inum].User = rnum;
					} else
					{
						str = " 此人不適合裝備此物品";
						drawtextwithrect(@str[1], 80, 30, 205, COLOR(0x66), COLOR(0x64));
						WaitKey;
						redraw;
						//SDL_UpdateRect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
					}
				}
			}
		}
2: //秘笈
		{
			menu = 1;
			if (Ritem[inum].User >= 0)
			{
				setlength(menustring, 2);
				menustring[0] = " 取消";
				menustring[1] = " 繼續";
				str = " 此秘笈正有人修煉，是否繼續？";
				drawtextwithrect(@str[1], 80, 30, 285, COLOR(7), COLOR(5));
				menu = commonmenu(80, 65, 45, 1);
			}
			if (menu == 1)
			{
				str = " 誰要修煉";
				str1 = big5toUTF8(@Ritem[inum].Name);
				drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, COLOR(0x23), COLOR(0x21));
				drawshadowtext(@str1[1], 160, 32, COLOR(0x66), COLOR(0x64));
				SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				menu = SelectOneTeamMember(80, 65, "", 0, 0);
				if (menu >= 0)
				{
					rnum = TeamList[menu];
					if (canequip(rnum, inum))
					{
						if (Ritem[inum].User >= 0) Rrole[Ritem[inum].User].PracticeBook = -1;
						if (Rrole[rnum].PracticeBook >= 0) Ritem[RRole[rnum].PracticeBook].User = -1;
						Rrole[rnum].PracticeBook = inum;
						Ritem[inum].User = rnum;
						if ((inum in [78, 93])) rrole[rnum].Sexual = 2;
					} else
					{
						str = " 此人不適合修煉此秘笈";
						drawtextwithrect(@str[1], 80, 30, 205, COLOR(0x66), COLOR(0x64));
						WaitKey;
						redraw;
						//SDL_UpdateRect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
					}
				}
			}
		}
3: //药品
		{
			if (g_inGame <> 2)
			{
				str = " 誰要服用";
				str1 = big5toUTF8(@Ritem[inum].Name);
				drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, COLOR(0x23), COLOR(0x21));
				drawshadowtext(@str1[1], 160, 32, COLOR(0x66), COLOR(0x64));
				SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				menu = SelectOneTeamMember(80, 65, "", 0, 0);
				rnum = TeamList[menu];
			}
			if (menu >= 0)
			{
				redraw;
				EatOneItem(rnum, inum);
				instruct_32(inum, -1);
				WaitKey;
			}
		}
4: //不处理暗器类物品
		{
			//if (g_inGame<>3) break;
		}
	}

}

//能否装备

function CanEquip(rnum, int inum = 0): boolean;
var
int   i = 0;
int r = 0;
{

	//判断是否符合
	//注意这里对"所需属性"为负值时均添加原版类似资质的处理

	result = true;

	if (sign(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP) result = false;
	if (sign(Ritem[inum].NeedAttack) * Rrole[rnum].Attack < Ritem[inum].NeedAttack) result = false;
	if (sign(Ritem[inum].NeedSpeed) * Rrole[rnum].Speed < Ritem[inum].NeedSpeed) result = false;
	if (sign(Ritem[inum].NeedUsePoi) * Rrole[rnum].UsePoi < Ritem[inum].NeedUsepoi) result = false;
	if (sign(Ritem[inum].NeedMedcine) * Rrole[rnum].Medcine < Ritem[inum].NeedMedcine) result = false;
	if (sign(Ritem[inum].NeedMedPoi) * Rrole[rnum].MedPoi < Ritem[inum].NeedMedPoi) result = false;
	if (sign(Ritem[inum].NeedFist) * Rrole[rnum].Fist < Ritem[inum].NeedFist) result = false;
	if (sign(Ritem[inum].NeedSword) * Rrole[rnum].Sword < Ritem[inum].NeedSword) result = false;
	if (sign(Ritem[inum].NeedKnife) * Rrole[rnum].Knife < Ritem[inum].NeedKnife) result = false;
	if (sign(Ritem[inum].NeedUnusual) * Rrole[rnum].Unusual < Ritem[inum].NeedUnusual) result = false;
	if (sign(Ritem[inum].NeedHidWeapon) * Rrole[rnum].HidWeapon < Ritem[inum].NeedHidWeapon) result = false;
	if (sign(Ritem[inum].NeedAptitude) * Rrole[rnum].Aptitude < Ritem[inum].NeedAptitude) result = false;

	//内力性质
	if ((rrole[rnum].MPType < 2) && (Ritem[inum].NeedMPType < 2))
		if (rrole[rnum].MPType <> Ritem[inum].NeedMPType) result = false;

	//如有专用人物, 前面的都作废
	if ((Ritem[inum].OnlyPracRole >= 0) && (result == true))
		if ((Ritem[inum].OnlyPracRole == rnum)) result = true else result = false;

	//如已有10种武功, 且物品也能练出武功, 则结果为假
	r = 0;
	for i = 0 to 9 do
		if (Rrole[rnum].Magic[i] > 0) r = r + 1;
	if ((r >= 10) && (ritem[inum].Magic > 0)) result = false;

	for i = 0 to 9 do
		if (Rrole[rnum].Magic[i] == ritem[inum].Magic)
		{
			result = true;
			break;
		}

}

//查看状态选单
void MenuStatus()
	var
	str: widestring;
	int menu = 0;
{
	str = " 查看隊員狀態";
	drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
	menu = SelectOneTeamMember(80, 65, "%3d", 15, 0);
	if (menu >= 0)
	{
		//******ShowStatus(TeamList[menu]);
		WaitKey;
		redraw;
		SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	}

}
#endif

bool MagicLeveup(int role, int* nextLevelExp)
{
	bool levelup = FALSE;
	*nextLevelExp = MAGIC_NEXT_EXP_NOTHING;
	if (g_hero.practiceBook >= 0)
	{
		int level = 0;
		int magic = g_roleData.items[g_hero.practiceBook].magic;
		if (magic > 0) {
			int i;
			for (i = 0; i < MAGIC_MAX_NUM; i++) {
				if (g_hero.magic[i] == magic)
				{
					level = g_hero.magLevel[i] / 100 + 1;
					break;
				}
			}

			if (level) {
				if (level < MAGIC_MAX_LEVEL) {
					*nextLevelExp = level * g_roleData.items[g_hero.practiceBook].needExp * (7 - g_hero.aptitude / 15);
					if (g_hero.expForBook >= *nextLevelExp && level < 10) {
						levelup = TRUE;
					}
				} else {
					*nextLevelExp = MAGIC_NEXT_EXP_NA;
				}
			}
		}
	}

	return levelup;
}

//显示状态
static void ShowStatus(int role)
{
	DrawFrameRectangle(STATUS_FRAME_X, STATUS_FRAME_Y, STATUS_FRAME_W, STATUS_FRAME_H, 0xff, 0, FRAME_TEXT_ALPHA);

	//显示头像
	DrawFacePic(g_hero.faceIndex, STATUS_FACE_X, STATUS_FACE_Y);

	//显示姓名
	char* big5 = g_hero.name;
	size_t big5Len = strlen(big5);
	char utf8[NAME_UTF8_LEN] = {'\0'};
	size_t utf8Len = NAME_UTF8_LEN;

	char* in = big5;
	char* out = utf8;
	iconv(g_big5ToUtf8, &in, &big5Len, &out, &utf8Len);
	DrawShadowText(utf8, STATUS_NAME_X, STATUS_NAME_Y, TEXT_NORMAL_COLOR);

	//各种属性
	char str[20];
	uint8 color = TEXT_COLOR;
	T_Position pos;

	//第一列
	DrawShadowText("等級", STATUS_TEXT_X(0), STATUS_TEXT_Y(5), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.level);
	DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(5), TEXT_COLOR);

	DrawShadowText("生命", STATUS_TEXT_X(0), STATUS_TEXT_Y(6), TEXT_COLOR);
	if (g_hero.wound > WOUND_FATAL) {
		color = TEXT_FATAL_COLOR;
	} else if (g_hero.wound > WOUND_SERIOUS) {
		color = TEXT_SERIOUS_COLOR;
	} else {
		color = TEXT_NORMAL_COLOR;
	}
	sprintf(str, STATUS_NUM_FORMAT_2, g_hero.life);
	pos = DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(6), color);
	pos = DrawShadowText("/", pos.x, STATUS_TEXT_Y(6), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_2, g_hero.maxLife);
	if (g_hero.poisioning > WOUND_FATAL) {
		color = TEXT_FATAL_COLOR;
	} else if (g_hero.wound > WOUND_SERIOUS) {
		color = TEXT_SERIOUS_COLOR;
	} else {
		color = TEXT_NORMAL_COLOR;
	}
	DrawShadowText(str, pos.x, STATUS_TEXT_Y(6), color);

	DrawShadowText("内力", STATUS_TEXT_X(0), STATUS_TEXT_Y(7), TEXT_COLOR);
	switch (g_hero.neiliType) {
		case EmMPYin:
			color = TEXT_YIN_COLOR;
			break;
		case EmMPYang:
			color = TEXT_YANG_COLOR;
			break;
		case EmMPUnified:
		default:
			color = TEXT_NORMAL_COLOR;
			break;
	}
	sprintf(str, STATUS_NUM_FORMAT_2, g_hero.neili);
	pos = DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(7), color);
	pos = DrawShadowText("/", pos.x, STATUS_TEXT_Y(7), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_2, g_hero.maxNeili);
	DrawShadowText(str, pos.x, STATUS_TEXT_Y(7), color);

	DrawShadowText("體力", STATUS_TEXT_X(0), STATUS_TEXT_Y(8), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_2, g_hero.phyPower);
	pos = DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(8), TEXT_NORMAL_COLOR);
	pos = DrawShadowText("/", pos.x, STATUS_TEXT_Y(8), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_2, MAX_PHYSICAL_POWER);
	DrawShadowText(str, pos.x, STATUS_TEXT_Y(8), TEXT_NORMAL_COLOR);

	DrawShadowText("經驗", STATUS_TEXT_X(0), STATUS_TEXT_Y(9), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.exp);
	DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(9), TEXT_NORMAL_COLOR);

	DrawShadowText("升級", STATUS_TEXT_X(0), STATUS_TEXT_Y(10), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_levelupList[g_hero.level - 1]);
	DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(10), TEXT_NORMAL_COLOR);

	DrawShadowText("資質", STATUS_TEXT_X(0), STATUS_TEXT_Y(13), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.aptitude);
	DrawShadowText(str, STATUS_TEXT_X(1), STATUS_TEXT_Y(13), TEXT_NORMAL_COLOR);

	//第二列
	DrawShadowText("裝備物品", STATUS_TEXT_X(2), STATUS_TEXT_Y(11), TEXT_COLOR);
	T_Item item;
	memset(&item, 0, sizeof(item));
	int i;
	for (i = 0; i < 2; i++) {
		if (g_hero.equip[i] >= 0)
		{
			item.addLife			+= g_roleData.items[g_hero.equip[i]].addLife;
			item.addMaxLife			+= g_roleData.items[g_hero.equip[i]].addMaxLife;
			item.addPoi				+= g_roleData.items[g_hero.equip[i]].addPoi;
			item.addPhyPower		+= g_roleData.items[g_hero.equip[i]].addPhyPower;
			item.changeNeiliType	+= g_roleData.items[g_hero.equip[i]].changeNeiliType;
			item.addNeili			+= g_roleData.items[g_hero.equip[i]].addNeili;
			item.addMaxNeili		+= g_roleData.items[g_hero.equip[i]].addMaxNeili;
			item.addAttack			+= g_roleData.items[g_hero.equip[i]].addAttack;
			item.addSpeed			+= g_roleData.items[g_hero.equip[i]].addSpeed;
			item.addDefence			+= g_roleData.items[g_hero.equip[i]].addDefence;
			item.addMedcine			+= g_roleData.items[g_hero.equip[i]].addMedcine;
			item.addUsePoi			+= g_roleData.items[g_hero.equip[i]].addUsePoi;
			item.addMedPoi			+= g_roleData.items[g_hero.equip[i]].addMedPoi;
			item.addDefPoi			+= g_roleData.items[g_hero.equip[i]].addDefPoi;
			item.addFist			+= g_roleData.items[g_hero.equip[i]].addFist;
			item.addSword			+= g_roleData.items[g_hero.equip[i]].addSword;
			item.addBlade			+= g_roleData.items[g_hero.equip[i]].addBlade;
			item.addUnusual			+= g_roleData.items[g_hero.equip[i]].addUnusual;
			item.addHidWeapon		+= g_roleData.items[g_hero.equip[i]].addHidWeapon;
			item.addKnowledge		+= g_roleData.items[g_hero.equip[i]].addKnowledge;
			item.addEthics			+= g_roleData.items[g_hero.equip[i]].addEthics;
			item.addAttTwice		+= g_roleData.items[g_hero.equip[i]].addAttTwice;
			item.addAttPoi			+= g_roleData.items[g_hero.equip[i]].addAttPoi;

			DrawBig5ShadowText(g_roleData.items[g_hero.equip[i]].name, STATUS_TEXT_X(3), STATUS_TEXT_Y(12 + i), TEXT_NORMAL_COLOR);
		}
	}
	DrawShadowText("攻擊", STATUS_TEXT_X(2), STATUS_TEXT_Y(0), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.attack + item.addAttack);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(0), TEXT_NORMAL_COLOR);

	DrawShadowText("防禦", STATUS_TEXT_X(2), STATUS_TEXT_Y(1), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.defence + item.addDefence);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(1), TEXT_NORMAL_COLOR);

	DrawShadowText("輕功", STATUS_TEXT_X(2), STATUS_TEXT_Y(2), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.speed + item.addSpeed);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(2), TEXT_NORMAL_COLOR);

	DrawShadowText("醫療能力", STATUS_TEXT_X(2), STATUS_TEXT_Y(3), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.medcine + item.addMedcine);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(3), TEXT_NORMAL_COLOR);

	DrawShadowText("用毒能力", STATUS_TEXT_X(2), STATUS_TEXT_Y(4), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.usePoi + item.addUsePoi);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(4), TEXT_NORMAL_COLOR);

	DrawShadowText("解毒能力", STATUS_TEXT_X(2), STATUS_TEXT_Y(5), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.medPoi + item.addMedPoi);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(5), TEXT_NORMAL_COLOR);

	DrawShadowText("拳掌功夫", STATUS_TEXT_X(2), STATUS_TEXT_Y(6), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.fist + item.addFist);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(6), TEXT_NORMAL_COLOR);

	DrawShadowText("御劍能力", STATUS_TEXT_X(2), STATUS_TEXT_Y(7), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.sword + item.addSword);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(7), TEXT_NORMAL_COLOR);

	DrawShadowText("耍刀技巧", STATUS_TEXT_X(2), STATUS_TEXT_Y(8), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.blade + item.addBlade);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(8), TEXT_NORMAL_COLOR);

	DrawShadowText("特殊兵器", STATUS_TEXT_X(2), STATUS_TEXT_Y(9), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.unusual + item.addUnusual);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(9), TEXT_NORMAL_COLOR);

	DrawShadowText("暗器技巧", STATUS_TEXT_X(2), STATUS_TEXT_Y(10), TEXT_COLOR);
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.hidWeapon + item.addHidWeapon);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(10), TEXT_NORMAL_COLOR);

	DrawShadowText("受傷", STATUS_TEXT_X(2), STATUS_TEXT_Y(13), TEXT_COLOR);
	if (g_hero.wound > WOUND_FATAL) {
		color = TEXT_FATAL_COLOR;
	} else if (g_hero.wound > WOUND_SERIOUS) {
		color = TEXT_SERIOUS_COLOR;
	} else {
		color = TEXT_NORMAL_COLOR;
	}
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.wound);
	DrawShadowText(str, STATUS_TEXT_X(3), STATUS_TEXT_Y(13), color);

	//第三列
	DrawShadowText("所會武功", STATUS_TEXT_X(4), STATUS_TEXT_Y(0), TEXT_COLOR);
	for (i = 0; i < 10; i++) {
		int magic = g_hero.magic[i];
		if (magic > 0)
		{
			DrawBig5ShadowText(g_roleData.magics[magic].name, STATUS_TEXT_X(4), STATUS_TEXT_Y(i + 1), TEXT_NORMAL_COLOR);
			sprintf(str, STATUS_NUM_FORMAT_1, g_hero.magLevel[i] / 100 + 1);
			DrawShadowText(str, STATUS_TEXT_X(5), STATUS_TEXT_Y(i + 1), TEXT_NORMAL_COLOR);
		}
	}

	DrawShadowText("修煉物品", STATUS_TEXT_X(4), STATUS_TEXT_Y(11), TEXT_COLOR);
	int nextLevelExp = MAGIC_NEXT_EXP_NOTHING;
	MagicLeveup(role, &nextLevelExp);
	switch (nextLevelExp) {
		case MAGIC_NEXT_EXP_NOTHING:
			break;
		case MAGIC_NEXT_EXP_NA:
			sprintf(str, STATUS_NUM_FORMAT_2, g_hero.expForBook);
			pos = DrawShadowText(str, STATUS_TEXT_X(5), STATUS_TEXT_Y(11), TEXT_NORMAL_COLOR);
			pos = DrawShadowText("/", pos.x, STATUS_TEXT_Y(11), TEXT_COLOR);
			DrawShadowText("=", pos.x, STATUS_TEXT_Y(11), TEXT_NORMAL_COLOR);
			break;
		default:
			sprintf(str, STATUS_NUM_FORMAT_2, g_hero.expForBook);
			pos = DrawShadowText(str, STATUS_TEXT_X(5), STATUS_TEXT_Y(11), TEXT_NORMAL_COLOR);
			pos = DrawShadowText("/", pos.x, STATUS_TEXT_Y(11), TEXT_COLOR);
			sprintf(str, STATUS_NUM_FORMAT_2, nextLevelExp);
			DrawShadowText(str, pos.x, STATUS_TEXT_Y(11), TEXT_NORMAL_COLOR);
			break;
	}

	DrawShadowText("中毒", STATUS_TEXT_X(4), STATUS_TEXT_Y(13), TEXT_COLOR);
	if (g_hero.poisioning > WOUND_FATAL) {
		color = TEXT_FATAL_COLOR;
	} else if (g_hero.wound > WOUND_SERIOUS) {
		color = TEXT_SERIOUS_COLOR;
	} else {
		color = TEXT_NORMAL_COLOR;
	}
	sprintf(str, STATUS_NUM_FORMAT_1, g_hero.poisioning);
	DrawShadowText(str, STATUS_TEXT_X(5), STATUS_TEXT_Y(13), color);

	UpdateScreen();
}
#if 0

//离队选单

void MenuLeave()
	var
	str: widestring;
	int   i = 0;
	int menu = 0;
{
	str = " 要求誰離隊？";
	drawtextwithrect(@str[1], 80, 30, 132, COLOR(0x23), COLOR(0x21));
	menu = SelectOneTeamMember(80, 65, "%3d", 15, 0);
	if (menu >= 0)
	{
		for i = 0 to 99 do
			if (g_leaveList[i] == TeamList[menu])
			{
				callevent(BEGIN_LEAVE_EVENT + i * 2);
				break;
			}
	}
	redraw;

}

//系统选单

void MenuSystem()
	var
	int   i = 0;
	int  menu = 0;
	int menup = 0;
{
	menu = 0;
	showmenusystem(menu);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		if (g_inGame == 3) break;
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > 3) menu = 0;
					showMenusystem(menu);
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = 3;
					showMenusystem(menu);
				}
				if ((event.key.keysym.sym == sdlk_escape))
				{
					redraw;
					SDL_UpdateRect(g_screenSurface, 80, 30, 47, 95);
					break;
				}
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					switch (menu) {
3:
						{
							MenuQuit;
						}
1:
						{
							MenuSave;
						}
0:
						{
							Menuload;
						}
2:
						{
							if (g_fullScreen == 1)
								g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_SWSURFACE || SDL_DOUBLEBUF || SDL_ANYFORMAT)
							else
								g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_FULLSCREEN);
							g_fullScreen = 1 - g_fullScreen;
							break;
						}
					}
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_right))
				{
					redraw;
					SDL_UpdateRect(g_screenSurface, 80, 30, 47, 95);
					break;
				}
				if ((event.button.button == sdl_button_left))
					switch (menu) {
3:
						{
							MenuQuit;
						}
1:
						{
							MenuSave;
						}
0:
						{
							Menuload;
						}
2:
						{
							if (g_fullScreen == 1)
								g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_SWSURFACE || SDL_DOUBLEBUF || SDL_ANYFORMAT)
							else
								g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_FULLSCREEN);
							g_fullScreen = 1 - g_fullScreen;
							break;
						}
					}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= 80) && (event.button.x < 127) && (event.button.y > 47) && (event.button.y < 120))
				{
					menup = menu;
					menu = (event.button.y - 32) / 22;
					if (menu > 3) menu = 3;
					if (menu < 0) menu = 0;
					if (menup <> menu) showMenusystem(menu);
				}
			}
		}
	}

}

//显示系统选单

void int ShowMenuSystem(menu = 0)()
	var
	word: array[0..3] of Widestring;
	int i = 0;
{
	Word[0] = " 讀取";
	Word[1] = " 存檔";
	Word[2] = " 全屏";
	Word[3] = " 離開";
	if (g_fullScreen == 1) Word[2] = " 窗口";
	ReDraw;
	DrawFrameRectangle(80, 30, 46, 92, 0, COLOR(255), 30);
	for i = 0 to 3 do
		if (i == menu)
		{
			drawtext(g_screenSurface, @word[i][1], 64, 32 + 22 * i, COLOR(0x64));
			drawtext(g_screenSurface, @word[i][1], 63, 32 + 22 * i, COLOR(0x66));
		}
		else {
			drawtext(g_screenSurface, @word[i][1], 64, 32 + 22 * i, COLOR(0x5));
			drawtext(g_screenSurface, @word[i][1], 63, 32 + 22 * i, COLOR(0x7));
		}
	SDL_UpdateRect(g_screenSurface, 80, 30, 47, 93);

}

//读档选单

void MenuLoad()
	var
	int menu = 0;
{
	setlength(menustring, 5);
	setlength(Menuengstring, 0);
	menustring[0] = " 進度一";
	menustring[1] = " 進度二";
	menustring[2] = " 進度三";
	menustring[3] = " 進度四";
	menustring[4] = " 進度五";
	menu = commonmenu(133, 30, 67, 4);
	if (menu >= 0)
	{
		LoadGame(menu + 1);
		Redraw;
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		ShowMenu(5);
		ShowMenusystem(0);
	}

}

//特殊的读档选单, 仅用在开始时读档

void MenuLoadAtBeginning()
	var
	int menu = 0;
{
	Redraw;
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	setlength(menustring, 5);
	setlength(Menuengstring, 0);
	menustring[0] = " 載入進度一";
	menustring[1] = " 載入進度二";
	menustring[2] = " 載入進度三";
	menustring[3] = " 載入進度四";
	menustring[4] = " 載入進度五";
	menu = commonmenu(265, 190, 107, 4);
	if (menu >= 0)
	{
		LoadGame(menu + 1);
		g_inGame = 0;
		Redraw;
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	}

}

//存档选单

void MenuSave()
	var
	int menu = 0;
{
	setlength(menustring, 5);
	menustring[0] = " 進度一";
	menustring[1] = " 進度二";
	menustring[2] = " 進度三";
	menustring[3] = " 進度四";
	menustring[4] = " 進度五";
	menu = commonmenu(133, 30, 67, 4);
	if (menu >= 0) SaveGame(menu + 1);

}

//退出选单

void MenuQuit()
	var
	int menu = 0;
{
	setlength(menustring, 2);
	menustring[0] = " 取消";
	menustring[1] = " 確定";
	menu = commonmenu(133, 30, 45, 1);
	if (menu == 1)
	{
		Quit;
	}

}

//医疗的效果
//未添加体力的需求与消耗

void EffectMedcine(role1, int role2 = 0)()
	var
	word: widestring;
	int addlife = 0;
{
	addlife = Rrole[role1].Medcine * (10 - Rrole[role2].Hurt / 15) / 10;
	if (Rrole[role2].Hurt - Rrole[role1].Medcine > 20) addlife = 0;
	Rrole[role2].Hurt = Rrole[role2].Hurt - addlife / LIFE_HURT;
	if (RRole[role2].Hurt < 0) RRole[role2].Hurt = 0;
	if (addlife > RRole[role2].MaxHP - Rrole[role2].CurrentHP) addlife = RRole[role2].MaxHP - Rrole[role2].CurrentHP;
	Rrole[role2].CurrentHP = Rrole[role2].CurrentHP + addlife;
	DrawFrameRectangle(115, 98, 145, 51, 0, COLOR(255), 30);
	word = " 增加生命";
	drawshadowtext(@word[1], 100, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[role2].Name, 100, 100, COLOR(0x23), COLOR(0x21));
	word = format("%3d", [addlife]);
	drawengshadowtext(@word[1], 220, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;

}

//解毒的效果

void EffectMedPoision(role1, int role2 = 0)()
	var
	word: widestring;
	int minuspoi = 0;
{
	minuspoi = Rrole[role1].MedPoi;
	if (minuspoi > Rrole[role2].Poision) minuspoi = Rrole[role2].Poision;
	Rrole[role2].Poision = Rrole[role2].Poision - minuspoi;
	DrawFrameRectangle(115, 98, 145, 51, 0, COLOR(255), 30);
	word = " 中毒減少";
	drawshadowtext(@word[1], 100, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[role2].Name, 100, 100, COLOR(0x23), COLOR(0x21));
	word = format("%3d", [minuspoi]);
	drawengshadowtext(@word[1], 220, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;

}

//使用物品的效果
//练成秘笈的效果

void EatOneItem(rnum, int inum = 0)()
	var
	int   i = 0;
	int  p = 0;
	int  l = 0;
	int  x = 0;
	int y = 0;
word: array[0..23] of widestring;
addvalue, rolelist: array[0..23] of integer;
str: widestring;
{

	word[0] = " 增加生命"; word[1] = " 增加生命最大值"; word[2] = " 中毒程度";
	word[3] = " 增加體力"; word[4] = " 內力門路陰陽合一"; word[5] = " 增加內力";
	word[6] = " 增加內力最大值"; word[7] = " 增加攻擊力"; word[8] = " 增加輕功";
	word[9] = " 增加防禦力"; word[10] = " 增加醫療能力"; word[11] = " 增加用毒能力";
	word[12] = " 增加解毒能力"; word[13] = " 增加抗毒能力"; word[14] = " 增加拳掌能力";
	word[15] = " 增加御劍能力"; word[16] = " 增加耍刀能力"; word[17] = " 增加特殊兵器";
	word[18] = " 增加暗器技巧"; word[19] = " 增加武學常識"; word[20] = " 增加品德指數";
	word[21] = " 習得左右互搏"; word[22] = " 增加攻擊帶毒"; word[23] = " 受傷程度";
	rolelist[0] = 17; rolelist[1] = 18; rolelist[2] = 20; rolelist[3] = 21;
	rolelist[4] = 40; rolelist[5] = 41; rolelist[6] = 42; rolelist[7] = 43;
	rolelist[8] = 44; rolelist[9] = 45; rolelist[10] = 46; rolelist[11] = 47;
	rolelist[12] = 48; rolelist[13] = 49; rolelist[14] = 50; rolelist[15] = 51;
	rolelist[16] = 52; rolelist[17] = 53; rolelist[18] = 54; rolelist[19] = 55;
	rolelist[20] = 56; rolelist[21] = 58; rolelist[22] = 57; rolelist[23] = 19;
	//rolelist=(17,18,20,21,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,58,57);
	for i = 0 to 22 do
	{
		addvalue[i] = Ritem[inum].data[45 + i];
	}
	//减少受伤
	addvalue[23] = -(addvalue[0] / LIFE_HURT);

	if (- addvalue[23] > rrole[rnum].data[19]) addvalue[23] = -rrole[rnum].data[19];

	//增加生命, 内力最大值的处理
	if (addvalue[1] + rrole[rnum].data[18] > MAX_HP)
		addvalue[1] = MAX_HP - rrole[rnum].data[18];
	if (addvalue[6] + rrole[rnum].data[42] > MAX_MP)
		addvalue[6] = MAX_MP - rrole[rnum].data[42];
	if (addvalue[1] + rrole[rnum].data[18] < 0)
		addvalue[1] = -rrole[rnum].data[18];
	if (addvalue[6] + rrole[rnum].data[42] < 0)
		addvalue[6] = -rrole[rnum].data[42];

	for i = 7 to 22 do
	{
		if (addvalue[i] + rrole[rnum].data[rolelist[i]] > MAX_PRO_LIST[rolelist[i]])
			addvalue[i] = MAX_PRO_LIST[rolelist[i]] - rrole[rnum].data[rolelist[i]];
		if (addvalue[i] + rrole[rnum].data[rolelist[i]] < 0)
			addvalue[i] = -rrole[rnum].data[rolelist[i]];
	}
	//生命不能超过最大值
	if (addvalue[0] + rrole[rnum].data[17] > addvalue[1] + rrole[rnum].data[18])
		addvalue[0] = addvalue[1] + rrole[rnum].data[18] - rrole[rnum].data[17];
	//中毒不能小于0
	if (addvalue[2] + rrole[rnum].data[20] < 0) addvalue[2] = -rrole[rnum].data[20];
	//体力不能超过100
	if (addvalue[3] + rrole[rnum].data[21] > MAX_PHYSICAL_POWER) addvalue[3] = MAX_PHYSICAL_POWER - rrole[rnum].data[21];
	//内力不能超过最大值
	if (addvalue[5] + rrole[rnum].data[41] > addvalue[6] + rrole[rnum].data[42])
		addvalue[5] = addvalue[6] + rrole[rnum].data[42] - rrole[rnum].data[41];
	p = 0;
	for i = 0 to 23 do
	{
		if ((i <> 4) && (i <> 21) && (addvalue[i] <> 0)) p = p + 1;
	}
	if ((addvalue[4] == 2) && (rrole[rnum].data[40] <> 2)) p = p + 1;
	if ((addvalue[21] == 1) && (rrole[rnum].data[58] <> 1)) p = p + 1;

	ShowSimpleStatus(rnum, 350, 50);
	DrawFrameRectangle(100, 70, 200, 25, 0, COLOR(255), 25);
	str = " 服用";
	if (Ritem[inum].ItemType == 2) str = " 練成";
	Drawshadowtext(@str[1], 83, 72, COLOR(0x23), COLOR(0x21));
	Drawbig5shadowtext(@Ritem[inum].Name, 143, 72, COLOR(0x66), COLOR(0x64));

	//如果增加的项超过11个, 分两列显示
	if (p < 11)
	{
		l = p;
		DrawFrameRectangle(100, 100, 200, 22 * l + 25, 0, COLOR(0xFF), 25);
	} else
	{
		l = p / 2 + 1;
		DrawFrameRectangle(100, 100, 400, 22 * l + 25, 0, COLOR(0xFF), 25);
	}
	drawbig5shadowtext(@rrole[rnum].data[4], 83, 102, COLOR(0x23), COLOR(0x21));
	str = " 未增加屬性";
	if (p == 0) drawshadowtext(@str[1], 163, 102, COLOR(7), COLOR(5));
	p = 0;
	for i = 0 to 23 do
	{
		if (p < l)
		{
			x = 0;
			y = 0;
		} else
		{
			x = 200;
			y = -l * 22;
		}
		if ((i <> 4) && (i <> 21) && (addvalue[i] <> 0))
		{
			rrole[rnum].data[rolelist[i]] = rrole[rnum].data[rolelist[i]] + addvalue[i];
			drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, COLOR(7), COLOR(5));
			str = format("%4d", [addvalue[i]]);
			drawengshadowtext(@str[1], 243 + x, 124 + y + p * 22, COLOR(0x66), COLOR(0x64));
			p = p + 1;
		}
		//对内力性质特殊处理
		if ((i == 4) && (addvalue[i] == 2))
		{
			if (rrole[rnum].data[rolelist[i]] <> 2)
			{
				rrole[rnum].data[rolelist[i]] = 2;
				drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, COLOR(7), COLOR(5));
				p = p + 1;
			}
		}
		//对左右互搏特殊处理
		if ((i == 21) && (addvalue[i] == 1))
		{
			if (rrole[rnum].data[rolelist[i]] <> 1)
			{
				rrole[rnum].data[rolelist[i]] = 1;
				drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, COLOR(7), COLOR(5));
				p = p + 1;
			}
		}
	}
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}


void EndAmi()
	var
	int   x = 0;
	int  y = 0;
	int  i = 0;
	int len = 0;
str: WideString;
int p = 0;
{
	instruct_14;
	redraw;
	i = fileopen("}.txt", fmOpenRead);
	len = fileseek(i, 0, 2);
	fileseek(i, 0, 0);
	setlength(str, len + 1);
	fileread(i, str[1], len);
	fileclose(i);
	p = 1;
	x = 30;
	y = 80;
	DrawRectangle(0, 50, SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2 - 100, 0, 60);
	for i = 1 to len + 1 do
	{
		if (str[i] == widechar(10)) str[i] = " ";
		if (str[i] == widechar(13))
		{
			str[i] = widechar(0);
			drawshadowtext(@str[p], x, y, COLOR(0xFF), COLOR(0xFF));
			p = i + 1;
			y = y + 25;
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		}
		if (str[i] == widechar(0x2A))
		{
			str[i] = " ";
			y = 80;
			redraw;
			WaitKey;
			DrawRectangle(0, 50, SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2 - 100, 0, 60);
		}
	}
	WaitKey;
	instruct_14;

}

//Battle.
//战斗, 返回值为是否胜利

function Battle(battlenum, int getexp = 0): boolean;
var
int   i = 0;
int  SelectTeamList = 0;
int  x = 0;
int y = 0;
{
	Bstatus = 0;
	CurrentBattle = battlenum;
	if (InitialBField)
	{
		//如果未发现自动战斗设定, 则选择人物
		SelectTeamList = SelectTeamMembers;
		for i = 0 to 5 do
		{
			y = warsta[21 + i];
			x = warsta[27 + i];
			if (SelectTeamList && (1 shl i) > 0)
			{
				Brole[BRoleAmount].rnum = TeamList[i];
				Brole[BRoleAmount].Team = 0;
				Brole[BRoleAmount].Y = y;
				Brole[BRoleAmount].X = x;
				Brole[BRoleAmount].Face = 2;
				Brole[BRoleAmount].Dead = 0;
				Brole[BRoleAmount].Step = 0;
				Brole[BRoleAmount].Acted = 0;
				Brole[BRoleAmount].ExpGot = 0;
				Brole[BRoleAmount].Auto = 0;
				BRoleAmount = BRoleAmount + 1;
			}
		}
		for i = 0 to 5 do
		{
			y = warsta[21 + i] + 1;
			x = warsta[27 + i];
			if ((warsta[9 + i] > 0) && (instruct_16(warsta[9 + i], 1, 0) == 0))
			{
				Brole[BRoleAmount].rnum = warsta[9 + i];
				Brole[BRoleAmount].Team = 0;
				Brole[BRoleAmount].Y = y;
				Brole[BRoleAmount].X = x;
				Brole[BRoleAmount].Face = 2;
				Brole[BRoleAmount].Dead = 0;
				Brole[BRoleAmount].Step = 0;
				Brole[BRoleAmount].Acted = 0;
				Brole[BRoleAmount].ExpGot = 0;
				Brole[BRoleAmount].Auto = 0;
				BRoleAmount = BRoleAmount + 1;
			}
		}
	}
	instruct_14;
	g_inGame = 2;
	initialwholeBfield; //初始化场景
	stopMP3;
	playmp3(warsta[8], -1);
	BattleMainControl;

	RestoreRoleStatus;

	if ((bstatus == 1) || ((bstatus == 2) && (getexp <> 0)))
	{
		AddExp;
		CheckLevelUp;
		CheckBook;
	}

	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

	if (Rscence[g_curScence].EntranceMusic >= 0)
	{
		stopmp3;
		playmp3(Rscence[g_curScence].EntranceMusic, -1);
	}

	g_inGame = EmInGameScence;
	if (bstatus == 1) result = true
	else result = false;

}

//选择人物, 返回值为整型, 按bit表示人物是否参战

function int SelectTeamMembers = 0;
var
int   i = 0;
int  menu = 0;
int  max = 0;
int menup = 0;
{
	result = 0;
	max = 0;
	menu = 0;
	setlength(menustring, 7);
	for i = 0 to 5 do
	{
		if (Teamlist[i] >= 0)
		{
			menustring[i] = Big5toUTF8(@RRole[Teamlist[i]].Name);
			max = max + 1;
		}
	}
	menustring[max] = "    開始戰鬥";
	ShowMultiMenu(max, 0, 0);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if (((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space)) && (menu <> max))
				{
					//选中人物则反转对应bit
					result = result xor (1 shl menu);
					ShowMultiMenu(max, menu, result);
				}
				if (((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space)) && (menu == max))
				{
					if (result <> 0) break;
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = max;
					ShowMultiMenu(max, menu, result);
				}
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > max) menu = 0;
					ShowMultiMenu(max, menu, result);
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_left) && (menu <> max))
				{
					result = result xor (1 shl menu);
					ShowMultiMenu(max, menu, result);
				}
				if ((event.button.button == sdl_button_left) && (menu == max))
				{
					if (result <> 0) break;
				}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= SCREEN_CENTER_X - 75) && (event.button.x < SCREEN_CENTER_X + 75) && (event.button.y >= 150) && (event.button.y < max * 22 + 178))
				{
					menup = menu;
					menu = (event.button.y - 152) / 22;
					if (menup <> menu) ShowMultiMenu(max, menu, result);
				}
			}
		}
	}

}

//显示选择参战人物选单

void ShowMultiMenu(max, menu, int status = 0)()
	var
	int   i = 0;
	int  x = 0;
	int y = 0;
	str, str1, str2: widestring;
{
	x = SCREEN_CENTER_X - 105;
	y = 150;
	ReDraw;
	str = " 選擇參與戰鬥之人物";
	str1 = " 參戰";
	//Drawtextwithrect(@str[1],x,y-35,200,COLOR(0x23),COLOR(0x21));
	DrawFrameRectangle(x + 30, y, 150, max * 22 + 28, 0, COLOR(255), 30);
	for i = 0 to max do
		if (i == menu)
		{
			drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, COLOR(0x66), COLOR(0x64));
			if ((status && (1 shl i)) > 0)
				drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, COLOR(0x66), COLOR(0x64));
		}
		else {
			drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, COLOR(0x7), COLOR(0x5));
			if ((status && (1 shl i)) > 0)
				drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, COLOR(0x23), COLOR(0x21));
		}
	sdl_updaterect(g_screenSurface, x + 30, y, 151, max * 22 + 28 + 1);
}

//Structure of Bfield arrays:
//0: Ground; 1: g_building; 2: Roles(Rrnum);

//Structure of Brole arrays:
//the 1st pointer is "Battle Num";
//The 2nd: 0: rnum, 1: Friend || enemy, 2: y, 3: x, 4: Face, 5: Dead || alive,
//         7: Acted, 8: Pic Num, 9: The number, 10, 11, 12: Auto, 13: Exp gotten.
//初始化战场

function InitialBField: boolean;
var
int   sta = 0;
int  grp = 0;
int  idx = 0;
int  offset = 0;
int  i = 0;
int  i1 = 0;
int  i2 = 0;
int  x = 0;
int  y = 0;
int fieldnum = 0;
{
	sta = fileopen("war.sta", fmopenread);
	offset = currentbattle * 0xBA;
	fileseek(sta, offset, 0);
	fileread(sta, warsta, 0xBA);
	fileclose(sta);
	fieldnum = warsta[6];
	if (fieldnum == 0) offset = 0
	else {
		idx = fileopen("warfld.idx", fmopenread);
		fileseek(idx, (fieldnum - 1) * 4, 0);
		fileread(idx, offset, 4);
		fileclose(idx);
	}
	grp = fileopen("warfld.grp", fmopenread);
	fileseek(grp, offset, 0);
	fileread(grp, Bfield[0, 0, 0], 2 * 64 * 64 * 2);
	fileclose(grp);
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
			Bfield[2, i1, i2] = -1;
	BRoleAmount = 0;
	result = true;
	//我方自动参战数据
	for i = 0 to 5 do
	{
		y = warsta[21 + i];
		x = warsta[27 + i];
		if (warsta[15 + i] >= 0)
		{
			Brole[BRoleAmount].rnum = warsta[15 + i];
			Brole[BRoleAmount].Team = 0;
			Brole[BRoleAmount].Y = y;
			Brole[BRoleAmount].X = x;
			Brole[BRoleAmount].Face = 2;
			Brole[BRoleAmount].Dead = 0;
			Brole[BRoleAmount].Step = 0;
			Brole[BRoleAmount].Acted = 0;
			Brole[BRoleAmount].ExpGot = 0;
			Brole[BRoleAmount].Auto = 0;
			BRoleAmount = BRoleAmount + 1;
		}
	}
	//如没有自动参战人物, 返回假, 激活选择人物
	if (BRoleAmount > 0) result = False;
	for i = 0 to 19 do
	{
		y = warsta[53 + i];
		x = warsta[73 + i];
		if (warsta[33 + i] >= 0)
		{
			Brole[BRoleAmount].rnum = warsta[33 + i];
			Brole[BRoleAmount].Team = 1;
			Brole[BRoleAmount].Y = y;
			Brole[BRoleAmount].X = x;
			Brole[BRoleAmount].Face = 1;
			Brole[BRoleAmount].Dead = 0;
			Brole[BRoleAmount].Step = 0;
			Brole[BRoleAmount].Acted = 0;
			Brole[BRoleAmount].ExpGot = 0;
			Brole[BRoleAmount].Auto = 0;
			BRoleAmount = BRoleAmount + 1;
		}
	}

}

//画战场

void DrawWholeBField()
	var
	int   i = 0;
	int  i1 = 0;
	int i2 = 0;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}
	DrawBFieldWithoutRole(Bx, By);

	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			if ((Bfield[2, i1, i2] >= 0) && (Brole[Bfield[2, i1, i2]].Dead == 0))
				DrawRoleOnBfield(i1, i2);
		}
	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}
}

//画战场上人物, 需更新人物身前的遮挡

void DrawRoleOnBfield(x, int y = 0)()
	var
	int   i1 = 0;
	int  i2 = 0;
	int  xpoint = 0;
	int ypoint = 0;
	pos, pos1: Tposition;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}

	pos = GetMapScenceXYPos(x, y, Bx, By);
	for i1 = x - 1 to x + 10 do
		for i2 = y - 1 to y + 10 do
		{
			if ((i1 == x) && (i2 == y))
				DrawBFPic(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0);

			if ((Bfield[1, i1, i2] > 0))
			{
				pos1 = GetMapScenceXYPos(i1, i2, Bx, By);
				DrawBFPicInRect(Bfield[1, i1, i2] / 2, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
				if ((Bfield[2, i1, i2] >= 0) && (Brole[Bfield[2, i1, i2]].Dead == 0))
					DrawBFPicInRect(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, i1, i2]].Face + BEGIN_BATTLE_ROLE_PIC, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
			}
		}

	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}

}

//初始化战场映像

void InitialWholeBField()
	var
	int   i1 = 0;
	int  i2 = 0;
	int  x = 0;
	int y = 0;
{
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			x = -i1 * 18 + i2 * 18 + 1151;
			y = i1 * 9 + i2 * 9 + 9;
			if ((i1 < 0) || (i2 < 0) || (i1 > 63) || (i2 > 63)) DrawPicToBFPic(0, x, y)
			else {
				DrawPicToBFPic(bfield[0, i1, i2] / 2, x, y);
				if ((bfield[1, i1, i2] > 0))
					DrawPicToBFPic(bfield[1, i1, i2] / 2, x, y);
			}
		}

}

//战斗主控制

void BattleMainControl()
	var
	int i = 0;
{
	//redraw;
	//战斗未分出胜负则继续
	while BStatus == 0 do
	{
		CalMoveAbility; //计算移动能力
		ReArrangeBRole; //排列角色顺序

		ClearDeadRolePic; //清除阵亡角色

		//是否已行动, 显示数字清空
		for i = 0 to broleamount - 1 do
		{
			Brole[i].Acted = 0;
			Brole[i].ShowNumber = 0;
		}

		i = 0;
		while (i < broleamount) && (Bstatus == 0) do
		{
			//当前人物位置作为屏幕中心
			Bx = Brole[i].X;
			By = Brole[i].Y;
			redraw;

			//战场序号保存至变量28005
			x50[28005] = i;
			//为我方且未阵亡, 非自动战斗, 则显示选单
			if ((Brole[i].Dead == 0))
			{
				if ((Brole[i].Team == 0) && (Brole[i].Auto == 0))
				{
					switch (BattleMenu(i)) {
0: Move(i);
1: Attack(i);
2: UsePoision(i);
3: MedPoision(i);
4: Medcine(i);
5: BattleMenuItem(i);
6: Wait(i);
   //状态改为仅能查看自己
7:
   {
	   ShowStatus(Brole[i].rnum);
	   WaitKey;
   }
8: Rest(i);
9:
   {
	   Brole[i].Auto = 1;
	   AutoBattle(i);
	   Brole[i].Acted = 1;
   }
					}
				}
				else {
					AutoBattle(i);
					Brole[i].Acted = 1;
				}
			}
			else Brole[i].Acted = 1;

			ClearDeadRolePic;
			redraw;
			Bstatus = BattleStatus;

			if (Brole[i].Acted == 1)
				i = i + 1;
			//showmessage(inttostr(i));
		}
		CalPoiHurtLife; //计算中毒损血

	}

}

//按轻功重排人物(未考虑装备)

void ReArrangeBRole()
	var
	int   i = 0;
	int  i1 = 0;
	int  i2 = 0;
	int x = 0;
temp: TBattleRole;
{
	for i1 = 0 to BRoleAmount - 2 do
		for i2 = i1 + 1 to BRoleAmount - 1 do
		{
			if (Rrole[Brole[i1].rnum].Speed < Rrole[Brole[i2].rnum].Speed)
			{
				temp = Brole[i1];
				Brole[i1] = Brole[i2];
				Brole[i2] = temp;
			}
		}

	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
			Bfield[2, i1, i2] = -1;

	for i = 0 to BRoleAmount - 1 do
	{
		if (Brole[i].Dead == 0)
			Bfield[2, Brole[i].X, Brole[i].Y] = i
		else
			Bfield[2, Brole[i].X, Brole[i].Y] = -1;
	}

}

//计算可移动步数(考虑装备)

void CalMoveAbility()
	var
	int   i = 0;
	int  rnum = 0;
	int addspeed = 0;
{
	for i = 0 to broleamount - 1 do
	{
		rnum = Brole[i].rnum;
		addspeed = 0;
		if (rrole[rnum].Equip[0] >= 0) addspeed = addspeed + ritem[rrole[rnum].Equip[0]].AddSpeed;
		if (rrole[rnum].Equip[1] >= 0) addspeed = addspeed + ritem[rrole[rnum].Equip[1]].AddSpeed;
		Brole[i].Step = (Rrole[Brole[i].rnum].Speed + addspeed) / 15;
	}

}

//0: Continue; 1: Victory; 2:Failed.
//检查是否有一方全部阵亡

function int BattleStatus = 0;
var
int   i = 0;
int  sum0 = 0;
int sum1 = 0;
{
	sum0 = 0;
	sum1 = 0;
	for i = 0 to broleamount - 1 do
	{
		if ((Brole[i].Team == 0) && (Brole[i].Dead == 0))
			sum0 = sum0 + 1;
		if ((Brole[i].Team == 1) && (Brole[i].Dead == 0))
			sum1 = sum1 + 1;
	}

	if ((sum0 > 0) && (sum1 > 0)) result = 0;
	if ((sum0 >= 0) && (sum1 == 0)) result = 1;
	if ((sum0 == 0) && (sum1 > 0)) result = 2;

}

//战斗主选单, menustatus按bit保存可用项

function int BattleMenu(bnum = 0int ) = 0;
var
int   i = 0;
int  p = 0;
int  menustatus = 0;
int  menu = 0;
int  max = 0;
int  rnum = 0;
int menup = 0;
realmenu: array[0..9] of integer;
{
	menustatus = 0x3E0;
	max = 4;
	//for i=0 to 9 do
	rnum = brole[bnum].rnum;
	//移动是否可用
	if (brole[bnum].Step > 0)
	{
		menustatus = menustatus || 1;
		max = max + 1;
	}

	//can not attack when phisical<10
	//攻击是否可用
	if (rrole[rnum].PhyPower >= 10)
	{
		p = 0;
		for i = 0 to 9 do
		{
			if (rrole[rnum].Magic[i] > 0)
			{
				p = 1;
				break;
			}
		}
		if (p > 0)
		{
			menustatus = menustatus || 2;
			max = max + 1;
		}
	}
	//用毒是否可用
	if ((Rrole[rnum].UsePoi > 0) && (rrole[rnum].PhyPower >= 30))
	{
		menustatus = menustatus || 4;
		max = max + 1;
	}
	//解毒是否可用
	if ((Rrole[rnum].MedPoi > 0) && (rrole[rnum].PhyPower >= 50))
	{
		menustatus = menustatus || 8;
		max = max + 1;
	}
	//医疗是否可用
	if ((Rrole[rnum].Medcine > 0) && (rrole[rnum].PhyPower >= 50))
	{
		menustatus = menustatus || 16;
		max = max + 1;
	}

	ReDraw;
	ShowSimpleStatus(brole[bnum].rnum, 350, 50);
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	menu = 0;
	showbmenu(menustatus, menu, max);
	//sdl_updaterect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					break;
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = max;
					showbmenu(menustatus, menu, max);
				}
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > max) menu = 0;
					showbmenu(menustatus, menu, max);
				}
				if ((event.key.keysym.sym == sdlk_return) && (event.key.keysym.modifier == kmod_lalt))
				{
					if (g_fullScreen == 1)
						g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_SWSURFACE || SDL_DOUBLEBUF || SDL_ANYFORMAT)
					else
						g_screenSurface = SDL_SetVideoMode(SCREEN_CENTER_X * 2, SCREEN_CENTER_Y * 2, 32, SDL_FULLSCREEN);
					g_fullScreen = 1 - g_fullScreen;
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_left))
					break;
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= 100) && (event.button.x < 147) && (event.button.y >= 50) && (event.button.y < max * 22 + 78))
				{
					menup = menu;
					menu = (event.button.y - 52) / 22;
					if (menu > max) menu = max;
					if (menu < 0) menu = 0;
					if (menup <> menu) showbmenu(menustatus, menu, max);
				}
			}
		}
	}
	//result=0;
	p = 0;
	for i = 0 to 9 do
	{
		if ((menustatus && (1 shl i)) > 0)
		{
			p = p + 1;
			if (p > menu) break;
		}
	}
	result = i;

}

//显示战斗主选单

void ShowBMenu(MenuStatus, menu, int max = 0)()
	var
	int   i = 0;
	int p = 0;
word: array[0..9] of widestring;
{
	word[0] = " 移動";
	word[1] = " 攻擊";
	word[2] = " 用毒";
	word[3] = " 解毒";
	word[4] = " 醫療";
	word[5] = " 物品";
	word[6] = " 等待";
	word[7] = " 狀態";
	word[8] = " 休息";
	word[9] = " 自動";
	Redraw;
	DrawFrameRectangle(100, 50, 47, max * 22 + 28, 0, COLOR(255), 30);
	p = 0;
	for i = 0 to 9 do
	{
		if ((p == menu) && ((menustatus && (1 shl i) > 0)))
		{
			drawshadowtext(@word[i][1], 83, 53 + 22 * p, COLOR(0x66), COLOR(0x64));
			p = p + 1;
		}
		else if ((p <> menu) && ((menustatus && (1 shl i) > 0)))
		{
			drawshadowtext(@word[i][1], 83, 53 + 22 * p, COLOR(0x23), COLOR(0x21));
			p = p + 1;
		}
	}
	sdl_updaterect(g_screenSurface, 100, 50, 48, max * 22 + 29);
}

//移动

void int Move(bnum = 0)()
	var
	int   s = 0;
	int i = 0;
{
	CalCanSelect(bnum, 0);
	if (SelectAim(bnum, brole[bnum].Step))
		MoveAmination(bnum);

}

//移动动画

void int MoveAmination(bnum = 0)()
	var
	int   s = 0;
	int i = 0;
{
	//CalCanSelect(bnum, 0);
	//if (SelectAim(bnum,Brole[bnum,6]))
	brole[bnum].Step = brole[bnum].Step - abs(Ax - Bx) - abs(Ay - By);
	s = sign(Ax - Bx);
	if (s < 0) Brole[bnum].Face = 0;
	if (s > 0) Brole[bnum].Face = 3;
	i = Bx + s;
	if (s <> 0)
		while s * (Ax - i) >= 0 do
		{
			sdl_delay(20);
			if (Bfield[2, Bx, By] == bnum) Bfield[2, Bx, By] = -1;
			Bx = i;
			if (Bfield[2, Bx, By] == -1) Bfield[2, Bx, By] = bnum;
			Redraw;
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			i = i + s;
		}
	s = sign(Ay - By);
	if (s < 0) Brole[bnum].Face = 2;
	if (s > 0) Brole[bnum].Face = 1;
	i = By + s;
	if (s <> 0)
		while s * (Ay - i) >= 0 do
		{
			sdl_delay(20);
			if (Bfield[2, Bx, By] == bnum) Bfield[2, Bx, By] = -1;
			By = i;
			if (Bfield[2, Bx, By] == -1) Bfield[2, Bx, By] = bnum;
			Redraw;
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			i = i + s;
		}
	Brole[bnum].X = Bx;
	Brole[bnum].Y = By;
	Bfield[2, Bx, By] = bnum;

}

//选择目标

function SelectAim(bnum, int step = 0): boolean;
var
int   Axp = 0;
int Ayp = 0;
{
	Ax = Bx;
	Ay = By;
	DrawBFieldWithCursor(step);
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					result = true;
					x50[28927] = 1;
					break;
				}
				if ((event.key.keysym.sym == sdlk_escape))
				{
					result = false;
					x50[28927] = 0;
					break;
				}
				if ((event.key.keysym.sym == sdlk_left))
				{
					Ay = Ay - 1;
					if ((abs(Ax - Bx) + abs(Ay - By) > step) || (Bfield[3, Ax, Ay] <> 0)) Ay = Ay + 1;
					DrawBFieldWithCursor(step);
					sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
				if ((event.key.keysym.sym == sdlk_right))
				{
					Ay = Ay + 1;
					if ((abs(Ax - Bx) + abs(Ay - By) > step) || (Bfield[3, Ax, Ay] <> 0)) Ay = Ay - 1;
					DrawBFieldWithCursor(step);
					sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
				if ((event.key.keysym.sym == sdlk_down))
				{
					Ax = Ax + 1;
					if ((abs(Ax - Bx) + abs(Ay - By) > step) || (Bfield[3, Ax, Ay] <> 0)) Ax = Ax - 1;
					DrawBFieldWithCursor(step);
					sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					Ax = Ax - 1;
					if ((abs(Ax - Bx) + abs(Ay - By) > step) || (Bfield[3, Ax, Ay] <> 0)) Ax = Ax + 1;
					DrawBFieldWithCursor(step);
					sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_left))
				{
					result = true;
					break;
				}
				if ((event.button.button == sdl_button_right))
				{
					result = false;
					break;
				}
			}
SDL_MOUSEMOTION:
			{
				Axp = (-event.button.x + SCREEN_CENTER_X + 2 * event.button.y - 2 * SCREEN_CENTER_Y + 18) / 36 + Bx;
				Ayp = (event.button.x - SCREEN_CENTER_X + 2 * event.button.y - 2 * SCREEN_CENTER_Y + 18) / 36 + By;
				if ((abs(Axp - Bx) + abs(Ayp - By) <= step) && (Bfield[3, Axp, Ayp] == 0))
				{
					Ax = Axp;
					Ay = Ayp;
					DrawBFieldWithCursor(step);
					sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
				}
			}
		}
	}

}

//计算可以被选中的位置
//利用递归确定

void SeekPath(x, y, int step = 0)()
{
	if (step > 0)
	{
		step = step - 1;
		if (Bfield[3, x, y] in [0..step])
		{
			Bfield[3, x, y] = step;
			if (Bfield[3, x + 1, y] in [0..step])
			{
				SeekPath(x + 1, y, step);
			}
			if (Bfield[3, x, y + 1] in [0..step])
			{
				SeekPath(x, y + 1, step);
			}
			if (Bfield[3, x - 1, y] in [0..step])
			{
				SeekPath(x - 1, y, step);
			}
			if (Bfield[3, x, y - 1] in [0..step])
			{
				SeekPath(x, y - 1, step);
			}
		}
	}

}


void CalCanSelect(bnum, int mode = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int i2 = 0;
{
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			Bfield[3, i1, i2] = 0;
			//mode为0表示移动, 这时建筑和有人物(不包括自己)的位置不可选
			if (mode == 0)
			{
				if (Bfield[1, i1, i2] > 0) Bfield[3, i1, i2] = -1;
				if (Bfield[2, i1, i2] >= 0) Bfield[3, i1, i2] = -1;
				if (Bfield[2, i1, i2] == bnum) Bfield[3, i1, i2] = 0;
			}
		}
	if (mode == 0)
	{
		SeekPath(Brole[bnum].X, Brole[bnum].Y, Brole[bnum].Step + 2);
		//递归算法的问题, 步数+2参与计算
		for i1 = 0 to 63 do
			for i2 = 0 to 63 do
			{
				if (Bfield[3, i1, i2] > 0)
					Bfield[3, i1, i2] = 0
				else
					Bfield[3, i1, i2] = 1;
			}
	}
}

//画带光标的子程
//此子程效率不高

void int DrawBFieldWithCursor(step = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int  i2 = 0;
	int bnum = 0;
pos: TPosition;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
			if (Bfield[0, i1, i2] > 0)
			{
				pos = GetMapScenceXYPos(i1, i2, Bx, By);
				if ((i1 == Ax) && (i2 == Ay))
					DrawBFPic(Bfield[0, i1, i2] / 2, pos.x, pos.y, 1)
				else if ((BField[3, i1, i2] == 0) && (abs(i1 - Bx) + abs(i2 - By) <= step))
					DrawBFPic(Bfield[0, i1, i2] / 2, pos.x, pos.y, 0)
				else
					DrawBFPic(Bfield[0, i1, i2] / 2, pos.x, pos.y, -1);
			}

	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			pos = GetMapScenceXYPos(i1, i2, Bx, By);
			if (Bfield[1, i1, i2] > 0)
				DrawBFPic(Bfield[1, i1, i2] / 2, pos.x, pos.y, 0);
			bnum = Bfield[2, i1, i2];
			if ((bnum >= 0) && (Brole[bnum].Dead == 0))
				DrawBFPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0);
		}
	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}

}

//画带效果的战场

void int DrawBFieldWithEft(Epicnum = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int i2 = 0;
pos: TPosition;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}
	DrawBfieldWithoutRole(Bx, By);

	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			pos = GetMapScenceXYPos(i1, i2, Bx, By);
			if ((Bfield[2, i1, i2] >= 0) && (Brole[Bfield[2, i1, i2]].Dead == 0))
				DrawRoleOnBField(i1, i2);
			if (Bfield[4, i1, i2] > 0)
				DrawEffect(Epicnum, pos.x, pos.y);
		}
	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}

}

//画带人物动作的战场

void DrawBFieldWithAction(bnum, int Apicnum = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int i2 = 0;
pos: TPosition;
{
	if ((SDL_MustLock(g_screenSurface)))
	{
		if ((SDL_LockSurface(g_screenSurface) < 0))
		{
			MessageBox(0, PChar(Format("Can't lock g_screenSurface : %s", [SDL_GetError])), "Error", MB_OK || MB_ICONHAND);
			exit;
		}
	}
	DrawBfieldWithoutRole(Bx, By);

	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			if ((Bfield[2, i1, i2] >= 0) && (Brole[Bfield[2, i1, i2]].Dead == 0) && (Bfield[2, i1, i2] <> bnum))
			{
				DrawRoleOnBfield(i1, i2);
			}
			if ((Bfield[2, i1, i2] == bnum))
			{
				pos = GetMapScenceXYPos(i1, i2, Bx, By);
				DrawAction(apicnum, pos.x, pos.y);
			}
		}
	if ((SDL_MustLock(g_screenSurface)))
	{
		SDL_UnlockSurface(g_screenSurface);
	}

}

//攻击

void int Attack(bnum = 0)()
	var
	int   rnum = 0;
	int  i = 0;
	int  mnum = 0;
	int  level = 0;
	int  step = 0;
	int i1 = 0;
{
	rnum = brole[bnum].rnum;
	i = SelectMagic(rnum);
	mnum = Rrole[rnum].Magic[i];
	level = Rrole[rnum].MagLevel[i] / 100 + 1;

	if (i >= 0)
		//依据攻击范围进一步选择
		switch (Rmagic[mnum].AttAreaType) {
			0, 3:
			{
				CalCanSelect(bnum, 1);
				step = Rmagic[mnum].MoveDistance[level - 1];
				if (SelectAim(bnum, step))
				{
					SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].AttDistance[level - 1]);
					Brole[bnum].Acted = 1;
				}
			}
1:
			{
				if (SelectDirector(bnum))
				{
					SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1]);
					Brole[bnum].Acted = 1;
				}
			}
2:
			{
				SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1]);
				Brole[bnum].Acted = 1;
			}
		}
	//如果行动成功, 武功等级增加, 播放效果
	if (Brole[bnum].Acted == 1)
	{
		for i1 = 0 to sign(Rrole[rnum].AttTwice) do
		{
			Rrole[rnum].MagLevel[i] = Rrole[rnum].MagLevel[i] + random(2) + 1;
			if (Rrole[rnum].MagLevel[i] > 999) Rrole[rnum].MagLevel[i] = 999;
			if (rmagic[mnum].UnKnow[4] > 0) callevent(rmagic[mnum].UnKnow[4])
			else AttackAction(bnum, mnum, level);
		}
	}

}

//攻击效果

void AttackAction(bnum, mnum, int level = 0)()
{
	PlayActionAmination(bnum, Rmagic[mnum].MagicType); //动画效果
	PlayMagicAmination(bnum, Rmagic[mnum].AmiNum); //武功效果
	CalHurtRole(bnum, mnum, level); //计算被打到的人物
	ShowHurtValue(rmagic[mnum].HurtType); //显示数字

}

//选择武功

function int SelectMagic(rnum = 0int ) = 0;
var
int   i = 0;
int  p = 0;
int  menustatus = 0;
int  max = 0;
int  menu = 0;
int menup = 0;
{
	menustatus = 0;
	max = 0;
	setlength(menustring, 10);
	setlength(menuengstring, 10);
	for i = 0 to 9 do
	{
		if (Rrole[rnum].Magic[i] > 0)
		{
			menustatus = menustatus || (1 shl i);
			menustring[i] = Big5toUTF8(@Rmagic[Rrole[rnum].Magic[i]].Name);
			menuengstring[i] = format("%3d", [Rrole[rnum].MagLevel[i] / 100 + 1]);
			max = max + 1;
		}
	}
	max = max - 1;

	ReDraw;
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	menu = 0;
	showmagicmenu(menustatus, menu, max);
	//sdl_updaterect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_return) || (event.key.keysym.sym == sdlk_space))
				{
					break;
				}
				if ((event.key.keysym.sym == sdlk_escape))
				{
					result = -1;
					break;
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					menu = menu - 1;
					if (menu < 0) menu = max;
					showmagicmenu(menustatus, menu, max);
				}
				if ((event.key.keysym.sym == sdlk_down))
				{
					menu = menu + 1;
					if (menu > max) menu = 0;
					showmagicmenu(menustatus, menu, max);
				}
			}
SDL_MOUSEBUTTONUP:
			{
				if ((event.button.button == sdl_button_left))
				{
					break;
				}
				if ((event.button.button == sdl_button_right))
				{
					result = -1;
					break;
				}
			}
SDL_MOUSEMOTION:
			{
				if ((event.button.x >= 100) && (event.button.x < 267) && (event.button.y >= 50) && (event.button.y < max * 22 + 78))
				{
					menup = menu;
					menu = (event.button.y - 52) / 22;
					if (menu > max) menu = max;
					if (menu < 0) menu = 0;
					if (menup <> menu) showmagicmenu(menustatus, menu, max);
				}
			}
		}
	}
	//result=0;
	if (result >= 0)
	{
		p = 0;
		for i = 0 to 9 do
		{
			if ((menustatus && (1 shl i)) > 0)
			{
				p = p + 1;
				if (p > menu) break;
			}
		}
		result = i;
	}

}

//显示武功选单

void ShowMagicMenu(menustatus, menu, int max = 0)()
	var
	int   i = 0;
	int p = 0;
{
	redraw;
	DrawFrameRectangle(100, 50, 167, max * 22 + 28, 0, COLOR(255), 30);
	p = 0;
	for i = 0 to 9 do
	{
		if ((p == menu) && ((menustatus && (1 shl i) > 0)))
		{
			drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, COLOR(0x66), COLOR(0x64));
			drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, COLOR(0x66), COLOR(0x64));
			p = p + 1;
		}
		else if ((p <> menu) && ((menustatus && (1 shl i) > 0)))
		{
			drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, COLOR(0x23), COLOR(0x21));
			drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, COLOR(0x23), COLOR(0x21));
			p = p + 1;
		}
	}
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}

//选择方向

function int SelectDirector(bnum = 0): boolean;
var
str: widestring;
{
	Ax = Bx;
	Ay = By;
	str = " 選擇攻擊方向";
	Drawtextwithrect(@str[1], 280, 200, 125, COLOR(0x23), COLOR(0x21));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	result = false;
	while (SDL_WaitEvent(@event) >= 0) do
	{
		switch (event.type) {
SDL_QUITEV:
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
SDL_KEYUP:
			{
				if ((event.key.keysym.sym == sdlk_escape))
				{
					break;
				}
				if ((event.key.keysym.sym == sdlk_left))
				{
					Ay = Ay - 1;
					break;
				}
				if ((event.key.keysym.sym == sdlk_right))
				{
					Ay = Ay + 1;
					break;
				}
				if ((event.key.keysym.sym == sdlk_down))
				{
					Ax = Ax + 1;
					break;
				}
				if ((event.key.keysym.sym == sdlk_up))
				{
					Ax = Ax - 1;
					break;
				}
			}
Sdl_mousebuttonup:
			{
				if (event.button.button == sdl_button_right) break;
				//按照所点击位置设置方向
				if (event.button.button == sdl_button_left)
				{
					if ((event.button.x < SCREEN_CENTER_X) && (event.button.y < SCREEN_CENTER_Y)) Ay = Ay - 1;
					if ((event.button.x < SCREEN_CENTER_X) && (event.button.y >= SCREEN_CENTER_Y)) Ax = Ax + 1;
					if ((event.button.x >= SCREEN_CENTER_X) && (event.button.y < SCREEN_CENTER_Y)) Ax = Ax - 1;
					if ((event.button.x >= SCREEN_CENTER_X) && (event.button.y >= SCREEN_CENTER_Y)) Ay = Ay + 1;
					break;
				}
			}
		}
	}
	if ((Ax <> Bx) || (Ay <> By)) result = true;

}

//设定攻击范围

void SetAminationPosition(mode, int step = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int i2 = 0;
{
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			Bfield[4, i1, i2] = 0;
			//按攻击类型判断是否在范围内
			switch (mode) {
0:
				{
					if ((i1 == Ax) && (i2 == Ay)) Bfield[4, i1, i2] = 1;
				}
3:
				{
					if ((abs(i1 - Ax) <= step) && (abs(i2 - Ay) <= step)) Bfield[4, i1, i2] = 1;
				}
1:
				{
					if (((i1 == Bx) || (i2 == By)) && (sign(Ax - Bx) == sign(i1 - Bx)) && (abs(i1 - Bx) <= step) && (sign(Ay - By) == sign(i2 - By)) && (abs(i2 - By) <= step))
						Bfield[4, i1, i2] = 1;
				}
2:
				{
					if (((i1 == Bx) && (abs(i2 - By) <= step)) || ((i2 == By) && (abs(i1 - Bx) <= step)))
						Bfield[4, i1, i2] = 1;
					if (((i1 == Bx) && (i2 == By))) Bfield[4, i1, i2] = 0;
				}
			}
		}

}

//显示武功效果

void PlayMagicAmination(bnum, int enum = 0)()
	var
	int   beginpic = 0;
	int  i = 0;
	int endpic = 0;
{
	beginpic = 0;
	//含音效
	playsound(enum, 0);
	for i = 0 to enum - 1 do
		beginpic = beginpic + g_effectList[i];
	endpic = beginpic + g_effectList[enum] - 1;


	for i = beginpic to endpic do
	{
		DrawBFieldWithEft(i);
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		sdl_delay(20);
	}

}

//判断是否有非行动方角色在攻击范围之内

void CalHurtRole(bnum, mnum, int level = 0)()
	var
	int   i = 0;
	int  rnum = 0;
	int  hurt = 0;
	int  addpoi = 0;
	int mp = 0;
{
	rnum = brole[bnum].rnum;
	rrole[rnum].PhyPower = rrole[rnum].PhyPower - 3;
	if (RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * ((level + 1) / 2)) level = RRole[rnum].CurrentMP / rmagic[mnum].NeedMP * 2;
	if (level > 10) level = 10;
	RRole[rnum].CurrentMP = RRole[rnum].CurrentMP - rmagic[mnum].NeedMP * ((level + 1) / 2);
	for i = 0 to broleamount - 1 do
	{
		Brole[i].ShowNumber = -1;
		if ((Bfield[4, Brole[i].X, Brole[i].Y] <> 0) && (Brole[bnum].Team <> Brole[i].Team) && (Brole[i].Dead == 0))
		{
			//生命伤害
			if ((rmagic[mnum].HurtType == 0))
			{
				hurt = CalHurtValue(bnum, i, mnum, level);
				Brole[i].ShowNumber = hurt;
				//受伤
				Rrole[Brole[i].rnum].CurrentHP = Rrole[Brole[i].rnum].CurrentHP - hurt;
				Rrole[Brole[i].rnum].Hurt = Rrole[Brole[i].rnum].Hurt + hurt / LIFE_HURT;
				if (Rrole[Brole[i].rnum].Hurt > 99) Rrole[Brole[i].rnum].Hurt = 99;
				Brole[bnum].ExpGot = Brole[bnum].ExpGot + hurt / 2;
				if (Rrole[Brole[i].rnum].CurrentHP <= 0) Brole[bnum].ExpGot = Brole[bnum].ExpGot + hurt / 2;
			}
			//内力伤害
			if ((rmagic[mnum].HurtType == 1))
			{
				hurt = rmagic[mnum].HurtMP[level - 1] + random(5) - random(5);
				Brole[i].ShowNumber = hurt;
				Rrole[Brole[i].rnum].CurrentMP = Rrole[Brole[i].rnum].CurrentMP - hurt;
				if (Rrole[Brole[i].rnum].CurrentMP <= 0) Rrole[Brole[i].rnum].CurrentMP = 0;
				//增加己方内力及最大值
				RRole[rnum].CurrentMP = RRole[rnum].CurrentMP + hurt;
				RRole[rnum].MaxMP = RRole[rnum].MaxMP + random(hurt / 2);
				if (RRole[rnum].MaxMP > MAX_MP) RRole[rnum].MaxMP = MAX_MP;
				if (RRole[rnum].CurrentMP > RRole[rnum].MaxMP) RRole[rnum].CurrentMP = RRole[rnum].MaxMP;
			}
			//中毒
			addpoi = rrole[rnum].AttPoi / 5 + rmagic[mnum].Poision * level / 2 - rrole[Brole[i].rnum].DefPoi;
			if (addpoi + rrole[Brole[i].rnum].Poision > 99) addpoi = 99 - rrole[Brole[i].rnum].Poision;
			if (addpoi < 0) addpoi = 0;
			if (rrole[Brole[i].rnum].DefPoi >= 99) addpoi = 0;
			rrole[Brole[i].rnum].Poision = rrole[Brole[i].rnum].Poision + addpoi;
		}
	}

}

//计算伤害值, 第一公式如小于0则取一个随机数, 无第二公式

int function CalHurtValue(bnum1 = 0;
		int  bnum2 = 0;
		int  mnum = 0;
		int level = 0int ) = 0;
var
int   i = 0;
int  rnum1 = 0;
int  rnum2 = 0;
int  mhurt = 0;
int  att = 0;
int  def = 0;
int  k1 = 0;
int  k2 = 0;
int dis = 0;
{
	//计算双方武学常识
	k1 = 0;
	k2 = 0;
	for i = 0 to broleamount - 1 do
	{
		if ((Brole[i].Team == brole[bnum1].Team) && (Brole[i].Dead == 0) && (rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)) k1 = k1 + rrole[Brole[i].rnum].Knowledge;
		if ((Brole[i].Team == brole[bnum2].Team) && (Brole[i].Dead == 0) && (rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE)) k2 = k2 + rrole[Brole[i].rnum].Knowledge;
	}
	rnum1 = Brole[bnum1].rnum;
	rnum2 = Brole[bnum2].rnum;
	mhurt = Rmagic[mnum].Attack[level - 1];

	att = Rrole[rnum1].Attack + k1 * 3 / 2 + mhurt / 3;
	def = Rrole[rnum2].Defence * 2 + k2 * 3;
	//攻击, 防御按伤害的折扣
	att = att * (100 - Rrole[rnum1].Hurt / 2) / 100;
	def = def * (100 - Rrole[rnum2].Hurt / 2) / 100;

	//如果有武器, 增加攻击, 检查配合列表
	if (rrole[rnum1].Equip[0] >= 0)
	{
		att = att + ritem[rrole[rnum1].Equip[0]].AddAttack;
		for i = 0 to MAX_WEAPON_MATCH - 1 do
		{
			if ((rrole[rnum1].Equip[0] == g_matchList[i, 0]) && (mnum == g_matchList[i, 1]))
			{
				att = att + g_matchList[i, 2] * 2 / 3;
				break;
			}
		}
	}
	//防具增加攻击
	if (rrole[rnum1].Equip[1] >= 0) att = att + ritem[rrole[rnum1].Equip[1]].AddAttack;
	//武器, 防具增加防御
	if (rrole[rnum2].Equip[0] >= 0) def = def + ritem[rrole[rnum2].Equip[0]].AddDefence;
	if (rrole[rnum2].Equip[1] >= 0) def = def + ritem[rrole[rnum2].Equip[1]].AddDefence;
	//showmessage(inttostr(att)+" "+inttostr(def));
	result = att - def + random(20) - random(20);
	dis = abs(brole[bnum1].X - brole[bnum2].X) + abs(brole[bnum1].Y - brole[bnum2].Y);
	if (dis > 10) dis = 10;
	result = result * (100 - (dis - 1) * 3) / 100;
	if ((result <= 0) || (level <= 0)) result = random(10) + 1;
	if ((result > 9999)) result = 9999;
	//showmessage(inttostr(result));

}

//0: red. 1: purple, 2: green
//显示数字

void int ShowHurtValue(mode = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int  x = 0;
	int y = 0;
	color1, color2: uint32;
word: array of widestring;
str: string;
{
	switch (mode) {
0:
		{
			color1 = COLOR(0x10);
			color2 = COLOR(0x14);
			str = "-%d";
		}
1:
		{
			color1 = COLOR(0x50);
			color2 = COLOR(0x53);
			str = "-%d";
		}
2:
		{
			color1 = COLOR(0x30);
			color2 = COLOR(0x32);
			str = "+%d";
		}
3:
		{
			color1 = COLOR(0x7);
			color2 = COLOR(0x5);
			str = "+%d";
		}
4:
		{
			color1 = COLOR(0x91);
			color2 = COLOR(0x93);
			str = "-%d";
		}
	}
	setlength(word, broleamount);
	for i = 0 to broleamount - 1 do
	{
		if (Brole[i].ShowNumber > 0)
		{
			//x = -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + SCREEN_CENTER_X - 10;
			//y = (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + SCREEN_CENTER_Y - 40;
			word[i] = format(str, [Brole[i].ShowNumber]);
		}
		Brole[i].ShowNumber = -1;
	}
	for i1 = 0 to 10 do
	{
		redraw;
		for i = 0 to broleamount - 1 do
		{
			x = -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + SCREEN_CENTER_X - 10;
			y = (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + SCREEN_CENTER_Y - 40;
			drawengshadowtext(@word[i, 1], x, y - i1 * 2, color1, color2);
			sdl_delay(5);
		}
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	}
	redraw;

}

//计算中毒减少的生命

void CalPoiHurtLife()
	var
	int i = 0;
p: boolean;
{
	p = false;
	for i = 0 to broleamount - 1 do
	{
		Brole[i].ShowNumber = -1;
		if ((Rrole[Brole[i].rnum].Poision > 0) && (Brole[i].Dead == 0))
		{
			Rrole[Brole[i].rnum].CurrentHP = Rrole[Brole[i].rnum].CurrentHP - Rrole[Brole[i].rnum].Poision / 10 - 1;
			if (Rrole[Brole[i].rnum].CurrentHP <= 0) Rrole[Brole[i].rnum].CurrentHP = 1;
			//Brole[i].ShowNumber = Rrole[Brole[i].rnum, 20] / 2+1;
			//p = true;
		}
	}
	//if (p) showhurtvalue(0);

}

//设置生命低于0的人物为已阵亡, 主要是清除所占的位置

void ClearDeadRolePic()
	var
	int i = 0;
{
	for i = 0 to broleamount - 1 do
	{
		if (Rrole[Brole[i].rnum].CurrentHP <= 0)
		{
			Brole[i].Dead = 1;
			bfield[2, Brole[i].X, Brole[i].Y] = -1;
			//bmount
		}
	}
	for i = 0 to broleamount - 1 do
		if (Brole[i].Dead == 0) bfield[2, Brole[i].X, Brole[i].Y] = i;

}

//显示简单状态(x, y表示位置)

void ShowSimpleStatus(rnum, x, int y = 0)()
	var
	int   i = 0;
	int magicnum = 0;
p: array[0..10] of integer;
str: widestring;
strs: array[0..3] of widestring;
color1, color2: uint32;
{
	strs[0] = " 等級";
	strs[1] = " 生命";
	strs[2] = " 內力";
	strs[3] = " 體力";

	DrawFrameRectangle(x, y, 145, 173, 0, COLOR(255), 30);
	DrawFacePic(Rrole[rnum].HeadNum, x + 50, y + 62);
	str = big5toUTF8(@rrole[rnum].Name);
	drawshadowtext(@str[1], x + 60 - length(pchar(@rrole[rnum].Name)) * 5, y + 65, COLOR(0x66), COLOR(0x63));
	for i = 0 to 3 do
		drawshadowtext(@strs[i, 1], x - 17, y + 86 + 21 * i, COLOR(0x23), COLOR(0x21));

	str = format("%9d", [Rrole[rnum].Level]);
	drawengshadowtext(@str[1], x + 50, y + 86, COLOR(0x7), COLOR(0x5));

	switch (RRole[rnum].Hurt) {
		34..66:
		{
			color1 = COLOR(0xE);
			color2 = COLOR(0x10);
		}
		67..1000:
		{
			color1 = COLOR(0x14);
			color2 = COLOR(0x16);
		}
		else
		{
			color1 = COLOR(0x7);
			color2 = COLOR(0x5);
		}
	}
	str = format("%4d", [RRole[rnum].CurrentHP]);
	drawengshadowtext(@str[1], x + 50, y + 107, color1, color2);

	str = "/";
	drawengshadowtext(@str[1], x + 90, y + 107, COLOR(0x66), COLOR(0x63));

	switch (RRole[rnum].Poision) {
		34..66:
		{
			color1 = COLOR(0x30);
			color2 = COLOR(0x32);
		}
		67..1000:
		{
			color1 = COLOR(0x35);
			color2 = COLOR(0x37);
		}
		else
		{
			color1 = COLOR(0x23);
			color2 = COLOR(0x21);
		}
	}
	str = format("%4d", [RRole[rnum].MaxHP]);
	drawengshadowtext(@str[1], x + 100, y + 107, color1, color2);

	//str=format("%4d/%4d", [Rrole[rnum,17],Rrole[rnum,18]]);
	//drawengshadowtext(@str[1],x+50,y+107,COLOR(0x7),COLOR(0x5));
	if (rrole[rnum].MPType == 0)
	{
		color1 = COLOR(0x50);
		color2 = COLOR(0x4E);
	} else
		if (rrole[rnum].MPType == 1)
		{
			color1 = COLOR(0x7);
			color2 = COLOR(0x5);
		} else
		{
			color1 = COLOR(0x66);
			color2 = COLOR(0x63);
		}
		str = format("%4d/%4d", [RRole[rnum].CurrentMP, RRole[rnum].MaxMP]);
		drawengshadowtext(@str[1], x + 50, y + 128, color1, color2);
		str = format("%9d", [rrole[rnum].PhyPower]);
		drawengshadowtext(@str[1], x + 50, y + 149, COLOR(0x7), COLOR(0x5));

		SDL_UpdateRect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}

//等待, 似乎不太完善

void int Wait(bnum = 0)()
	var
	int   i = 0;
	int  i1 = 0;
	int  i2 = 0;
	int x = 0;
{

	Brole[BroleAmount] = Brole[bnum];

	for i = bnum to BRoleAmount - 1 do
		Brole[i] = Brole[i + 1];

	for i = 0 to BRoleAmount - 1 do
	{
		if (Brole[i].Dead == 0)
			Bfield[2, Brole[i].X, Brole[i].Y] = i
		else
			Bfield[2, Brole[i].X, Brole[i].Y] = -1;
	}

}

//战斗结束恢复人物状态

void RestoreRoleStatus()
	var
	int   i = 0;
	int rnum = 0;
{
	for i = 0 to BRoleAmount - 1 do
	{
		rnum = Brole[i].rnum;
		//我方恢复部分生命, 内力; 敌方恢复全部
		if (Brole[i].Team == 0)
		{
			RRole[rnum].CurrentHP = RRole[rnum].CurrentHP + RRole[rnum].MaxHP / 2;
			if (RRole[rnum].CurrentHP <= 0) RRole[rnum].CurrentHP = 1;
			if (RRole[rnum].CurrentHP > RRole[rnum].MaxHP) RRole[rnum].CurrentHP = RRole[rnum].MaxHP;
			RRole[rnum].CurrentMP = RRole[rnum].CurrentMP + RRole[rnum].MaxMP / 20;
			if (RRole[rnum].CurrentMP > RRole[rnum].MaxMP) RRole[rnum].CurrentMP = RRole[rnum].MaxMP;
			rrole[rnum].PhyPower = rrole[rnum].PhyPower + MAX_PHYSICAL_POWER / 10;
			if (rrole[rnum].PhyPower > MAX_PHYSICAL_POWER) rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;
		} else
		{
			RRole[rnum].Hurt = 0;
			RRole[rnum].Poision = 0;
			RRole[rnum].CurrentHP = RRole[rnum].MaxHP;
			RRole[rnum].CurrentMP = RRole[rnum].MaxMP;
			rrole[rnum].PhyPower = MAX_PHYSICAL_POWER * 9 / 10;
		}
	}

}

//增加经验

void AddExp()
	var
	int   i = 0;
	int  rnum = 0;
	int  basicvalue = 0;
	int amount = 0;
str: widestring;
{
	for i = 0 to BRoleAmount - 1 do
	{
		rnum = Brole[i].rnum;
		Rrole[rnum].Exp = Rrole[rnum].Exp + Brole[i].ExpGot;
		Rrole[rnum].ExpForBook = Rrole[rnum].ExpForBook + Brole[i].ExpGot / 5 * 4;
		Rrole[rnum].ExpForItem = Rrole[rnum].ExpForItem + Brole[i].ExpGot / 5 * 3;
		amount = Calrnum(0);
		if (amount > 0) basicvalue = warsta[7] / amount
		else basicvalue = 0;
		if ((Brole[i].Team == 0) && (Brole[i].Dead == 0))
		{
			Rrole[rnum].Exp = Rrole[rnum].Exp + basicvalue;
			Rrole[rnum].ExpForBook = Rrole[rnum].ExpForBook + basicvalue / 5 * 4;
			Rrole[rnum].ExpForItem = Rrole[rnum].ExpForItem + basicvalue / 5 * 3;
			ShowSimpleStatus(rnum, 100, 50);
			DrawFrameRectangle(100, 235, 145, 25, 0, COLOR(255), 25);
			str = " 得經驗";
			Drawshadowtext(@str[1], 83, 237, COLOR(0x23), COLOR(0x21));
			str = format("%5d", [Brole[i].ExpGot + basicvalue]);
			Drawengshadowtext(@str[1], 188, 237, COLOR(0x66), COLOR(0x64));
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			Redraw;
			WaitKey;
		}

	}

}

//检查是否能够升级

void CheckLevelUp()
	var
	int   i = 0;
	int rnum = 0;
{
	for i = 0 to BRoleAmount - 1 do
	{
		rnum = Brole[i].rnum;
		while (uint16(Rrole[rnum].Exp) >= uint16(g_levelupList[Rrole[rnum].Level - 1])) && (Rrole[rnum].Level < MAX_LEVEL) do
		{
			Rrole[rnum].Exp = Rrole[rnum].Exp - g_levelupList[Rrole[rnum].Level - 1];
			Rrole[rnum].Level = Rrole[rnum].Level + 1;
			LevelUp(i);
		}
	}

}

//升级, 如是我方人物显示状态

void int LevelUp(bnum = 0)()
	var
	int   i = 0;
	int  rnum = 0;
	int add = 0;
str: widestring;
{

	rnum = brole[bnum].rnum;
	RRole[rnum].MaxHP = RRole[rnum].MaxHP + Rrole[rnum].IncLife * 3 + random(6);
	if (RRole[rnum].MaxHP > MAX_HP) RRole[rnum].MaxHP = MAX_HP;
	RRole[rnum].CurrentHP = RRole[rnum].MaxHP;

	add = Rrole[rnum].Aptitude / 15 + 1;
	add = random(add) + 1;

	RRole[rnum].MaxMP = RRole[rnum].MaxMP + (9 - add) * 3;
	if (RRole[rnum].MaxMP > MAX_MP) RRole[rnum].MaxMP = MAX_MP;
	RRole[rnum].CurrentMP = RRole[rnum].MaxMP;

	RRole[rnum].Attack = RRole[rnum].Attack + add;
	Rrole[rnum].Speed = Rrole[rnum].Speed + add;
	Rrole[rnum].Defence = Rrole[rnum].Defence + add;

	for i = 46 to 54 do
	{
		if (rrole[rnum].data[i] > 0)
			rrole[rnum].data[i] = rrole[rnum].data[i] + random(3) + 1;
	}
	for i = 43 to 58 do
	{
		if (rrole[rnum].data[i] > MAX_PRO_LIST[i])
			rrole[rnum].data[i] = MAX_PRO_LIST[i];
	}

	RRole[rnum].PhyPower = MAX_PHYSICAL_POWER;
	RRole[rnum].Hurt = 0;
	RRole[rnum].Poision = 0;

	if (Brole[bnum].Team == 0)
	{
		ShowStatus(rnum);
		str = " 升級";
		Drawtextwithrect(@str[1], 50, SCREEN_CENTER_Y - 150, 46, COLOR(0x23), COLOR(0x21));
		WaitKey;
	}

}

//检查身上秘笈

void CheckBook()
	var
	int   i = 0;
	int  i1 = 0;
	int  i2 = 0;
	int  p = 0;
	int  rnum = 0;
	int  inum = 0;
	int  mnum = 0;
	int  mlevel = 0;
	int  needexp = 0;
	int  needitem = 0;
	int  needitemamount = 0;
	int itemamount = 0;
str: widestring;
{
	for i = 0 to BRoleAmount - 1 do
	{
		rnum = Brole[i].rnum;
		inum = Rrole[rnum].PracticeBook;
		if (inum >= 0)
		{
			mlevel = 1;
			mnum = Ritem[inum].Magic;
			if (mnum > 0)
				for i1 = 0 to 9 do
					if (Rrole[rnum].Magic[i1] == mnum)
					{
						mlevel = Rrole[rnum].MagLevel[i1] / 100 + 1;
						break;
					}
			needexp = mlevel * Ritem[inum].NeedExp * (7 - Rrole[rnum].Aptitude / 15);

			if ((Rrole[rnum].ExpForBook >= needexp) && (mlevel < 10))
			{
				redraw;
				EatOneItem(rnum, inum);
				WaitKey;
				redraw;
				sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

				if (mnum > 0)
					instruct_33(rnum, mnum, 1);
				Rrole[rnum].ExpForBook = 0;
				//ShowStatus(rnum);
				//WaitKey;
			}
			//是否能够炼出物品
			if ((Rrole[rnum].ExpForItem >= ritem[inum].NeedExpForItem) && (ritem[inum].NeedExpForItem > 0) && (Brole[i].Team == 0))
			{
				redraw;
				p = 0;
				for i2 = 0 to 4 do
				{
					if (ritem[inum].GetItem[i2] >= 0) p = p + 1;
				}
				p = random(p);
				needitem = ritem[inum].NeedMaterial;
				if (ritem[inum].GetItem[p] >= 0)
				{
					needitemamount = ritem[inum].NeedMatAmount[p];
					itemamount = 0;
					for i2 = 0 to MAX_ITEM_NUM - 1 do
						if (RItemList[i2].Number == needitem)
						{
							itemamount = RItemList[i2].Amount;
							break;
						}
					if (needitemamount <= itemamount)
					{
						ShowSimpleStatus(rnum, 350, 50);
						DrawFrameRectangle(115, 63, 145, 25, 0, COLOR(255), 25);
						str = " 製藥成功";
						Drawshadowtext(@str[1], 127, 65, COLOR(0x23), COLOR(0x21));

						instruct_2(ritem[inum].GetItem[p], 1 + random(5));
						instruct_32(needitem, -needitemamount);
						Rrole[rnum].ExpForItem = 0;
					}
				}
				//ShowStatus(rnum);
				//WaitKey;
			}
		}
	}

}

//统计一方人数

function int CalRNum(team = 0int ) = 0;
var
int i = 0;
{
	result = 0;
	for i = 0 to broleamount - 1 do
	{
		if ((Brole[i].Team == team) && (Brole[i].Dead == 0)) result = result + 1;
	}

}

//战斗中物品选单

void int BattleMenuItem(bnum = 0)()
	var
	int   rnum = 0;
	int  inum = 0;
	int mode = 0;
str: widestring;
{
	if (MenuItem)
	{
		inum = g_usingItem;
		rnum = brole[bnum].rnum;
		mode = Ritem[inum].ItemType;
		switch (mode) {
3:
			{
				EatOneItem(rnum, inum);
				instruct_32(inum, -1);
				Brole[bnum].Acted = 1;
				WaitKey;
			}
4:
			{
				UseHiddenWeapen(bnum, inum);
			}
		}
	}

}

//动作动画

void PlayActionAmination(bnum, int mode = 0)()
	var
	int   d1 = 0;
	int  d2 = 0;
	int  dm = 0;
	int  rnum = 0;
	int  i = 0;
	int  beginpic = 0;
	int  endpic = 0;
	int  idx = 0;
	int  grp = 0;
	int  tnum = 0;
	int len = 0;
filename: string;
{
	d1 = Ax - Bx;
	d2 = Ay - By;
	dm = abs(d1) - abs(d2);
	if ((dm >= 0))
		if (d1 < 0) Brole[bnum].Face = 0 else Brole[bnum].Face = 3
		else
			if (d2 < 0) Brole[bnum].Face = 2 else Brole[bnum].Face = 1;

	Redraw;
	rnum = brole[bnum].rnum;
	if (rrole[rnum].AmiFrameNum[mode] > 0)
	{
		beginpic = 0;
		for i = 0 to 4 do
		{
			if (i >= mode) break;
			beginpic = beginpic + rrole[rnum].AmiFrameNum[i] * 4;
		}
		beginpic = beginpic + Brole[bnum].Face * rrole[rnum].AmiFrameNum[mode];
		endpic = beginpic + rrole[rnum].AmiFrameNum[mode] - 1;

		filename = format("%3d", [rrole[rnum].HeadNum]);

		for i = 1 to length(filename) do
			if (filename[i] == " ") filename[i] = "0";

		idx = fileopen("fight/fight" + filename + ".idx", fmopenread);
		grp = fileopen("fight/fight" + filename + ".grp", fmopenread);
		len = fileseek(grp, 0, 2);
		fileseek(grp, 0, 0);
		fileread(grp, g_actionBuff[0], len);
		tnum = fileseek(idx, 0, 2) / 4;
		fileseek(idx, 0, 0);
		fileread(idx, g_actIdxBuff[0], tnum * 4);
		fileclose(grp);
		fileclose(idx);

		for i = beginpic to endpic do
		{
			DrawBfieldWithAction(bnum, i);
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			sdl_delay(20);
		}
	}

}

//用毒

void int UsePoision(bnum = 0)()
	var
	int   rnum = 0;
	int  bnum1 = 0;
	int  rnum1 = 0;
	int  poi = 0;
	int  step = 0;
	int addpoi = 0;
select: boolean;
{
	calcanselect(bnum, 1);
	rnum = brole[bnum].rnum;
	poi = Rrole[rnum].UsePoi;
	step = poi / 15 + 1;
	if ((Brole[bnum].Team == 0) && (brole[bnum].Auto == 0))
		select = selectaim(bnum, step);
	if ((bfield[2, Ax, Ay] >= 0) && (select == true))
	{
		Brole[bnum].Acted = 1;
		rrole[rnum].PhyPower = rrole[rnum].PhyPower - 3;
		bnum1 = bfield[2, Ax, Ay];
		if (brole[bnum1].Team <> Brole[bnum].Team)
		{
			rnum1 = brole[bnum1].rnum;
			addpoi = Rrole[rnum].UsePoi / 3 - rrole[rnum1].DefPoi / 4;
			if (addpoi < 0) addpoi = 0;
			if (addpoi + rrole[rnum1].Poision > 99) addpoi = 99 - rrole[rnum1].Poision;
			rrole[rnum1].Poision = rrole[rnum1].Poision + addpoi;
			brole[bnum1].ShowNumber = addpoi;
			SetAminationPosition(0, 0);
			PlayActionAmination(bnum, 0);
			PlayMagicAmination(bnum, 30);
			ShowHurtValue(2);
		}
	}
}

//医疗

void int Medcine(bnum = 0)()
	var
	int   rnum = 0;
	int  bnum1 = 0;
	int  rnum1 = 0;
	int  med = 0;
	int  step = 0;
	int addlife = 0;
select: boolean;
{
	calcanselect(bnum, 1);
	rnum = brole[bnum].rnum;
	med = Rrole[rnum].Medcine;
	step = med / 15 + 1;
	if ((Brole[bnum].Team == 0) && (brole[bnum].Auto == 0))
		select = selectaim(bnum, step)
	else
	{
		Ax = Bx;
		Ay = By;
	}
	if ((bfield[2, Ax, Ay] >= 0) && (select == true))
	{
		Brole[bnum].Acted = 1;
		rrole[rnum].PhyPower = rrole[rnum].PhyPower - 5;
		bnum1 = bfield[2, Ax, Ay];
		if (brole[bnum1].Team == Brole[bnum].Team)
		{
			rnum1 = brole[bnum1].rnum;
			addlife = Rrole[rnum].Medcine; //calculate the value
			if (addlife < 0) addlife = 0;
			if (addlife + rrole[rnum1].CurrentHP > rrole[rnum1].MaxHP) addlife = rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP;
			rrole[rnum1].CurrentHP = rrole[rnum1].CurrentHP + addlife;
			Rrole[rnum1].Hurt = Rrole[rnum1].Hurt - addlife / LIFE_HURT;
			if (Rrole[rnum1].Hurt < 0) Rrole[rnum1].Hurt = 0;
			brole[bnum1].ShowNumber = addlife;
			SetAminationPosition(0, 0);
			PlayActionAmination(bnum, 0);
			PlayMagicAmination(bnum, 0);
			ShowHurtValue(3);
		}
	}

}

//解毒

void int MedPoision(bnum = 0)()
	var
	int   rnum = 0;
	int  bnum1 = 0;
	int  rnum1 = 0;
	int  medpoi = 0;
	int  step = 0;
	int minuspoi = 0;
select: boolean;
{
	calcanselect(bnum, 1);
	rnum = brole[bnum].rnum;
	medpoi = Rrole[rnum].MedPoi;
	step = medpoi / 15 + 1;
	if ((Brole[bnum].Team == 0) && (brole[bnum].Auto == 0))
		select = selectaim(bnum, step)
	else
	{
		Ax = Bx;
		Ay = By;
	}
	if ((bfield[2, Ax, Ay] >= 0) && (select == true))
	{
		Brole[bnum].Acted = 1;
		rrole[rnum].PhyPower = rrole[rnum].PhyPower - 5;
		bnum1 = bfield[2, Ax, Ay];
		if (brole[bnum1].Team == Brole[bnum].Team)
		{
			rnum1 = brole[bnum1].rnum;
			minuspoi = Rrole[rnum].MedPoi;
			if (minuspoi < 0) minuspoi = 0;
			if (rrole[rnum1].Poision - minuspoi <= 0) minuspoi = rrole[rnum1].Poision;
			rrole[rnum1].Poision = rrole[rnum1].Poision - minuspoi;
			brole[bnum1].ShowNumber = minuspoi;
			SetAminationPosition(0, 0);
			PlayActionAmination(bnum, 0);
			PlayMagicAmination(bnum, 36);
			ShowHurtValue(4);
		}
	}

}

//使用暗器

void UseHiddenWeapen(bnum, int inum = 0)()
	var
	int   rnum = 0;
	int  bnum1 = 0;
	int  rnum1 = 0;
	int  hidden = 0;
	int  step = 0;
	int hurt = 0;
select: boolean;
{
	calcanselect(bnum, 1);
	rnum = brole[bnum].rnum;
	hidden = rrole[rnum].HidWeapon;
	step = hidden / 15 + 1;
	if (ritem[inum].UnKnow7 > 0)
		callevent(ritem[inum].UnKnow7)
	else {
		if ((Brole[bnum].Team == 0) && (brole[bnum].Auto == 0))
			select = selectaim(bnum, step);
		if ((bfield[2, Ax, Ay] >= 0) && (select == true) && (brole[bfield[2, Ax, Ay]].Team <> 0))
		{
			Brole[bnum].Acted = 1;
			instruct_32(inum, -1);
			bnum1 = bfield[2, Ax, Ay];
			if (brole[bnum1].Team <> Brole[bnum].Team)
			{
				rnum1 = brole[bnum1].rnum;
				hurt = rrole[rnum].HidWeapon / 2 - ritem[inum].AddCurrentHP / 3;
				hurt = hurt * (rrole[rnum1].Hurt / 33 + 1);
				if (hurt < 0) hurt = 0;
				rrole[rnum1].CurrentHP = rrole[rnum1].CurrentHP - hurt;
				brole[bnum1].ShowNumber = hurt;
				SetAminationPosition(0, 0);
				PlayActionAmination(bnum, 0);
				PlayMagicAmination(bnum, ritem[inum].AmiNum);
				ShowHurtValue(0);
			}
		}
	}

}

//休息

void int Rest(bnum = 0)()
	var
	int rnum = 0;
{
	Brole[bnum].Acted = 1;
	rnum = brole[bnum].rnum;
	RRole[rnum].CurrentHP = RRole[rnum].CurrentHP + RRole[rnum].MaxHP / 20;
	if (RRole[rnum].CurrentHP > RRole[rnum].MaxHP) RRole[rnum].CurrentHP = RRole[rnum].MaxHP;
	RRole[rnum].CurrentMP = RRole[rnum].CurrentMP + RRole[rnum].MaxMP / 20;
	if (RRole[rnum].CurrentMP > RRole[rnum].MaxMP) RRole[rnum].CurrentMP = RRole[rnum].MaxMP;
	rrole[rnum].PhyPower = rrole[rnum].PhyPower + MAX_PHYSICAL_POWER / 20;
	if (rrole[rnum].PhyPower > MAX_PHYSICAL_POWER) rrole[rnum].PhyPower = MAX_PHYSICAL_POWER;

}

//The AI.

void int AutoBattle(bnum = 0)()
	var
	int   i = 0;
	int  p = 0;
	int  a = 0;
	int  temp = 0;
	int  rnum = 0;
	int  inum = 0;
	int  eneamount = 0;
	int  aim = 0;
	int  mnum = 0;
	int  level = 0;
	int  Ax1 = 0;
	int  Ay1 = 0;
	int  i1 = 0;
	int  i2 = 0;
	int  step = 0;
	int  step1 = 0;
	int  dis0 = 0;
	int dis = 0;
str: widestring;
{
	rnum = brole[bnum].rnum;
	showsimplestatus(rnum, 350, 50);
	sdl_delay(450);
	//showmessage("");
	//Life is less than 20%, 70% probality to medcine || eat a pill.
	//生命低于20%, 70%可能医疗或吃药
	if ((Brole[bnum].Acted == 0) && (RRole[rnum].CurrentHP < RRole[rnum].MaxHP / 5))
	{
		if (random(100) < 70)
		{
			//医疗大于50, 且体力大于50才对自身医疗
			if ((Rrole[rnum].Medcine >= 50) && (rrole[rnum].PhyPower >= 50) && (random(100) < 50))
			{
				medcine(bnum);
			} else
			{
				// if can"t medcine, eat the item which can add the most life on its body.
				//无法医疗则选择身上加生命最多的药品, 我方从物品栏选择
				AutoUseItem(bnum, 45);
			}
		}
	}

	//MP is less than 20%, 60% probality to eat a pill.
	//内力低于20%, 60%可能吃药
	if ((Brole[bnum].Acted == 0) && (RRole[rnum].CurrentMP < RRole[rnum].MaxMP / 5))
	{
		if (random(100) < 60)
		{
			AutoUseItem(bnum, 50);
		}
	}

	//Physical power is less than 20%, 80% probality to eat a pill.
	//体力低于20%, 80%可能吃药
	if ((Brole[bnum].Acted == 0) && (rrole[rnum].PhyPower < MAX_PHYSICAL_POWER / 5))
	{
		if (random(100) < 80)
		{
			AutoUseItem(bnum, 48);
		}
	}

	//如未能吃药且体力大于10, 则尝试攻击
	if ((Brole[bnum].Acted == 0) && (rrole[rnum].PhyPower >= 10))
	{
		//在敌方选择一个人物
		eneamount = Calrnum(1 - Brole[bnum].Team);
		aim = random(eneamount) + 1;
		//showmessage(inttostr(eneamount));
		for i = 0 to broleamount - 1 do
		{
			if ((Brole[bnum].Team <> Brole[i].Team) && (Brole[i].Dead == 0))
			{
				aim = aim - 1;
				if (aim <= 0) break;
			}
		}
		//Seclect one enemy randomly && try to close it.
		//尝试走到离敌人最近的位置
		Ax = Bx;
		Ay = By;
		Ax1 = Brole[i].X;
		Ay1 = Brole[i].Y;
		CalCanSelect(bnum, 0);
		dis0 = abs(Ax1 - Bx) + abs(Ay1 - By);
		for i1 = min(Ax1, Bx) to max(Ax1, Bx) do
			for i2 = min(Ay1, By) to max(Ay1, By) do
			{
				if (Bfield[3, i1, i2] == 0)
				{
					dis = abs(Ax1 - i1) + abs(Ay1 - i2);
					if ((dis < dis0) && (abs(i1 - Bx) + abs(i2 - By) <= brole[bnum].Step))
					{
						Ax = i1;
						Ay = i2;
						dis0 = dis;
					}
				}
			}
		if (Bfield[3, Ax, Ay] == 0) MoveAmination(bnum);
		Ax = Brole[i].X;
		Ay = Brole[i].Y;

		//Try to attack it. select the best WUGONG.
		//使用目前最强的武功攻击
		p = 0;
		a = 0;
		temp = 0;
		for i1 = 0 to 9 do
		{
			mnum = Rrole[rnum].Magic[i1];
			if (mnum > 0)
			{
				a = a + 1;
				level = Rrole[rnum].MagLevel[i1] / 100 + 1;
				if (RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * ((level + 1) / 2)) level = RRole[rnum].CurrentMP / rmagic[mnum].NeedMP * 2;
				if (level > 10) level = 10;
				if (level <= 0) level = 1;
				if (rmagic[mnum].Attack[level - 1] > temp)
				{
					p = i1;
					temp = rmagic[mnum].Attack[level - 1];
				}
			}
		}
		//5% probility to re-select WUGONG randomly.
		//5%的可能重新选择武功
		if (random(100) < 5) p = random(a);

		//If the most powerful Wugong can"t attack the aim,
		//re-select the one which has the longest attatck-distance.
		//如最强武功打不到, 选择攻击距离最远的武功
		if (abs(Ax - Bx) + abs(Ay - By) > step)
		{
			p = 0;
			a = 0;
			temp = 0;
			for i1 = 0 to 9 do
			{
				mnum = Rrole[rnum].Magic[i1];
				if (mnum > 0)
				{
					level = Rrole[rnum].MagLevel[i1] / 100 + 1;
					a = rmagic[mnum].MoveDistance[level - 1];
					if (rmagic[mnum].AttAreaType == 3) a = a + rmagic[mnum].AttDistance[level - 1];
					if (a > temp)
					{
						p = i1;
						temp = a;
					}
				}
			}
		}

		mnum = Rrole[rnum].Magic[p];
		level = Rrole[rnum].MagLevel[p] / 100 + 1;
		step = rmagic[mnum].MoveDistance[level - 1];
		step1 = 0;
		if (rmagic[mnum].AttAreaType == 3) step1 = rmagic[mnum].AttDistance[level - 1];
		if (abs(Ax - Bx) + abs(Ay - By) <= step + step1)
		{
			//step = Rmagic[mnum, 28+level-1];
			if ((rmagic[mnum].AttAreaType == 3))
			{
				//step1 = Rmagic[mnum, 38+level-1];
				dis = 0;
				Ax1 = Bx;
				Ay1 = By;
				for i1 = min(Ax, Bx) to max(Ax, Bx) do
					for i2 = min(Ay, By) to max(Ay, By) do
					{
						if ((abs(i1 - Ax) <= step1) && (abs(i2 - Ay) <= step1) && (abs(i1 - Bx) + abs(i2 - By) <= step + step1))
						{
							if (dis < abs(i1 - Bx) + abs(i2 - By))
							{
								dis = abs(i1 - Bx) + abs(i2 - By);
								Ax1 = i1;
								Ay1 = i2;
							}
						}
					}
				Ax = Ax1;
				Ay = Ay1;
			}
			if (Rmagic[mnum].AttAreaType <> 3)
				SetAminationPosition(Rmagic[mnum].AttAreaType, step)
			else
				SetAminationPosition(Rmagic[mnum].AttAreaType, step1);

			if (bfield[4, Ax, Ay] <> 0)
			{
				Brole[bnum].Acted = 1;
				for i1 = 0 to sign(Rrole[rnum].AttTwice) do
				{
					Rrole[rnum].MagLevel[p] = Rrole[rnum].MagLevel[p] + random(2) + 1;
					if (Rrole[rnum].MagLevel[p] > 999) Rrole[rnum].MagLevel[p] = 999;
					if (rmagic[mnum].UnKnow[4] > 0) callevent(rmagic[mnum].UnKnow[4])
					else AttackAction(bnum, mnum, level);
				}
			}
		}
	}

	//If all other actions fail, rest.
	//如果上面行动全部失败则休息
	if (Brole[bnum].Acted == 0) rest(bnum);

	//检查是否有esc被按下
	if (SDL_PollEvent(@event) >= 0)
	{
		if ((event.type == SDL_QUITEV))
			if (messagedlg("Are you sure to quit?", mtConfirmation, [mbOk, mbCancel], 0) == idOK) Quit;
		if ((event.key.keysym.sym == sdlk_Escape))
		{
			brole[bnum].Auto = 0;
		}
	}
}

//自动使用list的值最大的物品

void AutoUseItem(bnum, int list = 0)()
	var
	int   i = 0;
	int  p = 0;
	int  temp = 0;
	int  rnum = 0;
	int inum = 0;
str: widestring;
{
	rnum = brole[bnum].rnum;
	if (Brole[bnum].Team <> 0)
	{
		temp = 0;
		p = -1;
		for i = 0 to 3 do
		{
			if (Rrole[rnum].TakingItem[i] >= 0)
			{
				if (ritem[Rrole[rnum].TakingItem[i]].Data[list] > temp)
				{
					temp = ritem[Rrole[rnum].TakingItem[i]].Data[list];
					p = i;
				}
			}
		}
	} else
	{
		temp = 0;
		p = -1;
		for i = 0 to MAX_ITEM_NUM - 1 do
		{
			if ((RItemList[i].Amount > 0) && (ritem[RItemList[i].Number].ItemType == 3))
			{
				if (ritem[RItemList[i].Number].Data[list] > temp)
				{
					temp = ritem[RItemList[i].Number].Data[list];
					p = i;
				}
			}
		}
	}

	if (p >= 0)
	{
		if (Brole[bnum].Team <> 0)
			inum = rrole[rnum].TakingItem[p]
		else
			inum = RItemList[p].Number;
		redraw;
		SDL_UpdateRect(g_screenSurface, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
		EatOneItem(rnum, inum);
		if (Brole[bnum].Team <> 0)
			instruct_41(rnum, rrole[rnum].TakingItem[p], -1)
		else
			instruct_32(RItemList[p].Number, -1);
		Brole[bnum].Acted = 1;
		sdl_delay(750);
	}

}

}

//显示战场图片
static void DrawBFPic(int index, int x, int y, int highlight)
{
	DrawPicOnScreen(index, x, y, g_bfIdxBuff, g_bfPicBuff, highlight);
}
#endif

#if 0
//将战场映像画到屏幕
void DrawBFieldOnScreen(int x, int y)
{
	int maxW = g_bfSurface->w - x;
	int maxH = g_bfSurface->h - y;
	SDL_Rect srcRect = {
		x = x, .y = y,
		.w = SCREEN_WIDTH < maxW ? SCREEN_WIDTH : maxW,
		.h = SCREEN_HEIGHT < maxH ? SCREEN_HEIGHT : maxH
	};

	SDL_Rect dstRect = {
		x = 0, .y = 0,
		.w = SCREEN_WIDTH,
		.h = SCREEN_HEIGHT
	};

	SDL_BlitSurface(g_bfSurface, &srcRect, g_screenSurface, &dstRect);
}
#endif
