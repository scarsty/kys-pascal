// kys_main.cpp - 游戏主流程实现
// 对应 kys_main.pas

#include "kys_main.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_event.h"
#include "kys_battle.h"
#include "kys_script.h"
#include "kys_type.h"
#include "simplecc.h"

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_mixer/SDL_mixer.h>

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
#include <sstream>

// ---- 额外全局变量 ----
int Where = 0;
int CurScene = 0, CurEvent = -1, CurItem = -1;
int Cx = 0, Cy = 0;
int Bx = 0, By = 0;
int Ax = 0, Ay = 0;
int SFace = 0;
int NowMusic = 0, StartMusic = 16;
int BRoleAmount = 0;
TBattleRole Brole[200];
int BattleResult = 0;
int MainMapStep = 0;
int BeginTime = 0, NowTime = 0;
int CellPhone = 0;
int ScreenRotate = 0;
int CHNFONT_SPACEWIDTH = 10;
int ImageWidth = 0, ImageHeight = 0;
int BATTLE_SPEED = 10, WALK_SPEED = 10, WALK_SPEED2 = 10;
int MMAPAMI = 1, SEMIREAL = 0;
int KDEF_SCRIPT = 1, NIGHT_EFFECT = 0, EXPAND_GROUND = 0;
int ShowVirtualKey = 0;
int VirtualCrossX = 100, VirtualCrossY = 250;
int VirtualAX = 0, VirtualAY = 0, VirtualBX = 0, VirtualBY = 0;
int RENDERER = 0;
int TouchWalk = 1;
double EXP_RATE = 1.0;
int SkipTalk = 0;
SDL_Surface* VirtualKeyU = nullptr;
SDL_Surface* VirtualKeyD = nullptr;
SDL_Surface* VirtualKeyL = nullptr;
SDL_Surface* VirtualKeyR = nullptr;
SDL_Surface* VirtualKeyA = nullptr;
SDL_Surface* VirtualKeyB = nullptr;
TPosition TitlePosition = {0, 0};
TPosition OpenPicPosition = {-1, -1};
TCloud cloud[CLOUD_AMOUNT];
smallint x50[30001]; // 扩展x50变量区
int Script5032Pos = -100;
int Script5032Value = 0;
SDL_Mutex* mutex = nullptr;

// ---- 实现 ----

