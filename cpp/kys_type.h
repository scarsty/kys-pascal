#pragma once
// kys_type.h - 类型定义与全局变量声明
// 对应 kys_type.pas

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <cstdint>
#include <string>
#include <vector>
#include <map>

// 基本类型别名
using smallint = int16_t;
using uint32 = uint32_t;
using uint16 = uint16_t;

// ---- 结构体定义 ----

struct TPosition {
    int x = 0, y = 0;
};

struct TItemList {
    smallint Number = -1;
    smallint Amount = 0;
};

struct TBuildInfo {
    int c = 0;
    int b = 0, x = 0, y = 0;
};

struct TPNGIndex {
    smallint Num = 0, Frame = 0, x = 0, y = 0, Loaded = 0, UseGRP = 0;
    SDL_Surface** CurPointer = nullptr;
};

struct TCol {
    uint8_t r = 0, g = 0, b = 0;
};

struct TCloud {
    int Picnum = 0;
    int Shadow = 0;
    int Alpha = 0;
    uint32 mixColor = 0;
    int mixAlpha = 0;
    int Positionx = 0, Positiony = 0, Speedx = 0, Speedy = 0;
};

// ---- 游戏核心数据结构 ----
// 这些结构体使用union实现按元素/按数组两种访问方式, 对应Pascal中的variant record

#pragma pack(push, 1)

struct TRole {
    union {
        struct {
            smallint ListNum, HeadNum, IncLife, UnUse;
            char Name[10]; // ansichar
            char Nick[10];
            smallint Sexual, Level;
            uint16 Exp;
            smallint CurrentHP, MaxHP, Hurt, Poison, PhyPower;
            uint16 ExpForItem;
            smallint Equip[2];
            smallint AmiFrameNum[5], AmiDelay[5], SoundDealy[5];
            smallint MPType, CurrentMP, MaxMP;
            smallint Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi;
            smallint Fist, Sword, Knife, Unusual, HidWeapon;
            smallint Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook;
            uint16 ExpForBook;
            smallint Magic[10], MagLevel[10];
            smallint TakingItem[4], TakingItemAmount[4];
        };
        smallint Data[91];
    };
};

struct TItem {
    union {
        struct {
            smallint ListNum;
            char Name[20];
            char Name1[20];
            char Introduction[30];
            smallint Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7;
            smallint AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP;
            smallint AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi;
            smallint AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics, AddAttTwice, AddAttPoi;
            smallint OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi;
            smallint NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude;
            smallint NeedExp, NeedExpForItem, NeedMaterial;
            smallint GetItem[5], NeedMatAmount[5];
        };
        smallint Data[95];
    };
};

struct TScene {
    union {
        struct {
            smallint ListNum;
            char Name[10];
            smallint ExitMusic, EntranceMusic;
            smallint JumpScene, EnCondition;
            smallint MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2;
            smallint EntranceY, EntranceX;
            smallint ExitY[3], ExitX[3];
            smallint JumpY1, JumpX1, JumpY2, JumpX2;
        };
        smallint Data[26];
    };
};

struct TMagic {
    union {
        struct {
            smallint ListNum;
            char Name[10];
            smallint UnKnow[5];
            smallint SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison;
            smallint Attack[10], MoveDistance[10], AttDistance[10], AddMP[10], HurtMP[10];
        };
        smallint Data[68];
    };
};

struct TShop {
    union {
        struct {
            smallint Item[5], Amount[5], Price[5];
        };
        smallint Data[15];
    };
};

struct TBattleRole {
    union {
        struct {
            smallint rnum, Team, Y, X, Face, Dead, Step, Acted;
            smallint Pic, ShowNumber, UnUse1, UnUse2, UnUse3, ExpGot, Auto;
            smallint RealSpeed, RealProgress, BHead, AutoMode;
        };
        smallint Data[19];
    };
};

struct TWarData {
    union {
        struct {
            smallint Warnum;
            char Name[10];
            smallint BFieldNum, ExpGot, MusicNum;
            smallint TeamMate[6], AutoTeamMate[6], TeamY[6], TeamX[6];
            smallint Enemy[20], EnemyY[20], EnemyX[20];
        };
        smallint Data[0x5D];
    };
};

