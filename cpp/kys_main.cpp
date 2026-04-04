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

// ---- 简易INI解析 ----

static int readIniInt(const std::string& filename, const std::string& section, const std::string& key, int def) {
    FILE* f = fopen(filename.c_str(), "r");
    if (!f) return def;
    char line[512];
    bool inSection = false;
    std::string sec = "[" + section + "]";
    while (fgets(line, sizeof(line), f)) {
        std::string s = line;
        while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' ')) s.pop_back();
        if (s == sec) { inSection = true; continue; }
        if (!s.empty() && s[0] == '[') { inSection = false; continue; }
        if (inSection) {
            auto eq = s.find('=');
            if (eq != std::string::npos) {
                std::string k = s.substr(0, eq);
                while (!k.empty() && k.back() == ' ') k.pop_back();
                if (k == key) { fclose(f); return atoi(s.c_str() + eq + 1); }
            }
        }
    }
    fclose(f);
    return def;
}

static double readIniFloat(const std::string& filename, const std::string& section, const std::string& key, double def) {
    FILE* f = fopen(filename.c_str(), "r");
    if (!f) return def;
    char line[512];
    bool inSection = false;
    std::string sec = "[" + section + "]";
    while (fgets(line, sizeof(line), f)) {
        std::string s = line;
        while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' ')) s.pop_back();
        if (s == sec) { inSection = true; continue; }
        if (!s.empty() && s[0] == '[') { inSection = false; continue; }
        if (inSection) {
            auto eq = s.find('=');
            if (eq != std::string::npos) {
                std::string k = s.substr(0, eq);
                while (!k.empty() && k.back() == ' ') k.pop_back();
                if (k == key) { fclose(f); return atof(s.c_str() + eq + 1); }
            }
        }
    }
    fclose(f);
    return def;
}