void Run() {
#ifdef _WIN32
    SetConsoleOutputCP(65001);
#endif
    AppPath = "";
    ReadFiles();
    SetMODVersion();

    // 初始化 TTF
    TTF_Init();
    std::string fontPath = checkFileName(AppPath + CHINESE_FONT);
    ChineseFont = TTF_OpenFont(fontPath.c_str(), CHINESE_FONT_SIZE);
    fontPath = checkFileName(AppPath + ENGLISH_FONT);
    EnglishFont = TTF_OpenFont(fontPath.c_str(), ENGLISH_FONT_SIZE);

    // 测试空格宽度
    SDL_Color white = {255, 255, 255, 255};
    uint16_t space[2] = {32, 0};
    SDL_Surface* text = TTF_RenderText_Solid(ChineseFont, (const char*)space, 1, white);
    if (text) { CHNFONT_SPACEWIDTH = text->w; SDL_DestroySurface(text); }

    MIX_Init();

    // 初始化视频
    srand((unsigned)time(nullptr));
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Quit();
        return;
    }

    if (SMOOTH >= 2)
        SDL_SetHint("SDL_RENDER_SCALE_QUALITY", "1");
    else
        SDL_SetHint("SDL_RENDER_SCALE_QUALITY", "0");

    uint32_t screenFlag = SDL_WINDOW_RESIZABLE;
    window = SDL_CreateWindow(TitleString.c_str(), RESOLUTIONX, RESOLUTIONY, screenFlag);
    SDL_GetWindowSize(window, &RESOLUTIONX, &RESOLUTIONY);

    const char* render_str = "direct3d";
    if (RENDERER == 1) render_str = "opengl";
    if (RENDERER == 2) render_str = "software";

    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "direct3d,opengl,direct3d12,direct3d11");
    render = SDL_CreateRenderer(window, render_str);
    screen = SDL_CreateSurface(CENTER_X * 2, CENTER_Y * 2,
                               SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    screenTex = SDL_CreateTexture(render, SDL_PIXELFORMAT_ARGB8888,
                                  SDL_TEXTUREACCESS_STREAMING, CENTER_X * 2, CENTER_Y * 2);
    freshscreen = SDL_CreateSurface(CENTER_X * 2, CENTER_Y * 2,
                                    SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));

    ImageWidth = (36 * 32 + CENTER_X) * 2;
    ImageHeight = (18 * 32 + CENTER_Y) * 2;

    ImgScene = SDL_CreateSurface(ImageWidth, ImageHeight,
                                 SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    ImgSceneBack = SDL_CreateSurface(ImageWidth, ImageHeight,
                                     SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    ImgBField = SDL_CreateSurface(ImageWidth, ImageHeight,
                                  SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    ImgBBuild = SDL_CreateSurface(ImageWidth, ImageHeight,
                                  SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));

    BlockImg.resize(ImageWidth * ImageHeight, 0);
    BlockImg2.resize(ImageWidth * ImageHeight, 0);

    InitialScript();
    InitialMusic();

    SDL_AddEventWatch((SDL_EventFilter)EventFilter, nullptr);
    mutex = SDL_CreateMutex();
    SDL_AddTimer(200, UpdateSceneAmi, nullptr);

    Start();
    Quit();
}

void Quit() {
    for (auto& p : fonts) SDL_DestroySurface(p.second);
    fonts.clear();
    for (auto& p : FontsHr) SDL_DestroySurface(p.second);
    FontsHr.clear();
    FreeAllSurface();
    DestroyScript();
    if (ChineseFont) TTF_CloseFont(ChineseFont);
    if (EnglishFont) TTF_CloseFont(EnglishFont);
    TTF_Quit();
    if (mutex) SDL_DestroyMutex(mutex);
    SDL_Quit();
    MIX_Quit();
    exit(0);
}

void SetMODVersion() {
    Music.resize(200, nullptr);
    ESound.resize(300, nullptr);
    StartMusic = 16;
    TitleString = "All Heros in Kam Yung's Stories - Replicated Edition";
    OpenPicPosition = {-1, -1};
    TitlePosition.x = CENTER_X - 320 + 275;
    TitlePosition.y = CENTER_Y - 220 + 125;

    switch (MODVersion) {
        case 0: break;
        case 11:
            TitleString = "All Heros in Kam Yung's Stories - A Pig";
            TitlePosition.y = 270;
            CENTER_Y = 240;
            break;
        case 12:
            TitleString = "All Heros in Kam Yung's Stories - We Are Dragons";
            TitlePosition.x = 200;
            TitlePosition.y = 250;
            break;
        case 21:
            TitleString = "All Heros in Kam Yung's Stories - Books";
            TitlePosition.x = 275;
            TitlePosition.y = 285;
            break;
        case 22:
            TitleString = "Why I have to go after a pineapple in the period of Three Kingdoms??";
            MAX_ITEM_AMOUNT = 456;
            StartMusic = 37;
            CENTER_Y = 240;
            break;
        case 23:
            TitleString = "All Heros in Kam Yung's Stories - Four Dreams";
            TitlePosition.y = 165;
            StartMusic = 24;
            CENTER_Y = 240;
            break;
        case 31:
            TitleString = "All Heros in Kam Yung's Stories - Wider Rivers and Deeper Lakes";
            break;
        case 41:
            TitleString = "All Heros in Kam Yung's Stories - Here is PTT";
            TitlePosition.y = 255;
            CENTER_Y = 240;
            break;
        case 51:
            TitleString = "All Heros in Kam Yung's Stories - An Prime Minister of Tang";
            break;
        case 71:
            TitleString = "All Heros in Kam Yung's Stories - Books from Heaven";
            TitlePosition.x = 60;
            TitlePosition.y = 270;
            MAX_ITEM_AMOUNT = 400;
            break;
        case 72:
            TitleString = "All Heros in Kam Yung's Stories - Shake the World";
            MAX_ITEM_AMOUNT = 400;
            break;
        case 81:
            TitleString = "All Heros in Kam Yung's Stories - Awaking of Dragons";
            Music.resize(999, nullptr);
            TitlePosition.x = 200;
            TitlePosition.y = 250;
            break;
        case 91:
            TitleString = "All Heros in Kam Yung's Stories - What's Loving";
            break;
        default:
            TitlePosition.y = 270;
            break;
    }
}

void ReadFiles() {
    std::string filename = AppPath + "kysmod.ini";
    // 读取 INI 配置 - 使用简易解析
    FILE* f = fopen(filename.c_str(), "r");
    if (!f) return;

    char line[256];
    auto readInt = [&](const char* section, const char* key, int def) -> int {
        // 简化: 直接返回默认值, 实际应解析ini
        return def;
    };

    fclose(f);

    // 使用默认值
    ITEM_BEGIN_PIC = 3501;
    MAX_HEAD_NUM = 189;
    BEGIN_EVENT = 691;
    BEGIN_SCENE = 70;
    BEGIN_Sx = 20;
    BEGIN_Sy = 19;
    SOFTSTAR_BEGIN_TALK = 2547;
    SOFTSTAR_NUM_TALK = 18;
    MAX_PHYSICAL_POWER = 100;
    BEGIN_WALKPIC = 2501;
    MONEY_ID = 174;
    COMPASS_ID = 182;
    BEGIN_LEAVE_EVENT = 950;
    BEGIN_BATTLE_ROLE_PIC = 2553;
    MAX_LEVEL = 30;
    MAX_WEAPON_MATCH = 7;
    MIN_KNOWLEDGE = 80;
    MAX_HP = 999;
    MAX_MP = 999;
    LIFE_HURT = 10;
    POISON_HURT = 10;
    MED_LIFE = 4;
    NOVEL_BOOK = 144;
    MAX_ADD_PRO = 0;
    MAX_ITEM_AMOUNT = 200;
    BATTLE_SPEED = 10;
    WALK_SPEED = 10;
    WALK_SPEED2 = WALK_SPEED;
    SMOOTH = 1;
    HIRES_TEXT = 1;
    SIMPLE = 1;
    VOLUME = 30;
    VOLUMEWAV = 30;
    SOUND3D = 1;

    for (int i = 0; i < 16; i++) MaxProList[i] = 100;
    if (LIFE_HURT == 0) LIFE_HURT = 1;
    if (POISON_HURT == 0) POISON_HURT = 1;

    ReadFileToBuffer((char*)ACol, AppPath + "resource/mmap.col", 768, 0);
    memcpy(ACol1, ACol, 768);
    memcpy(ACol2, ACol, 768);

    ReadFileToBuffer((char*)Earth, AppPath + "resource/earth.002", 480 * 480 * 2, 0);
    ReadFileToBuffer((char*)Surface, AppPath + "resource/surface.002", 480 * 480 * 2, 0);
    ReadFileToBuffer((char*)Building, AppPath + "resource/building.002", 480 * 480 * 2, 0);
    ReadFileToBuffer((char*)BuildX, AppPath + "resource/buildy.002", 480 * 480 * 2, 0);
    ReadFileToBuffer((char*)BuildY, AppPath + "resource/buildx.002", 480 * 480 * 2, 0);

    ReadFileToBuffer((char*)LeaveList, AppPath + "list/leave.bin", 200, 0);
    ReadFileToBuffer((char*)EffectList, AppPath + "list/effect.bin", 400, 0);
    ReadFileToBuffer((char*)LevelUpList, AppPath + "list/levelup.bin", 200, 0);
    ReadFileToBuffer((char*)MatchList, AppPath + "list/match.bin", MAX_WEAPON_MATCH * 3 * 2, 0);

    HeadSurface.resize(999, nullptr);
    ItemSurface.resize(999, nullptr);

    ReadTiles();
}

// ---- 游戏开始画面 ----

void Start() {
    PlayMP3(StartMusic, -1);
    Where = 3;
    Redraw();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);

    BeginTime = rand() % 1440;
    NowTime = BeginTime;
    for (int i = 0; i < 480; i++)
        for (int j = 0; j < 480; j++)
            Entrance[i][j] = -1;

    MainMapStep = 0;
    FULLSCREEN = 0;
    for (int i = 0; i < CLOUD_AMOUNT; i++) CloudCreate(i);

    int x = TitlePosition.x, y = TitlePosition.y;
    int menu = 0;
    Redraw();
    DrawTitlePic(0, x, y);
    DrawTitlePic(menu + 1, x, y + menu * 20);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);

    bool selected = false;
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_KEY_UP:
                if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE)
                    selected = true;
                if (event.key.key == SDLK_UP) {
                    menu--;
                    if (menu < 0) menu = 2;
                    Redraw(); DrawTitlePic(0, x, y); DrawTitlePic(menu + 1, x, y + menu * 20);
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                }
                if (event.key.key == SDLK_DOWN) {
                    menu++;
                    if (menu > 2) menu = 0;
                    Redraw(); DrawTitlePic(0, x, y); DrawTitlePic(menu + 1, x, y + menu * 20);
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                }
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_LEFT) {
                    int mx = (int)(event.button.x / ((float)RESOLUTIONX / screen->w));
                    int my = (int)(event.button.y / ((float)RESOLUTIONY / screen->h));
                    if (mx > x && mx < x + 80 && my > y && my < y + 60) {
                        selected = true;
                        menu = (my - y) / 20;
                    }
                }
                break;
        }
        if (selected) {
            switch (menu) {
                case 2: return; // 退出
                case 1: // 读档
                    if (MenuLoadAtBeginning() >= 0) {
                        CurEvent = -1;
                        if (Where == 1) WalkInScene(0);
                        Walk();
                    }
                    break;
                case 0: // 新游戏
                    if (InitialRole()) {
                        CurScene = BEGIN_SCENE;
                        CurEvent = -1;
                        if (CurScene >= 0) WalkInScene(1);
                        else Where = 0;
                        Walk();
                    }
                    break;
            }
            Redraw();
            DrawTitlePic(0, x, y);
            DrawTitlePic(menu + 1, x, y + menu * 20);
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            selected = false;
        }
    }
}

