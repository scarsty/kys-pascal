/*******************************************************************************
* jinyong.c                                                 fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

/*******************************************************************************
* Headers                                                                      *
*******************************************************************************/

#include "draw.h"
#include "game.h"
#include "scence.h"

#include "cmd.h"

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

uint32* g_talkIdxBuff = NULL;
byte* g_talkBuff = NULL;

uint32* g_cmdIdxBuff = NULL;
byte* g_cmdGrpBuff = NULL;

int g_ex = 0;
int g_ey = 0;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

//事件指令含义请参阅其他相关文献
void CmdRedraw(sint16** cmd)	//0
{
	if (cmd) (*cmd)++;
	Redraw();
}

void CmdTalk(sint16** cmd)	//1
{
	(*cmd)++;
	int talkIndex = *((*cmd)++);
	int faceIndex = *((*cmd)++);
	int dispMode = *((*cmd)++);

	int talkX = 0;
	int talkY = 0;
	int talkWidth = 0;
	int talkHeight = 0;
	int faceX = 0;
	int faceY = 0;
	int textX = 0;
	int textY = 0;
	int textWidth = 0;
	int textHeight = 0;

	switch (dispMode) {
		case 0:
			talkX = TALK_1_X;
			talkY = TALK_1_Y;
			talkWidth = TALK_1_WIDTH;
			talkHeight = TALK_1_HEIGHT;
			faceX = TALK_1_FACE_X;
			faceY = TALK_1_FACE_Y;
			textX = TALK_1_TEXT_X;
			textY = TALK_1_TEXT_Y;
			textWidth = TALK_1_TEXT_WIDTH;
			textHeight = TALK_1_TEXT_HEIGHT;
			break;
		case 1:
			talkX = TALK_2_X;
			talkY = TALK_2_Y;
			talkWidth = TALK_2_WIDTH;
			talkHeight = TALK_2_HEIGHT;
			faceX = TALK_2_FACE_X;
			faceY = TALK_2_FACE_Y;
			textX = TALK_2_TEXT_X;
			textY = TALK_2_TEXT_Y;
			textWidth = TALK_2_TEXT_WIDTH;
			textHeight = TALK_2_TEXT_HEIGHT;
			break;
		case 2:
			talkX = TALK_3_X;
			talkY = TALK_3_Y;
			talkWidth = TALK_3_WIDTH;
			talkHeight = TALK_3_HEIGHT;
			faceX = 0;
			faceY = 0;
			textX = TALK_3_TEXT_X;
			textY = TALK_3_TEXT_Y;
			textWidth = TALK_3_TEXT_WIDTH;
			textHeight = TALK_3_TEXT_HEIGHT;
			break;
		case 3:
			talkX = TALK_4_X;
			talkY = TALK_4_Y;
			talkWidth = TALK_4_WIDTH;
			talkHeight = TALK_4_HEIGHT;
			faceX = 0;
			faceY = 0;
			textX = TALK_4_TEXT_X;
			textY = TALK_4_TEXT_Y;
			textWidth = TALK_4_TEXT_WIDTH;
			textHeight = TALK_4_TEXT_HEIGHT;
			break;
		case 4:
			talkX = TALK_5_X;
			talkY = TALK_5_Y;
			talkWidth = TALK_5_WIDTH;
			talkHeight = TALK_5_HEIGHT;
			faceX = TALK_5_FACE_X;
			faceY = TALK_5_FACE_Y;
			textX = TALK_5_TEXT_X;
			textY = TALK_5_TEXT_Y;
			textWidth = TALK_5_TEXT_WIDTH;
			textHeight = TALK_5_TEXT_HEIGHT;
			break;
		case 5:
			talkX = TALK_6_X;
			talkY = TALK_6_Y;
			talkWidth = TALK_6_WIDTH;
			talkHeight = TALK_6_HEIGHT;
			faceX = TALK_6_FACE_X;
			faceY = TALK_6_FACE_Y;
			textX = TALK_6_TEXT_X;
			textY = TALK_6_TEXT_Y;
			textWidth = TALK_6_TEXT_WIDTH;
			textHeight = TALK_6_TEXT_HEIGHT;
			break;
		default:
			break;
	}

	byte* talk = talkIndex ? g_talkBuff + *(g_talkIdxBuff + talkIndex - 1) : g_talkBuff;
	byte* nextTalk = g_talkBuff + *(g_talkIdxBuff + talkIndex);
	char talkStr[TEXT_BIG5_LEN] = {'\0'};
	byte* p = (byte*)talkStr;
	bool qm = FALSE;

	for (; talk < nextTalk && p < (byte*)talkStr + TEXT_BIG5_LEN; talk++) {
		if (*talk != (byte)~'\x2a') {
			*p = ~*talk;

			if (*(p - 1) == (byte)'\xa1') {
				switch (*p) {
					case (byte)'\x44':			//点替换成句号或者省略号
						if (*(p - 3) == (byte)'\xa1' && *(p - 2) == (byte)'\x43') {
							*(p - 2) = (byte)'\x4b';
							*p = (byte)'\x4b';
						} else if (*(p - 3) == (byte)'\xa1' && *(p - 2) == (byte)'\x4b') {
							p -= 2;
						} else {
							*p = (byte)'\x43';
						}
						break;
					case (byte)'\xa8':			//右双引号替换成左双引号
						if (!qm) {
							*p = (byte)'\xa7';
						}
						qm = !qm;
						break;
					default:
						break;
				}
			}

			p++;
		}
	}
	*(p - 1) = '\0';

	DrawTalk(talkStr, talkX, talkY, talkWidth, talkHeight, faceIndex, faceX, faceY, textX, textY, textWidth, textHeight);
}

void RearrangeItem()
{
	T_ItemList item[ITEM_NUM];
	int itemNum = 0;

	int i = 0;
	for (i = 0; i < ITEM_NUM; i++) {
		if (g_itemList[i].index >= 0 && g_itemList[i].num > 0)
		{
			item[i] = g_itemList[i];
		}
	}
	itemNum = i;

	for (i = 0; i < ITEM_NUM; i++) {
		if (i < itemNum)
		{
			g_itemList[i] = item[i];
		} else {
			g_itemList[i].index = -1;
			g_itemList[i].num = 0;
		}
	}
}

//得到物品可显示数量, 数量为负显示失去物品
void CmdGetItem(sint16** cmd)	//2
{
	(*cmd)++;
	int item = *((*cmd)++);
	int num = *((*cmd)++);

	bool bFount = FALSE;

	int i;
	for (i = 0; g_itemList[i].index >= 0 && i < ITEM_NUM; i++) {
		if (g_itemList[i].index == item) {
			g_itemList[i].num += num;

			if (g_itemList[i].num < 0) {
				g_itemList[i].num = 0;
			}

			bFount = TRUE;
			break;
		}
	}

	if (!bFount) {
		if (i < ITEM_NUM) {
			g_itemList[i].index = item;
			g_itemList[i].num =num;
		} else {
			return;
		}
	}

	RearrangeItem();

	int x = SCREEN_CENTER_X;
	char str[TEXT_UTF8_LEN];
	sprintf(str, "%s%d個%s", num > 0 ? "得到" : "失去", num, Big5ToUtf8(g_roleData.items[item].name));

	DrawFrameText(str, TEXT_NORMAL_COLOR, TEXT_COLOR);
	UpdateScreen();
	WaitKey();
	Redraw();
}