static int signof(int x) { return (x > 0) ? 1 : (x < 0) ? -1 : 0; }


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

    // INI解析
    ITEM_BEGIN_PIC = readIniInt(filename, "constant", "ITEM_BEGIN_PIC", 3501);
    MAX_HEAD_NUM = readIniInt(filename, "constant", "MAX_HEAD_NUM", 189);
    BEGIN_EVENT = readIniInt(filename, "constant", "BEGIN_EVENT", 691);
    BEGIN_SCENE = readIniInt(filename, "constant", "BEGIN_SCENE", 70);
    BEGIN_Sx = readIniInt(filename, "constant", "BEGIN_Sx", 20);
    BEGIN_Sy = readIniInt(filename, "constant", "BEGIN_Sy", 19);
    SOFTSTAR_BEGIN_TALK = readIniInt(filename, "constant", "SOFTSTAR_BEGIN_TALK", 2547);
    SOFTSTAR_NUM_TALK = readIniInt(filename, "constant", "SOFTSTAR_NUM_TALK", 18);
    MAX_PHYSICAL_POWER = readIniInt(filename, "constant", "MAX_PHYSICAL_POWER", 100);
    BEGIN_WALKPIC = readIniInt(filename, "constant", "BEGIN_WALKPIC", 2501);
    MONEY_ID = readIniInt(filename, "constant", "MONEY_ID", 174);
    COMPASS_ID = readIniInt(filename, "constant", "COMPASS_ID", 182);
    BEGIN_LEAVE_EVENT = readIniInt(filename, "constant", "BEGIN_LEAVE_EVENT", 950);
    BEGIN_BATTLE_ROLE_PIC = readIniInt(filename, "constant", "BEGIN_BATTLE_ROLE_PIC", 2553);
    MAX_LEVEL = readIniInt(filename, "constant", "MAX_LEVEL", 30);
    MAX_WEAPON_MATCH = readIniInt(filename, "constant", "MAX_WEAPON_MATCH", 7);
    MIN_KNOWLEDGE = readIniInt(filename, "constant", "MIN_KNOWLEDGE", 80);
    MAX_HP = readIniInt(filename, "constant", "MAX_HP", 999);
    MAX_MP = readIniInt(filename, "constant", "MAX_MP", 999);
    LIFE_HURT = readIniInt(filename, "constant", "LIFE_HURT", 10);
    POISON_HURT = readIniInt(filename, "constant", "POISON_HURT", 10);
    MED_LIFE = readIniInt(filename, "constant", "MED_LIFE", 4);
    NOVEL_BOOK = readIniInt(filename, "constant", "NOVEL_BOOK", 144);
    MAX_ADD_PRO = readIniInt(filename, "constant", "MAX_ADD_PRO", 0);
    MAX_ITEM_AMOUNT = readIniInt(filename, "constant", "MAX_ITEM_AMOUNT", 200);

    BATTLE_SPEED = readIniInt(filename, "system", "BATTLE_SPEED", 10);
    WALK_SPEED = readIniInt(filename, "system", "WALK_SPEED", 10);
    WALK_SPEED2 = readIniInt(filename, "system", "WALK_SPEED2", WALK_SPEED);
    SMOOTH = readIniInt(filename, "system", "SMOOTH", 1);
    HIRES_TEXT = readIniInt(filename, "system", "HIRES_TEXT", 1);
    SIMPLE = readIniInt(filename, "system", "SIMPLE", 1);
    VOLUME = readIniInt(filename, "music", "VOLUME", 30);
    VOLUMEWAV = readIniInt(filename, "music", "VOLUMEWAV", 30);
    SOUND3D = readIniInt(filename, "music", "SOUND3D", 1);
    MMAPAMI = readIniInt(filename, "system", "MMAPAMI", 1);
    SEMIREAL = readIniInt(filename, "system", "SEMIREAL", 0);
    MODVersion = readIniInt(filename, "system", "MODVersion", 0);
    CHINESE_FONT_SIZE = readIniInt(filename, "system", "CHINESE_FONT_SIZE", 20);
    ENGLISH_FONT_SIZE = readIniInt(filename, "system", "ENGLISH_FONT_SIZE", 19);
    KDEF_SCRIPT = readIniInt(filename, "system", "KDEF_SCRIPT", 1);
    NIGHT_EFFECT = readIniInt(filename, "system", "NIGHT_EFFECT", 0);
    EXPAND_GROUND = readIniInt(filename, "system", "EXPAND_GROUND", 0);
    WMP_4_PIC = readIniInt(filename, "system", "WMP_4_PIC", 0);
    TouchWalk = readIniInt(filename, "system", "TOUCH_WALK", 1);
    RENDERER = readIniInt(filename, "system", "RENDERER", 0);
    EXP_RATE = readIniFloat(filename, "system", "EXP_RATE", 1.0);

    if (CellPhone != 0) {
        ShowVirtualKey = readIniInt(filename, "system", "VirtualKey", 1);
        VirtualCrossX = readIniInt(filename, "system", "VirtualCrossX", 100);
        VirtualCrossY = readIniInt(filename, "system", "VirtualCrossY", 250);
        int w = CENTER_X * 2, h = CENTER_Y * 2;
        VirtualAX = readIniInt(filename, "system", "VirtualAX", w - 200);
        VirtualAY = readIniInt(filename, "system", "VirtualAY", h - 100);
        VirtualBX = readIniInt(filename, "system", "VirtualBX", w - 100);
        VirtualBY = readIniInt(filename, "system", "VirtualBY", h - 200);
    } else {
        ShowVirtualKey = 0;
        TouchWalk = 1;
    }

    char keybuf[32];
    for (int i = 0; i < 16; i++) {
        snprintf(keybuf, sizeof(keybuf), "MaxProList%d", 43 + i);
        MaxProList[i] = readIniInt(filename, "constant", keybuf, 100);
    }
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

void MenuMedcine() {
    std::string str = " 隊員醫療能力";
    DrawTextWithRect(screen, str, 80, 30, 132, ColColor(0x21), ColColor(0x23));
    int menu = SelectOneTeamMember(80, 65, "%4d", 46, 0);
    if (menu >= 0) {
        int role1 = menu;
        str = " 隊員目前生命";
        DrawTextWithRect(screen, str, 230, 30, 132, ColColor(0x21), ColColor(0x23));
        int menu2 = SelectOneTeamMember(230, 65, "%4d/%4d", 17, 18);
        if (menu2 >= 0) EffectMedcine(role1, menu2);
    }
}

void MenuMedPoison() {
    std::string str = " 隊員解毒能力";
    DrawTextWithRect(screen, str, 80, 30, 132, ColColor(0x21), ColColor(0x23));
    int menu = SelectOneTeamMember(80, 65, "%4d", 48, 0);
    if (menu >= 0) {
        int role1 = menu;
        str = " 隊員中毒程度";
        DrawTextWithRect(screen, str, 230, 30, 132, ColColor(0x21), ColColor(0x23));
        int menu2 = SelectOneTeamMember(230, 65, "%4d", 20, 0);
        if (menu2 >= 0) EffectMedPoison(role1, menu2);
    }
}

