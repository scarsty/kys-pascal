// kys_engine.cpp - 基础引擎实现
// 对应 kys_engine.pas

#define _USE_MATH_DEFINES

#include "kys_engine.h"
#include "PotConv.h"
#include "SimpleCC.h"
#include "filefunc.h"
#include "kys_draw.h"
#include "kys_main.h"

#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <SDL3_ttf/SDL_ttf.h>

#include <algorithm>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <format>
#include <map>
#include <string>
#include <vector>

// ---- 私有变量 ----
struct QueuedText
{
    std::string word;
    int x_pos, y_pos;
    uint32_t color;
    int screen_dx;
};

static std::vector<QueuedText> TextQueue;
static TTF_Font* FontHR = nullptr;
static TTF_Font* EngFontHR = nullptr;
static int FontHRSize = 0, EngFontHRSize = 0;
static std::map<int, SDL_Texture*> fonts_hr_tex;
static SDL_Surface* CachedImage = nullptr;
static std::string CachedImageName;
static bool HiResTextRenderOk = false;
static int compositeTexW = 0, compositeTexH = 0;
static MIX_Mixer* gMixer = nullptr;
static MIX_Track* MusicTrack = nullptr;
static MIX_Track* SfxTracks[10] = {};
static int SfxNextTrack = 0;

// SimpleCC handles
static SimpleCC sccS2T;
static SimpleCC sccT2S;
static bool sccS2T_loaded = false;
static bool sccT2S_loaded = false;

static uint64_t tic_time = 0;

// ---- 内部辅助函数 ----

static bool EnsureMixerCreated()
{
    if (gMixer)
    {
        return true;
    }
    if (!MIX_Init())
    {
        return false;
    }
    SDL_AudioSpec spec;
    spec.freq = 22500;
    spec.format = SDL_AUDIO_S16;
    spec.channels = 2;
    gMixer = MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec);
    return gMixer != nullptr;
}

static MIX_Track* AcquireSfxTrack(MIX_Audio* audio)
{
    if (!audio)
    {
        return nullptr;
    }
    int idx = SfxNextTrack;
    SfxNextTrack++;
    if (SfxNextTrack > 9)
    {
        SfxNextTrack = 0;
    }
    if (!MIX_SetTrackAudio(SfxTracks[idx], audio))
    {
        return nullptr;
    }
    return SfxTracks[idx];
}

static uint8_t BlendByteByPercent(uint8_t a, uint8_t b, int percent)
{
    return (uint8_t)((a * (100 - percent) + b * percent) / 100);
}

static uint32_t BlendRGBAByPercent(uint32_t src, uint32_t dst, int percent)
{
    uint8_t sr = (src >> 16) & 0xFF, sg = (src >> 8) & 0xFF, sb = src & 0xFF;
    uint8_t dr = (dst >> 16) & 0xFF, dg = (dst >> 8) & 0xFF, db = dst & 0xFF;
    return (BlendByteByPercent(sr, dr, percent) << 16) | (BlendByteByPercent(sg, dg, percent) << 8) | BlendByteByPercent(sb, db, percent);
}

// ---- 音频 ----

void InitialMusic()
{
    if (!EnsureMixerCreated())
    {
        return;
    }
    MusicTrack = MIX_CreateTrack(gMixer);
    for (int i = 0; i < 10; i++)
    {
        SfxTracks[i] = MIX_CreateTrack(gMixer);
    }
    SfxNextTrack = 0;

    for (int i = 0; i < (int)Music.size(); i++)
    {
        if (Music[i])
        {
            MIX_DestroyAudio(Music[i]);
            Music[i] = nullptr;
        }
        std::string str = AppPath + "music/" + std::to_string(i) + ".mp3";
        if (filefunc::fileExist(str))
        {
            Music[i] = MIX_LoadAudio(nullptr, str.c_str(), false);
        }
        else
        {
            str = AppPath + "music/" + std::to_string(i) + ".mid";
            if (filefunc::fileExist(str))
            {
                // MIDI loading with FluidSynth soundfont
                SDL_IOStream* io = SDL_IOFromFile(str.c_str(), "rb");
                if (io)
                {
                    SDL_PropertiesID id = SDL_CreateProperties();
                    SDL_SetPointerProperty(id, MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER, io);
                    SDL_SetBooleanProperty(id, MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN, true);
                    SDL_SetStringProperty(id, MIX_PROP_AUDIO_DECODER_STRING, "fluidsynth");
                    std::string sf2 = AppPath + "music/mid.sf2";
                    if (!filefunc::fileExist(sf2))
                    {
                        sf2 = AppPathCommon + "music/mid.sf2";
                    }
                    SDL_SetStringProperty(id, "SDL_mixer.decoder.fluidsynth.soundfont_path", sf2.c_str());
                    Music[i] = MIX_LoadAudioWithProperties(id);
                    SDL_DestroyProperties(id);
                    // io is closed by MIX_LoadAudioWithProperties due to closeio=true
                }
            }
            else
            {
                Music[i] = nullptr;
            }
        }
    }
    for (int i = 0; i < (int)ESound.size(); i++)
    {
        if (ESound[i])
        {
            MIX_DestroyAudio(ESound[i]);
            ESound[i] = nullptr;
        }
        std::string str = AppPath + std::format("sound/e{:02d}.wav", i);
        if (filefunc::fileExist(str))
        {
            ESound[i] = MIX_LoadAudio(nullptr, str.c_str(), false);
        }
        else
        {
            ESound[i] = nullptr;
        }
    }
    for (int i = 0; i < (int)ASound.size(); i++)
    {
        if (ASound[i])
        {
            MIX_DestroyAudio(ASound[i]);
            ASound[i] = nullptr;
        }
        std::string str = AppPath + std::format("sound/atk{:02d}.wav", i);
        if (filefunc::fileExist(str))
        {
            ASound[i] = MIX_LoadAudio(nullptr, str.c_str(), false);
        }
        else
        {
            ASound[i] = nullptr;
        }
    }
    // 调试: 统计加载数量
    {
        int mc = 0, ec = 0, ac = 0;
        for (int i = 0; i < (int)Music.size(); i++)
        {
            if (Music[i])
            {
                mc++;
            }
        }
        for (int i = 0; i < (int)ESound.size(); i++)
        {
            if (ESound[i])
            {
                ec++;
            }
        }
        for (int i = 0; i < (int)ASound.size(); i++)
        {
            if (ASound[i])
            {
                ac++;
            }
        }
        fprintf(stderr, "[InitialMusic] loaded: Music=%d/%d  ESound=%d/%d  ASound=%d/%d  gMixer=%p\n",
            mc, (int)Music.size(), ec, (int)ESound.size(), ac, (int)ASound.size(), (void*)gMixer);
    }
}

void PlayMP3(int MusicNum, int times, int frombeginning)
{
    if (!EnsureMixerCreated())
    {
        return;
    }
    if (!MusicTrack)
    {
        return;
    }
    if (MusicNum < 0 || MusicNum >= (int)Music.size())
    {
        return;
    }
    if (VOLUME <= 0)
    {
        return;
    }
    if (!Music[MusicNum])
    {
        return;
    }
    int loops = (times == -1) ? -1 : 0;
    MIX_StopTrack(MusicTrack, 0);
    MIX_SetTrackAudio(MusicTrack, Music[MusicNum]);
    if (frombeginning == 1)
    {
        MIX_SetTrackPlaybackPosition(MusicTrack, 0);
    }
    MIX_SetTrackGain(MusicTrack, (float)VOLUME / 100.0f);
    MIX_SetTrackLoops(MusicTrack, loops);
    SDL_PropertiesID id = SDL_CreateProperties();
    SDL_SetNumberProperty(id, MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, 50);
    SDL_SetNumberProperty(id, MIX_PROP_PLAY_LOOPS_NUMBER, loops);
    MIX_PlayTrack(MusicTrack, id);
    SDL_DestroyProperties(id);
    NowMusic = MusicNum;
}

