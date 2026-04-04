// kys_main.cpp - 游戏主流程实现
// 对应 kys_main.pas

#include "kys_main.h"
#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_event.h"
#include "kys_battle.h"
#include "kys_script.h"
#include "kys_type.h"
#include "INIReader.h"
#include "filefunc.h"

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_mixer/SDL_mixer.h>

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <string>
#include <vector>
#include <algorithm>

#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#endif

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
    INIReaderNormal ini;
    ini.loadFile(filename);

    ITEM_BEGIN_PIC = ini.getInt("constant", "ITEM_BEGIN_PIC", 3501);
    MAX_HEAD_NUM = ini.getInt("constant", "MAX_HEAD_NUM", 189);
    BEGIN_EVENT = ini.getInt("constant", "BEGIN_EVENT", 691);
    BEGIN_SCENE = ini.getInt("constant", "BEGIN_SCENE", 70);
    BEGIN_Sx = ini.getInt("constant", "BEGIN_Sx", 20);
    BEGIN_Sy = ini.getInt("constant", "BEGIN_Sy", 19);
    SOFTSTAR_BEGIN_TALK = ini.getInt("constant", "SOFTSTAR_BEGIN_TALK", 2547);
    SOFTSTAR_NUM_TALK = ini.getInt("constant", "SOFTSTAR_NUM_TALK", 18);
    MAX_PHYSICAL_POWER = ini.getInt("constant", "MAX_PHYSICAL_POWER", 100);
    BEGIN_WALKPIC = ini.getInt("constant", "BEGIN_WALKPIC", 2501);
    MONEY_ID = ini.getInt("constant", "MONEY_ID", 174);
    COMPASS_ID = ini.getInt("constant", "COMPASS_ID", 182);
    BEGIN_LEAVE_EVENT = ini.getInt("constant", "BEGIN_LEAVE_EVENT", 950);
    BEGIN_BATTLE_ROLE_PIC = ini.getInt("constant", "BEGIN_BATTLE_ROLE_PIC", 2553);
    MAX_LEVEL = ini.getInt("constant", "MAX_LEVEL", 30);
    MAX_WEAPON_MATCH = ini.getInt("constant", "MAX_WEAPON_MATCH", 7);
    MIN_KNOWLEDGE = ini.getInt("constant", "MIN_KNOWLEDGE", 80);
    MAX_HP = ini.getInt("constant", "MAX_HP", 999);
    MAX_MP = ini.getInt("constant", "MAX_MP", 999);
    LIFE_HURT = ini.getInt("constant", "LIFE_HURT", 10);
    POISON_HURT = ini.getInt("constant", "POISON_HURT", 10);
    MED_LIFE = ini.getInt("constant", "MED_LIFE", 4);
    NOVEL_BOOK = ini.getInt("constant", "NOVEL_BOOK", 144);
    MAX_ADD_PRO = ini.getInt("constant", "MAX_ADD_PRO", 0);
    MAX_ITEM_AMOUNT = ini.getInt("constant", "MAX_ITEM_AMOUNT", 200);

    BATTLE_SPEED = ini.getInt("system", "BATTLE_SPEED", 10);
    WALK_SPEED = ini.getInt("system", "WALK_SPEED", 10);
    WALK_SPEED2 = ini.getInt("system", "WALK_SPEED2", WALK_SPEED);
    SMOOTH = ini.getInt("system", "SMOOTH", 1);
    HIRES_TEXT = ini.getInt("system", "HIRES_TEXT", 1);
    SIMPLE = ini.getInt("system", "SIMPLE", 1);
    VOLUME = ini.getInt("music", "VOLUME", 30);
    VOLUMEWAV = ini.getInt("music", "VOLUMEWAV", 30);
    SOUND3D = ini.getInt("music", "SOUND3D", 1);
    MMAPAMI = ini.getInt("system", "MMAPAMI", 1);
    SEMIREAL = ini.getInt("system", "SEMIREAL", 0);
    MODVersion = ini.getInt("system", "MODVersion", 0);
    CHINESE_FONT_SIZE = ini.getInt("system", "CHINESE_FONT_SIZE", 20);
    ENGLISH_FONT_SIZE = ini.getInt("system", "ENGLISH_FONT_SIZE", 19);
    KDEF_SCRIPT = ini.getInt("system", "KDEF_SCRIPT", 1);
    NIGHT_EFFECT = ini.getInt("system", "NIGHT_EFFECT", 0);
    EXPAND_GROUND = ini.getInt("system", "EXPAND_GROUND", 0);
    WMP_4_PIC = ini.getInt("system", "WMP_4_PIC", 0);
    TouchWalk = ini.getInt("system", "TOUCH_WALK", 1);
    RENDERER = ini.getInt("system", "RENDERER", 0);
    EXP_RATE = ini.getReal("system", "EXP_RATE", 1.0);

    if (CellPhone != 0) {
        ShowVirtualKey = ini.getInt("system", "VirtualKey", 1);
        VirtualCrossX = ini.getInt("system", "VirtualCrossX", 100);
        VirtualCrossY = ini.getInt("system", "VirtualCrossY", 250);
        int w = CENTER_X * 2, h = CENTER_Y * 2;
        VirtualAX = ini.getInt("system", "VirtualAX", w - 200);
        VirtualAY = ini.getInt("system", "VirtualAY", h - 100);
        VirtualBX = ini.getInt("system", "VirtualBX", w - 100);
        VirtualBY = ini.getInt("system", "VirtualBY", h - 200);
    } else {
        ShowVirtualKey = 0;
        TouchWalk = 1;
    }

    char keybuf[32];
    for (int i = 0; i < 16; i++) {
        snprintf(keybuf, sizeof(keybuf), "MaxProList%d", 43 + i);
        MaxProList[i] = ini.getInt("constant", keybuf, 100);
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
            case SDL_EVENT_MOUSE_MOTION: {
                int mx = (int)(event.motion.x / ((float)RESOLUTIONX / screen->w));
                int my = (int)(event.motion.y / ((float)RESOLUTIONY / screen->h));
                if (mx > x && mx < x + 80 && my > y && my < y + 60) {
                    int menup = menu;
                    menu = (my - y) / 20;
                    if (menu != menup) {
                        DrawTitlePic(0, x, y);
                        DrawTitlePic(menu + 1, x, y + menu * 20);
                        UpdateScreen(screen, 0, 0, screen->w, screen->h);
                    }
                }
                break;
            }
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

// 严格按Pascal版: 输入姓名 + 随机属性 + 显示状态
bool InitialRole() {
    LoadR(0);
    Where = 3;
    Redraw();

    // 输入姓名
    std::string str1 = "請輸入主角之姓名";
    DrawTextWithRect(str1, CENTER_X - 83, CENTER_Y - 30, 166, ColColor(0x21), ColColor(0x23));

    std::string input_name = cp950toutf8(Rrole[0].Name);
    bool named = EnterString(input_name, CENTER_X - 43, CENTER_Y + 10, 86, 100);

    if (named) {
        if (input_name.empty())
            input_name = cp950toutf8(Rrole[0].Name);

        input_name = Simplified2Traditional(input_name);
        std::string cp950name = utf8tocp950(input_name);

        std::string homename = "主角的家";
        if (cp950name.size() >= 1 && cp950name.size() <= 7 && input_name != " ") {
            homename = input_name + "居";
        }
        std::string cp950home = utf8tocp950(homename);

        // 设置角色名
        memset(&Rrole[0].Data[4], 0, 5 * sizeof(int16_t));
        memcpy(Rrole[0].Name, cp950name.c_str(),
               std::min(cp950name.size(), (size_t)9));

        // 设置家名 (BEGIN_SCENE)
        if (MODVersion != 22 && MODVersion != 11 && MODVersion != 12 && MODVersion != 91) {
            memset(&Rscene[BEGIN_SCENE].Data[1], 0, 5 * sizeof(int16_t));
            memcpy(Rscene[BEGIN_SCENE].Name, cp950home.c_str(),
                   std::min(cp950home.size(), (size_t)9));
        }

        Redraw();
        std::string str = "資質";

        int key = 0;
        do {
            if (MODVersion != 21) {
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
            }
            Rrole[0].Aptitude = 1 + rand() % 100;

            if (MODVersion == 0) {
                Rrole[0].Magic[0] = 1;
                if (rand() % 100 < 70) Rrole[0].Magic[0] = rand() % 93;
            }
            if (MODVersion == 31) Rrole[0].Ethics = rand() % 50 + rand() % 50;
            if (MODVersion == 41) Rrole[0].Magic[0] = 0;

            Redraw();
            ShowStatus(0);
            DrawShadowText(screen, str, CENTER_X - 273 + 10, CENTER_Y + 111, ColColor(0x21), ColColor(0x23));
            char buf[32]; snprintf(buf, sizeof(buf), "%4d", Rrole[0].Aptitude);
            DrawEngShadowText(screen, buf, CENTER_X - 273 + 110, CENTER_Y + 111, ColColor(0x64), ColColor(0x66));
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            key = WaitAnyKey();
        } while (key != SDLK_ESCAPE && key != SDLK_RETURN);

        ShowStatus(0);
        DrawShadowText(screen, str, 30, CENTER_Y + 111, ColColor(0x23), ColColor(0x21));
        char buf[32]; snprintf(buf, sizeof(buf), "%4d", Rrole[0].Aptitude);
        DrawEngShadowText(screen, buf, 150, CENTER_Y + 111, ColColor(0x66), ColColor(0x63));
        UpdateScreen(screen, 0, 0, screen->w, screen->h);

        StartAmi();
    }
    return named;
}

// ---- 存读档 ----
// 严格按照Pascal版: 使用save/ranger.idx获取偏移, save/r<num>.grp单文件格式

void LoadR(int num) {
    SaveNum = num;
    std::string filename = (num == 0) ? "ranger" : ("r" + std::to_string(num));

    std::string idxpath = AppPath + "save/ranger.idx";
    std::string grppath = AppPath + "save/" + filename + ".grp";

    FILE* idx = fopen(idxpath.c_str(), "rb");
    FILE* grp = fopen(grppath.c_str(), "rb");
    if (!idx || !grp) {
        if (idx) fclose(idx);
        if (grp) fclose(grp);
        return;
    }

    int RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, length;
    fread(&RoleOffset, 4, 1, idx);
    fread(&ItemOffset, 4, 1, idx);
    fread(&SceneOffset, 4, 1, idx);
    fread(&MagicOffset, 4, 1, idx);
    fread(&WeiShopOffset, 4, 1, idx);
    fread(&length, 4, 1, idx);
    fclose(idx);

    fseek(grp, 0, SEEK_SET);

    // 读取主角位置和状态
    fread(&InShip, 2, 1, grp);
    fread(&SavedSceneIndex, 2, 1, grp);
    fread(&My, 2, 1, grp);
    fread(&Mx, 2, 1, grp);
    fread(&Sy, 2, 1, grp);
    fread(&Sx, 2, 1, grp);
    fread(&MFace, 2, 1, grp);
    fread(&ShipX, 2, 1, grp);
    fread(&ShipY, 2, 1, grp);
    fread(&ShipX1, 2, 1, grp);
    fread(&ShipY1, 2, 1, grp);
    fread(&ShipFace, 2, 1, grp);
    fread(TeamList, 2, 6, grp);

    // 物品列表
    RItemList.resize(MAX_ITEM_AMOUNT);
    for (int i = 0; i < MAX_ITEM_AMOUNT; i++) {
        RItemList[i].Number = -1;
        RItemList[i].Amount = 0;
    }
    fread(RItemList.data(), sizeof(TItemList), MAX_ITEM_AMOUNT, grp);

    // 读取游戏数据
    fread(&Rrole[0], 1, ItemOffset - RoleOffset, grp);
    fread(&Ritem[0], 1, SceneOffset - ItemOffset, grp);
    fread(&Rscene[0], 1, MagicOffset - SceneOffset, grp);
    fread(&Rmagic[0], 1, WeiShopOffset - MagicOffset, grp);
    fread(&RShop[0], 1, length - WeiShopOffset, grp);
    fclose(grp);

    // 初始化世界地图入口
    SceneAmount = (MagicOffset - SceneOffset) / sizeof(TScene);
    for (int i = 0; i < 480; i++)
        for (int j = 0; j < 480; j++)
            Entrance[i][j] = -1;

    for (int i = 0; i < SceneAmount; i++) {
        if (Rscene[i].MainEntranceX1 >= 0 && Rscene[i].MainEntranceX1 < 480 &&
            Rscene[i].MainEntranceY1 >= 0 && Rscene[i].MainEntranceY1 < 480)
            Entrance[Rscene[i].MainEntranceX1][Rscene[i].MainEntranceY1] = i;
        if (Rscene[i].MainEntranceX2 >= 0 && Rscene[i].MainEntranceX2 < 480 &&
            Rscene[i].MainEntranceY2 >= 0 && Rscene[i].MainEntranceY2 < 480)
            Entrance[Rscene[i].MainEntranceX2][Rscene[i].MainEntranceY2] = i;
    }

    // 恢复游戏状态
    if (SavedSceneIndex > 0) {
        CurScene = SavedSceneIndex - 1;
        Where = 1;
    } else {
        CurScene = -1;
        Where = 0;
    }

    // 读取场景地形数据
    std::string sfilename = (num == 0) ? "allsin" : ("s" + std::to_string(num));
    grp = fopen((AppPath + "save/" + sfilename + ".grp").c_str(), "rb");
    if (grp) {
        fread(&SData[0][0][0][0], 2, SceneAmount * 64 * 64 * 6, grp);
        fclose(grp);
    }

    // 读取NPC/对象数据
    std::string dfilename = (num == 0) ? "alldef" : ("d" + std::to_string(num));
    grp = fopen((AppPath + "save/" + dfilename + ".grp").c_str(), "rb");
    if (grp) {
        fread(&DData[0][0][0], 2, SceneAmount * 200 * 11, grp);
        fclose(grp);
    }
}

void SaveR(int num) {
    SaveNum = num;
    std::string filename = (num == 0) ? "ranger" : ("r" + std::to_string(num));

    std::string idxpath = AppPath + "save/ranger.idx";
    FILE* idx = fopen(idxpath.c_str(), "rb");
    if (!idx) return;

    int RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, length;
    fread(&RoleOffset, 4, 1, idx);
    fread(&ItemOffset, 4, 1, idx);
    fread(&SceneOffset, 4, 1, idx);
    fread(&MagicOffset, 4, 1, idx);
    fread(&WeiShopOffset, 4, 1, idx);
    fread(&length, 4, 1, idx);
    fclose(idx);

    std::string grppath = AppPath + "save/" + filename + ".grp";
    FILE* grp = fopen(grppath.c_str(), "wb");
    if (!grp) return;

    // 写入主角位置和状态
    fwrite(&InShip, 2, 1, grp);

    int16_t savedIdx = 0;
    if (Where == 1)
        savedIdx = (int16_t)(CurScene + 1);
    else
        savedIdx = 0;
    fwrite(&savedIdx, 2, 1, grp);
    fwrite(&My, 2, 1, grp);
    fwrite(&Mx, 2, 1, grp);
    fwrite(&Sy, 2, 1, grp);
    fwrite(&Sx, 2, 1, grp);
    fwrite(&MFace, 2, 1, grp);
    fwrite(&ShipX, 2, 1, grp);
    fwrite(&ShipY, 2, 1, grp);
    fwrite(&ShipX1, 2, 1, grp);
    fwrite(&ShipY1, 2, 1, grp);
    fwrite(&ShipFace, 2, 1, grp);
    fwrite(TeamList, 2, 6, grp);

    // 物品列表
    fwrite(RItemList.data(), sizeof(TItemList), MAX_ITEM_AMOUNT, grp);

    // 写入游戏数据
    fwrite(&Rrole[0], 1, ItemOffset - RoleOffset, grp);
    fwrite(&Ritem[0], 1, SceneOffset - ItemOffset, grp);
    fwrite(&Rscene[0], 1, MagicOffset - SceneOffset, grp);
    fwrite(&Rmagic[0], 1, WeiShopOffset - MagicOffset, grp);
    fwrite(&RShop[0], 1, length - WeiShopOffset, grp);
    fclose(grp);

    // 保存场景地形数据
    int sceneAmt = (MagicOffset - SceneOffset) / (int)sizeof(TScene);
    std::string sfilename = (num == 0) ? "allsin" : ("s" + std::to_string(num));
    grp = fopen((AppPath + "save/" + sfilename + ".grp").c_str(), "wb");
    if (grp) {
        fwrite(&SData[0][0][0][0], 2, sceneAmt * 64 * 64 * 6, grp);
        fclose(grp);
    }

    // 保存NPC/对象数据
    std::string dfilename = (num == 0) ? "alldef" : ("d" + std::to_string(num));
    grp = fopen((AppPath + "save/" + dfilename + ".grp").c_str(), "wb");
    if (grp) {
        fwrite(&DData[0][0][0], 2, sceneAmt * 200 * 11, grp);
        fclose(grp);
    }
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

// ---- 行走（严格按Pascal版: 连续按键+速度加速+动画+鼠标寻路） ----

void Walk() {
    if (Where >= 3) return;

    uint32_t next_time = SDL_GetTicks();
    uint32_t next_time2 = SDL_GetTicks();
    uint32_t next_time3 = SDL_GetTicks();

    Where = 0;
    int walking = 0;
    int Speed = 0;
    int gotoEntrance = -1;
    DrawMMap();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    MainMapStill = 0;
    MainMapStillcount = 0;

    while (true) {
        SDL_PollEvent(&event);
        if (Where >= 3) break;

        uint32_t now = SDL_GetTicks();

        // 每200ms换色
        if ((int)(now - next_time2) > 0) {
            ChangeCol();
            next_time2 = now + 200;
        }
        // 每40ms云动画
        if ((int)(now - next_time3) > 0 && MMAPAMI > 0) {
            for (int i = 0; i < CLOUD_AMOUNT && i < (int)Cloud.size(); i++) {
                Cloud[i].Positionx += Cloud[i].Speedx;
                Cloud[i].Positiony += Cloud[i].Speedy;
                if (Cloud[i].Positionx > 17279 || Cloud[i].Positionx < 0 ||
                    Cloud[i].Positiony > 8639 || Cloud[i].Positiony < 0)
                    CloudCreateOnSide(i);
            }
            next_time3 = now + 40;
        }
        // 每320ms步伐动画
        if ((int)(now - next_time) > 0 && Where == 0) {
            if (walking == 0)
                MainMapStillcount++;
            else
                MainMapStillcount = 0;
            if (MainMapStillcount >= 10) {
                MainMapStill = 1;
                MainMapStep++;
                if (MainMapStep > 6) MainMapStep = 1;
            }
            next_time = now + 320;
        }

        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_KEY_DOWN:
                if (event.key.key == SDLK_LEFT)  { MFace = 2; walking = 1; }
                if (event.key.key == SDLK_RIGHT) { MFace = 1; walking = 1; }
                if (event.key.key == SDLK_UP)    { MFace = 0; walking = 1; }
                if (event.key.key == SDLK_DOWN)  { MFace = 3; walking = 1; }
                break;
            case SDL_EVENT_KEY_UP: {
                const bool* ks = SDL_GetKeyboardState(nullptr);
                if (!ks[SDL_SCANCODE_LEFT] && !ks[SDL_SCANCODE_RIGHT] &&
                    !ks[SDL_SCANCODE_UP] && !ks[SDL_SCANCODE_DOWN]) {
                    walking = 0;
                    Speed = 0;
                }
                if (event.key.key == SDLK_ESCAPE) {
                    MenuEsc();
                }
                break;
            }
            case SDL_EVENT_MOUSE_MOTION:
                if (ShowVirtualKey == 0) {
                    int mx2, my2;
                    SDL_GetMouseState2(mx2, my2);
                    if (mx2 < CENTER_X && my2 < CENTER_Y) MFace = 2;
                    if (mx2 > CENTER_X && my2 < CENTER_Y) MFace = 0;
                    if (mx2 < CENTER_X && my2 > CENTER_Y) MFace = 3;
                    if (mx2 > CENTER_X && my2 > CENTER_Y) MFace = 1;
                }
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_RIGHT) {
                    event.button.button = 0;
                    MenuEsc();
                    nowstep = -1;
                    walking = 0;
                }
                if (event.button.button == SDL_BUTTON_LEFT && TouchWalk) {
                    walking = 2;
                    int axp, ayp;
                    GetMousePosition(axp, ayp, Mx, My);
                    if (ayp >= 0 && ayp <= 479 && axp >= 0 && axp <= 479) {
                        memset(PathCost, 0xFF, sizeof(PathCost));
                        FindWay(Mx, My);
                        gotoEntrance = -1;
                        if (BuildY[axp][ayp] > 0 && Entrance[axp][ayp] < 0) {
                            int bx = BuildX[axp][ayp];
                            int by = BuildY[axp][ayp];
                            axp = bx; ayp = by;
                            for (int i1 = bx - 3; i1 <= bx; i1++)
                                for (int i2 = by - 3; i2 <= by; i2++)
                                    if (i1 >= 0 && i2 >= 0 && Entrance[i1][i2] >= 0 &&
                                        BuildX[i1][i2] == bx && BuildY[i1][i2] == by) {
                                        axp = i1; ayp = i2;
                                        goto found_entrance;
                                    }
                            found_entrance:;
                        }
                        if (Entrance[axp][ayp] >= 0) {
                            int minstep = 4096;
                            for (int i = 0; i < 4; i++) {
                                int axp1 = axp, ayp1 = ayp;
                                switch (i) {
                                    case 0: axp1 = axp - 1; break;
                                    case 1: ayp1 = ayp + 1; break;
                                    case 2: ayp1 = ayp - 1; break;
                                    case 3: axp1 = axp + 1; break;
                                }
                                if (axp1 >= 0 && axp1 < 480 && ayp1 >= 0 && ayp1 < 480) {
                                    int step = PathCost[axp1][ayp1];
                                    if (step >= 0 && minstep > step) {
                                        gotoEntrance = i;
                                        minstep = step;
                                    }
                                }
                            }
                            if (gotoEntrance >= 0) {
                                switch (gotoEntrance) {
                                    case 0: axp = axp - 1; break;
                                    case 1: ayp = ayp + 1; break;
                                    case 2: ayp = ayp - 1; break;
                                    case 3: axp = axp + 1; break;
                                }
                                gotoEntrance = 3 - gotoEntrance;
                            }
                        }
                        FindWay(Mx, My);
                        Moveman(Mx, My, axp, ayp);
                        nowstep = PathCost[axp][ayp] - 1;
                    } else {
                        walking = 0;
                    }
                }
                break;
        }

        // 行走处理
        if (walking > 0) {
            MainMapStill = 0;
            MainMapStillcount = 0;
            switch (walking) {
                case 1: {
                    Speed++;
                    int Mx1 = Mx, My1 = My;
                    if (Speed == 1 || Speed >= 5) {
                        switch (MFace) {
                            case 0: Mx1 = Mx1 - 1; break;
                            case 1: My1 = My1 + 1; break;
                            case 2: My1 = My1 - 1; break;
                            case 3: Mx1 = Mx1 + 1; break;
                        }
                        MainMapStep++;
                        if (MainMapStep >= 7) MainMapStep = 1;
                        if (CanWalk(Mx1, My1)) { Mx = Mx1; My = My1; }
                    }
                    break;
                }
                case 2: {
                    if (nowstep < 0) {
                        walking = 0;
                        if (gotoEntrance >= 0) MFace = gotoEntrance;
                    } else {
                        MainMapStill = 0;
                        if (signof(linex[nowstep] - Mx) < 0) MFace = 0;
                        else if (signof(linex[nowstep] - Mx) > 0) MFace = 3;
                        else if (signof(liney[nowstep] - My) > 0) MFace = 1;
                        else MFace = 2;
                        MainMapStep++;
                        if (MainMapStep >= 7) MainMapStep = 1;
                        if (abs(Mx - linex[nowstep]) + abs(My - liney[nowstep]) == 1 &&
                            CanWalk(linex[nowstep], liney[nowstep])) {
                            Mx = linex[nowstep];
                            My = liney[nowstep];
                        } else {
                            walking = 0;
                        }
                        nowstep--;
                    }
                    break;
                }
            }
            Redraw();
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            if (CheckEntrance()) {
                walking = 0;
                MainMapStep = 0;
                MainMapStill = 0;
                MainMapStillcount = 0;
                Speed = 0;
                if (MMAPAMI == 0) {
                    Redraw();
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                }
            }
        }

        // 进入场景后行走
        if (Where == 1) {
            WalkInScene(0);
        }

        event.key.key = 0;
        event.button.button = 0;

        if (walking == 0) {
            if (MMAPAMI > 0) {
                Redraw();
                int axp2, ayp2;
                GetMousePosition(axp2, ayp2, Mx, My);
                TPosition pos = GetPositionOnScreen(axp2, ayp2, Mx, My);
                DrawMPic(1, pos.x, pos.y);
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
            }
            SDL_Delay(40);
        } else {
            SDL_Delay(WALK_SPEED);
        }
    }
}