bool InitialRole() {
    LoadR(0);
    Where = 3;
    Redraw();
    // 简化：使用默认名字
    std::string input_name = cp950toutf8(Rrole[0].Name);
    // ... 设置初始属性（随机）
    Rrole[0].MaxHP = 25 + rand() % 26;
    Rrole[0].CurrentHP = Rrole[0].MaxHP;
    Rrole[0].MaxMP = 25 + rand() % 26;
    Rrole[0].CurrentMP = Rrole[0].MaxMP;
    Rrole[0].MPType = rand() % 2;
    Rrole[0].IncLife = 1 + rand() % 10;
    Rrole[0].Attack = 25 + rand() % 6;
    Rrole[0].Speed = 25 + rand() % 6;
    Rrole[0].Defence = 25 + rand() % 6;
    Rrole[0].Medcine = 25 + rand() % 6;
    Rrole[0].UsePoi = 25 + rand() % 6;
    Rrole[0].MedPoi = 25 + rand() % 6;
    Rrole[0].Fist = 25 + rand() % 6;
    Rrole[0].Sword = 25 + rand() % 6;
    Rrole[0].Knife = 25 + rand() % 6;
    Rrole[0].Unusual = 25 + rand() % 6;
    Rrole[0].HidWeapon = 25 + rand() % 6;
    Rrole[0].Aptitude = 1 + rand() % 100;

    Redraw();
    ShowStatus(0);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    WaitAnyKey();
    return true;
}

