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
inline std::string AppPath, AppPathCommon;  // 程序的路径，公用文件的路径

// MOD系统
// 0-原版; 11-小猪闯江湖, 12-苍龙逐日; 21-天书奇侠, 22-菠萝三国, 23-笑梦游记; 31-再战江湖; 41-PTT; 51-魏征; 71-天书劫; 81-真龙觉醒; 91-问情; 100-其他
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
inline int ITEM_BEGIN_PIC = 3501;   // 物品起始图片
inline int BEGIN_EVENT = 691;       // 初始事件
inline int BEGIN_SCENE = 70;        // 初始场景
inline int BEGIN_Sx = 20;           // 初始坐标 (X)
// 程序中的x,y与修改器所见相反: 所有游戏数据均是先Y后X; 此处使用类似数学右旋坐标系而非计算机左旋坐标系
inline int BEGIN_Sy = 19;           // 初始坐标 (Y)
inline int SOFTSTAR_BEGIN_TALK = 2547;  // 软体娃娃对话的开始编号
inline int SOFTSTAR_NUM_TALK = 18;      // 软体娃娃的对话数量
inline int MAX_PHYSICAL_POWER = 100;    // 最大体力
inline int MONEY_ID = 174;          // 银两的物品代码
inline int COMPASS_ID = 182;        // 罗盘的物品代码
inline int BEGIN_LEAVE_EVENT = 950; // 起始离队事件
inline int BEGIN_BATTLE_ROLE_PIC = 2553;  // 人物起始战斗贴图
inline int MAX_LEVEL = 30;          // 最大等级
inline int MAX_WEAPON_MATCH = 7;    // '武功武器配合'组合的数量
inline int MIN_KNOWLEDGE = 80;      // 最低有效武学常识
inline int MAX_ITEM_AMOUNT = 200;   // 最大物品数量
inline int MAX_HP = 999;            // 最大生命
inline int MAX_MP = 999;            // 最大内功
inline int MaxProList[16] = {};     // 最大攻击值~最大左右互博值
inline int LIFE_HURT = 10;          // 伤害值比例
inline int POISON_HURT = 10;        // 中毒损血比例
inline int MED_LIFE = 4;            // 医疗增加生命比例
inline int MAX_ADD_PRO = 0;         // 是否升级最大化攻击属性
// 以下3个常数实际并未使用, 不能由ini文件指定
inline int NOVEL_BOOK = 144;        // 天书起始编码(因偷懒并未使用)
inline int MAX_HEAD_NUM = 189;      // 有专有头像的最大人物编号, 仅用于对话指令
inline int BEGIN_WALKPIC = 2501;    // 场景内行走贴图起始值

// 调色板
// 默认调色板数据; 第一个色调及顺序变化, 第二个仅色调变化, 第三个不可变
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

// 角色/物品/场景/武功/商店 (extern - 大数组, 均远大于原有容量)
extern TRole Rrole[2032];
extern TItem Ritem[725];
extern TScene Rscene[201];
extern TMagic Rmagic[999];
extern TShop RShop[11];
inline int SceneAmount = 0;

// 场景/事件数据 (extern - 巨大数组)
// SData[scene][layer][x][y]: 0-地面, 1-建筑, 2-物品, 3-事件, 4-建筑高度, 5-物品高度
extern int16_t SData[401][6][64][64];
extern int16_t DData[401][200][11];

// 战场地图
// BField[layer][x][y]: 0-地面, 1-建筑, 2-人物, 3-可否被选中, 4-攻击范围, 5-未使用, 6-标记第一次移动时不能到达的位置, 7-标记敌人身边
extern int16_t BField[8][64][64];
extern TWarData WarSta;  // 战场数据, 即war.sta文件的映像

// 列表
inline int16_t LeaveList[100] = {};   // 各类列表, 前四个从文件读入
inline int16_t EffectList[200] = {};
inline int16_t LevelUpList[100] = {};
inline int16_t MatchList[100][3] = {};