bool CanWalk(int x, int y) {
    if (x <= 0 || x >= 479 || y <= 0 || y >= 479) return false;
    bool result = (BuildX[x][y] == 0);
    if (Earth[x][y] == 838 || (Earth[x][y] >= 612 && Earth[x][y] <= 670))
        result = false;
    if ((Earth[x][y] >= 358 && Earth[x][y] <= 362) ||
        (Earth[x][y] >= 506 && Earth[x][y] <= 670) ||
        (Earth[x][y] >= 1016 && Earth[x][y] <= 1022))
        InShip = 1;
    else
        InShip = 0;
    if (MODVersion == 22) {
        if (InShip == 1) { result = false; InShip = 0; }
    }
    return result;
}

bool CheckEntrance() {
    int x = Mx, y = My;
    switch (MFace) {
        case 0: x = x - 1; break;
        case 1: y = y + 1; break;
        case 2: y = y - 1; break;
        case 3: x = x + 1; break;
    }
    if (x < 0 || x >= 480 || y < 0 || y >= 480) return false;
    if (Entrance[x][y] >= 0) {
        int snum = Entrance[x][y];
        if (!CheckCanEnter(snum)) return false;
        instruct_14();
        CurScene = Entrance[x][y];
        SFace = MFace;
        MFace = 3 - MFace;
        SStep = 0;
        Sx = Rscene[CurScene].EntranceX;
        Sy = Rscene[CurScene].EntranceY;
        SaveR(11);
        WalkInScene(0);
        event.key.key = 0;
        event.button.button = 0;
        return true;
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

// ---- 场景行走（严格按Pascal版: 连续按键+出口/跳转+NPC动画+鼠标寻路） ----

int WalkInScene(int Open) {
    uint32_t next_time = SDL_GetTicks();
    Where = 1;
    int walking = 0;
    CurEvent = -1;
    int AmiCount = 0;
    int Speed = 0;
    int localStillcount = 0;
    int gotoevent_local = -1;
    int exitscenemusicnum = Rscene[CurScene].ExitMusic;

    InitialScene();

    // 初始化NPC动画帧
    for (int i = 0; i < 200; i++) {
        if (DData[CurScene][i][7] < DData[CurScene][i][6]) {
            DData[CurScene][i][5] = DData[CurScene][i][7] +
                (DData[CurScene][i][8] * 2) % (DData[CurScene][i][6] - DData[CurScene][i][7] + 2);
        }
    }

    if (Open == 1) {
        Sx = BEGIN_Sx;
        Sy = BEGIN_Sy;
        Cx = Sx; Cy = Sy;
        SceneRolePic = 3445;
        CurEvent = BEGIN_EVENT;
        CallEvent(BEGIN_EVENT);
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
        CurEvent = -1;
    }

    SStep = 0;
    DrawScene();
    ShowSceneName(CurScene);
    CheckEvent3();

    while (SDL_PollEvent(&event) || true) {
        if (Where != 1) break;
        if (Sx > 63) Sx = 63;
        if (Sy > 63) Sy = 63;
        if (Sx < 0) Sx = 0;
        if (Sy < 0) Sy = 0;

        uint32_t now = SDL_GetTicks();
        // 每200ms NPC动画+换色
        if ((int)(now - next_time) > 0) {
            for (int i = 0; i < 200; i++) {
                if (DData[CurScene][i][7] < DData[CurScene][i][6]) {
                    DData[CurScene][i][5] += 2;
                    if (DData[CurScene][i][5] > DData[CurScene][i][6])
                        DData[CurScene][i][5] = DData[CurScene][i][7];
                }
            }
            if (SCENEAMI == 1) InitialScene(1);
            if (walking == 0) localStillcount++;
            else localStillcount = 0;
            if (localStillcount >= 20) { SStep = 0; localStillcount = 0; }
            next_time = now + 200;
            AmiCount++;
            ChangeCol();
        }

        // 检查出口 (3个出口点)
        if ((Sx == Rscene[CurScene].ExitX[0] && Sy == Rscene[CurScene].ExitY[0]) ||
            (Sx == Rscene[CurScene].ExitX[1] && Sy == Rscene[CurScene].ExitY[1]) ||
            (Sx == Rscene[CurScene].ExitX[2] && Sy == Rscene[CurScene].ExitY[2])) {
            Where = 0;
            break;
        }
        // 检查跳转场景
        if (Sx == Rscene[CurScene].JumpX1 && Sy == Rscene[CurScene].JumpY1 &&
            Rscene[CurScene].JumpScene >= 0) {
            instruct_14();
            int Prescene = CurScene;
            CurScene = Rscene[CurScene].JumpScene;
            if (Rscene[Prescene].MainEntranceX1 != 0) {
                Sx = Rscene[CurScene].EntranceX;
                Sy = Rscene[CurScene].EntranceY;
            } else {
                Sx = Rscene[CurScene].JumpX2;
                Sy = Rscene[CurScene].JumpY2;
            }
            InitialScene();
            walking = 0; Speed = 0; SStep = 0;
            DrawScene();
            ShowSceneName(CurScene);
            CheckEvent3();
        }

        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_KEY_UP: {
                const bool* ks = SDL_GetKeyboardState(nullptr);
                if (!ks[SDL_SCANCODE_LEFT] && !ks[SDL_SCANCODE_RIGHT] &&
                    !ks[SDL_SCANCODE_UP] && !ks[SDL_SCANCODE_DOWN]) {
                    walking = 0; Speed = 0;
                }
                if (event.key.key == SDLK_ESCAPE) {
                    MenuEsc();
                    walking = 0; Speed = 0;
                }
                if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) {
                    CheckEvent1();
                }
                break;
            }
            case SDL_EVENT_KEY_DOWN:
                if (event.key.key == SDLK_LEFT)  { SFace = 2; walking = 1; }
                if (event.key.key == SDLK_RIGHT) { SFace = 1; walking = 1; }
                if (event.key.key == SDLK_UP)    { SFace = 0; walking = 1; }
                if (event.key.key == SDLK_DOWN)  { SFace = 3; walking = 1; }
                break;
            case SDL_EVENT_MOUSE_MOTION:
                if (ShowVirtualKey == 0) {
                    int mx2, my2;
                    SDL_GetMouseState2(mx2, my2);
                    if (mx2 < CENTER_X && my2 < CENTER_Y) MFace = 2;
                    if (mx2 > CENTER_X && my2 < CENTER_Y) MFace = 0;
                    if (mx2 < CENTER_X && my2 > CENTER_Y) MFace = 3;
                    if (mx2 > CENTER_X && my2 > CENTER_Y) MFace = 1;
                }
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_RIGHT) {
                    MenuEsc();
                    nowstep = 0;
                    walking = 0; Speed = 0;
                    if (Where == 0) {
                        if (CurScene >= 0 && Rscene[CurScene].ExitMusic >= 0) {
                            StopMP3();
                            PlayMP3(Rscene[CurScene].ExitMusic, -1);
                        }
                        Redraw();
                        UpdateScreen(screen, 0, 0, screen->w, screen->h);
                        return 0;
                    }
                }
                if (event.button.button == SDL_BUTTON_MIDDLE) {
                    CheckEvent1();
                }
                if (event.button.button == SDL_BUTTON_LEFT && TouchWalk) {
                    if (walking == 0) {
                        walking = 2;
                        int axp, ayp;
                        GetMousePosition(axp, ayp, Sx, Sy, SData[CurScene][4][Sx][Sy]);
                        if (ayp >= 0 && ayp <= 63 && axp >= 0 && axp <= 63) {
                            memset(PathCost, 0xFF, sizeof(PathCost));
                            FindWay(Sx, Sy);
                            gotoevent_local = -1;
                            if (SData[CurScene][3][axp][ayp] >= 0) {
                                if (abs(axp - Sx) + abs(ayp - Sy) == 1) {
                                    if (axp < Sx) SFace = 0;
                                    if (axp > Sx) SFace = 3;
                                    if (ayp < Sy) SFace = 2;
                                    if (ayp > Sy) SFace = 1;
                                    if (CheckEvent1()) walking = 0;
                                } else {
                                    if (!CanWalkInScene(axp, ayp)) {
                                        int minstep = 4096;
                                        for (int i = 0; i < 4; i++) {
                                            int axp1 = axp, ayp1 = ayp;
                                            switch (i) {
                                                case 0: axp1 = axp - 1; break;
                                                case 1: ayp1 = ayp + 1; break;
                                                case 2: ayp1 = ayp - 1; break;
                                                case 3: axp1 = axp + 1; break;
                                            }
                                            if (axp1 >= 0 && axp1 < 64 && ayp1 >= 0 && ayp1 < 64) {
                                                int step = PathCost[axp1][ayp1];
                                                if (step >= 0 && minstep > step) {
                                                    gotoevent_local = i;
                                                    minstep = step;
                                                }
                                            }
                                        }
                                        if (gotoevent_local >= 0) {
                                            switch (gotoevent_local) {
                                                case 0: axp = axp - 1; break;
                                                case 1: ayp = ayp + 1; break;
                                                case 2: ayp = ayp - 1; break;
                                                case 3: axp = axp + 1; break;
                                            }
                                            gotoevent_local = 3 - gotoevent_local;
                                        }
                                    }
                                }
                            }
                            Moveman(Sx, Sy, axp, ayp);
                            nowstep = PathCost[axp][ayp] - 1;
                        } else {
                            walking = 0;
                        }
                    } else {
                        walking = 0;
                    }
                    event.button.button = 0;
                }
                break;
        }

        // 行走处理
        if (walking > 0) {
            switch (walking) {
                case 1: {
                    Speed++;
                    localStillcount = 0;
                    if (Speed == 1 || Speed >= 5) {
                        int Sx1 = Sx, Sy1 = Sy;
                        switch (SFace) {
                            case 0: Sx1 = Sx1 - 1; break;
                            case 1: Sy1 = Sy1 + 1; break;
                            case 2: Sy1 = Sy1 - 1; break;
                            case 3: Sx1 = Sx1 + 1; break;
                        }
                        SStep++;
                        if (SStep >= 7) SStep = 1;
                        if (CanWalkInScene(Sx1, Sy1)) { Sx = Sx1; Sy = Sy1; }
                    }
                    break;
                }
                case 2: {
                    if (nowstep >= 0) {
                        if (signof(liney[nowstep] - Sy) < 0) SFace = 2;
                        else if (signof(liney[nowstep] - Sy) > 0) SFace = 1;
                        else if (signof(linex[nowstep] - Sx) > 0) SFace = 3;
                        else SFace = 0;
                        SStep++;
                        if (SStep >= 7) SStep = 1;
                        if (abs(Sx - linex[nowstep]) + abs(Sy - liney[nowstep]) == 1) {
                            Sx = linex[nowstep];
                            Sy = liney[nowstep];
                        } else {
                            walking = 0;
                        }
                        nowstep--;
                    } else {
                        walking = 0;
                        if (gotoevent_local >= 0) {
                            SFace = gotoevent_local;
                            Redraw();
                            CheckEvent1();
                        }
                    }
                    break;
                }
            }
            Redraw();
            UpdateScreen(screen, 0, 0, screen->w, screen->h);
            CheckEvent3();
        }

        event.key.key = 0;
        event.button.button = 0;

        if (walking == 0 || Speed == 0) {
            if (SCENEAMI > 0) {
                Redraw();
                if (walking == 0) {
                    int axp2, ayp2;
                    GetMousePosition(axp2, ayp2, Sx, Sy, SData[CurScene][4][Sx][Sy]);
                    if (axp2 >= 0 && axp2 < 64 && ayp2 >= 0 && ayp2 < 64) {
                        TPosition pos = GetPositionOnScreen(axp2, ayp2, Sx, Sy);
                        DrawMPic(1, pos.x, pos.y - SData[CurScene][4][axp2][ayp2]);
                    }
                }
                UpdateScreen(screen, 0, 0, screen->w, screen->h);
            }
            SDL_Delay(40);
        } else {
            SDL_Delay(WALK_SPEED2);
        }
    }

    instruct_14();
    if (exitscenemusicnum > 0) {
        StopMP3();
        PlayMP3(exitscenemusicnum, -1);
    }
    return 0;
}