void PlayMP3(const char* filename, int times)
{
    if (!EnsureMixerCreated())
    {
        return;
    }
    if (!MusicTrack)
    {
        return;
    }
    if (VOLUME <= 0)
    {
        return;
    }
    MIX_Audio* audio = MIX_LoadAudio(nullptr, filename, false);
    if (!audio)
    {
        return;
    }
    MIX_StopTrack(MusicTrack, 0);
    MIX_SetTrackAudio(MusicTrack, audio);
    MIX_SetTrackGain(MusicTrack, (float)VOLUME / 100.0f);
    int loops = (times == -1) ? -1 : 0;
    MIX_SetTrackLoops(MusicTrack, loops);
    SDL_PropertiesID id = SDL_CreateProperties();
    SDL_SetNumberProperty(id, MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, 50);
    SDL_SetNumberProperty(id, MIX_PROP_PLAY_LOOPS_NUMBER, loops);
    MIX_PlayTrack(MusicTrack, id);
    SDL_DestroyProperties(id);
}

void StopMP3(int frombeginning)
{
    if (MusicTrack)
    {
        MIX_StopTrack(MusicTrack, 0);
        if (frombeginning == 1)
        {
            MIX_SetTrackPlaybackPosition(MusicTrack, 0);
        }
    }
}

void PlaySoundE(int SoundNum, int times)
{
    if (SoundNum < 0 || SoundNum >= (int)ESound.size())
    {
        return;
    }
    if (!ESound[SoundNum])
    {
        return;
    }
    MIX_Track* trk = AcquireSfxTrack(ESound[SoundNum]);
    if (trk)
    {
        MIX_SetTrackGain(trk, (float)VOLUMEWAV / 100.0f);
        MIX_PlayTrack(trk, 0);
    }
}

void PlaySoundE(int SoundNum)
{
    PlaySoundE(SoundNum, 0);
}

void PlaySoundE(int SoundNum, int times, int x, int y, int z)
{
    PlaySoundE(SoundNum, times);
}

void PlaySoundA(int SoundNum, int times)
{
    if (SoundNum < 0 || SoundNum >= (int)ASound.size())
    {
        return;
    }
    if (!ASound[SoundNum])
    {
        return;
    }
    int loops = (times == -1) ? -1 : 0;
    MIX_Track* trk = AcquireSfxTrack(ASound[SoundNum]);
    if (trk)
    {
        MIX_SetTrackGain(trk, (float)VOLUMEWAV / 100.0f);
        MIX_SetTrackLoops(trk, loops);
        MIX_PlayTrack(trk, 0);
    }
}

// ---- 文件读取 ----

char* ReadFileToBuffer(char* p, const std::string& filename, int size, int malloc_flag)
{
    FILE* f = fopen(filename.c_str(), "rb");
    if (!f)
    {
        return p;
    }
    if (malloc_flag && !p)
    {
        fseek(f, 0, SEEK_END);
        int len = (int)ftell(f);
        fseek(f, 0, SEEK_SET);
        p = new char[len];
        fread(p, 1, len, f);
    }
    else
    {
        fread(p, 1, size, f);
    }
    fclose(f);
    return p;
}

void FreeFileBuffer(char*& p)
{
    delete[] p;
    p = nullptr;
}

int LoadIdxGrp(const std::string& stridx, const std::string& strgrp,
    std::vector<int>& idxarray, std::vector<uint8_t>& grparray)
{
    filefunc::readFileToVector(stridx, idxarray);
    if (idxarray.empty())
    {
        return 0;
    }
    filefunc::readFileToVector(strgrp, grparray);
    return (int)idxarray.size();
}

SDL_Surface* LoadSurfaceFromFile(const std::string& filename)
{
    return SDL_LoadSurface(filename.c_str());
}

SDL_Surface* LoadSurfaceFromMem(const char* p, int len)
{
    SDL_IOStream* io = SDL_IOFromMem((void*)p, len);
    if (!io)
    {
        return nullptr;
    }
    SDL_Surface* s = SDL_LoadSurface_IO(io, true);
    return s;
}

static void ClearHiResGlyphCaches();

void FreeAllSurface()
{
    // 释放所有PNG tile surfaces
    for (auto& s : MPNGTile)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    MPNGTile.clear();
    for (auto& s : SPNGTile)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    SPNGTile.clear();
    for (auto& s : BPNGTile)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    BPNGTile.clear();
    for (auto& s : EPNGTile)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    EPNGTile.clear();
    for (auto& s : CPNGTile)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    CPNGTile.clear();
    for (auto& s : HeadSurface)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    HeadSurface.clear();
    for (auto& s : ItemSurface)
    {
        if (s)
        {
            SDL_DestroySurface(s);
        }
    }
    ItemSurface.clear();

    // 释放高清字体缓存
    ClearHiResGlyphCaches();
    if (FontHR)
    {
        TTF_CloseFont(FontHR);
        FontHR = nullptr;
    }
    if (EngFontHR)
    {
        TTF_CloseFont(EngFontHR);
        EngFontHR = nullptr;
    }
}

void ReadTiles()
{
    std::string path = AppPath;
    LoadIdxGrp(path + "resource/mmap.idx", path + "resource/mmap.grp", MIdx, MPic);
    MPicAmount = (int)MIdx.size();
    LoadIdxGrp(path + "resource/sdx", path + "resource/smp", SIdx, SPic);
    SPicAmount = (int)SIdx.size();
    LoadIdxGrp(path + "resource/wdx", path + "resource/wmp", WIdx, WPic);
    BPicAmount = (int)WIdx.size();
    LoadIdxGrp(path + "resource/eft.idx", path + "resource/eft.grp", EIdx, EPic);
    EPicAmount = (int)EIdx.size();
    LoadIdxGrp(path + "resource/cloud.idx", path + "resource/cloud.grp", CIdx, CPic);
    CPicAmount = (int)CIdx.size();
    LoadIdxGrp(path + "resource/hdgrp.idx", path + "resource/hdgrp.grp", HIdx, HPic);
    HPicAmount = (int)HIdx.size();
    LoadIdxGrp(path + "resource/title.idx", path + "resource/title.grp", TitleIdx, TitlePic);
    LoadIdxGrp(path + "resource/talk.idx", path + "resource/talk.grp", TIdx, TDef);
    LoadIdxGrp(path + "resource/kdef.idx", path + "resource/kdef.grp", KIdx, KDef);

    // 战斗图
    for (int i = 0; i < 1000; i++)
    {
        std::string fidx = path + std::format("fight/fight{:03d}.idx", i);
        std::string fgrp = path + std::format("fight/fight{:03d}.grp", i);
        if (filefunc::fileExist(fidx))
        {
            LoadIdxGrp(fidx, fgrp, FIdx[i], FPic[i]);
        }
    }
}

// ---- 基本绘图 ----

uint32_t GetPixel(SDL_Surface* surface, int x, int y)
{
    if (!surface)
    {
        return 0;
    }
    if (x < 0 || y < 0 || x >= surface->w || y >= surface->h)
    {
        return 0;
    }
    uint32_t* pixels = (uint32_t*)surface->pixels;
    return pixels[y * (surface->pitch / 4) + x];
}

void PutPixel(SDL_Surface* surface, int x, int y, uint32_t pixel)
{
    if (!surface)
    {
        return;
    }
    if (x < 0 || y < 0 || x >= surface->w || y >= surface->h)
    {
        return;
    }
    uint32_t* pixels = (uint32_t*)surface->pixels;
    pixels[y * (surface->pitch / 4) + x] = pixel;
}