// 图像与界面设置
inline int BIG_PNG_TILE = 0;
inline int FULLSCREEN = 0;          // 是否全屏
inline int RESOLUTIONX = 1280;
inline int RESOLUTIONY = 720;
inline int SIMPLE = 1;              // 是否简体
inline int SMOOTH = 1;              // 平滑设置: 0-完全不平滑, 1-仅标准分辨率不平滑, 2-任何时候都使用平滑
inline int WMP_4_PIC = 0;           // 战场人物的静止贴图使用WMP中的图片，否则直接从fight中计算

// SDL运行时对象
inline SDL_Event event = {};
inline bool BattleAutoEscapePressed = false;  // 自动战斗中ESC被按下的标志（防止事件被后续事件覆盖）
inline TTF_Font* ChineseFont = nullptr;
inline TTF_Font* EnglishFont = nullptr;

inline uint32 ScreenFlag = 0;
inline SDL_Surface* screen = nullptr;          // 主画面
inline SDL_Surface* freshscreen = nullptr;     // 用于菜单/事件中快速重画的画面
inline SDL_Window* window = nullptr;
inline SDL_Renderer* render = nullptr;
inline SDL_Texture* screenTex = nullptr;

// 重画场景和战场的图形映像; 实时重画效率较低, 故首先生成映像, 需要时载入
// ImgBBuild仅保存建筑层以方便快速载入
inline SDL_Surface* ImgScene = nullptr;
inline SDL_Surface* ImgSceneBack = nullptr;
inline SDL_Surface* ImgBField = nullptr;
inline SDL_Surface* ImgBBuild = nullptr;
inline std::vector<int16_t> BlockImg;   // 场景和战场的遮挡信息
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
inline std::vector<SDL_Surface*> HeadSurface;  // 用于画头像
inline std::vector<SDL_Surface*> BHead;
inline std::vector<SDL_Surface*> ItemSurface;

inline std::map<int, SDL_Surface*> fonts;

// 音频
inline int VOLUME = 30, VOLUMEWAV = 30, SOUND3D = 1;  // 音乐音量, 音效音量, 是否启用3D音效
inline std::vector<MIX_Audio*> Music;
inline std::vector<MIX_Audio*> ESound;
inline std::vector<MIX_Audio*> ASound;
inline int StartMusic = 16;
inline int ExitSceneMusicNum = 0;  // 离开场景的音乐
inline int NowMusic = -1;          // 正在播放的音乐

// 脚本系统
extern int16_t x50[0x8000];  // 扩充指令50所使用的变量
inline int KDEF_SCRIPT = 0;          // 使用脚本处理事件
inline lua_State* Lua_script = nullptr;  // lua脚本
inline int Script5032Pos = -100;     // 脚本用于处理50 32使用
inline int Script5032Value = -1;

// 场景动画
inline int SceneRolePic = 0;         // 主角场景内当前贴图编号, 引入该常量主要用途是25指令事件号为-1的情况
inline int NeedRefreshScene = 1;     // 是否需要刷新场景, 用于事件中和副线程
inline int SCENEAMI = 2;             // 场景内动态效果处理方式: 0-关闭, 1-打开, 2-用另一线程处理

// 云
inline int CLOUD_AMOUNT = 60;  // 云的数量
inline std::vector<TCloud> Cloud;

// 系统设置
inline int WALK_SPEED = 10, WALK_SPEED2 = 10, BATTLE_SPEED = 10;  // 行走时的主延时, 如果觉得行走速度慢可以修改这里
inline int MMAPAMI = 1;       // 主地图动态效果
inline int SHOW_SUBSCENE_NAME = 0;  // 主地图是否显示当前子场景名称
inline int SHOW_BATTLE_HP = 1;      // 战斗时是否显示头顶血条
inline int SEMIREAL = 0;      // 半即時
inline int NIGHT_EFFECT = 0;  // 是否使用白昼和黑夜效果
inline int EXIT_GAME = 1;     // 退出时的提问方式
inline int EXPAND_GROUND = 1;

