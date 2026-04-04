// kys_type.cpp - 大数组全局变量定义
// 仅保留无法放入inline的巨大数组,其余变量均在kys_type.h中以inline定义

#include "kys_type.h"

// 大地图 (480x480 x 2bytes each = ~460KB each)
int16_t Earth[480][480] = {};
int16_t Surface[480][480] = {};
int16_t Building[480][480] = {};
int16_t BuildX[480][480] = {};
int16_t BuildY[480][480] = {};
int16_t Entrance[480][480] = {};

// 角色/物品/场景/武功/商店
TRole Rrole[2032] = {};
TItem Ritem[725] = {};
TScene Rscene[201] = {};
TMagic Rmagic[999] = {};
TShop RShop[11] = {};

// 场景/事件数据
int16_t SData[401][6][64][64] = {};
int16_t DData[401][200][11] = {};

// 战场
int16_t BField[8][64][64] = {};
TWarData WarSta = {};

// 脚本x50数组
int16_t x50[0x8000] = {};

// 寻路
int16_t linex[480 * 480] = {};
int16_t liney[480 * 480] = {};
int PathCost[480][480] = {};

// 扩展地面
int16_t ExGround[192][192] = {};