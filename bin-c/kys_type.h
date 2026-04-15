#pragma once
// kys_type.h - 类型定义与全局变量声明
// 对应 kys_type.pas

#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

// 基本类型别名
using uint32 = uint32_t;
using uint16 = uint16_t;

// Forward declarations
struct lua_State;

// ---- 结构体定义 ----

struct TPosition
{
    int x = 0, y = 0;
};

struct TItemList
{
    int16_t Number = -1;
    int16_t Amount = 0;
};

struct TBuildInfo
{
    int c = 0;
    int b = 0, x = 0, y = 0;
};

struct TPNGIndex
{
    int16_t Num = 0, Frame = 0, x = 0, y = 0, Loaded = 0, UseGRP = 0;
    SDL_Surface** CurPointer = nullptr;
};

struct TCol
{
    uint8_t r = 0, g = 0, b = 0;
};

struct TCloud
{
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

struct TRole
{
    union
    {
        struct
        {
            int16_t ListNum, HeadNum, IncLife, UnUse;
            char Name[10];    // ansichar
            char Nick[10];
            int16_t Sexual, Level;
            uint16 Exp;
            int16_t CurrentHP, MaxHP, Hurt, Poison, PhyPower;
            uint16 ExpForItem;
            int16_t Equip[2];
            int16_t AmiFrameNum[5], AmiDelay[5], SoundDealy[5];
            int16_t MPType, CurrentMP, MaxMP;
            int16_t Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi;
            int16_t Fist, Sword, Knife, Unusual, HidWeapon;
            int16_t Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook;
            uint16 ExpForBook;
            int16_t Magic[10], MagLevel[10];
            int16_t TakingItem[4], TakingItemAmount[4];
        };
        int16_t Data[91];
    };
};

struct TItem
{
    union
    {
        struct
        {
            int16_t ListNum;
            char Name[20];
            char Name1[20];
            char Introduction[30];
            int16_t Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7;
            int16_t AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP;
            int16_t AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi;
            int16_t AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics, AddAttTwice, AddAttPoi;
            int16_t OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi;
            int16_t NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude;
            int16_t NeedExp, NeedExpForItem, NeedMaterial;
            int16_t GetItem[5], NeedMatAmount[5];
        };
        int16_t Data[95];
    };
};

struct TScene
{
    union
    {
        struct
        {
            int16_t ListNum;
            char Name[10];
            int16_t ExitMusic, EntranceMusic;
            int16_t JumpScene, EnCondition;
            int16_t MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2;
            int16_t EntranceY, EntranceX;
            int16_t ExitY[3], ExitX[3];
            int16_t JumpY1, JumpX1, JumpY2, JumpX2;
        };
        int16_t Data[26];
    };
};

struct TMagic
{
    union
    {
        struct
        {
            int16_t ListNum;
            char Name[10];
            int16_t UnKnow[5];
            int16_t SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison;
            int16_t Attack[10], MoveDistance[10], AttDistance[10], AddMP[10], HurtMP[10];
        };
        int16_t Data[68];
    };
};

struct TShop
{
    union
    {
        struct
        {
            int16_t Item[5], Amount[5], Price[5];
        };
        int16_t Data[15];
    };
};

struct TBattleRole
{
    union
    {
        struct
        {
            int16_t rnum, Team, Y, X, Face, Dead, Step, Acted;
            int16_t Pic, ShowNumber, UnUse1, UnUse2, UnUse3, ExpGot, Auto;
            int16_t RealSpeed, RealProgress, BHead, AutoMode;
        };
        int16_t Data[19];
    };
};

struct TWarData
{
    union
    {
        struct
        {
            int16_t Warnum;
            char Name[10];
            int16_t BFieldNum, ExpGot, MusicNum;
            int16_t TeamMate[6], AutoTeamMate[6], TeamY[6], TeamX[6];
            int16_t Enemy[20], EnemyY[20], EnemyX[20];
        };
        int16_t Data[0x5D];
    };
};

#pragma pack(pop)

// ---- 函数指针类型 ----
using TPInt1 = void (*)(int);

// ---- 全局变量 ----
// 大数组使用extern（定义在kys_type.cpp），其余使用C++17 inline变量

// 程序路径
inline std::string AppPath, AppPathCommon;

// MOD系统
inline int MODVersion = 0;
inline std::string TitleString = "All Heros in Kam Yung's Stories";
inline std::string VersionStr = "";

// 字体
inline const char* CHINESE_FONT = "resource/chinese.ttf";
inline int CHINESE_FONT_SIZE = 20;
inline const char* ENGLISH_FONT = "resource/eng.ttf";
inline int ENGLISH_FONT_SIZE = 19;
inline int CHNFONT_SPACEWIDTH = 10;

// 屏幕中心
inline int CENTER_X = 400;
inline int CENTER_Y = 225;

// 游戏常数
inline int ITEM_BEGIN_PIC = 3501;
inline int BEGIN_EVENT = 691;
inline int BEGIN_SCENE = 70;
inline int BEGIN_Sx = 20;
inline int BEGIN_Sy = 19;
inline int SOFTSTAR_BEGIN_TALK = 2547;
inline int SOFTSTAR_NUM_TALK = 18;
inline int MAX_PHYSICAL_POWER = 100;
inline int MONEY_ID = 174;
inline int COMPASS_ID = 182;
inline int BEGIN_LEAVE_EVENT = 950;
inline int BEGIN_BATTLE_ROLE_PIC = 2553;
inline int MAX_LEVEL = 30;
inline int MAX_WEAPON_MATCH = 7;
inline int MIN_KNOWLEDGE = 80;
inline int MAX_ITEM_AMOUNT = 200;
inline int MAX_HP = 999;
inline int MAX_MP = 999;
inline int MaxProList[16] = {};
inline int LIFE_HURT = 10;
inline int POISON_HURT = 10;
inline int MED_LIFE = 4;
inline int MAX_ADD_PRO = 0;
inline int NOVEL_BOOK = 144;
inline int MAX_HEAD_NUM = 189;
inline int BEGIN_WALKPIC = 2501;

// 调色板
inline uint8_t ACol[769] = {};
inline uint8_t ACol1[769] = {};
inline uint8_t ACol2[769] = {};

// 大地图数据 (extern - 大数组)
extern int16_t Earth[480][480];
extern int16_t Surface[480][480];
extern int16_t Building[480][480];
extern int16_t BuildX[480][480];
extern int16_t BuildY[480][480];
extern int16_t Entrance[480][480];

// 游戏状态
inline int16_t InShip = 0, SavedSceneIndex = 0;
inline int16_t Mx = 0, My = 0, Sx = 0, Sy = 0, MFace = 0;
inline int16_t ShipX = 0, ShipY = 0, ShipX1 = 0, ShipY1 = 0, ShipFace = 0;
inline int16_t TeamList[6] = {};
inline std::vector<TItemList> RItemList;

// 角色/物品/场景/武功/商店 (extern - 大数组)
extern TRole Rrole[2032];
extern TItem Ritem[725];
extern TScene Rscene[201];
extern TMagic Rmagic[999];
extern TShop RShop[11];
inline int SceneAmount = 0;

// 场景/事件数据 (extern - 巨大数组)
extern int16_t SData[401][6][64][64];
extern int16_t DData[401][200][11];

// 战场地图
extern int16_t BField[8][64][64];
extern TWarData WarSta;

// 列表
inline int16_t LeaveList[100] = {};
inline int16_t EffectList[200] = {};
inline int16_t LevelUpList[100] = {};
inline int16_t MatchList[100][3] = {};

// 图像与界面设置
inline int BIG_PNG_TILE = 0;
inline int FULLSCREEN = 0;
inline int RESOLUTIONX = 1280;
inline int RESOLUTIONY = 720;
inline int SIMPLE = 1;
inline int SMOOTH = 1;
inline int WMP_4_PIC = 0;

// SDL运行时对象
inline SDL_Event event = {};
inline TTF_Font* ChineseFont = nullptr;
inline TTF_Font* EnglishFont = nullptr;

inline uint32 ScreenFlag = 0;
inline SDL_Surface* screen = nullptr;
inline SDL_Surface* freshscreen = nullptr;
inline SDL_Window* window = nullptr;
inline SDL_Renderer* render = nullptr;
inline SDL_Texture* screenTex = nullptr;

inline SDL_Surface* ImgScene = nullptr;
inline SDL_Surface* ImgSceneBack = nullptr;
inline SDL_Surface* ImgBField = nullptr;
inline SDL_Surface* ImgBBuild = nullptr;
inline std::vector<int16_t> BlockImg;
inline std::vector<int16_t> BlockImg2;
inline TPosition BlockScreen;

inline int MPicAmount = 0, SPicAmount = 0, BPicAmount = 0;
inline int EPicAmount = 0, CPicAmount = 0, FPicAmount = 0, HPicAmount = 0;

// 贴图数据
inline std::vector<uint8_t> MPic, SPic, WPic, EPic, HPic, CPic, KDef, TDef, TitlePic;
inline std::vector<int> MIdx, SIdx, WIdx, EIdx, HIdx, CIdx, KIdx, TIdx, TitleIdx;

inline std::vector<uint8_t> FPic[1000];
inline std::vector<int> FIdx[1000];

inline std::vector<SDL_Surface*> MPNGTile, SPNGTile, BPNGTile, EPNGTile, CPNGTile, TitlePNGTile;
inline std::vector<SDL_Surface*> FPNGTile[1000];

inline SDL_Surface* MSurface = nullptr;
inline SDL_Surface* SSurface = nullptr;
inline std::vector<SDL_Surface*> HeadSurface;
inline std::vector<SDL_Surface*> BHead;
inline std::vector<SDL_Surface*> ItemSurface;

inline std::map<int, SDL_Surface*> fonts;

// 音频
inline int VOLUME = 30, VOLUMEWAV = 30, SOUND3D = 1;
inline std::vector<MIX_Audio*> Music;
inline std::vector<MIX_Audio*> ESound;
inline std::vector<MIX_Audio*> ASound;
inline int StartMusic = 16;
inline int ExitSceneMusicNum = 0;
inline int NowMusic = -1;

// 脚本系统
extern int16_t x50[0x8000];
inline int KDEF_SCRIPT = 0;
inline lua_State* Lua_script = nullptr;
inline int Script5032Pos = -100;
inline int Script5032Value = -1;

// 场景动画
inline int SceneRolePic = 0;
inline int NeedRefreshScene = 1;
inline int SCENEAMI = 2;

// 云
inline int CLOUD_AMOUNT = 60;
inline std::vector<TCloud> Cloud;

// 系统设置
inline int WALK_SPEED = 10, WALK_SPEED2 = 10, BATTLE_SPEED = 10;
inline int MMAPAMI = 1;
inline int SEMIREAL = 0;
inline int NIGHT_EFFECT = 0;
inline int EXIT_GAME = 1;
inline int EXPAND_GROUND = 1;

// 标题/开场位置
inline TPosition TitlePosition = {};
inline TPosition OpenPicPosition = { -1, -1 };

// SDL同步
inline SDL_Mutex* mutex = nullptr;
inline uint32 ChangeColorList[2][21] = {};
inline bool AskingQuit = false;
inline int BeginTime = 0;
inline double NowTime = 0;
inline bool LoadingScene = false;

// 行走/场景状态
inline int MainMapStep = 0, MainMapStill = 0, MainMapStillcount = 0;
inline int Cx = 0, Cy = 0, SFace = 0, SStep = 0;
inline int gotoevent = -1;
inline int CurScene = 0, CurEvent = -1, CurItem = -1;
inline int CurrentBattle = 0, Where = 0;
inline int SaveNum = 0;

// 战斗
inline TBattleRole Brole[200] = {};
inline int BRoleAmount = 0;
inline int Bx = 0, By = 0, Ax = 0, Ay = 0;
inline int BattleResult = 0;
inline int BattleRound = 0;

// 寻路
extern int16_t linex[480 * 480];
extern int16_t liney[480 * 480];
inline int nowstep = 0;
extern int PathCost[480][480];

// 物品列表
inline int16_t ItemList[501] = {};

// 扩展地面
extern int16_t ExGround[192][192];
inline int ImageWidth = 0, ImageHeight = 0;

// 手柄
inline uint32 JOY_RETURN = 0, JOY_ESCAPE = 0;
inline uint32 JOY_LEFT = 0, JOY_RIGHT = 0, JOY_UP = 0, JOY_DOWN = 0;
inline uint32 JOY_MOUSE_LEFT = 0, JOY_AXIS_DELAY = 0;

// 触控/手机
inline int CellPhone = 0;
inline int ScreenRotate = 0;
inline int FingerCount = 0;
inline uint32 FingerTick = 0;
inline bool FreeWalking = false;
inline bool BattleSelecting = false;

// 虚拟按键（手机模式）
inline int ShowVirtualKey = 0;
inline uint32 VirtualKeyValue = 0;
//inline int VirtualKeyUState = 0, VirtualKeyDState = 0, VirtualKeyLState = 0, VirtualKeyRState = 0, VirtualKeyAState = 0, VirtualKeyBState = 0;    //0: 无按键, 1: 经过, 2: 按下
inline int VirtualCrossX = 150, VirtualCrossY = 250;
inline int VirtualKeySize = 60;
inline int VirtualAX = 0, VirtualAY = 0;
inline int VirtualBX = 0, VirtualBY = 0;
inline SDL_Surface* VirtualKeyU = nullptr;
inline SDL_Surface* VirtualKeyD = nullptr;
inline SDL_Surface* VirtualKeyL = nullptr;
inline SDL_Surface* VirtualKeyR = nullptr;
inline SDL_Surface* VirtualKeyA = nullptr;
inline SDL_Surface* VirtualKeyB = nullptr;

// 其他系统变量
inline int RENDERER = 0;
inline int TouchWalk = 1;
inline double EXP_RATE = 1.0;
inline int SkipTalk = 0;

// 色值蒙版
constexpr uint32 RMask = 0xFF0000;
constexpr uint32 GMask = 0xFF00;
constexpr uint32 BMask = 0xFF;
constexpr uint32 AMask = 0xFF000000;

// ExGround偏移访问辅助: Pascal中下标为 -64..127, C++中用 [0..191]
inline int16_t& ExGroundAt(int x, int y)
{
    return ExGround[x + 64][y + 64];
}