// ---- 存读档 ----

void LoadR(int num) {
    char buf[64];
    snprintf(buf, sizeof(buf), "save/%d/", num);
    std::string path = AppPath + buf;

    ReadFileToBuffer((char*)&Rrole[0], path + "r.grp", sizeof(Rrole), 0);
    ReadFileToBuffer((char*)&Ritem[0], path + "i.grp", sizeof(Ritem), 0);
    ReadFileToBuffer((char*)&Rscene[0], path + "s.grp", sizeof(Rscene), 0);
    ReadFileToBuffer((char*)&Rmagic[0], path + "m.grp", sizeof(Rmagic), 0);
    ReadFileToBuffer((char*)&RShop[0], path + "shop.grp", sizeof(RShop), 0);

    FILE* f = fopen((path + "ranger.grp").c_str(), "rb");
    if (f) {
        fread(&InShip, 2, 1, f);
        fread(&SavedSceneIndex, 2, 1, f);
        fread(&Mx, 2, 1, f); fread(&My, 2, 1, f);
        fread(&Sx, 2, 1, f); fread(&Sy, 2, 1, f);
        fread(&MFace, 2, 1, f);
        fread(&ShipX, 2, 1, f); fread(&ShipY, 2, 1, f);
        fread(&ShipX1, 2, 1, f); fread(&ShipY1, 2, 1, f);
        fread(&ShipFace, 2, 1, f);
        fread(TeamList, 2, 6, f);
        fclose(f);
    }

    // 物品列表
    f = fopen((path + "item.grp").c_str(), "rb");
    if (f) {
        RItemList.resize(MAX_ITEM_AMOUNT);
        fread(RItemList.data(), sizeof(TItemList), MAX_ITEM_AMOUNT, f);
        fclose(f);
    }

    // 场景数据
    for (int i = 0; i < 401; i++) {
        snprintf(buf, sizeof(buf), "data/s%d.grp", i);
        std::string fname = path + buf;
        FILE* sf = fopen(fname.c_str(), "rb");
        if (sf) {
            fread(&SData[i][0][0][0], 2, 6 * 64 * 64, sf);
            fclose(sf);
        }
    }
    for (int i = 0; i < 401; i++) {
        snprintf(buf, sizeof(buf), "data/d%d.grp", i);
        std::string fname = path + buf;
        FILE* sf = fopen(fname.c_str(), "rb");
        if (sf) {
            fread(&DData[i][0][0], 2, 200 * 11, sf);
            fclose(sf);
        }
    }
}

void SaveR(int num) {
    char buf[64];
    snprintf(buf, sizeof(buf), "save/%d/", num);
    std::string path = AppPath + buf;

    // 创建目录
#ifdef _WIN32
    CreateDirectoryA(path.c_str(), nullptr);
#else
    mkdir(path.c_str(), 0755);
#endif

    FILE* f;
    f = fopen((path + "r.grp").c_str(), "wb");
    if (f) { fwrite(Rrole, sizeof(Rrole), 1, f); fclose(f); }
    f = fopen((path + "i.grp").c_str(), "wb");
    if (f) { fwrite(Ritem, sizeof(Ritem), 1, f); fclose(f); }
    f = fopen((path + "s.grp").c_str(), "wb");
    if (f) { fwrite(Rscene, sizeof(Rscene), 1, f); fclose(f); }
    f = fopen((path + "m.grp").c_str(), "wb");
    if (f) { fwrite(Rmagic, sizeof(Rmagic), 1, f); fclose(f); }
    f = fopen((path + "shop.grp").c_str(), "wb");
    if (f) { fwrite(RShop, sizeof(RShop), 1, f); fclose(f); }

    f = fopen((path + "ranger.grp").c_str(), "wb");
    if (f) {
        fwrite(&InShip, 2, 1, f); fwrite(&SavedSceneIndex, 2, 1, f);
        fwrite(&Mx, 2, 1, f); fwrite(&My, 2, 1, f);
        fwrite(&Sx, 2, 1, f); fwrite(&Sy, 2, 1, f);
        fwrite(&MFace, 2, 1, f);
        fwrite(&ShipX, 2, 1, f); fwrite(&ShipY, 2, 1, f);
        fwrite(&ShipX1, 2, 1, f); fwrite(&ShipY1, 2, 1, f);
        fwrite(&ShipFace, 2, 1, f);
        fwrite(TeamList, 2, 6, f);
        fclose(f);
    }

    f = fopen((path + "item.grp").c_str(), "wb");
    if (f) { fwrite(RItemList.data(), sizeof(TItemList), RItemList.size(), f); fclose(f); }
}

// ---- 等待按键 ----

int WaitAnyKey() {
    SDL_Event e;
    while (true) {
        while (SDL_PollEvent(&e)) {
            CheckBasicEvent();
            if (e.type == SDL_EVENT_KEY_UP) return e.key.key;
            if (e.type == SDL_EVENT_MOUSE_BUTTON_UP) {
                if (e.button.button == SDL_BUTTON_LEFT) return SDLK_RETURN;
                if (e.button.button == SDL_BUTTON_RIGHT) return SDLK_ESCAPE;
            }
        }
        SDL_Delay(10);
    }
}

