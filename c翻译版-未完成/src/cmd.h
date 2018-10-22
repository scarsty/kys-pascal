/*******************************************************************************
* cmd.h                                                     fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __CMD_H__
#define __CMD_H__

/*******************************************************************************
* Global Variables                                                             *
*******************************************************************************/

#define g_itemList (g_roleData.common.itemList)

extern int g_ex;
extern int g_ey;

extern uint32* g_talkIdxBuff;
extern byte* g_talkBuff;

extern uint32* g_cmdIdxBuff;
extern byte* g_cmdGrpBuff;

/*******************************************************************************
* Functions                                                                    *
*******************************************************************************/

void CmdRedraw(sint16** cmd);			//0
void CmdTalk(sint16** cmd);				//1
void CmdGetItem(sint16** cmd);			//2

void CmdSleep(sint16** cmd);			//12
void CmdScreenFadeIn(sint16** cmd);		//13
void CmdScreenFadeOut(sint16** cmd);	//14

#endif //__CMD_H__