#pragma pack(pop)

// ---- 函数指针类型 ----
using TPInt1 = void(*)(int);

// ---- 全局变量声明 (定义在 kys_type.cpp) ----

extern int MODVersion;
extern std::string TitleString;
extern std::string VersionStr;

extern const char* CHINESE_FONT;
extern int CHINESE_FONT_SIZE;
extern const char* ENGLISH_FONT;
extern int ENGLISH_FONT_SIZE;

extern int CENTER_X;
extern int CENTER_Y;

extern std::string AppPath, AppPathCommon;

// 游戏常数
extern int ITEM_BEGIN_PIC;
extern int BEGIN_EVENT;
extern int BEGIN_SCENE;
extern int BEGIN_Sx;
extern int BEGIN_Sy;
extern int SOFTSTAR_BEGIN_TALK;
extern int SOFTSTAR_NUM_TALK;
extern int MAX_PHYSICAL_POWER;
extern int MONEY_ID;
extern int COMPASS_ID;
extern int BEGIN_LEAVE_EVENT;
extern int BEGIN_BATTLE_ROLE_PIC;
extern int MAX_LEVEL;
extern int MAX_WEAPON_MATCH;
extern int MIN_KNOWLEDGE;
extern int MAX_ITEM_AMOUNT;
extern int MAX_HP;
extern int MAX_MP;
extern int MaxProList[16]; // index 43..58 => [0..15]
extern int LIFE_HURT;
extern int POISON_HURT;
extern int MED_LIFE;
extern int MAX_ADD_PRO;
extern int NOVEL_BOOK;
extern int MAX_HEAD_NUM;
extern int BEGIN_WALKPIC;

// 游戏数据
extern uint8_t ACol[769];
extern uint8_t ACol1[769];
extern uint8_t ACol2[769];

extern smallint Earth[480][480];
extern smallint Surface[480][480];
extern smallint Building[480][480];
extern smallint BuildX[480][480];
extern smallint BuildY[480][480];
extern smallint Entrance[480][480];

extern smallint InShip, SavedSceneIndex, Mx, My, Sx, Sy, MFace, ShipX, ShipY, ShipX1, ShipY1, ShipFace;
extern smallint TeamList[6];
extern std::vector<TItemList> RItemList;
extern TRole Rrole[2032];
extern TItem Ritem[725];
extern TScene Rscene[201];
extern TMagic Rmagic[999];
extern TShop RShop[11];
extern int SceneAmount;

extern smallint SData[401][6][64][64];
extern smallint DData[401][200][11];

extern smallint BField[8][64][64];
extern TWarData WarSta;

extern smallint LeaveList[100];
extern smallint EffectList[200];
extern smallint LevelUpList[100];
extern smallint MatchList[100][3];

// 图像与界面设置
extern int BIG_PNG_TILE;
extern int FULLSCREEN;
extern int RESOLUTIONX;
extern int RESOLUTIONY;
extern int SIMPLE;
extern int SMOOTH;
extern int HIRES_TEXT;
extern int WMP_4_PIC;

// SDL运行时对象
extern SDL_Event event;
extern TTF_Font* ChineseFont;
extern TTF_Font* EnglishFont;

extern uint32 ScreenFlag;
extern SDL_Surface* screen;
extern SDL_Surface* freshscreen;
extern SDL_Window* window;
extern SDL_Renderer* render;
extern SDL_Texture* screenTex;
extern SDL_Texture* compositeTex;

extern SDL_Surface* ImgScene;
extern SDL_Surface* ImgSceneBack;
extern SDL_Surface* ImgBField;
extern SDL_Surface* ImgBBuild;
extern std::vector<smallint> BlockImg;
extern std::vector<smallint> BlockImg2;
extern TPosition BlockScreen;

extern int MPicAmount, SPicAmount, BPicAmount, EPicAmount, CPicAmount, FPicAmount, HPicAmount;

// 贴图数据
extern std::vector<uint8_t> MPic, SPic, WPic, EPic, HPic, CPic, KDef, TDef;
extern std::vector<int> MIdx, SIdx, WIdx, EIdx, HIdx, CIdx, KIdx, TIdx;

extern std::vector<uint8_t> FPic[1000];
extern std::vector<int> FIdx[1000];