// ---- 行走 ----

void Walk() {
    Where = 0;
    Redraw();
    UpdateAllScreen();

    while (true) {
        while (SDL_PollEvent(&event)) {
            CheckBasicEvent();
            if (event.type == SDL_EVENT_KEY_UP) {
                switch (event.key.key) {
                    case SDLK_UP:
                        Mx--; My--;
                        if (!CanWalk(Mx, My)) { Mx++; My++; }
                        break;
                    case SDLK_DOWN:
                        Mx++; My++;
                        if (!CanWalk(Mx, My)) { Mx--; My--; }
                        break;
                    case SDLK_LEFT:
                        Mx++; My--;
                        if (!CanWalk(Mx, My)) { Mx--; My++; }
                        break;
                    case SDLK_RIGHT:
                        Mx--; My++;
                        if (!CanWalk(Mx, My)) { Mx++; My--; }
                        break;
                    case SDLK_ESCAPE:
                        MenuEsc();
                        break;
                    case SDLK_RETURN:
                    case SDLK_SPACE:
                        if (CheckEntrance()) {
                            WalkInScene(1);
                        }
                        break;
                }
                if (Where == 0) { Redraw(); UpdateAllScreen(); }
                else return; // 进入场景
            }
        }
        SDL_Delay(10);
    }
}

bool CanWalk(int x, int y) {
    if (x < 0 || x >= 480 || y < 0 || y >= 480) return false;
    int bld = Building[x][y];
    if (bld > 0) return false;
    return true;
}

bool CheckEntrance() {
    for (int i = 0; i < SceneAmount; i++) {
        if (Rscene[i].MainEntranceX1 == Mx && Rscene[i].MainEntranceY1 == My) {
            CurScene = i;
            return true;
        }
        if (Rscene[i].MainEntranceX2 == Mx && Rscene[i].MainEntranceY2 == My) {
            CurScene = i;
            return true;
        }
    }
    return false;
}

bool CheckCanEnter(int snum) {
    if (snum < 0 || snum >= 201) return false;
    if (Rscene[snum].EnCondition == 0) return true;
    return (Rscene[snum].EnCondition == 2);
}

uint32_t UpdateSceneAmi(void* param, SDL_TimerID timerid, uint32_t interval) {
    if (Where == 1) UpdateScene();
    return interval;
}

int WalkInScene(int Open) {
    Where = 1;
    if (Open) {
        Sx = Rscene[CurScene].EntranceX;
        Sy = Rscene[CurScene].EntranceY;
    }
    Cx = Sx; Cy = Sy;
    InitialScene();
    PlayMP3(Rscene[CurScene].EntranceMusic, -1);
    Redraw();
    UpdateAllScreen();

    while (true) {
        while (SDL_PollEvent(&event)) {
            CheckBasicEvent();
            if (event.type == SDL_EVENT_KEY_UP) {
                int ox = Sx, oy = Sy;
                switch (event.key.key) {
                    case SDLK_UP: SFace = 0; Sx--; Sy--; break;
                    case SDLK_DOWN: SFace = 2; Sx++; Sy++; break;
                    case SDLK_LEFT: SFace = 3; Sx++; Sy--; break;
                    case SDLK_RIGHT: SFace = 1; Sx--; Sy++; break;
                    case SDLK_ESCAPE:
                        Where = 0;
                        PlayMP3(Rscene[CurScene].ExitMusic, -1);
                        return 0;
                    case SDLK_RETURN:
                    case SDLK_SPACE:
                        if (CheckEvent1()) continue;
                        break;
                }
                if (!CanWalkInScene(Sx, Sy)) { Sx = ox; Sy = oy; }
                Cx = Sx; Cy = Sy;
                Redraw();
                UpdateAllScreen();
                CheckEvent3();
                if (Where != 1) return 0;
            }
        }
        SDL_Delay(10);
    }
    return 0;
}

bool CanWalkInScene(int x, int y) {
    if (x < 0 || x >= 64 || y < 0 || y >= 64) return false;
    if (SData[CurScene][1][x][y] > 0) return false;
    if (SData[CurScene][2][x][y] > 0) return false;
    return true;
}

bool CanWalkInScene(int x1, int y1, int x, int y) {
    return CanWalkInScene(x, y);
}

bool CheckEvent1() {
    // 面向一格检测事件
    int tx = Sx, ty = Sy;
    switch (SFace) {
        case 0: tx--; ty--; break;
        case 1: tx--; ty++; break;
        case 2: tx++; ty++; break;
        case 3: tx++; ty--; break;
    }
    if (tx < 0 || tx >= 64 || ty < 0 || ty >= 64) return false;
    int eIdx = SData[CurScene][3][tx][ty];
    if (eIdx < 0 || eIdx >= 200) return false;
    int eventNum = DData[CurScene][eIdx][0]; // 事件触发号
    if (eventNum < 0) return false;
    CurEvent = eIdx;
    CallEvent(eventNum);
    return true;
}