//改变事件，如在当前场景需重置场景。在需改变贴图较多时效率较低
void CmdChageScence(sint16** cmd)	//3
{
	(*cmd)++;

	int scence = *((*cmd)++);
	if (scence == -2) scence = g_curScence;
	int eventIndex = *((*cmd)++);
	if (eventIndex == -2) eventIndex = g_curEvent;

	T_Event* event = (T_Event*)*cmd;
	*cmd = (sint16*)(event + 1);
	if(event->x == -2) event->x = g_scenceEventData[scence][eventIndex].x;
	if(event->y == -2) event->y = g_scenceEventData[scence][eventIndex].y;

	g_scenceEventData[scence][eventIndex] = *event;

	g_scenceData[scence][EmScenceLayerEvent][g_scenceEventData[scence][eventIndex].y][g_scenceEventData[scence][eventIndex].x] = eventIndex;
}

//是否使用了某剧情物品
void CmdIsUsingSpItem(sint16** cmd)	//4
{
	(*cmd)++;

	int item = *((*cmd)++);
	int jump1 = *((*cmd)++);
	int jump2 = *((*cmd)++);

	(*cmd) += item == g_usingItem ? jump1 : jump2;
}

//询问是否战斗
int CmdChalenge(sint16** cmd)	//5
{
	(*cmd)++;

	int jump1 = *((*cmd)++);
	int jump2 = *((*cmd)++);

	char* str[] = {
		"是否與之過招？",
		"罢了",
		"過招"
	};

	bool select = ShowYesNoBox(str);

	(*cmd) += select ? jump1 : jump2;
	Redraw();
}

#if 0
//战斗

int function instruct_6(battlenum = 0;
		int  jump1 = 0;
		int  jump2 = 0;
		int getexp = 0int ) = 0;
{
	result = jump2;
	if (Battle(battlenum, getexp))
		result = jump1;

}

//询问是否加入

void int instruct_8(musicnum = 0)()
{
	exitscencemusicnum = musicnum;
}

int function instruct_9(jump1 = 0;
		int jump2 = 0int ) = 0;
var
int menu = 0;
{
	setlength(menustring, 3);
	menustring[0] = " 取消";
	menustring[1] = " 要求";
	menustring[2] = " 是否要求加入？";
	drawtextwithrect(@menustring[2][1], SCREEN_CENTER_X - 75, SCREEN_CENTER_Y - 85, 150, COLOR(7), COLOR(5));
	menu = commonmenu2(SCREEN_CENTER_X - 49, SCREEN_CENTER_Y - 50, 98);
	if (menu == 1) result = jump1 else result = jump2;
	redraw;
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}

//加入队友, 同时得到其身上物品

void int instruct_10(rnum = 0)()
	var
	int   i = 0;
	int i1 = 0;
{
	for i = 0 to 5 do
	{
		if (Teamlist[i] < 0)
		{
			Teamlist[i] = rnum;
			for i1 = 0 to 3 do
			{
				if ((Rrole[rnum].TakingItem[i1] >= 0) && (Rrole[rnum].TakingItemAmount[i1] > 0))
				{
					instruct_2(Rrole[rnum].TakingItem[i1], Rrole[rnum].TakingItemAmount[i1]);
					Rrole[rnum].TakingItem[i1] = -1;
					Rrole[rnum].TakingItemAmount[i1] = 0;
				}
			}
			break;
		}
	}

}

//询问是否住宿

int function instruct_11(jump1 = 0;
		int jump2 = 0int ) = 0;
var
int menu = 0;
{
	setlength(menustring, 3);
	menustring[0] = " 否";
	menustring[1] = " 是";
	menustring[2] = " 是否需要住宿？";
	drawtextwithrect(@menustring[2][1], SCREEN_CENTER_X - 75, SCREEN_CENTER_Y - 85, 150, COLOR(7), COLOR(5));
	menu = commonmenu2(SCREEN_CENTER_X - 49, SCREEN_CENTER_Y - 50, 98);
	if (menu == 1) result = jump1 else result = jump2;
	redraw;
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);

}
#endif

//住宿
void CmdSleep(sint16** cmd) //12
{
	if (cmd) (*cmd)++;

	int i;
	for (i = 0; i < MAX_TEAM_ROLE; i++) {
		int role = g_roleData.common.team[i];
		if (g_roleData.roles[role].wound < WOUND_SERIOUS && g_roleData.roles[role].poisioning == 0) {
			g_roleData.roles[role].life = g_roleData.roles[role].maxLife;
			g_roleData.roles[role].neili = g_roleData.roles[role].maxNeili;
			g_roleData.roles[role].phyPower = MAX_PHYSICAL_POWER;
		}
	}
}

//亮屏
void CmdScreenFadeIn(sint16** cmd) //13
{
	if (cmd) (*cmd)++;

	int i;
	for (i = 0xff; i > 0; i -= 0x0f) {
		RedrawWithoutUpdate();
		DrawRectangle(0, 0, g_screenSurface->w, g_screenSurface->h, 0, i);
		UpdateScreen();
	}

	RedrawWithoutUpdate();
	UpdateScreen();
}

//黑屏
void CmdScreenFadeOut(sint16** cmd) //14
{
	if (cmd) (*cmd)++;

	int i;
	for (i = 0; i < 0xff; i += 0x0f) {
		RedrawWithoutUpdate();
		DrawRectangle(0, 0, g_screenSurface->w, g_screenSurface->h, 0, i);
		UpdateScreen();
	}

	DrawRectangle(0, 0, g_screenSurface->w, g_screenSurface->h, 0, 0xff);
	UpdateScreen();
}

#if 0

//失败画面

void instruct_15()
	var
	int i = 0;
str: widestring;
{
	g_inGame = 3;
	redraw;
	str = " 勝敗乃兵家常事，但是…";
	drawshadowtext(@str[1], 50, 330, COLOR(255), COLOR(255));
	str = " 地球上又多了一失蹤人口";
	drawshadowtext(@str[1], 50, 360, COLOR(255), COLOR(255));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
}

int function instruct_16(rnum = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump2;
	for i = 0 to 5 do
	{
		if (Teamlist[i] == rnum)
		{
			result = jump1;
			break;
		}
	}
}