void display_img(const char* file_name, int x, int y)
{
    std::string name(file_name);
    SDL_Surface* img = nullptr;
    if (name == CachedImageName && CachedImage)
    {
        img = CachedImage;
    }
    else
    {
        if (CachedImage)
        {
            SDL_DestroySurface(CachedImage);
        }
        std::string fullpath = checkFileName(name);
        img = SDL_LoadSurface(fullpath.c_str());
        CachedImage = img;
        CachedImageName = name;
    }
    if (!img)
    {
        return;
    }
    if (x < 0)
    {
        x = CENTER_X - img->w / 2;
    }
    if (y < 0)
    {
        y = CENTER_Y - img->h / 2;
    }
    SDL_Rect dst = { x, y, img->w, img->h };
    SDL_BlitSurface(img, nullptr, screen, &dst);
}

uint32_t ColColor(uint8_t num)
{
    if (num * 3 + 2 >= 768)
    {
        return 0;
    }
    return SDL_MapRGB(SDL_GetPixelFormatDetails(screen->format),
        SDL_GetSurfacePalette(screen),
        ACol[num * 3] * 4, ACol[num * 3 + 1] * 4, ACol[num * 3 + 2] * 4);
}

void DrawRectangle(SDL_Surface* sur, int x, int y, int w, int h,
    int colorin, uint32_t colorframe, int alpha)
{
    if (!sur)
    {
        return;
    }
    SDL_Surface* tempscr = SDL_CreateSurface(w + 1, h + 1,
        SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    if (!tempscr)
    {
        return;
    }

    uint8_t r, g, b, r1, g1, b1;
    SDL_GetRGB(colorin, SDL_GetPixelFormatDetails(tempscr->format),
        SDL_GetSurfacePalette(tempscr), &r, &g, &b);
    SDL_GetRGB(colorframe, SDL_GetPixelFormatDetails(tempscr->format),
        SDL_GetSurfacePalette(tempscr), &r1, &g1, &b1);

    SDL_FillSurfaceRect(tempscr, nullptr,
        SDL_MapSurfaceRGBA(tempscr, r, g, b, (uint8_t)(alpha * 255 / 100)));

    for (int i1 = 0; i1 <= w; i1++)
    {
        for (int i2 = 0; i2 <= h; i2++)
        {
            int l1 = i1 + i2;
            int l2 = -(i1 - w) + i2;
            int l3 = i1 - (i2 - h);
            int l4 = -(i1 - w) - (i2 - h);
            // 4角裁切
            if (!((l1 >= 4) && (l2 >= 4) && (l3 >= 4) && (l4 >= 4)))
            {
                PutPixel(tempscr, i1, i2, 0);
            }
            // 框线 + 渐变alpha
            if (((l1 >= 4) && (l2 >= 4) && (l3 >= 4) && (l4 >= 4) && ((i1 == 0) || (i1 == w) || (i2 == 0) || (i2 == h))) || ((l1 == 4) || (l2 == 4) || (l3 == 4) || (l4 == 4)))
            {
                double frac = (double)i1 / w + (double)i2 / h - 1.0;
                uint8_t a = (uint8_t)(int)(250.0 - fabs(frac) * 150.0);
                PutPixel(tempscr, i1, i2,
                    SDL_MapSurfaceRGBA(tempscr, r1, g1, b1, a));
            }
        }
    }

    SDL_Rect dst = { x, y, 0, 0 };
    SDL_BlitSurface(tempscr, nullptr, sur, &dst);
    SDL_DestroySurface(tempscr);
}

void DrawRectangleWithoutFrame(SDL_Surface* sur, int x, int y, int w, int h,
    uint32_t colorin, int alpha)
{
    if (!sur)
    {
        return;
    }
    SDL_Surface* temp = SDL_CreateSurface(w, h,
        SDL_GetPixelFormatForMasks(32, RMask, GMask, BMask, AMask));
    if (!temp)
    {
        return;
    }
    SDL_FillSurfaceRect(temp, nullptr, colorin | 0xFF000000);
    SDL_SetSurfaceAlphaMod(temp, (uint8_t)(alpha * 255 / 100));
    SDL_Rect dst = { x, y, 0, 0 };
    SDL_BlitSurface(temp, nullptr, sur, &dst);
    SDL_DestroySurface(temp);
}

// ---- RLE8绘图 ----

bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys)
{
    return (px + w > 0 && px - xs < screen->w && py + h > 0 && py - ys < screen->h);
}

bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys,
    int xx, int yy, int xw, int yh)
{
    return (px + w > xx && px < xx + xw && py + h > yy && py < yy + yh);
}

// 基础RLE8解码绘制 (shadow only)
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI, int shadow)
{
    DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image,
        widthI, heightI, sizeI, shadow, 0);
}

// RLE8解码绘制 with alpha
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI,
    int shadow, int alpha)
{
    DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image,
        widthI, heightI, sizeI, shadow, alpha,
        nullptr, nullptr, 0, 0, 0, 0, 0, 0, 0);
}