void CheckEvent3() {
    // 踩到事件（自动触发）
    int eIdx = SData[CurScene][3][Sx][Sy];
    if (eIdx < 0 || eIdx >= 200) return;
    int eventNum = DData[CurScene][eIdx][1]; // 自动触发号
    if (eventNum < 0) return;
    CurEvent = eIdx;
    CallEvent(eventNum);
}

void FindWay(int x1, int y1) {
    // 寻路 - 移向目标
    Moveman(Sx, Sy, x1, y1);
}

void Moveman(int x1, int y1, int x2, int y2) {
    // 简单移动动画
    while (x1 != x2 || y1 != y2) {
        if (x1 < x2) { x1++; SFace = 2; }
        else if (x1 > x2) { x1--; SFace = 0; }
        if (y1 < y2) { y1++; SFace = 1; }
        else if (y1 > y2) { y1--; SFace = 3; }
        Sx = x1; Sy = y1; Cx = Sx; Cy = Sy;
        Redraw();
        UpdateAllScreen();
        SDL_Delay(50);
    }
}

void ShowSceneName(int snum) {
    if (snum < 0 || snum >= 201) return;
    std::string name = cp950toutf8(Rscene[snum].Name);
    DrawTextWithRect(name, CENTER_X - 50, 10, 100, ColColor(0x21), ColColor(0x23));
    UpdateAllScreen();
}

// ---- 菜单系统 ----

int CommonMenu(int x, int y, int w, int max, const std::string menuString[], int count) {
    return CommonMenu(x, y, w, max, 0, menuString);
}

int CommonMenu(int x, int y, int w, int max, int default_, const std::string menuString[], int count) {
    return CommonMenu(x, y, w, max, default_, menuString, nullptr);
}

int CommonMenu(int x, int y, int w, int max, int default_, const std::string menuString[], TPInt1 fn, int count) {
    int menu = default_;
    if (menu < 0) menu = 0;
    if (menu > max) menu = max;

    while (true) {
        RecordFreshScreen();
        DrawRectangle(screen, x, y, w, (max + 1) * 22 + 10, 0, ColColor(0xFF), 50);
        for (int i = 0; i <= max; i++) {
            uint32_t col1 = (i == menu) ? ColColor(0x64) : ColColor(0x05);
            uint32_t col2 = (i == menu) ? ColColor(0x66) : ColColor(0x07);
            DrawShadowText(screen, menuString[i], x + 5, y + 5 + i * 22, col1, col2);
        }
        UpdateScreen(screen, x, y, w + 1, (max + 1) * 22 + 11);
        if (fn) fn(menu);

        int key = WaitAnyKey();
        if (key == SDLK_UP) { menu--; if (menu < 0) menu = max; }
        if (key == SDLK_DOWN) { menu++; if (menu > max) menu = 0; }
        if (key == SDLK_RETURN || key == SDLK_SPACE) {
            LoadFreshScreen();
            return menu;
        }
        if (key == SDLK_ESCAPE) {
            LoadFreshScreen();
            return -1;
        }
    }
}

int CommonScrollMenu(int x, int y, int w, int max, int maxshow, const std::string menuString[]) {
    int menu = 0, top = 0;
    if (maxshow <= 0) maxshow = max + 1;

    while (true) {
        RecordFreshScreen();
        int showCount = std::min(max + 1, maxshow);
        DrawRectangle(screen, x, y, w, showCount * 22 + 10, 0, ColColor(0xFF), 50);
        for (int i = 0; i < showCount && (top + i) <= max; i++) {
            int idx = top + i;
            uint32_t col1 = (idx == menu) ? ColColor(0x64) : ColColor(0x05);
            uint32_t col2 = (idx == menu) ? ColColor(0x66) : ColColor(0x07);
            DrawShadowText(screen, menuString[idx], x + 5, y + 5 + i * 22, col1, col2);
        }
        UpdateScreen(screen, x, y, w + 1, showCount * 22 + 11);

        int key = WaitAnyKey();
        if (key == SDLK_UP) {
            menu--;
            if (menu < 0) menu = max;
            if (menu < top) top = menu;
            if (menu > top + maxshow - 1) top = menu - maxshow + 1;
        }
        if (key == SDLK_DOWN) {
            menu++;
            if (menu > max) menu = 0;
            if (menu < top) top = menu;
            if (menu > top + maxshow - 1) top = menu - maxshow + 1;
        }
        if (key == SDLK_RETURN || key == SDLK_SPACE) { LoadFreshScreen(); return menu; }
        if (key == SDLK_ESCAPE) { LoadFreshScreen(); return -1; }
    }
}

int CommonGridMenu(int x, int y, int cols, int cellW, int maxShowRows, int maxItem, const std::string menuString[]) {
    // 网格菜单 - 简化
    return CommonScrollMenu(x, y, cols * cellW, maxItem, maxShowRows, menuString);
}

int CommonMenu2(int x, int y, int w, const std::string menuString[]) {
    return CommonMenu(x, y, w, 1, 0, menuString);
}

int SelectOneTeamMember(int x, int y, const std::string& str, int list1, int list2) {
    std::vector<std::string> names;
    std::vector<int> indices;
    for (int i = 0; i < 6; i++) {
        if (TeamList[i] >= 0) {
            int rnum = TeamList[i];
            names.push_back(cp950toutf8(Rrole[rnum].Name));
            indices.push_back(rnum);
        }
    }
    if (names.empty()) return -1;
    int sel = CommonScrollMenu(x, y, 100, (int)names.size() - 1, 6, names.data());
    if (sel < 0) return -1;
    return indices[sel];
}