// 严格按Pascal版: 只检查SData[1]==0, 加NPC阻挡和地面类型检查
bool CanWalkInScene(int x, int y) {
    if (CurScene < 0 || x < 0 || y < 0 || x >= 64 || y >= 64) return false;
    bool result = (SData[CurScene][1][x][y] == 0);
    // NPC阻挡
    if (SData[CurScene][3][x][y] >= 0 && result &&
        DData[CurScene][SData[CurScene][3][x][y]][0] == 1)
        result = false;
    // 地面类型检查
    int ground = SData[CurScene][0][x][y];
    if ((ground >= 358 && ground <= 362) || ground == 522 || ground == 1022 ||
        (ground >= 1324 && ground <= 1330) || ground == 1348)
        result = false;
    if (MODVersion == 23 && (SData[CurScene][1][x][y] == 1358 * 2 || SData[CurScene][1][x][y] == 1269 * 2))
        result = true;
    return result;
}

bool CanWalkInScene(int x1, int y1, int x, int y) {
    return (abs(SData[CurScene][4][x][y] - SData[CurScene][4][x1][y1]) <= 10) && CanWalkInScene(x, y);
}

// 严格按Pascal版: 面向方向 0=x-1, 1=y+1, 2=y-1, 3=x+1
bool CheckEvent1() {
    int x = Sx, y = Sy;
    switch (SFace) {
        case 0: x = x - 1; break;
        case 1: y = y + 1; break;
        case 2: y = y - 1; break;
        case 3: x = x + 1; break;
    }
    if (x < 0 || x >= 64 || y < 0 || y >= 64) return false;
    if (SData[CurScene][3][x][y] >= 0) {
        CurEvent = SData[CurScene][3][x][y];
        if (DData[CurScene][CurEvent][2] >= 0) {
            Cx = Sx; Cy = Sy;
            CallEvent(DData[CurScene][SData[CurScene][3][x][y]][2]);
            CurEvent = -1;
            return true;
        }
    }
    CurEvent = -1;
    return false;
}