// 完整RLE8解码绘制 - 严格按照Pascal版逻辑实现
// colorPanel: 调色板指针 (每色3字节)
// num, px, py: 图片编号和绘制位置
// Pidx, Ppic: 图片索引和数据
// RectArea: 绘制范围矩形(4个int), nullptr表示全屏
// Image: 目标表面, nullptr则画到screen
// widthI, heightI, sizeI: 映像尺寸和单位大小
// shadow: 亮度调整(加到乘数4上)
// alpha: 透明度(低8位为未遮挡alpha, 高8位为被遮挡alpha)
// BlockImageW: 深度映像, 写入depth用于遮挡
// BlockPosition: 遮挡偏移(2个int: blockx, blocky)
// widthW, heightW, sizeW: BlockImageW尺寸
// depth: 绘图优先级/深度
// mixColor, mixAlpha: 混合颜色和混合度
// totalpix: 最大绘制像素数, 0表示不限制
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
    const int* Pidx, const uint8_t* Ppic,
    const char* RectArea, SDL_Surface* Image,
    int widthI, int heightI, int sizeI,
    int shadow, int alpha,
    char* BlockImageW, const char* BlockPosition,
    int widthW, int heightW, int sizeW,
    int depth, uint32_t mixColor, int mixAlpha, int totalpix)
{
    if (!Pidx || !Ppic)
    {
        return;
    }
    if (num < 0)
    {
        return;
    }

    // 计算数据偏移
    int offset = 0;
    if (num != 0)
    {
        offset = Pidx[num - 1];
    }

    const uint8_t* data = Ppic + offset;

    // RLE8头部: w(2), h(2), xs(2), ys(2)
    int16_t w = *(const int16_t*)(data);
    int16_t h = *(const int16_t*)(data + 2);
    int16_t xs = *(const int16_t*)(data + 4);
    int16_t ys = *(const int16_t*)(data + 6);
    data += 8;

    int pixdepth = 0;
    int curdepth = 0;
    int total = 0;

    if (Image == nullptr)
    {
        Image = screen;
    }
    if (!Image)
    {
        return;
    }

    // 确定绘制区域
    SDL_Rect area;
    if (RectArea != nullptr)
    {
        area = *(const SDL_Rect*)RectArea;
    }
    else
    {
        area.x = 0;
        area.y = 0;
        area.w = Image->w;
        area.h = Image->h;
    }

    // 读取遮挡偏移
    int blockx = 0, blocky = 0;
    if (BlockPosition != nullptr)
    {
        blockx = *(const int*)(BlockPosition);
        blocky = *(const int*)(BlockPosition + 4);
    }

    // 预解析混合色
    bool hasMixColor = (Image == screen) && (mixAlpha != 0);
    uint8_t mixColor1 = 0, mixColor2 = 0, mixColor3 = 0, mixColor4 = 0;
    if (hasMixColor)
    {
        SDL_GetRGBA(mixColor, SDL_GetPixelFormatDetails(screen->format),
            SDL_GetSurfacePalette(screen),
            &mixColor1, &mixColor2, &mixColor3, &mixColor4);
    }

    int alpha1 = (alpha >> 8) & 0xFF;

    // 边界检查
    if ((w <= 1 && h <= 1) || (px - xs + w < area.x) || (px - xs >= area.x + area.w) || (py - ys + h < area.y) || (py - ys >= area.y + area.h))
    {
        return;
    }

    const uint8_t* colPanel = (const uint8_t*)colorPanel;

    // 逐行解码
    for (int iy = 1; iy <= h; iy++)
    {
        int l = *data;    // 本行entry数量 (1字节)
        data++;
        int ww = 1;    // 当前列位置, 从1开始
        int p = 0;     // 状态: 0=读跳过, 1=读像素数, >=2=逐像素绘制

        for (int ix = 1; ix <= l; ix++)
        {
            int l1 = *data;
            data++;

            if (p == 0)
            {
                // 跳过l1个空白像素
                ww = ww + l1;
                p = 1;
            }
            else if (p == 1)
            {
                // 接下来有l1个像素数据
                p = 2 + l1;
            }
            else if (p > 2)
            {
                p = p - 1;
                // l1是颜色索引, 绘制像素
                int x = ww - xs + px;
                int y = iy - ys + py;
                if (x >= area.x && y >= area.y && x < area.x + area.w && y < area.y + area.h)
                {
                    uint8_t pix1 = colPanel[l1 * 3] * (4 + shadow);
                    uint8_t pix2 = colPanel[l1 * 3 + 1] * (4 + shadow);
                    uint8_t pix3 = colPanel[l1 * 3 + 2] * (4 + shadow);
                    uint8_t pix4 = 0;

                    if (Image == screen)
                    {
                        // 画到屏幕
                        if (hasMixColor)
                        {
                            // BlendRGBAByPercent: r = BlendByte(srcR, r, percent)
                            pix1 = (uint8_t)((mixAlpha * mixColor1 + (100 - mixAlpha) * pix1) / 100);
                            pix2 = (uint8_t)((mixAlpha * mixColor2 + (100 - mixAlpha) * pix2) / 100);
                            pix3 = (uint8_t)((mixAlpha * mixColor3 + (100 - mixAlpha) * pix3) / 100);
                            pix4 = (uint8_t)((mixAlpha * mixColor4 + (100 - mixAlpha) * pix4) / 100);
                        }

                        int isAlpha = 0;
                        if (alpha != 0)
                        {
                            if (BlockImageW == nullptr)
                            {
                                isAlpha = 1;
                            }
                            else
                            {
                                // 需要遮挡判断
                                int bx = x + blockx;
                                int by = y + blocky;
                                if (bx >= 0 && bx < widthW && by >= 0 && by < heightW)
                                {
                                    pixdepth = *(const int16_t*)(BlockImageW + (bx * heightW + by) * sizeW);
                                    curdepth = depth;
                                    if (pixdepth >= curdepth)
                                    {
                                        isAlpha = 1;
                                    }
                                    else
                                    {
                                        isAlpha = 0;
                                    }
                                }
                            }

                            if (isAlpha == 1 && alpha < 100)
                            {
                                uint32_t colorin = GetPixel(screen, x, y);
                                uint8_t color1, color2, color3, color4;
                                SDL_GetRGBA(colorin, SDL_GetPixelFormatDetails(screen->format),
                                    SDL_GetSurfacePalette(screen),
                                    &color1, &color2, &color3, &color4);
                                // BlendRGBAByPercent(pix, color, alpha)
                                int a = alpha;
                                pix1 = (uint8_t)((a * color1 + (100 - a) * pix1) / 100);
                                pix2 = (uint8_t)((a * color2 + (100 - a) * pix2) / 100);
                                pix3 = (uint8_t)((a * color3 + (100 - a) * pix3) / 100);
                                pix4 = (uint8_t)((a * color4 + (100 - a) * pix4) / 100);
                            }

                            if (isAlpha == 0 && alpha1 > 0 && alpha1 <= 100)
                            {
                                uint32_t colorin = GetPixel(screen, x, y);
                                uint8_t color1, color2, color3, color4;
                                SDL_GetRGBA(colorin, SDL_GetPixelFormatDetails(screen->format),
                                    SDL_GetSurfacePalette(screen),
                                    &color1, &color2, &color3, &color4);
                                pix1 = (uint8_t)((alpha1 * color1 + (100 - alpha1) * pix1) / 100);
                                pix2 = (uint8_t)((alpha1 * color2 + (100 - alpha1) * pix2) / 100);
                                pix3 = (uint8_t)((alpha1 * color3 + (100 - alpha1) * pix3) / 100);
                                pix4 = (uint8_t)((alpha1 * color4 + (100 - alpha1) * pix4) / 100);
                            }
                        }

                        uint32_t pix = SDL_MapSurfaceRGBA(screen, pix1, pix2, pix3, 255);
                        if (alpha < 100 || pixdepth <= curdepth)
                        {
                            PutPixel(screen, x, y, pix);
                            total++;
                            if (totalpix > 0 && total >= totalpix)
                            {
                                return;
                            }
                        }
                    }
                    else
                    {
                        // 画到映像Image
                        if (x < widthI && y < heightI)
                        {
                            if (BlockImageW != nullptr)
                            {
                                *(int16_t*)(BlockImageW + (x * heightI + y) * sizeI) = (int16_t)depth;
                            }
                            uint32_t pix = SDL_MapSurfaceRGBA(screen, pix1, pix2, pix3, 255);
                            PutPixel(Image, x, y, pix);
                            total++;
                            if (totalpix > 0 && total >= totalpix)
                            {
                                return;
                            }
                        }
                    }
                }
                ww = ww + 1;
                if (p == 2)
                {
                    p = 0;
                }
            }
        }
    }
}

TPosition GetPositionOnScreen(int x, int y, int CenterX, int CenterY)
{
    TPosition p;
    p.x = -(x - CenterX) * 18 + (y - CenterY) * 18 + CENTER_X;
    p.y = (x - CenterX) * 9 + (y - CenterY) * 9 + CENTER_Y;
    return p;
}

// ---- 文字编码 ----

std::string cp950toutf8(const char* str, int len)
{
    if (!str)
    {
        return "";
    }
    int slen = (len < 0) ? (int)strlen(str) : len;
    if (slen == 0)
    {
        return "";
    }
    return PotConv::cp950toutf8(std::string(str));    //这里暂时不处理len参数了，后续如果有需要再加上
}

std::string utf8tocp950(const std::string& str)
{
    if (str.empty())
    {
        return "";
    }
    return PotConv::conv(str, "utf-8", "cp950");
}

// ---- 文字绘制 ----

int utf8follow(char c1)
{
    uint8_t c = (uint8_t)c1;
    if (c < 0x80)
    {
        return 1;
    }
    if (c < 0xC0)
    {
        return 1;
    }
    if (c < 0xE0)
    {
        return 2;
    }
    if (c < 0xF0)
    {
        return 3;
    }
    return 4;
}

// ---- HiRes 文字渲染 ----

static void ClearHiResGlyphCaches()
{
    for (auto& [k, surf] : FontsHr)
    {
        SDL_DestroySurface(surf);
    }
    FontsHr.clear();

    for (auto& [k, tex] : fonts_hr_tex)
    {
        SDL_DestroyTexture(tex);
    }
    fonts_hr_tex.clear();

    HiResTextRenderOk = false;
}