// 标题/开场位置
inline TPosition TitlePosition = {};
inline TPosition OpenPicPosition = { -1, -1 };

// SDL同步
inline SDL_Mutex* mutex = nullptr;
inline uint32 ChangeColorList[2][21] = {};  // 替换色表, 无用
inline bool AskingQuit = false;    // 是否正在提问退出
inline int BeginTime = 0;          // 游戏开始时间, 单位为分钟, 0~1439
inline double NowTime = 0;
inline bool LoadingScene = false;  // 是否正在载入场景

// 行走/场景状态
inline int MainMapStep = 0, MainMapStill = 0, MainMapStillcount = 0;  // 主地图步数, 是否处于静止
inline int Cx = 0, Cy = 0, SFace = 0, SStep = 0;  // 场景内坐标, 场景中心点, 方向, 步数
inline int gotoevent = -1;
inline int CurScene = 0, CurEvent = -1, CurItem = -1;  // 当前场景, 事件(在场景中的事件号), 使用物品
inline int CurrentBattle = 0, Where = 0;  // 当前战斗, Where: 0-主地图, 1-场景, 2-战场, 3-开头画面
inline int SaveNum = 0;  // 存档号, 未使用

// 战斗
// Brole[n]: 0-人物序号, 1-敌我, 2/3-坐标, 4-面对方向, 5-是否仍在战场, 6-可移动步数, 7-是否行动完毕, 8-贴图(未使用), 9-头上显示数字, 13-已获得经验, 14-是否自动战斗
inline TBattleRole Brole[200] = {};
inline int BRoleAmount = 0;          // 战场人物总数
inline int Bx = 0, By = 0, Ax = 0, Ay = 0;  // 当前人物坐标, 选择目标的坐标
inline int BattleResult = 0;         // 战斗状态: 0-继续, 1-胜利, 2-失败
inline int BattleRound = 0;

// 寻路
extern int16_t linex[480 * 480];
extern int16_t liney[480 * 480];
inline int nowstep = 0;
extern int PathCost[480][480];

// 物品列表
inline int16_t ItemList[501] = {};  // 物品显示使用的列表

// 扩展地面
extern int16_t ExGround[64][64];  // 用来使场景边缘的显示效果改善
inline int ImageWidth = 0, ImageHeight = 0;

// 手柄
inline uint32 JOY_RETURN = 0, JOY_ESCAPE = 0;
inline uint32 JOY_LEFT = 0, JOY_RIGHT = 0, JOY_UP = 0, JOY_DOWN = 0;
inline uint32 JOY_MOUSE_LEFT = 0, JOY_AXIS_DELAY = 0;

// 触控/手机
inline int CellPhone = 0;
inline int ScreenRotate = 0;
inline int FingerCount = 0;           // 双指操作计数
inline uint32 FingerTick = 0;         // 双指操作间隔
inline bool FreeWalking = false;
inline bool BattleSelecting = false;  // 是否处于战场上选择

// 虚拟按键（手机模式）
inline int ShowVirtualKey = 0;
inline uint32 VirtualKeyValue = 0;
//inline int VirtualKeyUState = 0, VirtualKeyDState = 0, VirtualKeyLState = 0, VirtualKeyRState = 0, VirtualKeyAState = 0, VirtualKeyBState = 0;    //0: 无按键, 1: 经过, 2: 按下
inline int VirtualCrossX = 150, VirtualCrossY = 250;
inline int VirtualKeySize = 60;
inline int VirtualAX = 0, VirtualAY = 0;
inline int VirtualBX = 0, VirtualBY = 0;
inline SDL_Surface* VirtualKeyU = nullptr;  // 虚拟按键图像
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