// 严格按Pascal版: 使用DData索引4作为自动触发
void CheckEvent3() {
    int enumIdx = SData[CurScene][3][Sx][Sy];
    if (enumIdx >= 0 && DData[CurScene][enumIdx][4] > 0) {
        CurEvent = enumIdx;
        Cx = Sx; Cy = Sy;
        CallEvent(DData[CurScene][enumIdx][4]);
        CurEvent = -1;
    }
}

// 严格按Pascal版: BFS寻路
void FindWay(int x1, int y1) {
    int16_t Xlist[4097], Ylist[4097];
    int16_t steplist[4097];
    int Xinc[4] = {0, 1, -1, 0};
    int Yinc[4] = {-1, 0, 0, 1};
    int curgrid = 0, totalgrid = 1;
    Xlist[0] = x1; Ylist[0] = y1; steplist[0] = 0;
    PathCost[x1][y1] = 0;

    while (curgrid < totalgrid) {
        int curX = Xlist[curgrid];
        int curY = Ylist[curgrid];
        int curstep = steplist[curgrid];
        int Bgrid[4] = {};

        if (Where == 1) {
            for (int i = 0; i < 4; i++) {
                int nextX = curX + Xinc[i];
                int nextY = curY + Yinc[i];
                if (nextX < 0 || nextX > 63 || nextY < 0 || nextY > 63)
                    Bgrid[i] = 3;
                else if (PathCost[nextX][nextY] >= 0)
                    Bgrid[i] = 2;
                else if (!CanWalkInScene(curX, curY, nextX, nextY))
                    Bgrid[i] = 1;
                else
                    Bgrid[i] = 0;
            }
        } else {
            for (int i = 0; i < 4; i++) {
                int nextX = curX + Xinc[i];
                int nextY = curY + Yinc[i];
                if (nextX < 0 || nextX > 479 || nextY < 0 || nextY > 479)
                    Bgrid[i] = 3;
                else if (Entrance[nextX][nextY] >= 0)
                    Bgrid[i] = 6;
                else if (PathCost[nextX][nextY] >= 0)
                    Bgrid[i] = 2;
                else if (BuildX[nextX][nextY] > 0)
                    Bgrid[i] = 1;
                else if (Surface[nextX][nextY] >= 1692 && Surface[nextX][nextY] <= 1700)
                    Bgrid[i] = 1;
                else if (Earth[nextX][nextY] == 838 || (Earth[nextX][nextY] >= 612 && Earth[nextX][nextY] <= 670))
                    Bgrid[i] = 1;
                else if ((Earth[nextX][nextY] >= 358 && Earth[nextX][nextY] <= 362) ||
                         (Earth[nextX][nextY] >= 506 && Earth[nextX][nextY] <= 670) ||
                         (Earth[nextX][nextY] >= 1016 && Earth[nextX][nextY] <= 1022)) {
                    if (nextX == ShipY && nextY == ShipX)
                        Bgrid[i] = 4;
                    else if ((Surface[nextX][nextY] / 2 >= 863 && Surface[nextX][nextY] / 2 <= 872) ||
                             (Surface[nextX][nextY] / 2 >= 852 && Surface[nextX][nextY] / 2 <= 854) ||
                             (Surface[nextX][nextY] / 2 >= 858 && Surface[nextX][nextY] / 2 <= 860))
                        Bgrid[i] = 0;
                    else
                        Bgrid[i] = 5;
                } else {
                    Bgrid[i] = 0;
                }
            }
        }

        for (int i = 0; i < 4; i++) {
            bool canwalk = false;
            if (MODVersion == 22) {
                if ((InShip == 1 && Bgrid[i] == 5) || ((Bgrid[i] == 0 || Bgrid[i] == 4) && InShip == 0))
                    canwalk = true;
            } else {
                if (Bgrid[i] == 0 || Bgrid[i] == 4 || Bgrid[i] == 5 || Bgrid[i] == 7)
                    canwalk = true;
            }
            if (canwalk) {
                int nx = curX + Xinc[i], ny = curY + Yinc[i];
                Xlist[totalgrid] = nx;
                Ylist[totalgrid] = ny;
                steplist[totalgrid] = curstep + 1;
                PathCost[nx][ny] = steplist[totalgrid];
                totalgrid++;
                if (totalgrid > 4096) return;
            }
        }
        curgrid++;
        if (Where == 0 && curX - Mx > 22 && curY - My > 22) break;
    }
}

