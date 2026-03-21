#pragma once

#include <array>
#include <cstdint>

namespace kys {

using i16 = std::int16_t;
using u16 = std::uint16_t;
using i32 = std::int32_t;

#pragma pack(push, 1)

struct TItemList {
    i16 number;
    i16 amount;
};

struct TRoleElement {
    i16 listNum;
    i16 headNum;
    i16 incLife;
    i16 unUse;
    char name[10];
    char nick[10];
    i16 sexual;
    i16 level;
    u16 exp;
    i16 currentHP;
    i16 maxHP;
    i16 hurt;
    i16 poison;
    i16 phyPower;
    u16 expForItem;
    i16 equip[2];
    i16 amiFrameNum[5];
    i16 amiDelay[5];
    i16 soundDealy[5];
    i16 mpType;
    i16 currentMP;
    i16 maxMP;
    i16 attack;
    i16 speed;
    i16 defence;
    i16 medcine;
    i16 usePoi;
    i16 medPoi;
    i16 defPoi;
    i16 fist;
    i16 sword;
    i16 knife;
    i16 unusual;
    i16 hidWeapon;
    i16 knowledge;
    i16 ethics;
    i16 attPoi;
    i16 attTwice;
    i16 repute;
    i16 aptitude;
    i16 practiceBook;
    u16 expForBook;
    i16 magic[10];
    i16 magLevel[10];
    i16 takingItem[4];
    i16 takingItemAmount[4];
};

union TRole {
    TRoleElement element;
    i16 data[91];
};

struct TItemElement {
    i16 listNum;
    char name[20];
    char name1[20];
    char introduction[30];
    i16 magic;
    i16 amiNum;
    i16 user;
    i16 equipType;
    i16 showIntro;
    i16 itemType;
    i16 unKnow5;
    i16 unKnow6;
    i16 unKnow7;
    i16 addCurrentHP;
    i16 addMaxHP;
    i16 addPoi;
    i16 addPhyPower;
    i16 changeMPType;
    i16 addCurrentMP;
    i16 addMaxMP;
    i16 addAttack;
    i16 addSpeed;
    i16 addDefence;
    i16 addMedcine;
    i16 addUsePoi;
    i16 addMedPoi;
    i16 addDefPoi;
    i16 addFist;
    i16 addSword;
    i16 addKnife;
    i16 addUnusual;
    i16 addHidWeapon;
    i16 addKnowledge;
    i16 addEthics;
    i16 addAttTwice;
    i16 addAttPoi;
    i16 onlyPracRole;
    i16 needMPType;
    i16 needMP;
    i16 needAttack;
    i16 needSpeed;
    i16 needUsePoi;
    i16 needMedcine;
    i16 needMedPoi;
    i16 needFist;
    i16 needSword;
    i16 needKnife;
    i16 needUnusual;
    i16 needHidWeapon;
    i16 needAptitude;
    i16 needExp;
    i16 needExpForItem;
    i16 needMaterial;
    i16 getItem[5];
    i16 needMatAmount[5];
};

union TItem {
    TItemElement element;
    i16 data[95];
};

struct TSceneElement {
    i16 listNum;
    char name[10];
    i16 exitMusic;
    i16 entranceMusic;
    i16 jumpScene;
    i16 enCondition;
    i16 mainEntranceY1;
    i16 mainEntranceX1;
    i16 mainEntranceY2;
    i16 mainEntranceX2;
    i16 entranceY;
    i16 entranceX;
    i16 exitY[3];
    i16 exitX[3];
    i16 jumpY1;
    i16 jumpX1;
    i16 jumpY2;
    i16 jumpX2;
};

union TScene {
    TSceneElement element;
    i16 data[26];
};

struct TMagicElement {
    i16 listNum;
    char name[10];
    i16 unKnow[5];
    i16 soundNum;
    i16 magicType;
    i16 amiNum;
    i16 hurtType;
    i16 attAreaType;
    i16 needMP;
    i16 poison;
    i16 attack[10];
    i16 moveDistance[10];
    i16 attDistance[10];
    i16 addMP[10];
    i16 hurtMP[10];
};

union TMagic {
    TMagicElement element;
    i16 data[68];
};

struct TShopElement {
    i16 item[5];
    i16 amount[5];
    i16 price[5];
};

union TShop {
    TShopElement element;
    i16 data[15];
};

struct TBattleRoleElement {
    i16 rnum;          // Role number from Rrole array
    i16 team;          // 0 = player, 1 = enemy
    i16 y, x;          // Grid position (0-63)
    i16 face;          // Direction: 0=left, 1=down, 2=up, 3=right
    i16 dead;          // 0 = alive, 1 = dead
    i16 step;          // Remaining movement steps this turn
    i16 acted;         // 0 = not acted, 1 = acted, 2 = moved
    i16 pic;
    i16 showNumber;    // Damage number to display (-1 = none)
    i16 unUse1, unUse2, unUse3;
    i16 expGot;        // Experience gained
    i16 autoFlag;      // 0 = manual, 1 = auto
    i16 realSpeed;
    i16 realProgress;
    i16 bHead;
    i16 autoMode;      // 0=manual, 1=all-attack, 2=balanced, 3=bystander
};

union TBattleRole {
    TBattleRoleElement element;
    i16 data[19];
};

struct TWarDataElement {
    i16 warNum;
    char name[10];     // 10 ansichar = 10 bytes = 5 i16 slots
    i16 bFieldNum;
    i16 expGot;
    i16 musicNum;
    i16 teamMate[6];
    i16 autoTeamMate[6];
    i16 teamY[6];
    i16 teamX[6];
    i16 enemy[20];
    i16 enemyY[20];
    i16 enemyX[20];
};

union TWarData {
    TWarDataElement element;
    i16 data[93];
};

#pragma pack(pop)

static_assert(sizeof(TItemList) == 4, "TItemList size mismatch");
static_assert(sizeof(TRole) == 182, "TRole size mismatch");
static_assert(sizeof(TItem) == 190, "TItem size mismatch");
static_assert(sizeof(TScene) == 52, "TScene size mismatch");
static_assert(sizeof(TMagic) == 136, "TMagic size mismatch");
static_assert(sizeof(TShop) == 30, "TShop size mismatch");
static_assert(sizeof(TBattleRole) == 38, "TBattleRole size mismatch");
static_assert(sizeof(TWarData) == 186, "TWarData size mismatch");

} // namespace kys