extern std::vector<SDL_Surface*> MPNGTile, SPNGTile, BPNGTile, EPNGTile, CPNGTile, TitlePNGTile;
extern std::vector<SDL_Surface*> FPNGTile[1000];

extern SDL_Surface* MSurface;
extern SDL_Surface* SSurface;
extern std::vector<SDL_Surface*> HeadSurface;
extern std::vector<SDL_Surface*> BHead;
extern std::vector<SDL_Surface*> ItemSurface;

extern std::map<int, SDL_Surface*> fonts;
extern std::map<int, SDL_Surface*> FontsHr;

// 音频
extern int VOLUME, VOLUMEWAV, SOUND3D;
extern std::vector<MIX_Audio> Music;
extern std::vector<MIX_Audio> ESound;
extern std::vector<MIX_Audio> ASound;

extern int StartMusic;
extern int ExitSceneMusicNum;
extern int NowMusic;

// 事件和脚本状态
extern smallint x50[0x8000];
extern int KDEF_SCRIPT;
extern struct lua_State* lua_script;
extern int Script5032Pos;
extern int Script5032Value;

extern int SceneRolePic;
extern int NeedRefreshScene;

// 游戏体验设置
extern int CLOUD_AMOUNT;
extern std::vector<TCloud> Cloud;

extern int WALK_SPEED, WALK_SPEED2, BATTLE_SPEED;
extern int MMAPAMI;
extern int SCENEAMI;
extern int SEMIREAL;
extern int NIGHT_EFFECT;
extern int EXIT_GAME;

extern TPosition TitlePosition;
extern TPosition OpenPicPosition;

// 运行时状态
extern SDL_Mutex* mutex;
extern uint32 ChangeColorList[2][21];
extern bool AskingQuit;
extern int BeginTime;
extern double NowTime;
extern bool LoadingScene;

extern int MainMapStep, MainMapStill;
extern int Cx, Cy, SFace, SStep;
extern int CurScene, CurEvent, CurItem, CurrentBattle, Where;
extern int SaveNum;
extern TBattleRole Brole[100];
extern int BRoleAmount;
extern int Bx, By, Ax, Ay;
extern int BattleResult;

// 寻路
extern smallint linex[480 * 480];
extern smallint liney[480 * 480];
extern int nowstep;
extern int PathCost[480][480];

extern smallint ItemList[501];

extern int EXPAND_GROUND;
extern smallint ExGround[192][192]; // [-64..127]
extern smallint ImageWidth, ImageHeight;
extern int BattleRound;

extern int CHNFONT_SPACEWIDTH;

// 手柄控制
extern uint32 JOY_RETURN, JOY_ESCAPE, JOY_LEFT, JOY_RIGHT, JOY_UP, JOY_DOWN, JOY_MOUSE_LEFT;
extern uint32 JOY_AXIS_DELAY;

extern int CellPhone;
extern int ScreenRotate;

extern int FingerCount;
extern uint32 FingerTick;
extern bool FreeWalking;
extern bool BattleSelecting;

extern SDL_Surface* VirtualKeyU;
extern SDL_Surface* VirtualKeyD;
extern SDL_Surface* VirtualKeyL;
extern SDL_Surface* VirtualKeyR;
extern SDL_Surface* VirtualKeyA;
extern SDL_Surface* VirtualKeyB;
extern int ShowVirtualKey;
extern uint32 VirtualKeyValue;
extern int VirtualCrossX, VirtualCrossY, VirtualKeySize;
extern int VirtualAX, VirtualAY, VirtualBX, VirtualBY;

extern int SkipTalk;
extern uint64_t tttt;

// 简繁转换
extern void* cct2s;
extern void* ccs2t;

extern double EXP_RATE;
extern bool TouchWalk;
extern int RENDERER;

// 色值蒙版
constexpr uint32 RMask = 0xFF0000;
constexpr uint32 GMask = 0xFF00;
constexpr uint32 BMask = 0xFF;
constexpr uint32 AMask = 0xFF000000;

// ExGround偏移访问辅助: Pascal中下标为 -64..127, C++中用 [0..191]
inline smallint& ExGroundAt(int x, int y) {
    return ExGround[x + 64][y + 64];
}