// 严格按Pascal版: 从目标回溯路径
void Moveman(int x1, int y1, int x2, int y2) {
    if (PathCost[x2][y2] > 0) {
        int Xinc[4] = {0, 1, -1, 0};
        int Yinc[4] = {-1, 0, 0, 1};
        linex[0] = x2;
        liney[0] = y2;
        for (int a = 1; a <= PathCost[x2][y2]; a++) {
            for (int i = 0; i < 4; i++) {
                int tempx = linex[a - 1] + Xinc[i];
                int tempy = liney[a - 1] + Yinc[i];
                if (tempx >= 0 && tempy >= 0 &&
                    PathCost[tempx][tempy] == PathCost[linex[a - 1]][liney[a - 1]] - 1) {
                    linex[a] = tempx;
                    liney[a] = tempy;
                    break;
                }
            }
        }
    }
}

void ShowSceneName(int snum) {
    if (snum < 0 || snum >= 201) return;
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    std::string name = cp950toutf8(Rscene[snum].Name);
    int nameLen = (int)strlen((const char*)Rscene[snum].Name);
    DrawTextWithRect(screen, name, CENTER_X - nameLen * 5 + 7, 100, nameLen * 10 + 6, ColColor(5), ColColor(7));
    if (Rscene[snum].EntranceMusic >= 0) {
        StopMP3();
        PlayMP3(Rscene[snum].EntranceMusic, -1);
    }
    SDL_Delay(500);
}