bool MenuItem() {
    std::string menuStr[] = {" 全部", " 劇情", " 神兵", " 秘笈", " 藥品", " 暗器", " 整理"};
    int typeMap[] = {100, 0, 1, 2, 3, 4};
    int sel = CommonMenu(CENTER_X - 60, CENTER_Y - 80, 60, 6, menuStr);
    if (sel < 0) return false;
    if (sel == 6) { ReArrangeItem(1); return true; }
    int itemType = typeMap[sel];
    int count = ReadItemList(itemType);
    if (count == 0) return false;
    std::string itemNames[501];
    for (int i = 0; i < count; i++) {
        if (ItemList[i] < 0) { itemNames[i] = ""; continue; }
        int inum = RItemList[ItemList[i]].Number;
        std::string name = cp950toutf8(Ritem[inum].Name);
        char buf[32]; snprintf(buf, sizeof(buf), " x%d", RItemList[ItemList[i]].Amount);
        itemNames[i] = name + buf;
    }
    int idx = CommonScrollMenu(CENTER_X - 120, CENTER_Y - 120, 240, count - 1, 15, itemNames);
    if (idx >= 0 && ItemList[idx] >= 0) {
        UseItem(RItemList[ItemList[idx]].Number);
    }
    return true;
}

int ReadItemList(int ItemType) {
    int p = 0;
    for (int i = 0; i < 501; i++) ItemList[i] = -1;
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++) {
        if (RItemList[i].Number >= 0) {
            if (Ritem[RItemList[i].Number].ItemType == ItemType || ItemType == 100) {
                ItemList[p] = i;
                p++;
            }
        }
    }
    return p;
}

void DrawItemFrame(int x, int y) {
    int xp = 110, yp = 60, d = 42;
    for (int i = 0; i < 40; i++) {
        uint8_t t = 250 - i * 3;
        uint32_t c = SDL_MapSurfaceRGB(screen, t, t, t);
        PutPixel(screen, x * d + 6 + i + xp, y * d + 36 + yp, c);
        PutPixel(screen, x * d + 6 + 39 - i + xp, y * d + 36 + 39 + yp, c);
        PutPixel(screen, x * d + 6 + xp, y * d + 36 + i + yp, c);
        PutPixel(screen, x * d + 6 + 39 + xp, y * d + 36 + 39 - i + yp, c);
    }
}

