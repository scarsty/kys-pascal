// kys_type.cpp - 全局变量定义
// 对应 kys_type.pas implementation

#include "kys_type.h"
#include <cstring>

int MODVersion = 0;
std::string TitleString = "All Heros in Kam Yung's Stories";
std::string VersionStr = "";

const char* CHINESE_FONT = "chinese.ttf";
int CHINESE_FONT_SIZE = 20;
const char* ENGLISH_FONT = "english.ttf";
int ENGLISH_FONT_SIZE = 20;

int CENTER_X = 0;
int CENTER_Y = 0;

std::string AppPath, AppPathCommon;

int ITEM_BEGIN_PIC = 0;
int BEGIN_EVENT = 0;
int BEGIN_SCENE = 0;
int BEGIN_Sx = 0;
int BEGIN_Sy = 0;
int SOFTSTAR_BEGIN_TALK = 0;
int SOFTSTAR_NUM_TALK = 0;
int MAX_PHYSICAL_POWER = 100;
int MONEY_ID = 174;
int COMPASS_ID = 182;
int BEGIN_LEAVE_EVENT = 0;
int BEGIN_BATTLE_ROLE_PIC = 2553;
int MAX_LEVEL = 30;
int MAX_WEAPON_MATCH = 100;
int MIN_KNOWLEDGE = 1;
int MAX_ITEM_AMOUNT = 99;
int MAX_HP = 999;
int MAX_MP = 999;
int MaxProList[16] = {0};
int LIFE_HURT = 5;
int POISON_HURT = 5;
int MED_LIFE = 3;
int MAX_ADD_PRO = 0;
int NOVEL_BOOK = 144;
int MAX_HEAD_NUM = 0;
int BEGIN_WALKPIC = 0;

uint8_t ACol[769] = {0};
uint8_t ACol1[769] = {0};
uint8_t ACol2[769] = {0};

smallint Earth[480][480] = {{}};
smallint Surface[480][480] = {{}};
smallint Building[480][480] = {{}};
smallint BuildX[480][480] = {{}};
smallint BuildY[480][480] = {{}};
smallint Entrance[480][480] = {{}};

smallint InShip = 0, SavedSceneIndex = 0, Mx = 0, My = 0, Sx = 0, Sy = 0, MFace = 0;
smallint ShipX = 0, ShipY = 0, ShipX1 = 0, ShipY1 = 0, ShipFace = 0;
smallint TeamList[6] = {0};
std::vector<TItemList> RItemList;
TRole Rrole[2032] = {};
TItem Ritem[725] = {};
TScene Rscene[201] = {};
TMagic Rmagic[999] = {};
TShop RShop[11] = {};
int SceneAmount = 0;

smallint SData[401][6][64][64] = {};
smallint DData[401][200][11] = {};

smallint BField[8][64][64] = {};
TWarData WarSta = {};

smallint LeaveList[100] = {};
smallint EffectList[200] = {};
smallint LevelUpList[100] = {};
smallint MatchList[100][3] = {};

int BIG_PNG_TILE = 0;
int FULLSCREEN = 0;
int RESOLUTIONX = 320;
int RESOLUTIONY = 240;
int SIMPLE = 0;
int SMOOTH = 0;
int HIRES_TEXT = 0;
int WMP_4_PIC = 0;

SDL_Event event = {};
TTF_Font* ChineseFont = nullptr;
TTF_Font* EnglishFont = nullptr;

uint32 ScreenFlag = 0;
SDL_Surface* screen = nullptr;
SDL_Surface* freshscreen = nullptr;
SDL_Window* window = nullptr;
SDL_Renderer* render = nullptr;
SDL_Texture* screenTex = nullptr;
SDL_Texture* compositeTex = nullptr;

SDL_Surface* ImgScene = nullptr;
SDL_Surface* ImgSceneBack = nullptr;
SDL_Surface* ImgBField = nullptr;
SDL_Surface* ImgBBuild = nullptr;
std::vector<smallint> BlockImg;
std::vector<smallint> BlockImg2;
TPosition BlockScreen;

int MPicAmount = 0, SPicAmount = 0, BPicAmount = 0, EPicAmount = 0, CPicAmount = 0, FPicAmount = 0, HPicAmount = 0;