// ---- 菜单系统 ----

// 严格按Pascal版: SDL_WaitEvent + 鼠标motion hover + 左右键

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

    int menuH = max * 22 + 29;

    auto ShowCommonMenu = [&]() {
        LoadFreshScreen(x, y, w + 1, menuH);
        DrawRectangle(screen, x, y, w, max * 22 + 28, 0, ColColor(0xFF), 50);
        for (int i = 0; i <= max; i++) {
            uint32_t col1 = (i == menu) ? ColColor(0x64) : ColColor(0x05);
            uint32_t col2 = (i == menu) ? ColColor(0x66) : ColColor(0x07);
            DrawShadowText(screen, menuString[i], x + 3, y + 2 + 22 * i, col1, col2);
        }
    };

    RecordFreshScreen(x, y, w + 1, menuH);
    ShowCommonMenu();
    UpdateScreen(screen, x, y, w + 1, menuH);
    if (fn) fn(menu);

    int result = -1;
    while (SDL_WaitEvent(&event)) {
        CheckBasicEvent();
        switch (event.type) {
            case SDL_EVENT_KEY_UP:
                if (event.key.key == SDLK_DOWN) {
                    menu++; if (menu > max) menu = 0;
                    ShowCommonMenu();
                    UpdateScreen(screen, x, y, w + 1, menuH);
                    if (fn) fn(menu);
                }
                if (event.key.key == SDLK_UP) {
                    menu--; if (menu < 0) menu = max;
                    ShowCommonMenu();
                    UpdateScreen(screen, x, y, w + 1, menuH);
                    if (fn) fn(menu);
                }
                if (event.key.key == SDLK_ESCAPE) {
                    result = -1; goto menu_done;
                }
                if (event.key.key == SDLK_RETURN || event.key.key == SDLK_SPACE) {
                    result = menu; goto menu_done;
                }
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.button.button == SDL_BUTTON_LEFT) {
                    result = menu; goto menu_done;
                }
                if (event.button.button == SDL_BUTTON_RIGHT) {
                    result = -1; goto menu_done;
                }
                break;
            case SDL_EVENT_MOUSE_MOTION: {
                float sx = (float)RESOLUTIONX / screen->w;
                float sy = (float)RESOLUTIONY / screen->h;
                int emx = (int)(event.motion.x / sx);
                int emy = (int)(event.motion.y / sy);
                if (emx >= x && emx < x + w && emy > y && emy < y + menuH) {
                    int menup = menu;
                    menu = (emy - y - 2) / 22;
                    if (menu > max) menu = max;
                    if (menu < 0) menu = 0;
                    if (menup != menu) {
                        ShowCommonMenu();
                        UpdateScreen(screen, x, y, w + 1, menuH);
                        if (fn) fn(menu);
                    }
                }
                break;
            }
        }
    }