void UseItem(int inum) {
    CurItem = inum;
    Redraw();
    switch (Ritem[inum].ItemType) {
        case 0: { // 剧情物品
            if (Ritem[inum].UnKnow7 > 0) {
                CallEvent(Ritem[inum].UnKnow7);
            } else if (Where == 1) {
                int x = Sx, y = Sy;
                switch (SFace) {
                    case 0: x--; break; case 1: y++; break;
                    case 2: x++; break; case 3: y--; break;
                }
                if (SData[CurScene][3][x][y] >= 0) {
                    CurEvent = SData[CurScene][3][x][y];
                    if (DData[CurScene][CurEvent][3] >= 0) {
                        Cx = Sx; Cy = Sy;
                        CallEvent(DData[CurScene][CurEvent][3]);
                    }
                }
                CurEvent = -1;
            }
            break;
        }
        case 1: { // 装备
            int menu = 1;
            if (Ritem[inum].User >= 0) {
                Redraw();
                std::string ms[] = {" 取消", " 繼續"};
                std::string str = " 此物品正有人裝備，是否繼續？";
                DrawTextWithRect(screen, str, 80, 30, 285, ColColor(5), ColColor(7));
                menu = CommonMenu(80, 65, 45, 1, ms);
            }
            if (menu == 1) {
                Redraw();
                std::string str1 = cp950toutf8(Ritem[inum].Name);
                DrawTextWithRect(screen, " 誰要裝備", 80, 30, (int)str1.size() * 11 + 80, ColColor(0x21), ColColor(0x23));
                DrawShadowText(screen, str1, 160, 32, ColColor(0x64), ColColor(0x66));
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
                int sel = SelectOneTeamMember(80, 65, "", 0, 0);
                if (sel >= 0) {
                    int rnum = sel;
                    int p = Ritem[inum].EquipType;
                    if (p < 0 || p > 1) p = 0;
                    if (CanEquip(rnum, inum)) {
                        if (Ritem[inum].User >= 0) Rrole[Ritem[inum].User].Equip[p] = -1;
                        if (Rrole[rnum].Equip[p] >= 0) Ritem[Rrole[rnum].Equip[p]].User = -1;
                        Rrole[rnum].Equip[p] = inum;
                        Ritem[inum].User = rnum;
                    } else {
                        DrawTextWithRect(screen, " 此人不適合裝備此物品", 80, 230, 205, ColColor(0x64), ColColor(0x66));
                        WaitAnyKey(); Redraw();
                    }
                }
            }
            break;
        }
        case 2: { // 秘笈
            int menu = 1;
            if (Ritem[inum].User >= 0) {
                Redraw();
                std::string ms[] = {" 取消", " 繼續"};
                DrawTextWithRect(screen, " 此秘笈正有人修煉，是否繼續？", 80, 30, 285, ColColor(5), ColColor(7));
                menu = CommonMenu(80, 65, 45, 1, ms);
            }
            if (menu == 1) {
                Redraw();
                std::string str1 = cp950toutf8(Ritem[inum].Name);
                DrawTextWithRect(screen, " 誰要修煉", 80, 30, (int)str1.size() * 11 + 80, ColColor(0x21), ColColor(0x23));
                DrawShadowText(screen, str1, 160, 32, ColColor(0x64), ColColor(0x66));
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
                int sel = SelectOneTeamMember(80, 65, "", 0, 0);
                if (sel >= 0) {
                    int rnum = sel;
                    if (CanEquip(rnum, inum)) {
                        if (Ritem[inum].User >= 0) Rrole[Ritem[inum].User].PracticeBook = -1;
                        if (Rrole[rnum].PracticeBook >= 0) Ritem[Rrole[rnum].PracticeBook].User = -1;
                        Rrole[rnum].PracticeBook = inum;
                        Ritem[inum].User = rnum;
                    } else {
                        DrawTextWithRect(screen, " 此人不適合修煉此秘笈", 80, 230, 205, ColColor(0x64), ColColor(0x66));
                        WaitAnyKey(); Redraw();
                    }
                }
            }
            break;
        }
        case 3: { // 药品
            int sel = -1;
            if (Where != 2) {
                std::string str1 = cp950toutf8(Ritem[inum].Name);
                DrawTextWithRect(screen, " 誰要服用", 80, 30, (int)str1.size() * 11 + 80, ColColor(0x21), ColColor(0x23));
                DrawShadowText(screen, str1, 160, 32, ColColor(0x64), ColColor(0x66));
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
                sel = SelectOneTeamMember(80, 65, "", 0, 0);
            }
            if (sel >= 0) {
                Redraw();
                EatOneItem(sel, inum);
                instruct_32(inum, -1);
                WaitAnyKey();
            }
            break;
        }
        case 4: break; // 暗器
    }
}

