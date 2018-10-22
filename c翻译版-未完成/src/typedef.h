/*******************************************************************************
* typedef.h                                                 fileencoding=UTF-8 *
*******************************************************************************/

#include "claim.h"

#ifndef __TYPEDEF_H__
#define __TYPEDEF_H__

#pragma pack (1)

#define FALSE	0
#define TRUE	(!FALSE)

typedef int				bool;

typedef char			sint8;
typedef unsigned char	uint8;
typedef uint8			byte;

typedef short 			sint16;
typedef unsigned short	uint16;

typedef long 			sint32;
typedef unsigned long	uint32;

typedef enum {
	EmScenceLayerGround,
	EmScenceLayerBuilding,
	EmScenceLayerSky,
	EmScenceLayerEvent,
	EmScenceLayerBuildingOffset,
	EmScenceLayerSkyOffset,

	SCENCE_LAYER_NUM
} EmScenceLayer;

typedef enum {
	EmInScenceStart,
	EmInScenceEnter,
	EmInScenceJump,
} EmInScence;

typedef enum {
	EmInGameMap,
	EmInGameScence,
	EmInGameBattleField,
	EmInGameTitle
} EmInGame;

typedef enum {
	EmMainMenuNew,
	EmMainMenuLoad,
	EmMainMenuExit
} EmMainMenu;

typedef enum {
	EmMPYin,
	EmMPYang,
	EmMPUnified
} EmNeiliType;

typedef struct
{
	sint16 x;
	sint16 y;
} T_Position;

typedef struct
{
	uint16 w;
	uint16 h;
	sint16 dx;
	sint16 dy;
} T_PicRect;

typedef struct
{
	sint16 x;
	sint16 y;
	uint16 w;
	uint16 h;
} T_Rect;

typedef struct
{
	uint8 r;
	uint8 g;
	uint8 b;
} T_RGB;

typedef struct
{
	sint16 index;
	sint16 num;
} T_ItemList;

typedef struct
{
	bool inShip;
	sint16 mx;
	sint16 my;
	sint16 sx;
	sint16 sy;
	sint16 mFace;
	sint16 shipX;
	sint16 shipY;
	sint16 shipX1;
	sint16 shipY1;
	sint16 shipFace;
	sint16 team[MAX_TEAM_ROLE];
	T_ItemList itemList[ITEM_NUM];
} T_SaveCommon;

typedef struct
{
	sint16 listNum;
	sint16 faceIndex;
	sint32 incLife;
	char name[NAME_LEN];
	sint16 sexual;
	sint16 level;
	sint16 exp;
	sint16 life;
	sint16 maxLife;
	sint16 wound;
	sint16 poisioning;
	sint16 phyPower;
	uint16 expForItem;
	sint16 equip[2];
	sint16 amiFrameNum[5];
	sint16 amiDelay[5];
	sint16 soundDealy[5];
	sint16 neiliType;
	sint16 neili;
	sint16 maxNeili;
	sint16 attack;
	sint16 speed;
	sint16 defence;
	sint16 medcine;
	sint16 usePoi;
	sint16 medPoi;
	sint16 defPoi;
	sint16 fist;
	sint16 sword;
	sint16 blade;
	sint16 unusual;
	sint16 hidWeapon;
	sint16 knowledge;
	sint16 ethics;
	sint16 attPoi;
	sint16 attTwice;
	sint16 repute;
	sint16 aptitude;
	sint16 practiceBook;
	sint16 expForBook;
	sint16 magic[10];
	sint16 magLevel[10];
	sint16 takingItem[4];
	sint16 takingItemNum[4];
} T_Role;

typedef struct
{
	sint16 listNum;
	char name[20];
	char name1[20];
	char introduction[30];
	sint16 magic;
	sint16 amiNum;
	sint16 user;
	sint16 equipType;
	sint16 showIntro;
	sint16 itemType;
	sint16 unknown1;
	sint16 unknown2;
	sint16 unknown3;
	sint16 addLife;
	sint16 addMaxLife;
	sint16 addPoi;
	sint16 addPhyPower;
	sint16 changeNeiliType;
	sint16 addNeili;
	sint16 addMaxNeili;
	sint16 addAttack;
	sint16 addSpeed;
	sint16 addDefence;
	sint16 addMedcine;
	sint16 addUsePoi;
	sint16 addMedPoi;
	sint16 addDefPoi;
	sint16 addFist;
	sint16 addSword;
	sint16 addBlade;
	sint16 addUnusual;
	sint16 addHidWeapon;
	sint16 addKnowledge;
	sint16 addEthics;
	sint16 addAttTwice;
	sint16 addAttPoi;
	sint16 onlyPracRole;
	sint16 needMPType;
	sint16 needMP;
	sint16 needAttack;
	sint16 needSpeed;
	sint16 needUsePoi;
	sint16 needMedcine;
	sint16 needMedPoi;
	sint16 needFist;
	sint16 needSword;
	sint16 needBlade;
	sint16 needUnusual;
	sint16 needHidWeapon;
	sint16 needAptitude;
	sint16 needExp;
	sint16 needExpForItem;
	sint16 needMaterial;
	sint16 getItem[5];
	sint16 needMatNum[5];
} T_Item;

typedef struct
{
	sint16 listNum;
	char name[10];
	sint16 exitMusic;
	sint16 entranceMusic;
	sint16 jumpScence;
	sint16 enCondition;
	sint16 mapEntrance1Y;
	sint16 mapEntrance1X;
	sint16 mapEntrance2Y;
	sint16 mapEntrance2X;
	sint16 entranceY;
	sint16 entranceX;

	sint16 exitY[3];
	sint16 exitX[3];
	sint16 jumpY;
	sint16 jumpX;
	sint16 jumpEntranceY;
	sint16 jumpEntranceX;
} T_Scence;

typedef struct
{
	sint16 listNum;
	char name[10];
	sint16 unKnow[5];
	sint16 soundNum;
	sint16 magicType;
	sint16 amiNum;
	sint16 hurtType;
	sint16 attAreaType;
	sint16 needMP;
	sint16 poision;
	sint16 attack[10];
	sint16 moveDistance[10];
	sint16 attDistance[10];
	sint16 addMP[10];
	sint16 hurtMP[10];
} T_Magic;

typedef struct
{
	sint16 item[5];
	sint16 num[5];
	sint16 price[5];
} T_Shop;

typedef struct
{
	T_SaveCommon common;
	T_Role roles[ROLE_NUM];
	T_Item items[ITEM_NUM];
	T_Scence scences[SCENCE_NUM];
	T_Magic magics[MAGIC_NUM];
	T_Shop shops[SHOP_NUM];
} T_RoleData;

typedef struct
{
	sint16 block;
	sint16 order;
	sint16 actionEvent;
	sint16 itemEvent;
	sint16 stepEvent;
	sint16 pic1;
	sint16 pic2;
	sint16 pic3;
	sint16 fps;
	sint16 x;
	sint16 y;
} T_Event;

typedef struct
{
	sint16 num;
	sint16 team;
	sint16 y;
	sint16 x;
	sint16 face;
	sint16 dead;
	sint16 step;
	sint16 acted;
	sint16 pic;
	sint16 showNumber;
	sint16 unUse1;
	sint16 unUse2;
	sint16 unUse3;
	sint16 expGot;
	sint16 autoMode;
} T_BattleRole;

#endif //__TYPEDEF_H__