void MenuEsc() {
    std::string menuStr[] = {" 藥", " 毒", " 物", " 狀", " 離", " 系"};
    int menu = CommonMenu(CENTER_X - 50, CENTER_Y - 80, 60, 5, menuStr);
    switch (menu) {
        case 0: MenuMedcine(); break;
        case 1: MenuMedPoison(); break;
        case 2: MenuItem(); break;
        case 3: MenuStatus(); break;
        case 4: MenuLeave(); break;
        case 5: MenuSystem(); break;
    }
    Redraw();
    UpdateAllScreen();
}

void ShowMenu(int menu) {}
void MenuMedcine() {}
void MenuMedPoison() {}
bool MenuItem() { return false; }
int ReadItemList(int ItemType) { return 0; }
void DrawItemFrame(int x, int y) {}
void UseItem(int inum) {}
bool CanEquip(int rnum, int inum) { return false; }

void MenuStatus() {
    for (int i = 0; i < 6; i++) {
        if (TeamList[i] >= 0) {
            ShowStatus(TeamList[i]);
            WaitAnyKey();
        }
    }
}

void ShowStatusByTeam(int tnum) {
    if (tnum < 0 || tnum >= 6) return;
    if (TeamList[tnum] >= 0)
        ShowStatus(TeamList[tnum]);
}

void ShowStatus(int rnum) {
    ShowStatus(rnum, CENTER_X - 270, CENTER_Y - 155);
}

void ShowStatus(int rnum, int x, int y) {
    Redraw();
    DrawRectangle(screen, x, y, 540, 310, 0, ColColor(0xFF), 50);
    std::string name = cp950toutf8(Rrole[rnum].Name);
    DrawShadowText(screen, name, x + 10, y + 10, ColColor(0x21), ColColor(0x23));

    char buf[128];
    auto drawProp = [&](const char* label, int val, int row) {
        DrawShadowText(screen, label, x + 10, y + 35 + row * 22, ColColor(0x21), ColColor(0x23));
        snprintf(buf, sizeof(buf), "%d", val);
        DrawEngShadowText(screen, buf, x + 110, y + 35 + row * 22, ColColor(0x64), ColColor(0x66));
    };

    drawProp(" 等級", Rrole[rnum].Level, 0);
    drawProp(" 體力", Rrole[rnum].CurrentHP, 1);
    drawProp(" 內力", Rrole[rnum].CurrentMP, 2);
    drawProp(" 攻擊", Rrole[rnum].Attack, 3);
    drawProp(" 防禦", Rrole[rnum].Defence, 4);
    drawProp(" 輕功", Rrole[rnum].Speed, 5);
    drawProp(" 醫術", Rrole[rnum].Medcine, 6);
    drawProp(" 用毒", Rrole[rnum].UsePoi, 7);
    drawProp(" 解毒", Rrole[rnum].MedPoi, 8);

    DrawHeadPic(Rrole[rnum].HeadNum, x + 400, y + 10);
    UpdateScreen(screen, x, y, 541, 311);
}

void ShowSimpleStatus(int rnum, int x, int y) {
    ShowStatus(rnum, x, y);
}

void MenuLeave() {}
int MenuSystem() {
    std::string menuStr[] = {" 存檔", " 讀檔", " 退出"};
    int sel = CommonMenu(CENTER_X - 40, CENTER_Y - 40, 80, 2, menuStr);
    switch (sel) {
        case 0: MenuSave(); break;
        case 1: MenuLoad(); break;
        case 2: MenuQuit(); break;
    }
    return sel;
}

void MenuLoad() {
    std::string menuStr[10];
    for (int i = 0; i < 10; i++) {
        char buf[32]; snprintf(buf, sizeof(buf), " 進度 %d", i);
        menuStr[i] = buf;
    }
    int sel = CommonMenu(CENTER_X - 50, CENTER_Y - 120, 100, 9, menuStr);
    if (sel >= 0) LoadR(sel);
}

int MenuLoadAtBeginning() {
    std::string menuStr[10];
    for (int i = 0; i < 10; i++) {
        char buf[32]; snprintf(buf, sizeof(buf), " 進度 %d", i);
        menuStr[i] = buf;
    }
    int sel = CommonMenu(CENTER_X - 50, CENTER_Y - 120, 100, 9, menuStr);
    if (sel >= 0) LoadR(sel);
    return sel;
}

void MenuSave() {
    std::string menuStr[10];
    for (int i = 0; i < 10; i++) {
        char buf[32]; snprintf(buf, sizeof(buf), " 進度 %d", i);
        menuStr[i] = buf;
    }
    int sel = CommonMenu(CENTER_X - 50, CENTER_Y - 120, 100, 9, menuStr);
    if (sel >= 0) SaveR(sel);
}

void MenuQuit() {
    Quit();
}

// ---- 使用物品效果 ----

int EffectMedcine(int role1, int role2) {
    int heal = Rrole[role1].Medcine * MED_LIFE;
    Rrole[role2].CurrentHP += heal;
    if (Rrole[role2].CurrentHP > Rrole[role2].MaxHP)
        Rrole[role2].CurrentHP = Rrole[role2].MaxHP;
    return heal;
}