void instruct_17(list: array of integer)()
	var
	int   i1 = 0;
	int i2 = 0;
{
	if (list[0] == -2) list[0] = g_curScence;
	g_scenceData[list[0], list[1], list[3], list[2]] = list[4];

}

int function instruct_18(inum = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump2;
	for i = 0 to ITEM_NUM - 1 do
	{
		if (RItemList[i].Number == inum)
		{
			result = jump1;
			break;
		}
	}
}

void instruct_19(x, int y = 0)()
{
	Sx = y;
	Sy = x;
	g_ex = Sx;
	g_ey = Sy;
	Redraw;
}

//Judge the team is full || not.

int function instruct_20(jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump1;
	for i = 0 to 5 do
	{
		if (TeamList[i] < 0)
		{
			result = jump2;
			break;
		}
	}
}

void int instruct_21(rnum = 0)()
	var
	int   i = 0;
	int p = 0;
newlist: array[0..5] of integer;
{
	p = 0;
	for i = 0 to 5 do
	{
		newlist[i] = -1;
		if (Teamlist[i] <> rnum)
		{
			newlist[p] = Teamlist[i];
			p = p + 1;
		}
	}
	for i = 0 to 5 do
		Teamlist[i] = newlist[i];
}

void instruct_22()
	var
	int i = 0;
{
	for i = 0 to 5 do
		RRole[Teamlist[i]].CurrentMP = 0;
}

void instruct_23(rnum, int Poision = 0)()
{
	RRole[rnum].UsePoi = Poision;
}

//Black the g_screenSurface when fail in battle.
//Note: never be used, leave it as blank.

void instruct_24()
{
}

//Note: never display the leading role.
//This will be improved when I have a better method.

void instruct_25(x1, y1, x2, int y2 = 0)()
	var
	int   i = 0;
	int s = 0;
{
	s = sign(x2 - x1);
	i = x1 + s;
	//showmessage(inttostr(ssx*100+ssy));
	if (s <> 0)
		while s * (x2 - i) >= 0 do
		{
			sdl_delay(50);
			DrawScenceWithoutRole(y1, i);
			//showmessage(inttostr(i));
			DrawRoleOnScence(y1, i);
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			i = i + s;
			//showmessage(inttostr(s*(x2-i)));
		}
	s = sign(y2 - y1);
	i = y1 + s;
	if (s <> 0)
		while s * (y2 - i) >= 0 do
		{
			sdl_delay(50);
			DrawScenceWithoutRole(i, x2);
			//showmessage(inttostr(i));
			DrawRoleOnScence(i, x2);
			//Redraw;
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			i = i + s;
		}
	g_ex = y2;
	g_ey = x2;
	//SSx=0;
	//SSy=0;
	//showmessage(inttostr(ssx*100+ssy));
}

void instruct_26(snum, enum, add1, add2, int add3 = 0)()
{
	if (snum == -2) snum = g_curScence;
	g_scenceEventData[snum, enum, 2] = g_scenceEventData[snum, enum, 2] + add1;
	g_scenceEventData[snum, enum, 3] = g_scenceEventData[snum, enum, 3] + add2;
	g_scenceEventData[snum, enum, 4] = g_scenceEventData[snum, enum, 4] + add3;

}

//Note: of course an more effective engine can take place of it.
//动画, 至今仍不完善

void instruct_27(enum, beginpic, int endpic = 0)()
	var
	int   i = 0;
	int  xpoint = 0;
	int ypoint = 0;
AboutMainRole: boolean;
{
	AboutMainRole = false;
	if (enum == -1)
	{
		enum = g_curEvent;
		if (g_curScenceData[ 3, Sx, Sy] >= 0)
			enum = g_curScenceData[ 3, Sx, Sy];
		AboutMainRole = true;
	}
	if (enum == g_curScenceData[ 3, Sx, Sy]) AboutMainRole = true;
	g_curScenceData[ 3, g_curScenceEventData[ enum, 10], g_curScenceEventData[ enum, 9]] = enum;
	for i = beginpic to endpic do
	{
		g_curScenceEventData[ enum, 5] = i;
		UpdateScence(g_curScenceEventData[ enum, 10], g_curScenceEventData[ enum, 9]);
		sdl_delay(20);
		DrawScenceWithoutRole(Sx, Sy);
		if (not (AboutMainRole))
			DrawRoleOnScence(Sx, Sy);
		//showmessage(inttostr(enum+100*g_curEvent));
		SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	}
	//showmessage(inttostr(Sx+100*Sy));
	//showmessage(inttostr(g_curScenceEventData[ [enum,10]+100*g_curScenceEventData[ [enum,9]));
	g_curScenceEventData[ enum, 5] = g_curScenceEventData[ enum, 7];
	UpdateScence(g_curScenceEventData[ enum, 10], g_curScenceEventData[ enum, 9]);
}