std::vector<uint8_t> MPic, SPic, WPic, EPic, HPic, CPic, KDef, TDef;
std::vector<int> MIdx, SIdx, WIdx, EIdx, HIdx, CIdx, KIdx, TIdx;

std::vector<uint8_t> FPic[1000];
std::vector<int> FIdx[1000];

std::vector<SDL_Surface*> MPNGTile, SPNGTile, BPNGTile, EPNGTile, CPNGTile, TitlePNGTile;
std::vector<SDL_Surface*> FPNGTile[1000];

SDL_Surface* MSurface = nullptr;
SDL_Surface* SSurface = nullptr;
std::vector<SDL_Surface*> HeadSurface;
std::vector<SDL_Surface*> BHead;
std::vector<SDL_Surface*> ItemSurface;

std::map<int, SDL_Surface*> fonts;
std::map<int, SDL_Surface*> FontsHr;

int VOLUME = 32, VOLUMEWAV = 32, SOUND3D = 0;
std::vector<MIX_Audio> Music;
std::vector<MIX_Audio> ESound;
std::vector<MIX_Audio> ASound;

int StartMusic = 0;
int ExitSceneMusicNum = 0;
int NowMusic = 0;

smallint x50[0x8000] = {0};
int KDEF_SCRIPT = 0;
struct lua_State* lua_script = nullptr;
int Script5032Pos = 0;
int Script5032Value = 0;

int SceneRolePic = 0;
int NeedRefreshScene = 0;

int CLOUD_AMOUNT = 50;
std::vector<TCloud> Cloud;

int WALK_SPEED = 4, WALK_SPEED2 = 8, BATTLE_SPEED = 1;
int MMAPAMI = 0;
int SCENEAMI = 0;
int SEMIREAL = 0;
int NIGHT_EFFECT = 0;
int EXIT_GAME = 0;

TPosition TitlePosition = {};
TPosition OpenPicPosition = {};

SDL_Mutex* mutex = nullptr;
uint32 ChangeColorList[2][21] = {};
bool AskingQuit = false;
int BeginTime = 0;
double NowTime = 0;
bool LoadingScene = false;

int MainMapStep = 0, MainMapStill = 0;
int Cx = 0, Cy = 0, SFace = 0, SStep = 0;
int CurScene = 0, CurEvent = 0, CurItem = 0, CurrentBattle = 0, Where = 0;
int SaveNum = 0;
TBattleRole Brole[100] = {};
int BRoleAmount = 0;
int Bx = 0, By = 0, Ax = 0, Ay = 0;
int BattleResult = 0;

smallint linex[480 * 480] = {0};
smallint liney[480 * 480] = {0};
int nowstep = 0;
int PathCost[480][480] = {};

smallint ItemList[501] = {0};

int EXPAND_GROUND = 0;
smallint ExGround[192][192] = {};
smallint ImageWidth = 0, ImageHeight = 0;
int BattleRound = 0;

int CHNFONT_SPACEWIDTH = 0;

uint32 JOY_RETURN = 0, JOY_ESCAPE = 0, JOY_LEFT = 0, JOY_RIGHT = 0, JOY_UP = 0, JOY_DOWN = 0, JOY_MOUSE_LEFT = 0;
uint32 JOY_AXIS_DELAY = 0;

int CellPhone = 0;
int ScreenRotate = 0;

int FingerCount = 0;
uint32 FingerTick = 0;
bool FreeWalking = false;
bool BattleSelecting = false;

SDL_Surface* VirtualKeyU = nullptr;
SDL_Surface* VirtualKeyD = nullptr;
SDL_Surface* VirtualKeyL = nullptr;
SDL_Surface* VirtualKeyR = nullptr;
SDL_Surface* VirtualKeyA = nullptr;
SDL_Surface* VirtualKeyB = nullptr;
int ShowVirtualKey = 0;
uint32 VirtualKeyValue = 0;
int VirtualCrossX = 0, VirtualCrossY = 0, VirtualKeySize = 0;
int VirtualAX = 0, VirtualAY = 0, VirtualBX = 0, VirtualBY = 0;

int SkipTalk = 0;
uint64_t tttt = 0;

void* cct2s = nullptr;
void* ccs2t = nullptr;

double EXP_RATE = 1.0;
bool TouchWalk = false;
int RENDERER = 0;