bool CanEquip(int rnum, int inum) {
    bool result = true;
    if (signof(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP) result = false;
    if (signof(Ritem[inum].NeedAttack) * Rrole[rnum].Attack < Ritem[inum].NeedAttack) result = false;
    if (signof(Ritem[inum].NeedSpeed) * Rrole[rnum].Speed < Ritem[inum].NeedSpeed) result = false;
    if (signof(Ritem[inum].NeedUsePoi) * Rrole[rnum].UsePoi < Ritem[inum].NeedUsePoi) result = false;
    if (signof(Ritem[inum].NeedMedcine) * Rrole[rnum].Medcine < Ritem[inum].NeedMedcine) result = false;
    if (signof(Ritem[inum].NeedMedPoi) * Rrole[rnum].MedPoi < Ritem[inum].NeedMedPoi) result = false;
    if (signof(Ritem[inum].NeedFist) * Rrole[rnum].Fist < Ritem[inum].NeedFist) result = false;
    if (signof(Ritem[inum].NeedSword) * Rrole[rnum].Sword < Ritem[inum].NeedSword) result = false;
    if (signof(Ritem[inum].NeedKnife) * Rrole[rnum].Knife < Ritem[inum].NeedKnife) result = false;
    if (signof(Ritem[inum].NeedUnusual) * Rrole[rnum].Unusual < Ritem[inum].NeedUnusual) result = false;
    if (signof(Ritem[inum].NeedHidWeapon) * Rrole[rnum].HidWeapon < Ritem[inum].NeedHidWeapon) result = false;
    if (signof(Ritem[inum].NeedAptitude) * Rrole[rnum].Aptitude < Ritem[inum].NeedAptitude) result = false;
    // 内力性质
    if (Rrole[rnum].MPType < 2 && Ritem[inum].NeedMPType < 2)
        if (Rrole[rnum].MPType != Ritem[inum].NeedMPType) result = false;
    // 专用人物
    if (Ritem[inum].OnlyPracRole >= 0 && result)
        result = (Ritem[inum].OnlyPracRole == rnum);
    // 武功槽满
    int r = 0;
    for (int i = 0; i < 10; i++) if (Rrole[rnum].Magic[i] > 0) r++;
    if (r >= 10 && Ritem[inum].Magic > 0) result = false;
    // 已有该武功且未满级
    for (int i = 0; i < 10; i++)
        if (Rrole[rnum].Magic[i] == Ritem[inum].Magic && Rrole[rnum].MagLevel[i] < 900)
            { result = true; break; }
    // 自宫确认
    if ((inum == 78 || inum == 93) && result && Rrole[rnum].Sexual != 2) {
        Redraw();
        std::string ms[] = {" 取消", " 繼續"};
        DrawTextWithRect(screen, " 是否自宮？", 80, 30, 105, ColColor(7), ColColor(5));
        if (CommonMenu(80, 65, 45, 1, ms) == 1)
            Rrole[rnum].Sexual = 2;
        else result = false;
    }
    return result;
}

void MenuLeave() {
    if (Where == 0 || MODVersion == 22) {
        std::string str = (MODVersion == 22) ? " 選擇一個隊友" : " 要求誰離隊？";
        DrawTextWithRect(screen, str, 80, 30, 132, ColColor(0x21), ColColor(0x23));
        int menu = SelectOneTeamMember(80, 65, "%3d", 15, 0);
        if (menu >= 0) {
            for (int i = 0; i < 6; i++) {
                if (TeamList[i] == menu) {
                    for (int j = 0; j < 100; j++) {
                        if (LeaveList[j] == TeamList[i]) {
                            Redraw();
                            CallEvent(BEGIN_LEAVE_EVENT + j * 2);
                            UpdateScreen(screen, 0, 0, screen->w, screen->h);
                            break;
                        }
                    }
                    break;
                }
            }
        }
    } else {
        DrawTextWithRect(screen, " 子場景不可離隊！", 80, 30, 172, ColColor(0x21), ColColor(0x23));
        WaitAnyKey();
    }
    Redraw();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
}

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
    SStep = 0;
    SceneRolePic = BEGIN_WALKPIC + SFace * 7;
    NeedRefreshScene = 0;

    // 优先尝试lua脚本
    char buf[128];
    snprintf(buf, sizeof(buf), "script/event/ka%d.lua", num);
    std::string scriptFile = AppPath + buf;
    if (KDEF_SCRIPT != 0) {
        FILE* tf = fopen(scriptFile.c_str(), "rb");
        if (tf) { fclose(tf); ExecScript(scriptFile, ""); goto event_end; }
    }

    // kdef二进制指令分发
    {
        int offset, len;
        if (num == 0) { offset = 0; len = KIdx[0]; }
        else { offset = KIdx[num - 1]; len = KIdx[num] - offset; }
        int ecount = len / 2 + 1;
        std::vector<int16_t> e(ecount, 0);
        if (len > 0) memcpy(e.data(), KDef.data() + offset, len);
        int i = 0;

        while (i < ecount - 1) {
            SDL_PollEvent(&event);
            CheckBasicEvent();
            if (e[i] < 0) break;
            switch (e[i]) {
                case 0:  instruct_0(); i += 1; break;
                case 1:  instruct_1(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 2:  instruct_2(e[i+1], e[i+2]); i += 3; break;
                case 3:  { int list[13]; for(int j=0;j<13;j++) list[j]=e[i+1+j]; instruct_3(list); i += 14; break; }
                case 4:  i += instruct_4(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 5:  i += instruct_5(e[i+1], e[i+2]); i += 3; break;
                case 6:  i += instruct_6(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 7:  i += 1; goto event_end;
                case 8:  instruct_8(e[i+1]); i += 2; break;
                case 9:  i += instruct_9(e[i+1], e[i+2]); i += 3; break;
                case 10: instruct_10(e[i+1]); i += 2; break;
                case 11: i += instruct_11(e[i+1], e[i+2]); i += 3; break;
                case 12: instruct_12(); i += 1; break;
                case 13: instruct_13(); i += 1; break;
                case 14: instruct_14(); i += 1; break;
                case 15: instruct_15(); i += 1; goto event_end;
                case 16: i += instruct_16(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 17: { int list[5]; for(int j=0;j<5;j++) list[j]=e[i+1+j]; instruct_17(list); i += 6; break; }
                case 18: i += instruct_18(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 19: instruct_19(e[i+1], e[i+2]); i += 3; break;
                case 20: i += instruct_20(e[i+1], e[i+2]); i += 3; break;
                case 21: instruct_21(e[i+1]); i += 2; break;
                case 22: instruct_22(); i += 1; break;
                case 23: instruct_23(e[i+1], e[i+2]); i += 3; break;
                case 24: instruct_24(); i += 1; break;
                case 25: instruct_25(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 26: instruct_26(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5]); i += 6; break;
                case 27: instruct_27(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 28: i += instruct_28(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5]); i += 6; break;
                case 29: i += instruct_29(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5]); i += 6; break;
                case 30: instruct_30(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 31: i += instruct_31(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 32: instruct_32(e[i+1], e[i+2]); i += 3; break;
                case 33: instruct_33(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 34: instruct_34(e[i+1], e[i+2]); i += 3; break;
                case 35: instruct_35(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 36: i += instruct_36(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 37: instruct_37(e[i+1]); i += 2; break;
                case 38: instruct_38(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 39: instruct_39(e[i+1]); i += 2; break;
                case 40: instruct_40(e[i+1]); i += 2; break;
                case 41: instruct_41(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 42: i += instruct_42(e[i+1], e[i+2]); i += 3; break;
                case 43: i += instruct_43(e[i+1], e[i+2], e[i+3]); i += 4; break;
                case 44: instruct_44(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5], e[i+6]); i += 7; break;
                case 45: instruct_45(e[i+1], e[i+2]); i += 3; break;
                case 46: instruct_46(e[i+1], e[i+2]); i += 3; break;
                case 47: instruct_47(e[i+1], e[i+2]); i += 3; break;
                case 48: instruct_48(e[i+1], e[i+2]); i += 3; break;
                case 49: instruct_49(e[i+1], e[i+2]); i += 3; break;
                case 50: {
                    int list[7]; for(int j=0;j<7;j++) list[j]=e[i+1+j];
                    int p = instruct_50(list);
                    i += 8;
                    if (p < 622592) i += p;
                    else e[i + ((p + 32768) / 655360) - 1] = p % 655360;
                    break;
                }
                case 51: instruct_51(); i += 1; break;
                case 52: instruct_52(); i += 1; break;
                case 53: instruct_53(); i += 1; break;
                case 54: instruct_54(); i += 1; break;
                case 55: i += instruct_55(e[i+1], e[i+2], e[i+3], e[i+4]); i += 5; break;
                case 56: instruct_56(e[i+1]); i += 2; break;
                case 57: instruct_57(); i += 1; break;
                case 58: instruct_58(); i += 1; break;
                case 59: instruct_59(); i += 1; break;
                case 60: i += instruct_60(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5]); i += 6; break;
                case 61: i += instruct_61(e[i+1], e[i+2]); i += 3; break;
                case 62: instruct_62(e[i+1], e[i+2], e[i+3], e[i+4], e[i+5], e[i+6]); i += 7; goto event_end;
                case 63: instruct_63(e[i+1], e[i+2]); i += 3; break;
                case 64: instruct_64(); i += 1; break;
                case 65: i += 1; break; // NOP
                case 66: instruct_66(e[i+1]); i += 2; break;
                case 67: instruct_67(e[i+1]); i += 2; break;
                default: i += 1; break;
            }
        }
    }

event_end:
    if (NeedRefreshScene == 1) InitialScene(0);
    NeedRefreshScene = 1;
    if (MMAPAMI * SCENEAMI == 0) {
        Redraw();
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
    }
}

// ---- 云 ----

void CloudCreate(int num) {
    if (num < 0 || num >= CLOUD_AMOUNT) return;
    if ((int)Cloud.size() <= num) Cloud.resize(num + 1);
    Cloud[num].Picnum = rand() % std::max(1, CPicAmount);
    Cloud[num].Shadow = 0;
    Cloud[num].Alpha = 20 + rand() % 30;
    Cloud[num].Positionx = rand() % (CENTER_X * 2);
    Cloud[num].Positiony = rand() % (CENTER_Y * 2);
    Cloud[num].Speedx = 1 + rand() % 3;
    Cloud[num].Speedy = 0;
}

void CloudCreateOnSide(int num) {
    CloudCreate(num);
    if (num >= 0 && num < (int)Cloud.size())
        Cloud[num].Positionx = -100;
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

// instruct_32 定义在 kys_event.cpp 中