static void EnsureHiResFonts(double scaleY)
{
    if (scaleY <= 0)
        scaleY = 1;
    int newCn = std::max(1, (int)std::round(CHINESE_FONT_SIZE * scaleY));
    int newEn = std::max(1, (int)std::round(ENGLISH_FONT_SIZE * scaleY));
    bool needResetCache = false;

    if (FontHR && FontHRSize != newCn)
    {
        TTF_CloseFont(FontHR);
        FontHR = nullptr;
        needResetCache = true;
    }
    if (EngFontHR && EngFontHRSize != newEn)
    {
        TTF_CloseFont(EngFontHR);
        EngFontHR = nullptr;
        needResetCache = true;
    }
    if (!FontHR && FontHRSize != newCn)
        needResetCache = true;
    if (!EngFontHR && EngFontHRSize != newEn)
        needResetCache = true;

    if (needResetCache)
        ClearHiResGlyphCaches();

    if (needResetCache)
    {
        FontHRSize = 0;
        EngFontHRSize = 0;
    }
    if (!FontHR)
    {
        std::string str = checkFileName(CHINESE_FONT);
        FontHR = TTF_OpenFont(str.c_str(), newCn);
        FontHRSize = newCn;
    }
    if (!EngFontHR)
    {
        std::string str = checkFileName(ENGLISH_FONT);
        EngFontHR = TTF_OpenFont(str.c_str(), newEn);
        EngFontHRSize = newEn;
    }
}

static void GetHiResGlyphTexture(int k, TTF_Font* fontObj, const char* pText, int textLen,
    const SDL_Color& tempcolor, SDL_Texture*& textTex, int& glyphW, int& glyphH)
{
    textTex = nullptr;
    glyphW = 0;
    glyphH = 0;

    SDL_Surface* textSurf = nullptr;
    auto itSurf = FontsHr.find(k);
    if (itSurf == FontsHr.end())
    {
        textSurf = TTF_RenderText_Blended(fontObj, pText, textLen, tempcolor);
        if (textSurf)
            FontsHr[k] = textSurf;
        else
            return;
    }
    else
    {
        textSurf = itSurf->second;
    }
    glyphW = textSurf->w;
    glyphH = textSurf->h;

    auto itTex = fonts_hr_tex.find(k);
    if (itTex == fonts_hr_tex.end())
    {
        textTex = SDL_CreateTextureFromSurface(render, textSurf);
        if (textTex)
            fonts_hr_tex[k] = textTex;
    }
    else
    {
        textTex = itTex->second;
    }
}

static void QueueTextForHiRes(const std::string& word, int x_pos, int y_pos, uint32_t color, int adx = 0)
{
    TextQueue.push_back({ word, x_pos, y_pos, color, adx });
}

static void RenderQueuedHiResText(int updateX, int updateY, int updateW, int updateH)
{
    if (TextQueue.empty())
        return;
    if (HIRES_TEXT == 0 || !render)
        return;

    int curW, curH;
    SDL_GetWindowSize(window, &curW, &curH);
    if (curW > 0 && curH > 0)
    {
        RESOLUTIONX = curW;
        RESOLUTIONY = curH;
    }
    double scaleX = RESOLUTIONX / (double)(CENTER_X * 2);
    double scaleY = RESOLUTIONY / (double)(CENTER_Y * 2);
    if (scaleX <= 0) scaleX = 1;
    if (scaleY <= 0) scaleY = 1;
    int stepX = std::max(1, (int)std::round(10 * scaleX));

    EnsureHiResFonts(scaleY);
    if (!FontHR || !EngFontHR)
        return;

    SDL_Color tempcolor = { 255, 255, 255, 255 };
    bool renderSucceeded = false;
    std::vector<QueuedText> remainQueue;

    for (size_t idx = 0; idx < TextQueue.size(); idx++)
    {
        std::string word = TextQueue[idx].word;
        if (SIMPLE == 1)
            word = Traditional2Simplified(word);
        int len = (int)word.size();
        if (len == 0)
            continue;

        int queueX = TextQueue[idx].x_pos;
        int queueY = TextQueue[idx].y_pos;
        int queueW = DrawLength(word) * 10 + 20;
        int queueH = 24;
        if (queueX + queueW <= updateX || queueX >= updateX + updateW ||
            queueY + queueH <= updateY || queueY >= updateY + updateH)
        {
            remainQueue.push_back(TextQueue[idx]);
            continue;
        }

        int drawX = (int)std::round(TextQueue[idx].x_pos * scaleX) + TextQueue[idx].screen_dx;
        int i = 0;
        while (i < len)
        {
            uint8_t c = (uint8_t)word[i];
            int advanceUnits = 1;
            SDL_Texture* textTex = nullptr;
            int glyphW = 0, glyphH = 0;
            int drawY = 0;

            if (c > 32 && c < 128)
            {
                // ASCII字符
                int k = c;
                char buf[2] = { (char)c, 0 };
                GetHiResGlyphTexture(k, EngFontHR, buf, 1, tempcolor, textTex, glyphW, glyphH);
                drawY = (int)std::round((TextQueue[idx].y_pos + 2) * scaleY);
                i += 1;
            }
            else if (c >= 0xC0 && c < 0xE0 && i + 1 < len)
            {
                // 2字节UTF-8
                char buf[3] = { word[i], word[i + 1], 0 };
                int k = (uint8_t)word[i] + 256 * (uint8_t)word[i + 1];
                GetHiResGlyphTexture(k, FontHR, buf, 2, tempcolor, textTex, glyphW, glyphH);
                drawY = (int)std::round(TextQueue[idx].y_pos * scaleY);
                i += 2;
            }
            else if (c >= 0xE0 && i + 2 < len)
            {
                // 3字节UTF-8 (CJK等)
                char buf[4] = { word[i], word[i + 1], word[i + 2], 0 };
                int k = (uint8_t)word[i] + 256 * (uint8_t)word[i + 1] + 65536 * (uint8_t)word[i + 2];
                GetHiResGlyphTexture(k, FontHR, buf, 3, tempcolor, textTex, glyphW, glyphH);
                drawY = (int)std::round(TextQueue[idx].y_pos * scaleY);
                advanceUnits = 2;
                i += 3;
            }
            else
            {
                i += 1;
            }

            if (textTex)
            {
                uint8_t r, g, b;
                SDL_GetRGB(TextQueue[idx].color, SDL_GetPixelFormatDetails(screen->format),
                    SDL_GetSurfacePalette(screen), &r, &g, &b);
                SDL_FRect src = { 0, 0, (float)glyphW, (float)glyphH };
                SDL_FRect dest = { (float)drawX, (float)drawY, (float)glyphW, (float)glyphH };
                SDL_SetTextureColorMod(textTex, r, g, b);
                SDL_SetTextureBlendMode(textTex, SDL_BLENDMODE_BLEND);
                SDL_SetTextureAlphaMod(textTex, 255);
                SDL_RenderTexture(render, textTex, &src, &dest);
                renderSucceeded = true;
            }

            drawX += stepX * advanceUnits;
        }
    }

    TextQueue = std::move(remainQueue);
    HiResTextRenderOk = renderSucceeded;
}