int EffectMedPoison(int role1, int role2) {
    int cure = Rrole[role1].MedPoi;
    Rrole[role2].Poison -= cure;
    if (Rrole[role2].Poison < 0) Rrole[role2].Poison = 0;
    return cure;
}

int EatOneItem(int rnum, int inum, int times, int display) {
    if (inum < 0 || inum >= 725) return 0;
    TItem& item = Ritem[inum];
    TRole& role = Rrole[rnum];
    role.CurrentHP += item.AddCurrentHP * times;
    if (role.CurrentHP > role.MaxHP) role.CurrentHP = role.MaxHP;
    role.MaxHP += item.AddMaxHP * times;
    role.CurrentMP += item.AddCurrentMP * times;
    if (role.CurrentMP > role.MaxMP) role.CurrentMP = role.MaxMP;
    role.MaxMP += item.AddMaxMP * times;
    role.Attack += item.AddAttack * times;
    role.Speed += item.AddSpeed * times;
    role.Defence += item.AddDefence * times;
    role.Medcine += item.AddMedcine * times;
    role.UsePoi += item.AddUsePoi * times;
    role.MedPoi += item.AddMedPoi * times;
    return 1;
}

// ---- 事件调用 ----

void CallEvent(int num) {
    if (KDEF_SCRIPT == 1) {
        // 尝试lua脚本
        char buf[128];
        snprintf(buf, sizeof(buf), "script/%d.lua", num);
        std::string scriptFile = AppPath + buf;
        FILE* f = fopen(scriptFile.c_str(), "rb");
        if (f) {
            fclose(f);
            char funcname[32];
            snprintf(funcname, sizeof(funcname), "f%d", num);
            ExecScript(scriptFile, funcname);
            return;
        }
    }
    // kdef二进制指令
    if (num < 0 || num >= (int)KIdx.size()) return;
    int offset = (num == 0) ? 0 : KIdx[num - 1];
    int len = KIdx[num] - offset;
    if (len <= 0) return;
    const int16_t* code = (const int16_t*)(KDef.data() + offset);
    int count = len / 2;
    int pos = 0;
    while (pos < count) {
        int inst = code[pos++];
        // 读取最多12个参数
        int p[12] = {};
        int nparams = 0;
        if (inst == 50) nparams = 7;
        else if (inst <= 67) nparams = std::min(12, count - pos);

        // 简化：跳过复杂指令分发
        // 实际应交由 kys_event 中的 instruct_N 处理
        break;
    }
}

// ---- 云 ----

void CloudCreate(int num) {
    if (num < 0 || num >= CLOUD_AMOUNT) return;
    cloud[num].Picnum = rand() % std::max(1, CPicAmount);
    cloud[num].Shadow = 0;
    cloud[num].Alpha = 20 + rand() % 30;
    cloud[num].Positionx = rand() % (CENTER_X * 2);
    cloud[num].Positiony = rand() % (CENTER_Y * 2);
    cloud[num].Speedx = 1 + rand() % 3;
    cloud[num].Speedy = 0;
}

void CloudCreateOnSide(int num) {
    CloudCreate(num);
    cloud[num].Positionx = -100;
}

bool IsCave(int snum) {
    return false;
}

int teleport() { return 0; }
int TeleportByList() { return 0; }

// EnterString (from event system, moved here for accessibility)
bool EnterString(std::string& str, int x, int y, int w, int h) {
    SDL_Rect r = {x, y, w, h};
    SDL_StartTextInput(window);
    SDL_SetTextInputArea(window, &r, 0);
    int tick = 0;
    while (true) {
        tick++;
        Redraw();
        std::string display = str;
        if ((tick / 16) % 2 == 0) display += "_";
        DrawTextWithRect(display, x, y, w, ColColor(0x66), ColColor(0x63));
        SDL_PollEvent(&event);
        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_TEXT_INPUT:
                str += event.text.text;
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_RIGHT) { SDL_StopTextInput(window); return false; }
                break;
            case SDL_EVENT_KEY_UP:
                if (event.key.key == SDLK_RETURN) { SDL_StopTextInput(window); return true; }
                if (event.key.key == SDLK_ESCAPE) { SDL_StopTextInput(window); return false; }
                if (event.key.key == SDLK_BACKSPACE) {
                    int l = (int)str.size();
                    if (l >= 3 && (uint8_t)str[l - 1] >= 128) str.resize(l - 3);
                    else if (l >= 1) str.resize(l - 1);
                }
                break;
        }
        SDL_Delay(16);
    }
}

// instruct_32 辅助 (直接增减物品)
void instruct_32(int itemnum, int amount) {
    if (amount > 0) {
        for (auto& il : RItemList) {
            if (il.Number == itemnum) { il.Amount += amount; return; }
        }
        for (auto& il : RItemList) {
            if (il.Number < 0) { il.Number = itemnum; il.Amount = amount; return; }
        }
    } else {
        for (auto& il : RItemList) {
            if (il.Number == itemnum) {
                il.Amount += amount;
                if (il.Amount <= 0) { il.Number = -1; il.Amount = 0; }
                return;
            }
        }
    }
}