menu_done:
    event.key.key = 0;
    event.button.button = 0;
    return result;
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

// 严格按Pascal版: 7项菜单(含传送), 循环选择
void MenuEsc() {
    NeedRefreshScene = 0;
    std::string menuStr[7];
    menuStr[0] = "醫療";
    menuStr[1] = "解毒";
    menuStr[2] = "物品";
    menuStr[3] = "狀態";
    menuStr[4] = (MODVersion == 22) ? "特殊" : "離隊";
    menuStr[5] = "傳送";
    menuStr[6] = "系統";

    int i = 0;
    while (i >= 0) {
        i = CommonMenu(27, 30, 46, 6, i, menuStr);
        switch (i) {
            case 0: MenuMedcine(); break;
            case 1: MenuMedPoison(); break;
            case 2: MenuItem(); break;
            case 5: {
                if (Where == 0) {
                    std::string transportMenu[] = {"地圖", "列表"};
                    int i2 = CommonMenu(80, 30, 45, 1, transportMenu);
                    int i1 = 0;
                    if (i2 == 0) i1 = teleport();
                    else if (i2 == 1) i1 = TeleportByList();
                    Redraw();
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                    if (i1 != 0) { i = -1; continue; }
                } else {
                    DrawTextWithRect("子場景不可傳送!", 80, 30, 172, ColColor(0x21), ColColor(0x23));
                    WaitAnyKey();
                }
                break;
            }
            case 6: {
                int i1 = MenuSystem();
                if (i1 >= 2) { i = -1; continue; }
                break;
            }
            case 4: MenuLeave(); break;
            case 3: {
                if (MODVersion == 51) {
                    CallEvent(1092);
                    Redraw();
                    UpdateScreen(screen, 0, 0, screen->w, screen->h);
                } else {
                    MenuStatus();
                }
                break;
            }
        }
        Redraw();
        UpdateScreen(screen, 80, 0, screen->w - 80, screen->h);
        if (Where == 3) break;
    }
    Redraw();
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    NeedRefreshScene = 1;
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

// StartAmi: 显示开场文字(list/start.txt)
void StartAmi() {
    instruct_14();
    Redraw();
    std::string filepath = AppPath + "list/start.txt";
    FILE* f = fopen(filepath.c_str(), "rb");
    if (!f) return;
    fseek(f, 0, SEEK_END);
    int len = (int)ftell(f);
    fseek(f, 0, SEEK_SET);
    std::string str(len + 1, '\0');
    fread(&str[0], 1, len, f);
    str[len] = '\r';
    fclose(f);

    int x = 30, y = 80;
    DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);

    int p = 0;
    for (int i = 0; i <= len; i++) {
        if (str[i] == '\n') str[i] = ' ';
        if (str[i] == '\r') {
            std::string line = str.substr(p, i - p);
            DrawShadowText(screen, line, x, y, ColColor(0xFF), ColColor(0xFF));
            UpdateScreen(screen, x, y, (int)line.size() * 10 + 2, 22);
            p = i + 1;
            y += 25;
        }
        if (str[i] == '*') {
            str[i] = ' ';
            y = 80;
            Redraw();
            WaitAnyKey();
            DrawRectangleWithoutFrame(screen, 0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
        }
    }
    WaitAnyKey();
    instruct_14();
}

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