int function instruct_28(rnum = 0;
		int  e1 = 0;
		int  e2 = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
{
	result = jump2;
	if ((rrole[rnum].Ethics >= e1) && (rrole[rnum].Ethics <= e2)) result = jump1;
}

int function instruct_29(rnum = 0;
		int  r1 = 0;
		int  r2 = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
{
	result = jump2;
	if ((rrole[rnum].Attack >= r1) && (rrole[rnum].Attack <= r2)) result = jump1;
}

void instruct_30(x1, y1, x2, int y2 = 0)()
	var
	int s = 0;
{
	s = sign(x2 - x1);
	Sy = x1 + s;
	if (s > 0) g_sFace = 1;
	if (s < 0) g_sFace = 2;
	if (s <> 0)
		while s * (x2 - Sy) >= 0 do
		{
			sdl_delay(50);
			DrawScenceWithoutRole(Sx, Sy);
			g_sStep = g_sStep + 1;
			if (g_sStep >= 8) g_sStep = 0;
			DrawRoleOnScence(Sx, Sy);
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			Sy = Sy + s;
		}
	s = sign(y2 - y1);
	Sx = y1 + s;
	if (s > 0) g_sFace = 3;
	if (s < 0) g_sFace = 0;
	if (s <> 0)
		while s * (y2 - Sx) >= 0 do
		{
			sdl_delay(50);
			DrawScenceWithoutRole(Sx, Sy);
			g_sStep = g_sStep + 1;
			if (g_sStep >= 8) g_sStep = 0;
			DrawRoleOnScence(Sx, Sy);
			SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			Sx = Sx + s;
		}
	Sx = y2;
	Sy = x2;
	g_sStep = 0;
	g_ex = Sx;
	g_ey = Sy;
}

int function instruct_31(moneynum = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump2;
	for i = 0 to ITEM_NUM - 1 do
	{
		if ((RItemList[i].Number == MONEY_ID) && (RItemList[i].Amount >= moneynum))
		{
			result = jump1;
			break;
		}
	}
}

void instruct_32(inum, int amount = 0)()
	var
	int i = 0;
word: widestring;
{
	i = 0;
	while (RItemList[i].Number >= 0) && (i < ITEM_NUM) do
	{
		if ((RItemList[i].Number == inum))
		{
			RItemList[i].Amount = RItemList[i].Amount + amount;
			if ((RItemList[i].Amount < 0) && (amount >= 0)) RItemList[i].Amount = 32767;
			if ((RItemList[i].Amount < 0) && (amount < 0)) RItemList[i].Amount = 0;
			break;
		}
		i = i + 1;
	}
	if (RItemList[i].Number < 0)
	{
		RItemList[i].Number = inum;
		RItemList[i].Amount = amount;
	}
	ReArrangeItem;
}

//学到武功, 如果已有武功则升级, 如果已满10个不会洗武功

void instruct_33(rnum, magicnum, int dispMode = 0)()
	var
	int i = 0;
word: widestring;
{
	for i = 0 to 9 do
	{
		if ((RRole[rnum].Magic[i] <= 0) || (RRole[rnum].Magic[i] == magicnum))
		{
			if (RRole[rnum].Magic[i] > 0) RRole[rnum].Maglevel[i] = RRole[rnum].Maglevel[i] + 100;
			RRole[rnum].Magic[i] = magicnum;
			if (RRole[rnum].MagLevel[i] > 999) RRole[rnum].Maglevel[i] = 999;
			break;
		}
	}
	//if (i == 10) rrole[rnum].data[i+63] = magicnum;
	if (dispMode == 0)
	{
		DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 76, 0, COLOR(255), 30);
		word = " 學會";
		drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
		drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
		drawbig5shadowtext(@Rmagic[magicnum].Name, SCREEN_CENTER_X - 90, 150, COLOR(0x66), COLOR(0x64));
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		WaitKey;
		redraw;
	}
}

void instruct_34(rnum, int iq = 0)()
	var
	word: widestring;
{
	if (RRole[rnum].Aptitude + iq <= 100)
	{
		RRole[rnum].Aptitude = RRole[rnum].Aptitude + iq;
	}
	else {
		iq = 100 - RRole[rnum].Aptitude;
		RRole[rnum].Aptitude = 100;
	}
	if (iq > 0)
	{
		DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 51, 0, COLOR(255), 30);
		word = " 資質增加";
		drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
		drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
		word = format("%3d", [iq]);
		drawengshadowtext(@word[1], SCREEN_CENTER_X + 30, 125, COLOR(0x66), COLOR(0x64));
		sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		WaitKey;
		redraw;
	}
}

void instruct_35(rnum, magiclistnum, magicnum, int exp = 0)()
	var
	int i = 0;
{
	if ((magiclistnum < 0) || (magiclistnum > 9))
	{
		for i = 0 to 9 do
		{
			if (RRole[rnum].Magic[i] <= 0)
			{
				RRole[rnum].Magic[i] = magicnum;
				RRole[rnum].MagLevel[i] = exp;
				break;
			}
		}
		if (i == 10)
		{
			RRole[rnum].Magic[0] = magicnum;
			RRole[rnum].MagLevel[i] = exp;
		}
	}
	else {
		RRole[rnum].Magic[magiclistnum] = magicnum;
		RRole[rnum].MagLevel[magiclistnum] = exp;
	}
}