void DrawText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color)
{
    if (!sur || word.empty() || !ChineseFont)
    {
        return;
    }
    if (HIRES_TEXT != 0 && sur == screen)
    {
        QueueTextForHiRes(word, x_pos, y_pos, color);
        if (HiResTextRenderOk)
            return;
    }
    std::string text = word;
    if (SIMPLE == 1)
    {
        text = Traditional2Simplified(text);
    }

    uint8_t r, g, b;
    SDL_GetRGB(color, SDL_GetPixelFormatDetails(sur->format), SDL_GetSurfacePalette(sur), &r, &g, &b);

    int len = (int)text.size();
    int i = 0;
    while (i < len)
    {
        uint8_t c = (uint8_t)text[i];

        if (c > 32 && c < 128)
        {
            // ASCII字符 - 使用EnglishFont
            int k = c;
            auto it = fonts.find(k);
            if (it == fonts.end())
            {
                SDL_Color white = { 255, 255, 255, 255 };
                char buf[2] = { (char)c, 0 };
                SDL_Surface* glyph = TTF_RenderText_Blended(EnglishFont, buf, 1, white);
                if (glyph)
                {
                    fonts[k] = glyph;
                }
                it = fonts.find(k);
            }
            if (it != fonts.end())
            {
                SDL_Surface* glyph = it->second;
                SDL_SetSurfaceColorMod(glyph, r, g, b);
                SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_BLEND);
                SDL_SetSurfaceAlphaMod(glyph, 255);
                SDL_Rect dst;
                dst.x = x_pos;
                dst.y = y_pos + 2;
                SDL_BlitSurface(glyph, nullptr, sur, &dst);
            }
            x_pos += 10;
            i += 1;
        }
        else if (c >= 0xC0 && c < 0xE0 && i + 1 < len)
        {
            // 2字节UTF-8
            int k = (uint8_t)text[i] + 256 * (uint8_t)text[i + 1];
            auto it = fonts.find(k);
            if (it == fonts.end())
            {
                SDL_Color white = { 255, 255, 255, 255 };
                char buf[3] = { text[i], text[i + 1], 0 };
                SDL_Surface* glyph = TTF_RenderText_Blended(ChineseFont, buf, 2, white);
                if (glyph)
                {
                    fonts[k] = glyph;
                }
                it = fonts.find(k);
            }
            if (it != fonts.end())
            {
                SDL_Surface* glyph = it->second;
                SDL_SetSurfaceColorMod(glyph, r, g, b);
                SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_BLEND);
                SDL_SetSurfaceAlphaMod(glyph, 255);
                SDL_Rect dst;
                dst.x = x_pos;
                dst.y = y_pos;
                SDL_BlitSurface(glyph, nullptr, sur, &dst);
            }
            x_pos += 10;
            i += 2;
        }
        else if (c >= 0xE0 && i + 2 < len)
        {
            // 3字节UTF-8 (CJK等)
            int k = (uint8_t)text[i] + 256 * (uint8_t)text[i + 1] + 65536 * (uint8_t)text[i + 2];
            auto it = fonts.find(k);
            if (it == fonts.end())
            {
                SDL_Color white = { 255, 255, 255, 255 };
                char buf[4] = { text[i], text[i + 1], text[i + 2], 0 };
                SDL_Surface* glyph = TTF_RenderText_Blended(ChineseFont, buf, 3, white);
                if (glyph)
                {
                    fonts[k] = glyph;
                }
                it = fonts.find(k);
            }
            if (it != fonts.end())
            {
                SDL_Surface* glyph = it->second;
                SDL_SetSurfaceColorMod(glyph, r, g, b);
                SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_BLEND);
                SDL_SetSurfaceAlphaMod(glyph, 255);
                SDL_Rect dst;
                dst.x = x_pos;
                dst.y = y_pos;
                SDL_BlitSurface(glyph, nullptr, sur, &dst);
            }
            x_pos += 20;
            i += 3;
        }
        else
        {
            // 空格或控制字符, 仅前进
            x_pos += 10;
            i += 1;
        }
    }
}

void DrawEngText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color)
{
    DrawText(sur, word, x_pos, y_pos + 2, color);
}

void DrawShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2)
{
    if (HIRES_TEXT != 0 && sur == screen)
    {
        QueueTextForHiRes(word, x_pos, y_pos, color2, 1);
        QueueTextForHiRes(word, x_pos, y_pos, color1, 0);
        return;
    }
    DrawText(sur, word, x_pos + 1, y_pos, color2);
    DrawText(sur, word, x_pos, y_pos, color1);
}

void DrawShadowText(const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2)
{
    DrawShadowText(screen, word, x_pos, y_pos, color1, color2);
}

void DrawEngShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2)
{
    DrawShadowText(sur, word, x_pos, y_pos, color1, color2);
}

void DrawBig5Text(SDL_Surface* sur, const char* str, int x_pos, int y_pos, uint32_t color)
{
    std::string utf8 = cp950toutf8(str);
    DrawText(sur, utf8, x_pos, y_pos, color);
}

void DrawBig5ShadowText(SDL_Surface* sur, const char* word, int x_pos, int y_pos, uint32_t color1, uint32_t color2)
{
    std::string utf8 = cp950toutf8(word);
    if (HIRES_TEXT != 0 && sur == screen)
    {
        QueueTextForHiRes(utf8, x_pos, y_pos, color2, 1);
        QueueTextForHiRes(utf8, x_pos, y_pos, color1, 0);
        return;
    }
    DrawText(sur, utf8, x_pos + 1, y_pos, color2);
    DrawText(sur, utf8, x_pos, y_pos, color1);
}

void DrawTextWithRect(const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2)
{
    DrawTextWithRect(screen, word, x, y, w, color1, color2);
}

void DrawTextWithRect(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2)
{
    if (w < 0)
    {
        w = DrawLength(word) * 10 + 7;
    }
    DrawRectangle(sur, x, y, w, 28, 0, ColColor(0xFF), 50);
    DrawShadowText(sur, word, x + 3, y + 3, color1, color2);
    if (HIRES_TEXT == 0 || sur == screen)
        UpdateScreen(sur, x, y, w + 1, 29);
}

void DrawTextWithRectNoUpdate(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2)
{
    if (w < 0)
    {
        w = DrawLength(word) * 10 + 7;
    }
    DrawRectangle(sur, x, y, w, 28, 0, ColColor(0xFF), 50);
    DrawShadowText(sur, word, x + 3, y + 3, color1, color2);
}

// ---- PNG贴图 (桩实现) ----
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py) {}
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py,
    int shadow, int alpha, uint32_t mixColor, int mixAlpha) {}
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py,
    int shadow, int alpha, uint32_t mixColor, int mixAlpha, int depth,
    char* BlockImgR, int Width, int Height, int size, int leftupx, int leftupy) {}

// ---- 屏幕管理 ----

static void EnsureCompositeTex()
{
    if (compositeTex && compositeTexW == RESOLUTIONX && compositeTexH == RESOLUTIONY)
    {
        return;
    }
    if (compositeTex)
    {
        SDL_DestroyTexture(compositeTex);
    }
    compositeTex = SDL_CreateTexture(render, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_TARGET, RESOLUTIONX, RESOLUTIONY);
    compositeTexW = RESOLUTIONX;
    compositeTexH = RESOLUTIONY;
    // 创建时清空为透明
    SDL_SetRenderTarget(render, compositeTex);
    SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(render, 0, 0, 0, 0);
    SDL_RenderClear(render);
    SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_BLEND);
    SDL_SetRenderTarget(render, nullptr);
}

void UpdateScreen(SDL_Surface* scr1, int x, int y, int w, int h)
{
    if (!render || !scr1)
    {
        return;
    }

    SDL_Rect dest = { x, y, w, h };
    if (w <= 0) dest.w = CENTER_X * 2;
    if (h <= 0) dest.h = CENTER_Y * 2;

    if (scr1 == screen)
    {
        // 上传脏矩形到 screenTex
        void* p = (void*)((uintptr_t)screen->pixels + y * screen->pitch + x * 4);
        SDL_UpdateTexture(screenTex, &dest, p, screen->pitch);

        // 同步窗口大小
        int curW, curH;
        SDL_GetWindowSize(window, &curW, &curH);
        if (curW > 0 && curH > 0)
        {
            RESOLUTIONX = curW;
            RESOLUTIONY = curH;
        }

        // 合成高清文字覆盖层
        EnsureCompositeTex();
        SDL_SetRenderTarget(render, compositeTex);
        double scaleX = RESOLUTIONX / (double)(CENTER_X * 2);
        double scaleY = RESOLUTIONY / (double)(CENTER_Y * 2);
        if (scaleX <= 0) scaleX = 1;
        if (scaleY <= 0) scaleY = 1;
        SDL_FRect clearFRect;
        clearFRect.x = (float)(dest.x * scaleX);
        clearFRect.y = (float)(dest.y * scaleY);
        clearFRect.w = (float)(dest.w * scaleX);
        clearFRect.h = (float)(dest.h * scaleY);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(render, 0, 0, 0, 0);
        SDL_RenderFillRect(render, &clearFRect);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_BLEND);
        RenderQueuedHiResText(dest.x, dest.y, dest.w, dest.h);
        SDL_SetRenderTarget(render, nullptr);

        // 最终渲染呈现
        SDL_RenderTexture(render, screenTex, nullptr, nullptr);
        SDL_SetTextureBlendMode(compositeTex, SDL_BLENDMODE_BLEND);
        SDL_RenderTexture(render, compositeTex, nullptr, nullptr);
        SDL_RenderPresent(render);
    }
}