int function instruct_36(sexual = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
{
	result = jump2;
	if (rrole[0].Sexual == sexual) result = jump1;
	if (sexual > 255)
		if (x50[0x7000] == 0) result = jump1 else result = jump2;
}

void int instruct_37(Ethics = 0)()
{
	RRole[0].Ethics = RRole[0].Ethics + ethics;
	if (RRole[0].Ethics > 100) RRole[0].Ethics = 100;
	if (RRole[0].Ethics < 0) RRole[0].Ethics = 0;
}

void instruct_38(snum, layernum, oldpic, int newpic = 0)()
	var
	int   i1 = 0;
	int i2 = 0;
{
	if (snum == -2) snum = g_curScence;
	for i1 = 0 to 63 do
		for i2 = 0 to 63 do
		{
			if (g_scenceData[snum, layernum, i1, i2] == oldpic) g_scenceData[snum, layernum, i1, i2] = newpic;
		}
}

void int instruct_39(snum = 0)()
{
	g_roleData.scences[snum].EnCondition = 0;
}

void int instruct_40(director = 0)()
{
	g_sFace = director;
}

void instruct_41(rnum, inum, int amount = 0)()
	var
	int   i = 0;
	int p = 0;
{
	p = 0;
	for i = 0 to 3 do
	{
		if (Rrole[rnum].TakingItem[i] == inum)
		{
			Rrole[rnum].TakingItemAmount[i] = Rrole[rnum].TakingItemAmount[i] + amount;
			p = 1;
			break;
		}
	}
	if (p == 0)
	{
		for i = 0 to 3 do
		{
			if (Rrole[rnum].TakingItem[i] == -1)
			{
				Rrole[rnum].TakingItem[i] = inum;
				Rrole[rnum].TakingItemAmount[i] = amount;
				break;
			}
		}
	}
	for i = 0 to 3 do
	{
		if (Rrole[rnum].TakingItemAmount[i] <= 0)
		{
			Rrole[rnum].TakingItem[i] = -1;
			Rrole[rnum].TakingItemAmount[i] = 0;
		}
	}

}

int function instruct_42(jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump2;
	for i = 0 to 5 do
	{
		if (Rrole[Teamlist[i]].Sexual == 1)
		{
			result = jump1;
			break;
		}
	}
}

int function instruct_43(inum = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
var
int i = 0;
{
	result = jump2;
	for i = 0 to ITEM_NUM - 1 do
		if (RItemList[i].Number == inum)
		{
			result = jump1;
			break;
		}
}

void instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, int endpic2 = 0)()
	var
	int i = 0;
{
	g_curScenceData[ 3, g_curScenceEventData[ enum1, 10], g_curScenceEventData[ enum1, 9]] = enum1;
	g_curScenceData[ 3, g_curScenceEventData[ enum2, 10], g_curScenceEventData[ enum2, 9]] = enum2;
	for i = 0 to endpic1 - beginpic1 do
	{
		g_curScenceEventData[ enum1, 5] = beginpic1 + i;
		g_curScenceEventData[ enum2, 5] = beginpic2 + i;
		UpdateScence(g_curScenceEventData[ enum1, 10], g_curScenceEventData[ enum1, 9]);
		UpdateScence(g_curScenceEventData[ enum2, 10], g_curScenceEventData[ enum2, 9]);
		sdl_delay(20);
		DrawScenceWithoutRole(Sx, Sy);
		DrawScence;
		SDL_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	}
	//g_curScenceData[ 3, g_curScenceEventData[ [enum,10],g_curScenceEventData[ [enum,9]]=-1;
}

void instruct_45(rnum, int speed = 0)()
	var
	word: widestring;
{
	RRole[rnum].Speed = RRole[rnum].Speed + speed;
	DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 51, 0, COLOR(255), 30);
	word = " 輕功增加";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
	word = format("%4d", [speed]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 20, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

void instruct_46(rnum, int mp = 0)()
	var
	word: widestring;
{
	RRole[rnum].MaxMP = RRole[rnum].MaxMP + mp;
	RRole[rnum].CurrentMP = RRole[rnum].MaxMP;
	DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 51, 0, COLOR(255), 30);
	word = " 內力增加";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
	word = format("%4d", [mp]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 20, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

void instruct_47(rnum, int attack = 0)()
	var
	word: widestring;
{
	RRole[rnum].Attack = RRole[rnum].Attack + attack;
	DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 51, 0, COLOR(255), 30);
	word = " 武力增加";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
	word = format("%4d", [attack]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 20, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

void instruct_48(rnum, int hp = 0)()
	var
	word: widestring;
{
	RRole[rnum].MaxHP = RRole[rnum].MaxHP + hp;
	RRole[rnum].CurrentHP = RRole[rnum].MaxHP;
	DrawFrameRectangle(SCREEN_CENTER_X - 75, 98, 145, 51, 0, COLOR(255), 30);
	word = " 生命增加";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 90, 125, COLOR(0x7), COLOR(0x5));
	drawbig5shadowtext(@rrole[rnum].Name, SCREEN_CENTER_X - 90, 100, COLOR(0x23), COLOR(0x21));
	word = format("%4d", [hp]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 20, 125, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

void instruct_49(rnum, int MPpro = 0)()
{
	RRole[rnum].MPType = MPpro;
}

function instruct_50(list: array of int integer) = 0;
var
int   i = 0;
int p = 0;
//instruct_50e: function (list1: array of int integer) = 0;
{
	result = 0;
	if (list[0] <= 128)
	{
		//instruct_50e="";
		result = instruct_50e(list[0], list[1], list[2], list[3], list[4], list[5], list[6]);
	}
	else {
		result = list[6];
		p = 0;
		for i = 0 to 4 do
		{
			p = p + instruct_18(list[i], 1, 0);
		}
		if (p == 5) result = list[5];
	}
}

void instruct_51()
{
	instruct_1(SOFTSTAR_BEGIN_TALK + random(SOFTSTAR_NUM_TALK), 0x72, 0);
}

void instruct_52()
	var
	word: widestring;
{
	DrawFrameRectangle(SCREEN_CENTER_X - 110, 98, 220, 26, 0, COLOR(255), 30);
	word = " 你的品德指數為：";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 125, 100, COLOR(0x7), COLOR(0x5));
	word = format("%3d", [rrole[0].Ethics]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 65, 100, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

void instruct_53()
	var
	word: widestring;
{
	DrawFrameRectangle(SCREEN_CENTER_X - 110, 98, 220, 26, 0, COLOR(255), 30);
	word = " 你的聲望指數為：";
	drawshadowtext(@word[1], SCREEN_CENTER_X - 125, 100, COLOR(0x7), COLOR(0x5));
	word = format("%3d", [rrole[0].Repute]);
	drawengshadowtext(@word[1], SCREEN_CENTER_X + 65, 100, COLOR(0x66), COLOR(0x64));
	sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
	WaitKey;
	redraw;
}

//Open all scences.
//Note: in primary game, some scences are set to different entrancing condition.

void instruct_54()
	var
	int i = 0;
{
	for i = 0 to 100 do
	{
		Rscence[i].EnCondition = 0;
	}
	Rscence[2].EnCondition = 2;
	Rscence[38].EnCondition = 2;
	Rscence[75].EnCondition = 1;
	Rscence[80].EnCondition = 1;
}

//Judge the event number.

int function instruct_55(enum = 0;
		int  value = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
{
	result = jump2;
	if (g_curScenceEventData[ enum, 2] == value) result = jump1;
}

//Add repute.
//声望刚刚超过200时家里出现请帖

void int instruct_56(Repute = 0)()
{
	RRole[0].Repute = RRole[0].Repute + repute;
	if ((RRole[0].Repute > 200) && (RRole[0].Repute - repute <= 200))
	{
		//showmessage("");
		instruct_3([70, 11, 0, 11, 0x3A4, -1, -1, 0x1F20, 0x1F20, 0x1F20, 0, 18, 21]);
	}
}

{void instruct_57()
	var
		int i = 0;
	{
		for i=0 to endpic1-beginpic1 do
		{
			g_curScenceEventData[ [enum1,5]=beginpic1+i;
			g_curScenceEventData[ [enum2,5]=beginpic2+i;
			UpdateScence(g_curScenceEventData[ [enum1,10],g_curScenceEventData[ [enum1,9]);
			UpdateScence(g_curScenceEventData[ [enum2,10],g_curScenceEventData[ [enum2,9]);
			sdl_delay(20);
			DrawScenceByCenter(Sx,Sy);
			DrawScence;
			SDL_updaterect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
		}
	}}

void instruct_58()
	var
	int   i = 0;
	int p = 0;
{
	for i = 0 to 14 do
	{
		p = random(2);
		instruct_1(2854 + i * 2 + p, 0, 3);
		if (not (battle(102 + i * 2 + p, 0))) instruct_15;
		instruct_14;
		instruct_13;
		if (i mod 3 == 2)
		{
			instruct_1(2891, 0, 3);
			instruct_12;
			instruct_14;
			instruct_13;
		}
	}
	instruct_1(2884, 0, 3);
	instruct_1(2885, 0, 3);
	instruct_1(2886, 0, 3);
	instruct_1(2887, 0, 3);
	instruct_1(2888, 0, 3);
	instruct_1(2889, 0, 1);
	instruct_2(0x8F, 1);

}

//全员离队, 但未清除相关事件

void instruct_59()
	var
	int i = 0;
{
	for i = 1 to 5 do
		TeamList[i] = -1;

}

int function instruct_60(snum = 0;
		int  enum = 0;
		int  pic = 0;
		int  jump1 = 0;
		int jump2 = 0int ) = 0;
{
	result = jump2;
	if (snum == -2) snum = g_curScence;
	if (g_scenceEventData[snum, enum, 5] == pic) result = jump1;
	//showmessage(inttostr(g_scenceEventData[snum,enum,5]));
}

void instruct_62()
	var
	int i = 0;
str: widestring;
{
	g_inGame = 3;
	redraw;
	EndAmi;
	//display_img("}.png", 0, 0);
	//g_inGame = 3;
}

//Set sexual.
void instruct_63(rnum, int sexual = 0)()
{
	RRole[rnum].Sexual = sexual;
}

//韦小宝的商店

void instruct_64()
	var
	int   i = 0;
	int  amount = 0;
	int  shopnum = 0;
	int  menu = 0;
	int price = 0;
list: array[0..4] of integer;
{
	setlength(Menustring, 5);
	setlength(Menuengstring, 5);
	amount = 0;
	//任选一个商店, 因未写他去其他客栈的指令
	shopnum = random(5);
	//p=0;
	for i = 0 to 4 do
	{
		if (Rshop[shopnum].Amount[i] > 0)
		{
			menustring[amount] = Big5toUTF8(@Ritem[Rshop[shopnum].Item[i]].Name);
			menuengstring[amount] = format("%10d", [Rshop[shopnum].Price[i]]);
			list[amount] = i;
			amount = amount + 1;
		}
	}
	instruct_1(0xB9E, 0x6F, 0);
	menu = commonmenu(SCREEN_CENTER_X - 100, 150, 85 + length(menuengstring[0]) * 10, amount - 1);
	if (menu >= 0)
	{
		menu = list[menu];
		price = Rshop[shopnum].Price[menu];
		if (instruct_31(price, 1, 0) == 1)
		{
			instruct_2(Rshop[shopnum].Item[menu], 1);
			instruct_32(MONEY_ID, -price);
			Rshop[shopnum].Amount[menu] = Rshop[shopnum].Amount[menu] - 1;
			instruct_1(0xBA0, 0x6F, 0);
		} else
			instruct_1(0xB9F, 0x6F, 0);
	}
}

void int instruct_66(musicnum = 0)()
{
	stopmp3;
	playmp3(musicnum, -1);
}

void int instruct_67(Soundnum = 0)()
	var
	int i = 0;
	//g_sound: PMIX_Chunk;
filename: string;
{
	filename = "atk" + format("%2d", [soundnum]) + ".wav";
	for i = 1 to length(filename) do
		if (filename[i] == " ") filename[i] = "0";
	playsound(pchar(filename), 0);
}

//50指令中获取变量值

int function e_GetValue(bit = 0;
		int  t = 0;
		int x = 0int ) = 0;
var
int i = 0;
{
	i = t && (1 shl bit);
	if (i == 0) result = x else result = x50[x];
}

//Expanded 50 instructs.

int function instruct_50e(code = 0;
		int  e1 = 0;
		int  e2 = 0;
		int  e3 = 0;
		int  e4 = 0;
		int  e5 = 0;
		int e6 = 0int ) = 0;
var
int   i = 0;
int  t1 = 0;
int  grp = 0;
int  idx = 0;
int  offset = 0;
int  len = 0;
int  i1 = 0;
int i2 = 0;
p, p1: pchar;
//ps :pstring;
str: string;
word: widestring;
{
	result = 0;
	switch (code) {
0: //Give a value to a papameter.
		{
			x50[e1] = e2;
		}
1: //Give a value to one member in parameter group.
		{
			t1 = e3 + e_getvalue(0, e1, e4);
			x50[t1] = e_getvalue(1, e1, e5);
			if (e2 == 1) x50[t1] = x50[t1] && 0xFF;
		}
2: //Get the value of one member in parameter group.
		{
			t1 = e3 + e_getvalue(0, e1, e4);
			x50[e5] = x50[t1];
			if (e2 == 1) x50[t1] = x50[t1] && 0xFF;
		}
3: //Basic calculations.
		{
			t1 = e_getvalue(0, e1, e5);
			switch (e2) {
0: x50[e3] = x50[e4] + t1;
1: x50[e3] = x50[e4] - t1;
2: x50[e3] = x50[e4] * t1;
3: x50[e3] = x50[e4] / t1;
4: x50[e3] = x50[e4] mod t1;
5: x50[e3] = Uint16(x50[e4]) / t1;
			}
		}
4: //Judge the parameter.
		{
			x50[0x7000] = 0;
			t1 = e_getvalue(0, e1, e4);
			switch (e2) {
0: if (not (x50[e3] < t1)) x50[0x7000] = 1;
1: if (not (x50[e3] <= t1)) x50[0x7000] = 1;
2: if (not (x50[e3] == t1)) x50[0x7000] = 1;
3: if (not (x50[e3] <> t1)) x50[0x7000] = 1;
4: if (not (x50[e3] >= t1)) x50[0x7000] = 1;
5: if (not (x50[e3] > t1)) x50[0x7000] = 1;
6: x50[0x7000] = 0;
7: x50[0x7000] = 1;
			}
		}
5: //Zero all parameters.
		{
			for i = -0x8000 to 0x7FFF do
				x50[i] = 0;
		}
8: //Read talk to string.
		{
			t1 = e_getvalue(0, e1, e2);
			idx = fileopen("talk.idx", fmopenread);
			grp = fileopen("talk.grp", fmopenread);
			if (t1 == 0)
			{
				offset = 0;
				fileread(idx, len, 4);
			}
			else
			{
				fileseek(idx, (t1 - 1) * 4, 0);
				fileread(idx, offset, 4);
				fileread(idx, len, 4);
			}
			len = (len - offset);
			fileseek(grp, offset, 0);
			fileread(grp, x50[e3], len);
			fileclose(idx);
			fileclose(grp);
			p = @x50[e3];
			for i = 0 to len - 1 do
			{
				p^ = char(byte(p^) xor 0xFF);
				p = p + 1;
			}
			p^ = char(0);
			//x50[e3+i]=0;
		}
9: //Format the string.
		{
			e4 = e_getvalue(0, e1, e4);
			p = @x50[e2];
			p1 = @x50[e3];
			str = p1;
			str = format(string(p1), [e4]);
			for i = 0 to length(str) do
			{
				p^ = str[i + 1];
				p = p + 1;
			}
		}
10: //Get the length of a string.
		{
			x50[e2] = length(pchar(@x50[e1]));
			//showmessage(inttostr(x50[e2]));
		}
11: //Combine 2 strings.
		{
			p = @x50[e1];
			p1 = @x50[e2];
			for i = 0 to length(p1) - 1 do
			{
				p^ = (p1 + i)^;
				p = p + 1;
			}
			p1 = @x50[e3];
			for i = 0 to length(p1) do
			{
				p^ = (p1 + i)^;
				p = p + 1;
			}
			//p^=char(0);
		}
12: //Build a string with spaces.
		//Note: here the width of one "space" is the same as one Chinese charactor.
		{
			e3 = e_getvalue(0, e1, e3);
			p = @x50[e2];
			for i = 0 to e3 do
			{
				p^ = char(0x20);
				p = p + 1;
			}
			p^ = char(0);
		}
16: //Write R data.
		{
			e3 = e_getvalue(0, e1, e3);
			e4 = e_getvalue(1, e1, e4);
			e5 = e_getvalue(2, e1, e5);
			switch (e2) {
0: Rrole[e3].Data[e4 / 2] = e5;
1: Ritem[e3].Data[e4 / 2] = e5;
2: Rscence[e3].Data[e4 / 2] = e5;
3: Rmagic[e3].Data[e4 / 2] = e5;
4: Rshop[e3].Data[e4 / 2] = e5;
			}
		}
17: //Read R data.
		{
			e3 = e_getvalue(0, e1, e3);
			e4 = e_getvalue(1, e1, e4);
			switch (e2) {
0: x50[e5] = Rrole[e3].Data[e4 / 2];
1: x50[e5] = Ritem[e3].Data[e4 / 2];
2: x50[e5] = Rscence[e3].Data[e4 / 2];
3: x50[e5] = Rmagic[e3].Data[e4 / 2];
4: x50[e5] = Rshop[e3].Data[e4 / 2];
			}
		}
18: //Write team data.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			TeamList[e2] = e3;
			//showmessage(inttostr(e3));
		}
19: //Read team data.
		{
			e2 = e_getvalue(0, e1, e2);
			x50[e3] = TeamList[e2];
		}
20: //Get the amount of one item.
		{
			e2 = e_getvalue(0, e1, e2);
			x50[e3] = 0;
			for i = 0 to ITEM_NUM - 1 do
				if (RItemList[i].Number == e2)
				{
					x50[e3] = RItemList[i].Amount;
					break;
				}
			//showmessage("rer");
		}
21: //Write event in scence.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			g_scenceEventData[e2, e3, e4] = e5;
			//if (e2=g_curScence) g_curScenceEventData[ [e3,e4]=e5;
			//InitialScence;
			//Redraw;
			//sdl_updaterect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
		}
22:
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			x50[e5] = g_scenceEventData[e2, e3, e4];
		}
23:
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			e6 = e_getvalue(4, e1, e6);
			g_scenceData[e2, e3, e5, e4] = e6;
			//if (e2=g_curScence) g_curScenceData[ 3, e5,e4]=e6;;
			//InitialScence;
			//Redraw;
			//sdl_updaterect(g_screenSurface,0,0,g_screenSurface.w,g_screenSurface.h);
		}
24:
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			x50[e6] = g_scenceData[e2, e3, e5, e4];
			//showmessage(inttostr(g_sFace));
		}
25:
		{
			e5 = e_getvalue(0, e1, e5);
			e6 = e_getvalue(1, e1, e6);
			t1 = uint16(e3) + uint16(e4) * 0x10000 + uint16(e6);
			i = uint16(e3) + uint16(e4) * 0x10000;
			switch (t1) {
0x1D295A: Sx = e5;
0x1D295C: Sy = e5;
		  //0x1D2956: g_ex = e5;
		  //0x1D2958: g_ey = e5;
		  //0x0544f2:
			}
			switch (i) {
0x18FE2C:
				{
					if (e6 mod 4 <= 1)
						Ritemlist[e6 / 4].Number = e5
					else
						Ritemlist[e6 / 4].Amount = e5;
				}
			}
			switch (i) {
0x051C83:
				{
					g_palette[e6] = e5 mod 256;
					g_palette[e6 + 1] = e5 / 256;
				}
			}
			//redraw;
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		}
26:
		{
			e6 = e_getvalue(0, e1, e6);
			t1 = uint16(e3) + uint16(e4) * 0x10000 + uint(e6);
			i = uint16(e3) + uint16(e4) * 0x10000;
			switch (t1) {
0x1D295E: x50[e5] = g_curScence;
0x1D295A: x50[e5] = Sx;
0x1D295C: x50[e5] = Sy;
0x1C0B88: x50[e5] = Mx;
0x1C0B8C: x50[e5] = My;
		  //0x1D2956: x50[e5] = g_ex;
		  //0x1D2958: x50[e5] = g_ey;
0x05B53A: x50[e5] = 1;
0x0544F2: x50[e5] = g_sFace;
			}
			if ((t1 - 0x18FE2C >= 0) && (t1 - 0x18FE2C < 800))
			{
				i = t1 - 0x18FE2C;
				//showmessage(inttostr(e3));
				if (i mod 4 <= 1)
					x50[e5] = Ritemlist[i / 4].Number
				else
					x50[e5] = Ritemlist[i / 4].Amount;
			}

		}
27: //Read name to string.
		{
			e3 = e_getValue(0, e1, e3);
			p = @x50[e4];
			switch (e2) {
0: p1 = @Rrole[e3].Name;
1: p1 = @Ritem[e3].Name;
2: p1 = @Rscence[e3].Name;
3: p1 = @Rmagic[e3].Name;
			}
			for i = 0 to 9 do
			{
				(p + i)^ = (p1 + i)^;
				if ((p1 + i)^ == char(0)) break;
			}
			(p + i)^ = char(0x20);
			(p + i + 1)^ = char(0);
		}
28: //Get the battle number.
		{
			x50[e1] = x50[28005];
		}
29: //Select aim.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			if (e5 == 0)
			{
				//showmessage("IN CASE");
				selectaim(e2, e3);
			}
			x50[e4] = bfield[2, Ax, Ay];
		}
30: //Read battle properties.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			x50[e4] = brole[e2].data[e3 / 2];
		}
31: //Write battle properties.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			brole[e2].Data[e3 / 2] = e4;
		}
32: //Modify next instruct.
		{
			e3 = e_getvalue(0, e1, e3);
			result = 655360 * (e3 + 1) + x50[e2];
			//showmessage(inttostr(result));
		}
33: //Draw a string.
		{
			e3 = e_getvalue(0, e1, e3);
			e4 = e_getvalue(1, e1, e4);
			e5 = e_getvalue(2, e1, e5);
			//showmessage(inttostr(e5));
			i = 0;
			t1 = 0;
			p = @x50[e2];
			p1 = p;
			while byte(p^) > 0 do
			{
				if (byte(p^) == 0x2A)
				{
					p^ = char(0);
					drawbig5shadowtext(p1, e3 - 22, e4 + 22 * i - 25, COLOR(e5 && 0xFF), COLOR((e5 && 0xFF00) shl 8));
					i = i + 1;
					p1 = p + 1;
				}
				p = p + 1;
			}
			drawbig5shadowtext(p1, e3 - 22, e4 + 22 - 25, COLOR(e5 && 0xFF), COLOR((e5 && 0xFF00) shl 8));
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			//WaitKey;
		}
34: //Draw a rectangle as background.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			DrawFrameRectangle(e2, e3, e4, e5, 0, COLOR(0xFF), 40);
			//sdl_updaterect(g_screenSurface,e1,e2,e3+1,e4+1);
		}
35: //Pause && wait a key.
		{
			i = WaitKey;
			x50[e1] = i;
			switch (i) {
sdlk_left: x50[e1] = 154;
sdlk_right: x50[e1] = 156;
sdlk_up: x50[e1] = 158;
sdlk_down: x50[e1] = 152;
			}
		}
36: //Draw a string with background then pause, if (the key pressed is "Y") jump=0.
		{
			e3 = e_getvalue(0, e1, e3);
			e4 = e_getvalue(1, e1, e4);
			e5 = e_getvalue(2, e1, e5);
			//word = big5toUTF8(@x50[e2]);
			//t1 = length(word);
			//drawtextwithrect(@word[1], e3, e4, t1 * 20 - 15, COLOR(e5 && 0xFF), COLOR((e5 && 0xFF00) shl 8));
			p = @x50[e2];
			i1 = 1;
			i2 = 0;
			t1 = 0;
			while byte(p^) > 0 do
			{
				//showmessage("");
				if (byte(p^) == 0x2A)
				{
					if (t1 > i2) i2 = t1;
					t1 = 0;
					i1 = i1 + 1;
				}
				if (byte(p^) == 0x20) t1 = t1 + 1;
				p = p + 1;
				t1 = t1 + 1;
			}
			if (t1 > i2) i2 = t1;
			p = p - 1;
			if (i1 == 0) i1 = 1;
			if (byte(p^) == 0x2A) i1 = i1 - 1;
			DrawFrameRectangle(e3, e4, i2 * 10 + 25, i1 * 22 + 5, 0, COLOR(255), 30);
			p = @x50[e2];
			p1 = p;
			i = 0;
			while byte(p^) > 0 do
			{
				if (byte(p^) == 0x2A)
				{
					p^ = char(0);
					drawbig5shadowtext(p1, e3 - 17, e4 + 22 * i + 2, COLOR(e5 && 0xFF), COLOR((e5 && 0xFF00) shl 8));
					i = i + 1;
					p1 = p + 1;
				}
				p = p + 1;
			}
			drawbig5shadowtext(p1, e3 - 17, e4 + 22 * i + 2, COLOR(e5 && 0xFF), COLOR((e5 && 0xFF00) shl 8));
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
			i = WaitKey;
			if (i == sdlk_y) x50[0x7000] = 0 else x50[0x7000] = 1;
			//redraw;
		}
37: //Delay.
		{
			e2 = e_getvalue(0, e1, e2);
			sdl_delay(e2);
		}
38: //Get a number randomly.
		{
			e2 = e_getvalue(0, e1, e2);
			x50[e3] = random(e2);
		}
39: //Show a menu to select. The 40th instruct is too complicable, just use the 30th.
		{
			e2 = e_getvalue(0, e1, e2);
			e5 = e_getvalue(1, e1, e5);
			e6 = e_getvalue(2, e1, e6);
			setlength(menustring, e2);
			setlength(menuengstring, 0);
			t1 = 0;
			for i = 0 to e2 - 1 do
			{
				menustring[i] = big5toUTF8(@x50[x50[e3 + i]]);
				i1 = length(pchar(@x50[x50[e3 + i]]));
				if (i1 > t1) t1 = i1;
			}
			x50[e4] = commonmenu(e5, e6, t1 * 10 + 3, e2 - 1) + 1;
		}
40: //Show a menu to select. The 40th instruct is too complicable, just use the 30th.
		{
			e2 = e_getvalue(0, e1, e2);
			e5 = e_getvalue(1, e1, e5);
			e6 = e_getvalue(2, e1, e6);
			setlength(menustring, e2);
			setlength(menuengstring, 0);
			i2 = 0;
			for i = 0 to e2 - 1 do
			{
				menustring[i] = big5toUTF8(@x50[x50[e3 + i]]);
				i1 = length(pchar(@x50[x50[e3 + i]]));
				if (i1 > i2) i2 = i1;
			}
			t1 = (e1 shr 8) && 0xFF;
			if (t1 == 0) t1 = 5;
			//showmessage(inttostr(t1));
			x50[e4] = commonscrollmenu(e5, e6, i2 * 10 + 3, e2 - 1, t1) + 1;
		}
41: //Draw a picture.
		{
			e3 = e_getvalue(0, e1, e3);
			e4 = e_getvalue(1, e1, e4);
			e5 = e_getvalue(2, e1, e5);
			switch (e2) {
0:
				{
					if (g_inGame == 1) DrawScencePic(e5 / 2, e3, e4, 0, 0, g_screenSurface.w, g_screenSurface.h)
					else DrawMapPic(e5 / 2, e3, e4);
				}
1: DrawFacePic(e5, e3, e4);
2:
   {
	   str = "pic/" + inttostr(e5) + ".png";
	   display_img(@str[1], e3, e4);
   }
			}
			sdl_updaterect(g_screenSurface, 0, 0, g_screenSurface.w, g_screenSurface.h);
		}
42: //Change the poistion on world map.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(0, e1, e3);
			Mx = e3;
			My = e2;
		}
43: //Call another event.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			e6 = e_getvalue(4, e1, e6);
			x50[0x7100] = e3;
			x50[0x7101] = e4;
			x50[0x7102] = e5;
			x50[0x7103] = e6;
			if (e2 == 202)
			{
				if (e5 == 0) instruct_2(e3, e4) else instruct_32(e3, e4);
			}
			else
				callevent(e2);
			//showmessage(inttostr(e2));
		}
44: //Play amination.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			playActionAmination(e2, e3);
			playMagicAmination(e2, e4);
		}
45: //Show values.
		{
			e2 = e_getvalue(0, e1, e2);
			showhurtvalue(e2);
		}
46: //Set effect layer.
		{
			e2 = e_getvalue(0, e1, e2);
			e3 = e_getvalue(1, e1, e3);
			e4 = e_getvalue(2, e1, e4);
			e5 = e_getvalue(3, e1, e5);
			e6 = e_getvalue(4, e1, e6);
			for i1 = e2 to e2 + e4 - 1 do
				for i2 = e3 to e3 + e5 - 1 do
					bfield[4, i1, i2] = e6;
		}
47: //Here no need to re-set the pic.
		{
		}
48: //Show some parameters.
		{
			str = "";
			for i = e1 to e1 + e2 - 1 do
				str = str + "x" + inttostr(i) + "=" + inttostr(x50[i]) + char(13) + char(10);
			messagebox(0, @str[1], "KYS Windows", MB_OK);
		}
49: //In PE files, you can not call any procedure as your wish.
		{
		}
	}

}
#endif

//Event.
//事件系统
void (*CMD_FUNCS[])(sint16**) = {
	CmdRedraw,
	CmdTalk,
	CmdGetItem,
};

void CallEvent(int event)
{
	sint16* cmdBuffer = NULL;

	//g_curEvent=num;
	g_ex = g_sx;
	g_ey = g_sy;
	//g_sStep = 0;
	
	if (event) {
		cmdBuffer = (sint16*)(g_cmdGrpBuff + *(g_cmdIdxBuff + event - 1));
	} else {
		cmdBuffer = (sint16*)g_cmdGrpBuff;
	}

	sint16* cmd = cmdBuffer;
	while (*cmd >= 0 && *cmd <= sizeof(CMD_FUNCS) / sizeof (void *(sint16**))) {
		(*CMD_FUNCS[*cmd])(&cmd);
	}

	Redraw();
}