void UpdateAllScreen()
{
    if (screen)
    {
        UpdateScreen(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2);
    }
}

void TransBlackScreen()
{
    DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 50);
}

void ResizeWindow(int w, int h)
{
    RESOLUTIONX = w;
    RESOLUTIONY = h;
}

void SwitchFullscreen()
{
    // Pascal版未实现
}

void SDL_GetMouseState2(int& x, int& y)
{
    float fx, fy;
    SDL_GetMouseState(&fx, &fy);
    x = (int)(fx * screen->w / RESOLUTIONX + 0.5f);
    y = (int)(fy * screen->h / RESOLUTIONY + 0.5f);
}

void GetMousePosition(int& x, int& y, int x0, int y0, int yp)
{
    int x1, y1;
    SDL_GetMouseState2(x1, y1);
    x = (-x1 + CENTER_X + 2 * (y1 + yp) - 2 * CENTER_Y + 18) / 36 + x0;
    y = (x1 - CENTER_X + 2 * (y1 + yp) - 2 * CENTER_Y + 18) / 36 + y0;
}

bool MouseInRegion(int x, int y, int w, int h)
{
    int mx, my;
    SDL_GetMouseState2(mx, my);
    return mx >= x && mx < x + w && my >= y && my < y + h;
}

bool MouseInRegion(int x, int y, int w, int h, int& x1, int& y1)
{
    SDL_GetMouseState2(x1, y1);
    return x1 >= x && x1 < x + w && y1 >= y && y1 < y + h;
}

void CleanKeyValue()
{
    event.key.key = 0;
    event.button.button = 0;
}

// ---- 事件处理 ----

static bool inReturn(int x, int y)
{
    return InRegion(x, y, VirtualAX, VirtualAY, 100, 100);
}

static bool inEscape(int x, int y)
{
    return InRegion(x, y, VirtualBX, VirtualBY, 100, 100);
}

static uint32_t inVirtualKey(int x, int y, uint32_t& key)
{
    uint32_t result = 0;
    if (InRegion(x, y, CENTER_X * 2 - 200, CENTER_Y * 2 - 200, 200, 200))
    {
        result = SDLK_TAB;
    }
    if (InRegion(x, y, 0, VirtualCrossY, VirtualKeySize * 2 + VirtualCrossX, CENTER_Y * 2 - VirtualCrossY))
    {
        result = SDLK_TAB;
    }
    if (InRegion(x, y, VirtualCrossX, VirtualCrossY, VirtualKeySize, VirtualKeySize))
    {
        result = SDLK_UP;
    }
    if (InRegion(x, y, VirtualCrossX - VirtualKeySize, VirtualCrossY + VirtualKeySize, VirtualKeySize, VirtualKeySize))
    {
        result = SDLK_LEFT;
    }
    if (InRegion(x, y, VirtualCrossX, VirtualCrossY + VirtualKeySize * 2, VirtualKeySize, VirtualKeySize))
    {
        result = SDLK_DOWN;
    }
    if (InRegion(x, y, VirtualCrossX + VirtualKeySize, VirtualCrossY + VirtualKeySize, VirtualKeySize, VirtualKeySize))
    {
        result = SDLK_RIGHT;
    }
    key = result;
    return result;
}

bool EventFilter(void* p, SDL_Event* e)
{
    switch (e->type)
    {
    case SDL_EVENT_FINGER_UP:
    case SDL_EVENT_FINGER_DOWN:
    case SDL_EVENT_GAMEPAD_AXIS_MOTION:
    case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
    case SDL_EVENT_GAMEPAD_BUTTON_UP:
        return false;
    case SDL_EVENT_FINGER_MOTION:
        if (CellPhone == 0)
        {
            return false;
        }
        return true;
    case SDL_EVENT_DID_ENTER_FOREGROUND:
        PlayMP3(NowMusic, -1, 0);
        return true;
    case SDL_EVENT_DID_ENTER_BACKGROUND:
        StopMP3();
        return true;
    }
    return true;
}

uint32_t CheckBasicEvent()
{
    // 刷掉无用事件
    SDL_FlushEvent(SDL_EVENT_MOUSE_WHEEL);
    SDL_FlushEvent(SDL_EVENT_JOYSTICK_AXIS_MOTION);
    SDL_FlushEvent(SDL_EVENT_FINGER_MOTION);
    if (CellPhone == 1)
    {
        SDL_FlushEvent(SDL_EVENT_MOUSE_MOTION);
    }

    uint32_t result = event.type;
    switch (event.type)
    {
    case SDL_EVENT_JOYSTICK_BUTTON_UP:
        event.type = SDL_EVENT_KEY_UP;
        if (event.jbutton.button == JOY_ESCAPE)
        {
            event.key.key = SDLK_ESCAPE;
        }
        else if (event.jbutton.button == JOY_RETURN)
        {
            event.key.key = SDLK_RETURN;
        }
        else if (event.jbutton.button == JOY_UP)
        {
            event.key.key = SDLK_UP;
        }
        else if (event.jbutton.button == JOY_DOWN)
        {
            event.key.key = SDLK_DOWN;
        }
        else if (event.jbutton.button == JOY_LEFT)
        {
            event.key.key = SDLK_LEFT;
        }
        else if (event.jbutton.button == JOY_RIGHT)
        {
            event.key.key = SDLK_RIGHT;
        }
        break;
    case SDL_EVENT_JOYSTICK_BUTTON_DOWN:
        event.type = SDL_EVENT_KEY_DOWN;
        if (event.jbutton.button == JOY_UP)
        {
            event.key.key = SDLK_UP;
        }
        else if (event.jbutton.button == JOY_DOWN)
        {
            event.key.key = SDLK_DOWN;
        }
        else if (event.jbutton.button == JOY_LEFT)
        {
            event.key.key = SDLK_LEFT;
        }
        else if (event.jbutton.button == JOY_RIGHT)
        {
            event.key.key = SDLK_RIGHT;
        }
        break;
    case SDL_EVENT_QUIT:
        QuitConfirm();
        break;
    case SDL_EVENT_WINDOW_RESIZED:
        ResizeWindow(event.window.data1, event.window.data2);
        UpdateAllScreen();
        break;
    case SDL_EVENT_DID_ENTER_FOREGROUND:
        PlayMP3(NowMusic, -1, 0);
        break;
    case SDL_EVENT_DID_ENTER_BACKGROUND:
        StopMP3(0);
        break;
    case SDL_EVENT_FINGER_MOTION:
        if (CellPhone == 1)
        {
            if (event.tfinger.fingerID == 1)
            {
                uint32_t msCount = SDL_GetTicks() - FingerTick;
                uint32_t msWait = 50;
                if (BattleSelecting)
                {
                    msWait = 100;
                }
                if (msCount > 500)
                {
                    FingerCount = 1;
                }
                if ((FingerCount <= 2 && msCount > 200) || (FingerCount > 2 && msCount > msWait))
                {
                    FingerCount++;
                    FingerTick = SDL_GetTicks();
                    event.type = SDL_EVENT_KEY_DOWN;
                    event.key.key = AngleToDirection(event.tfinger.dy, event.tfinger.dx);
                }
            }
        }
        break;
    case SDL_EVENT_MOUSE_MOTION:
        if (CellPhone == 1)
        {
            FingerCount = 0;
            int mx, my;
            SDL_GetMouseState2(mx, my);
            if (inEscape(mx, my) || inReturn(mx, my))
            {
                event.type = 0;
            }
            inVirtualKey(mx, my, VirtualKeyValue);
        }
        break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
        if (CellPhone == 1 && ShowVirtualKey != 0)
        {
            int mx, my;
            SDL_GetMouseState2(mx, my);
            inVirtualKey(mx, my, VirtualKeyValue);
            if (VirtualKeyValue != 0)
            {
                event.type = SDL_EVENT_KEY_DOWN;
                event.key.key = VirtualKeyValue;
            }
        }
        break;
    case SDL_EVENT_KEY_UP:
    case SDL_EVENT_MOUSE_BUTTON_UP:
        if (CellPhone == 1 && event.type == SDL_EVENT_MOUSE_BUTTON_UP && event.button.button == SDL_BUTTON_LEFT)
        {
            int mx, my;
            SDL_GetMouseState2(mx, my);
            if (inEscape(mx, my))
            {
                event.button.button = SDL_BUTTON_RIGHT;
                event.key.key = SDLK_ESCAPE;
                kyslog("Change to escape");
            }
            else if (inReturn(mx, my))
            {
                event.type = SDL_EVENT_KEY_UP;
                event.key.key = SDLK_RETURN;
                kyslog("Change to return");
            }
            else if (ShowVirtualKey != 0 && inVirtualKey(mx, my, VirtualKeyValue) != 0)
            {
                if (VirtualKeyValue != 0)
                {
                    event.type = SDL_EVENT_KEY_UP;
                    event.key.key = VirtualKeyValue;
                }
            }
            else if (Where == 2 && BattleSelecting)
            {
                event.button.button = 0;
            }
            if (FingerCount >= 1)
            {
                event.button.button = 0;
            }
        }
        if (event.key.key == SDLK_KP_ENTER)
        {
            event.key.key = SDLK_RETURN;
        }
        break;
    }
    return result;
}

void QuitConfirm()
{
    if (EXIT_GAME == 0 || AskingQuit)
    {
        Quit();
        return;
    }
    if (AskingQuit)
    {
        return;
    }
    AskingQuit = true;
    SDL_Surface* tempscr = SDL_ConvertSurface(screen, screen->format);
    SDL_BlitSurface(tempscr, nullptr, screen, nullptr);
    DrawRectangleWithoutFrame(screen, 0, 0, screen->w, screen->h, 0, 50);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    std::string menuStr[2] = { "取消", "確認" };
    if (CommonMenu(CENTER_X * 2 - 50, 2, 45, 1, menuStr) == 1)
    {
        Quit();
    }
    Redraw();
    SDL_BlitSurface(tempscr, nullptr, screen, nullptr);
    UpdateScreen(screen, 0, 0, screen->w, screen->h);
    SDL_DestroySurface(tempscr);
    AskingQuit = false;
}

int AngleToDirection(double y, double x)
{
    double angle = atan2(y, x) * 180.0 / M_PI;
    if (angle < 0)
    {
        angle += 360;
    }
    if (angle < 45)
    {
        return 2;
    }
    if (angle < 135)
    {
        return 0;
    }
    if (angle < 225)
    {
        return 3;
    }
    if (angle < 315)
    {
        return 1;
    }
    return 2;
}

// ---- 辅助函数 ----

int DrawLength(const std::string& str)
{
    int len = 0;
    int i = 0;
    int slen = (int)str.size();
    while (i < slen)
    {
        int charlen = utf8follow(str[i]);
        len += (charlen >= 3) ? 2 : 1;
        i += charlen;
    }
    return len;
}

int DrawLength(const char* p)
{
    if (!p)
    {
        return 0;
    }
    return DrawLength(std::string(p));
}

void swap(uint32_t& x, uint32_t& y)
{
    uint32_t t = x;
    x = y;
    y = t;
}

int RegionParameter(int x, int x1, int x2)
{
    if (x < x1)
    {
        return x1;
    }
    if (x > x2)
    {
        return x2;
    }
    return x;
}

void QuickSortB(TBuildInfo* a, int l, int r)
{
    if (l >= r)
    {
        return;
    }
    int i = l, j = r;
    TBuildInfo pivot = a[(l + r) / 2];
    while (i <= j)
    {
        while (a[i].c < pivot.c)
        {
            i++;
        }
        while (a[j].c > pivot.c)
        {
            j--;
        }
        if (i <= j)
        {
            TBuildInfo tmp = a[i];
            a[i] = a[j];
            a[j] = tmp;
            i++;
            j--;
        }
    }
    if (l < j)
    {
        QuickSortB(a, l, j);
    }
    if (i < r)
    {
        QuickSortB(a, i, r);
    }
}

void ClearQueuedHiResText()
{
    TextQueue.clear();
    if (compositeTex && render)
    {
        SDL_SetRenderTarget(render, compositeTex);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(render, 0, 0, 0, 0);
        SDL_RenderClear(render);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_BLEND);
        SDL_SetRenderTarget(render, nullptr);
    }
}

void ChangeCol()
{
    uint32_t now = SDL_GetTicks();
    if (NIGHT_EFFECT == 1)
    {
        NowTime += 0.3;
        if (NowTime > 1440)
        {
            NowTime = 0;
        }
        double p = NowTime / 1440.0;
        if (p > 0.5)
        {
            p = 1.0 - p;
        }
        double p0 = 0.6 + p;
        double p1 = 0.6 + p;
        double p2 = 1.0 - 0.4 / 1.3 + p / 1.3;
        for (int i = 0; i < 256; i++)
        {
            int b = i * 3;
            ACol1[b] = (uint8_t)std::min((int)(ACol2[b] * p0), 63);
            ACol1[b + 1] = (uint8_t)std::min((int)(ACol2[b + 1] * p1), 63);
            ACol1[b + 2] = (uint8_t)std::min((int)(ACol2[b + 2] * p2), 63);
        }
        memcpy(ACol, ACol1, 768);
    }

    int add0 = 0xE0;
    int len = 8;
    int a = now / 200 % len;
    memcpy(ACol + add0 * 3 + a * 3, ACol1 + add0 * 3, (len - a) * 3);
    memcpy(ACol + add0 * 3, ACol1 + add0 * 3 + (len - a) * 3, a * 3);

    add0 = 0xF4;
    len = 9;
    a = now / 200 % len;
    memcpy(ACol + add0 * 3 + a * 3, ACol1 + add0 * 3, (len - a) * 3);
    memcpy(ACol + add0 * 3, ACol1 + add0 * 3 + (len - a) * 3, a * 3);
}

// ---- 简繁转换 ----

std::string Simplified2Traditional(const std::string& str)
{
    if (!sccS2T_loaded)
    {
        sccS2T.init({ checkFileName("cc/STCharacters.txt"), checkFileName("cc/STPhrases.txt") });
        sccS2T_loaded = true;
    }
    return sccS2T.conv(str);
}

std::string Traditional2Simplified(const std::string& str)
{
    if (!sccT2S_loaded)
    {
        sccT2S.init({ checkFileName("cc/TSCharacters.txt"), checkFileName("cc/TSPhrases.txt") });
        sccT2S_loaded = true;
    }
    return sccT2S.conv(str);
}

// ---- 调试 ----

void tic()
{
    tic_time = SDL_GetTicksNS();
}

void toc()
{
    uint64_t now = SDL_GetTicksNS();
    kyslog("toc: %llu ms", (unsigned long long)(now - tic_time) / 1000000);
}

void kyslog(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
    fflush(stdout);
}

std::string checkFileName(const std::string& f)
{
    std::string result = AppPath + f;
    if (!filefunc::fileExist(result))
    {
        result = AppPathCommon + f;
    }
    return result;
}

bool InRegion(int x1, int y1, int x, int y, int w, int h)
{
    return x1 >= x && x1 < x + w && y1 >= y && y1 < y + h;
}
