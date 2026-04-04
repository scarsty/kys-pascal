// kys_engine.cpp - 基础引擎实现
// 对应 kys_engine.pas

#define _USE_MATH_DEFINES

#include "kys_engine.h"
#include "kys_draw.h"
#include "kys_main.h"
#include "PotConv.h"
#include "SimpleCC.h"

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <SDL3_image/SDL_image.h>

#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cmath>
#include <algorithm>
#include <map>
#include <vector>
#include <string>

// ---- 私有变量 ----
struct QueuedText {
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

static bool EnsureMixerCreated() {
    if (gMixer) return true;
    if (!MIX_Init()) return false;
    SDL_AudioSpec spec;
    spec.freq = 22500;
    spec.format = SDL_AUDIO_S16;
    spec.channels = 2;
    gMixer = MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec);
    return gMixer != nullptr;
}

static MIX_Track* AcquireSfxTrack(MIX_Audio* audio) {
    if (!audio) return nullptr;
    int idx = SfxNextTrack;
    SfxNextTrack++;
    if (SfxNextTrack > 9) SfxNextTrack = 0;
    if (!MIX_SetTrackAudio(SfxTracks[idx], audio)) return nullptr;
    return SfxTracks[idx];
}

static uint8_t BlendByteByPercent(uint8_t a, uint8_t b, int percent) {
    return (uint8_t)((a * (100 - percent) + b * percent) / 100);
}

static uint32_t BlendRGBAByPercent(uint32_t src, uint32_t dst, int percent) {
    uint8_t sr = (src >> 16) & 0xFF, sg = (src >> 8) & 0xFF, sb = src & 0xFF;
    uint8_t dr = (dst >> 16) & 0xFF, dg = (dst >> 8) & 0xFF, db = dst & 0xFF;
    return (BlendByteByPercent(sr, dr, percent) << 16) |
           (BlendByteByPercent(sg, dg, percent) << 8) |
           BlendByteByPercent(sb, db, percent);
}

// ---- 音频 ----

void InitialMusic() {
    if (!EnsureMixerCreated()) return;
    MusicTrack = MIX_CreateTrack(gMixer);
    for (int i = 0; i < 10; i++)
        SfxTracks[i] = MIX_CreateTrack(gMixer);
    SfxNextTrack = 0;

    for (int i = 0; i < (int)Music.size(); i++) {
        if (Music[i]) { MIX_DestroyAudio(Music[i]); Music[i] = nullptr; }
        std::string str = AppPath + "music/" + std::to_string(i) + ".mp3";
        if (SDL_IOFromFile(str.c_str(), "rb")) {
            Music[i] = MIX_LoadAudio(gMixer, str.c_str(), false);
        } else {
            str = AppPath + "music/" + std::to_string(i) + ".mid";
            // midi loading with fluidsynth would go here
            Music[i] = nullptr;
        }
    }
    for (int i = 0; i < (int)ESound.size(); i++) {
        if (ESound[i]) { MIX_DestroyAudio(ESound[i]); ESound[i] = nullptr; }
        char buf[64];
        snprintf(buf, sizeof(buf), "sound/e%02d.wav", i);
        std::string str = AppPath + buf;
        FILE* f = fopen(str.c_str(), "rb");
        if (f) {
            fclose(f);
            ESound[i] = MIX_LoadAudio(gMixer, str.c_str(), false);
        } else {
            ESound[i] = nullptr;
        }
    }
}

void PlayMP3(int MusicNum, int times, int frombeginning) {
    if (!MusicTrack) return;
    if (MusicNum < 0 || MusicNum >= (int)Music.size()) return;
    if (!Music[MusicNum]) return;
    NowMusic = MusicNum;
    MIX_SetTrackAudio(MusicTrack, Music[MusicNum]);
    MIX_SetTrackGain(MusicTrack, (float)VOLUME / 100.0f);
    if (times == -1) MIX_SetTrackLoops(MusicTrack, -1); else MIX_SetTrackLoops(MusicTrack, times);
    MIX_PlayTrack(MusicTrack, 0);
}

void PlayMP3(const char* filename, int times) {
    if (!MusicTrack) return;
    MIX_Audio* audio = MIX_LoadAudio(gMixer, filename, false);
    if (!audio) return;
    MIX_SetTrackAudio(MusicTrack, audio);
    MIX_SetTrackGain(MusicTrack, (float)VOLUME / 100.0f);
    if (times == -1) MIX_SetTrackLoops(MusicTrack, -1);
    MIX_PlayTrack(MusicTrack, 0);
}

void StopMP3(int frombeginning) {
    if (MusicTrack) MIX_StopTrack(MusicTrack, 0);
}

void PlaySoundE(int SoundNum, int times) {
    if (SoundNum < 0 || SoundNum >= (int)ESound.size()) return;
    if (!ESound[SoundNum]) return;
    MIX_Track* trk = AcquireSfxTrack(ESound[SoundNum]);
    if (trk) {
        MIX_SetTrackGain(trk, (float)VOLUMEWAV / 100.0f);
        MIX_PlayTrack(trk, 0);
    }
}

void PlaySoundE(int SoundNum) {
    PlaySoundE(SoundNum, 0);
}

void PlaySoundE(int SoundNum, int times, int x, int y, int z) {
    PlaySoundE(SoundNum, times);
}

void PlaySoundA(int SoundNum, int times) {
    PlaySoundE(SoundNum, times);
}

// ---- 文件读取 ----

char* ReadFileToBuffer(char* p, const std::string& filename, int size, int malloc_flag) {
    FILE* f = fopen(filename.c_str(), "rb");
    if (!f) return p;
    if (malloc_flag && !p) {
        fseek(f, 0, SEEK_END);
        int len = (int)ftell(f);
        fseek(f, 0, SEEK_SET);
        p = new char[len];
        fread(p, 1, len, f);
    } else {
        fread(p, 1, size, f);
    }
    fclose(f);
    return p;
}

void FreeFileBuffer(char*& p) {
    delete[] p;
    p = nullptr;
}

int LoadIdxGrp(const std::string& stridx, const std::string& strgrp,
               std::vector<int>& idxarray, std::vector<uint8_t>& grparray) {
    FILE* f = fopen(stridx.c_str(), "rb");
    if (!f) return 0;
    fseek(f, 0, SEEK_END);
    int len = (int)ftell(f);
    fseek(f, 0, SEEK_SET);
    int count = len / 4;
    idxarray.resize(count);
    fread(idxarray.data(), 4, count, f);
    fclose(f);

    f = fopen(strgrp.c_str(), "rb");
    if (!f) return count;
    fseek(f, 0, SEEK_END);
    len = (int)ftell(f);
    fseek(f, 0, SEEK_SET);
    grparray.resize(len);
    fread(grparray.data(), 1, len, f);
    fclose(f);
    return count;
}

SDL_Surface* LoadSurfaceFromFile(const std::string& filename) {
    return IMG_Load(filename.c_str());
}

SDL_Surface* LoadSurfaceFromMem(const char* p, int len) {
    SDL_IOStream* io = SDL_IOFromMem((void*)p, len);
    if (!io) return nullptr;
    SDL_Surface* s = IMG_Load_IO(io, true);
    return s;
}

void FreeAllSurface() {
    // 释放所有PNG tile surfaces
    for (auto& s : MPNGTile) { if (s) SDL_DestroySurface(s); }
    MPNGTile.clear();
    for (auto& s : SPNGTile) { if (s) SDL_DestroySurface(s); }
    SPNGTile.clear();
    for (auto& s : BPNGTile) { if (s) SDL_DestroySurface(s); }
    BPNGTile.clear();
    for (auto& s : EPNGTile) { if (s) SDL_DestroySurface(s); }
    EPNGTile.clear();
    for (auto& s : CPNGTile) { if (s) SDL_DestroySurface(s); }
    CPNGTile.clear();
    for (auto& s : HeadSurface) { if (s) SDL_DestroySurface(s); }
    HeadSurface.clear();
    for (auto& s : ItemSurface) { if (s) SDL_DestroySurface(s); }
    ItemSurface.clear();
}

void ReadTiles() {
    std::string path = AppPath;
    LoadIdxGrp(path + "resource/mmap.idx", path + "resource/mmap.grp", MIdx, MPic);
    MPicAmount = (int)MIdx.size();
    LoadIdxGrp(path + "resource/sdx", path + "resource/smp", SIdx, SPic);
    SPicAmount = (int)SIdx.size();
    LoadIdxGrp(path + "resource/wdx", path + "resource/wmp", WIdx, WPic);
    LoadIdxGrp(path + "resource/eft.idx", path + "resource/eft.grp", EIdx, EPic);
    EPicAmount = (int)EIdx.size();
    LoadIdxGrp(path + "resource/cloud.idx", path + "resource/cloud.grp", CIdx, CPic);
    CPicAmount = (int)CIdx.size();
    LoadIdxGrp(path + "resource/hdgrp.idx", path + "resource/hdgrp.grp", HIdx, HPic);
    HPicAmount = (int)HIdx.size();
    LoadIdxGrp(path + "resource/talk.idx", path + "resource/talk.grp", TIdx, TDef);
    LoadIdxGrp(path + "resource/kdef.idx", path + "resource/kdef.grp", KIdx, KDef);

    // 战斗图
    for (int i = 0; i < 1000; i++) {
        char buf[128];
        snprintf(buf, sizeof(buf), "fight/fight%03d.idx", i);
        std::string fidx = path + buf;
        snprintf(buf, sizeof(buf), "fight/fight%03d.grp", i);
        std::string fgrp = path + buf;
        FILE* f = fopen(fidx.c_str(), "rb");
        if (f) {
            fclose(f);
            LoadIdxGrp(fidx, fgrp, FIdx[i], FPic[i]);
        }
    }
}

// ---- 基本绘图 ----

uint32_t GetPixel(SDL_Surface* surface, int x, int y) {
    if (!surface) return 0;
    if (x < 0 || y < 0 || x >= surface->w || y >= surface->h) return 0;
    uint32_t* pixels = (uint32_t*)surface->pixels;
    return pixels[y * (surface->pitch / 4) + x];
}

void PutPixel(SDL_Surface* surface, int x, int y, uint32_t pixel) {
    if (!surface) return;
    if (x < 0 || y < 0 || x >= surface->w || y >= surface->h) return;
    uint32_t* pixels = (uint32_t*)surface->pixels;
    pixels[y * (surface->pitch / 4) + x] = pixel;
}

void display_img(const char* file_name, int x, int y) {
    std::string name(file_name);
    SDL_Surface* img = nullptr;
    if (name == CachedImageName && CachedImage) {
        img = CachedImage;
    } else {
        if (CachedImage) SDL_DestroySurface(CachedImage);
        std::string fullpath = checkFileName(AppPath + name);
        img = IMG_Load(fullpath.c_str());
        if (!img) {
            fullpath = checkFileName(AppPathCommon + name);
            img = IMG_Load(fullpath.c_str());
        }
        CachedImage = img;
        CachedImageName = name;
    }
    if (!img) return;
    SDL_Rect dst = {x, y, img->w, img->h};
    SDL_BlitSurface(img, nullptr, screen, &dst);
}

uint32_t ColColor(uint8_t num) {
    if (num * 3 + 2 >= 768) return 0;
    return SDL_MapRGB(SDL_GetPixelFormatDetails(screen->format),
                      SDL_GetSurfacePalette(screen),
                      ACol[num * 3] * 4, ACol[num * 3 + 1] * 4, ACol[num * 3 + 2] * 4);
}

void DrawRectangle(SDL_Surface* sur, int x, int y, int w, int h,
                   int colorin, uint32_t colorframe, int alpha) {
    if (!sur) return;
    SDL_Rect rect = {x + 2, y + 2, w - 3, h - 3};
    // 半透明填充
    SDL_Surface* temp = SDL_CreateSurface(w, h, sur->format);
    if (!temp) return;
    SDL_FillSurfaceRect(temp, nullptr, 0);
    SDL_SetSurfaceAlphaMod(temp, (uint8_t)(alpha * 255 / 100));
    SDL_SetSurfaceBlendMode(temp, SDL_BLENDMODE_BLEND);
    SDL_Rect dst = {x, y, w, h};
    SDL_BlitSurface(temp, nullptr, sur, &dst);
    SDL_DestroySurface(temp);

    // 绘制边框 - 简单实现
    for (int i = x; i < x + w; i++) { PutPixel(sur, i, y, colorframe); PutPixel(sur, i, y + h - 1, colorframe); }
    for (int i = y; i < y + h; i++) { PutPixel(sur, x, i, colorframe); PutPixel(sur, x + w - 1, i, colorframe); }
}

void DrawRectangleWithoutFrame(SDL_Surface* sur, int x, int y, int w, int h,
                               uint32_t colorin, int alpha) {
    if (!sur) return;
    SDL_Surface* temp = SDL_CreateSurface(w, h, sur->format);
    if (!temp) return;
    SDL_FillSurfaceRect(temp, nullptr, colorin);
    SDL_SetSurfaceAlphaMod(temp, (uint8_t)(alpha * 255 / 100));
    SDL_SetSurfaceBlendMode(temp, SDL_BLENDMODE_BLEND);
    SDL_Rect dst = {x, y, w, h};
    SDL_BlitSurface(temp, nullptr, sur, &dst);
    SDL_DestroySurface(temp);
}

// ---- RLE8绘图 ----

bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys) {
    return (px + w > 0 && px - xs < screen->w && py + h > 0 && py - ys < screen->h);
}

bool JudgeInScreen(int px, int py, int w, int h, int xs, int ys,
                   int xx, int yy, int xw, int yh) {
    return (px + w > xx && px < xx + xw && py + h > yy && py < yy + yh);
}

// 基础RLE8解码绘制 (shadow only)
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
                 const int* Pidx, const uint8_t* Ppic,
                 const char* RectArea, SDL_Surface* Image,
                 int widthI, int heightI, int sizeI, int shadow) {
    DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image,
                widthI, heightI, sizeI, shadow, 0);
}

// RLE8解码绘制 with alpha
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
                 const int* Pidx, const uint8_t* Ppic,
                 const char* RectArea, SDL_Surface* Image,
                 int widthI, int heightI, int sizeI,
                 int shadow, int alpha) {
    DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image,
                widthI, heightI, sizeI, shadow, alpha,
                nullptr, nullptr, 0, 0, 0, 0, 0, 0, 0);
}

// 完整RLE8解码绘制
void DrawRLE8Pic(const char* colorPanel, int num, int px, int py,
                 const int* Pidx, const uint8_t* Ppic,
                 const char* RectArea, SDL_Surface* Image,
                 int widthI, int heightI, int sizeI,
                 int shadow, int alpha,
                 char* BlockImageW, const char* BlockPosition,
                 int widthW, int heightW, int sizeW,
                 int depth, uint32_t mixColor, int mixAlpha, int totalpix) {
    if (!Pidx || !Ppic) return;
    if (num < 0) return;

    int offset = (num == 0) ? 0 : Pidx[num - 1];
    const uint8_t* p = Ppic + offset;

    // RLE8 头部: w(2bytes), h(2bytes), xs(2bytes), ys(2bytes)
    int w = *(int16_t*)(p);
    int h = *(int16_t*)(p + 2);
    int xs = *(int16_t*)(p + 4);
    int ys = *(int16_t*)(p + 6);
    p += 8;

    int drawX = px - xs;
    int drawY = py - ys;

    SDL_Surface* target = Image ? Image : screen;
    if (!target) return;

    int targetW = Image ? widthI : target->w;
    int targetH = Image ? heightI : target->h;

    // 裁剪检查
    if (drawX + w <= 0 || drawX >= targetW || drawY + h <= 0 || drawY >= targetH) return;

    SDL_LockSurface(target);
    uint32_t* targetPixels = (uint32_t*)target->pixels;
    int targetPitch = target->pitch / 4;

    const uint8_t* colPanel = (const uint8_t*)colorPanel;

    for (int row = 0; row < h; row++) {
        int len = *(int16_t*)p; p += 2;
        const uint8_t* rowEnd = p + len;
        int col = 0;
        while (p < rowEnd) {
            uint8_t b = *p++;
            if (b & 0x80) {
                // 跳过 (b & 0x7F) 个像素
                col += (b & 0x7F);
            } else if (b & 0x40) {
                // 重复下一个颜色 (b & 0x3F) 次
                int count = b & 0x3F;
                uint8_t colorIdx = *p++;
                for (int k = 0; k < count; k++) {
                    int tx = drawX + col + k;
                    int ty = drawY + row;
                    if (tx >= 0 && tx < targetW && ty >= 0 && ty < targetH) {
                        uint8_t r = colPanel[colorIdx * 3] * 4;
                        uint8_t g = colPanel[colorIdx * 3 + 1] * 4;
                        uint8_t b2 = colPanel[colorIdx * 3 + 2] * 4;
                        if (shadow == 1) {
                            // 阴影模式：叠加黑色
                            uint32_t existing = targetPixels[ty * targetPitch + tx];
                            uint8_t er = (existing >> 16) & 0xFF;
                            uint8_t eg = (existing >> 8) & 0xFF;
                            uint8_t eb = existing & 0xFF;
                            r = er / 2; g = eg / 2; b2 = eb / 2;
                        }
                        if (mixAlpha > 0 && mixColor != 0) {
                            uint8_t mr = (mixColor >> 16) & 0xFF;
                            uint8_t mg = (mixColor >> 8) & 0xFF;
                            uint8_t mb = mixColor & 0xFF;
                            r = (uint8_t)(r * (100 - mixAlpha) / 100 + mr * mixAlpha / 100);
                            g = (uint8_t)(g * (100 - mixAlpha) / 100 + mg * mixAlpha / 100);
                            b2 = (uint8_t)(b2 * (100 - mixAlpha) / 100 + mb * mixAlpha / 100);
                        }
                        if (alpha > 0) {
                            uint32_t existing = targetPixels[ty * targetPitch + tx];
                            uint8_t er = (existing >> 16) & 0xFF;
                            uint8_t eg = (existing >> 8) & 0xFF;
                            uint8_t eb = existing & 0xFF;
                            r = BlendByteByPercent(r, er, alpha);
                            g = BlendByteByPercent(g, eg, alpha);
                            b2 = BlendByteByPercent(b2, eb, alpha);
                        }
                        targetPixels[ty * targetPitch + tx] = (0xFF << 24) | (r << 16) | (g << 8) | b2;
                    }
                }
                col += count;
            } else {
                // 直接绘制 b 个像素
                int count = b;
                for (int k = 0; k < count; k++) {
                    uint8_t colorIdx = *p++;
                    int tx = drawX + col + k;
                    int ty = drawY + row;
                    if (tx >= 0 && tx < targetW && ty >= 0 && ty < targetH) {
                        uint8_t r = colPanel[colorIdx * 3] * 4;
                        uint8_t g = colPanel[colorIdx * 3 + 1] * 4;
                        uint8_t b2 = colPanel[colorIdx * 3 + 2] * 4;
                        if (shadow == 1) {
                            uint32_t existing = targetPixels[ty * targetPitch + tx];
                            uint8_t er = (existing >> 16) & 0xFF;
                            uint8_t eg = (existing >> 8) & 0xFF;
                            uint8_t eb = existing & 0xFF;
                            r = er / 2; g = eg / 2; b2 = eb / 2;
                        }
                        if (mixAlpha > 0 && mixColor != 0) {
                            uint8_t mr = (mixColor >> 16) & 0xFF;
                            uint8_t mg = (mixColor >> 8) & 0xFF;
                            uint8_t mb = mixColor & 0xFF;
                            r = (uint8_t)(r * (100 - mixAlpha) / 100 + mr * mixAlpha / 100);
                            g = (uint8_t)(g * (100 - mixAlpha) / 100 + mg * mixAlpha / 100);
                            b2 = (uint8_t)(b2 * (100 - mixAlpha) / 100 + mb * mixAlpha / 100);
                        }
                        if (alpha > 0) {
                            uint32_t existing = targetPixels[ty * targetPitch + tx];
                            uint8_t er = (existing >> 16) & 0xFF;
                            uint8_t eg = (existing >> 8) & 0xFF;
                            uint8_t eb = existing & 0xFF;
                            r = BlendByteByPercent(r, er, alpha);
                            g = BlendByteByPercent(g, eg, alpha);
                            b2 = BlendByteByPercent(b2, eb, alpha);
                        }
                        targetPixels[ty * targetPitch + tx] = (0xFF << 24) | (r << 16) | (g << 8) | b2;
                    }
                }
                col += count;
            }
        }
        p = rowEnd;
    }
    // Block image 写入
    if (BlockImageW && depth > 0) {
        int16_t* blockW = (int16_t*)BlockImageW;
        for (int row = 0; row < h; row++) {
            for (int c = 0; c < w; c++) {
                int tx = drawX + c;
                int ty = drawY + row;
                if (tx >= 0 && tx < widthW && ty >= 0 && ty < heightW) {
                    int bidx = ty * widthW + tx;
                    if (depth >= blockW[bidx])
                        blockW[bidx] = (int16_t)depth;
                }
            }
        }
    }
    SDL_UnlockSurface(target);
}

TPosition GetPositionOnScreen(int x, int y, int CenterX, int CenterY) {
    TPosition p;
    p.x = -(y - x) * 18 + CenterX;
    p.y = (x + y) * 9 + CenterY;
    return p;
}

// ---- 文字编码 ----

std::string cp950toutf8(const char* str, int len) {
    if (!str) return "";
    int slen = (len < 0) ? (int)strlen(str) : len;
    if (slen == 0) return "";
    return PotConv::cp950toutf8(std::string(str, slen));
}

std::string utf8tocp950(const std::string& str) {
    if (str.empty()) return "";
    return PotConv::conv(str, "utf-8", "cp950");
}

// ---- 文字绘制 ----

int utf8follow(char c1) {
    uint8_t c = (uint8_t)c1;
    if (c < 0x80) return 1;
    if (c < 0xC0) return 1;
    if (c < 0xE0) return 2;
    if (c < 0xF0) return 3;
    return 4;
}

void DrawText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color) {
    if (!sur || word.empty() || !ChineseFont) return;
    std::string text = word;
    if (SIMPLE == 1) text = Traditional2Simplified(text);

    int i = 0;
    int len = (int)text.size();
    int dx = 0;
    while (i < len) {
        int charlen = utf8follow(text[i]);
        std::string ch = text.substr(i, charlen);
        i += charlen;

        SDL_Color c;
        uint8_t r, g, b;
        SDL_GetRGB(color, SDL_GetPixelFormatDetails(sur->format), SDL_GetSurfacePalette(sur), &r, &g, &b);
        c.r = r; c.g = g; c.b = b; c.a = 255;

        // 使用字体缓存
        int k = 0;
        for (int j = 0; j < charlen; j++)
            k = k * 256 + (uint8_t)ch[j];

        SDL_Surface* glyph = nullptr;
        auto it = fonts.find(k);
        if (it != fonts.end()) {
            glyph = it->second;
        } else {
            SDL_Color white = {255, 255, 255, 255};
            glyph = TTF_RenderText_Blended(ChineseFont, ch.c_str(), (int)ch.size(), white);
            if (glyph) fonts[k] = glyph;
        }

        if (glyph) {
            SDL_SetSurfaceColorMod(glyph, r, g, b);
            SDL_Rect dst = {x_pos + dx, y_pos, glyph->w, glyph->h};
            SDL_BlitSurface(glyph, nullptr, sur, &dst);
        }

        dx += (charlen >= 3) ? 20 : 10;
    }
}

void DrawEngText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color) {
    if (!sur || word.empty() || !EnglishFont) return;
    SDL_Color c;
    uint8_t r, g, b;
    SDL_GetRGB(color, SDL_GetPixelFormatDetails(sur->format), SDL_GetSurfacePalette(sur), &r, &g, &b);
    c.r = r; c.g = g; c.b = b; c.a = 255;
    SDL_Surface* text = TTF_RenderText_Blended(EnglishFont, word.c_str(), (int)word.size(), c);
    if (text) {
        SDL_Rect dst = {x_pos, y_pos, text->w, text->h};
        SDL_BlitSurface(text, nullptr, sur, &dst);
        SDL_DestroySurface(text);
    }
}

void DrawShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2) {
    DrawText(sur, word, x_pos + 1, y_pos + 1, color2);
    DrawText(sur, word, x_pos, y_pos, color1);
}

void DrawShadowText(const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2) {
    DrawShadowText(screen, word, x_pos, y_pos, color1, color2);
}

void DrawEngShadowText(SDL_Surface* sur, const std::string& word, int x_pos, int y_pos, uint32_t color1, uint32_t color2) {
    DrawEngText(sur, word, x_pos + 1, y_pos + 1, color2);
    DrawEngText(sur, word, x_pos, y_pos, color1);
}

void DrawBig5Text(SDL_Surface* sur, const char* str, int x_pos, int y_pos, uint32_t color) {
    std::string utf8 = cp950toutf8(str);
    DrawText(sur, utf8, x_pos, y_pos, color);
}

void DrawBig5ShadowText(SDL_Surface* sur, const char* word, int x_pos, int y_pos, uint32_t color1, uint32_t color2) {
    std::string utf8 = cp950toutf8(word);
    DrawShadowText(sur, utf8, x_pos, y_pos, color1, color2);
}

void DrawTextWithRect(const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2) {
    DrawTextWithRect(screen, word, x, y, w, color1, color2);
}

void DrawTextWithRect(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2) {
    DrawRectangle(sur, x - 3, y - 3, w + 6, 28, 0, ColColor(0xFF), 50);
    DrawShadowText(sur, word, x, y, color1, color2);
    UpdateScreen(sur, x - 3, y - 3, w + 7, 29);
}

void DrawTextWithRectNoUpdate(SDL_Surface* sur, const std::string& word, int x, int y, int w, uint32_t color1, uint32_t color2) {
    DrawRectangle(sur, x - 3, y - 3, w + 6, 28, 0, ColColor(0xFF), 50);
    DrawShadowText(sur, word, x, y, color1, color2);
}

// ---- PNG贴图 (桩实现) ----
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py) {}
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py,
                 int shadow, int alpha, uint32_t mixColor, int mixAlpha) {}
void DrawPNGTile(TPNGIndex PNGIndex, int FrameNum, const char* RectArea, SDL_Surface* scr, int px, int py,
                 int shadow, int alpha, uint32_t mixColor, int mixAlpha, int depth,
                 char* BlockImgR, int Width, int Height, int size, int leftupx, int leftupy) {}

// ---- 屏幕管理 ----

static void EnsureCompositeTex() {
    int curW, curH;
    SDL_GetWindowSize(window, &curW, &curH);
    if (curW <= 0 || curH <= 0) return;
    if (compositeTex && compositeTexW == curW && compositeTexH == curH) return;
    if (compositeTex) SDL_DestroyTexture(compositeTex);
    compositeTex = SDL_CreateTexture(render, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_TARGET, curW, curH);
    SDL_SetTextureBlendMode(compositeTex, SDL_BLENDMODE_BLEND);
    compositeTexW = curW;
    compositeTexH = curH;
}

void UpdateScreen(SDL_Surface* scr1, int x, int y, int w, int h) {
    if (!render || !scr1) return;

    // 上传 surface 到 texture
    void* pixels;
    int pitch;
    SDL_Rect area = {x, y, w, h};
    if (SDL_LockTexture(screenTex, &area, &pixels, &pitch)) {
        uint32_t* src = (uint32_t*)scr1->pixels;
        int srcPitch = scr1->pitch / 4;
        for (int row = 0; row < h && (y + row) < scr1->h; row++) {
            memcpy((uint8_t*)pixels + row * pitch,
                   &src[(y + row) * srcPitch + x],
                   w * 4);
        }
        SDL_UnlockTexture(screenTex);
    }

    // 合成高清文字
    if (HIRES_TEXT) {
        EnsureCompositeTex();
        SDL_SetRenderTarget(render, compositeTex);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(render, 0, 0, 0, 0);
        SDL_RenderClear(render);
        SDL_SetRenderDrawBlendMode(render, SDL_BLENDMODE_BLEND);
        // RenderQueuedHiResText(...); // TODO: hi-res text
        SDL_SetRenderTarget(render, nullptr);
    }

    // 最终渲染
    SDL_RenderClear(render);
    SDL_RenderTexture(render, screenTex, nullptr, nullptr);
    if (HIRES_TEXT && compositeTex) {
        SDL_RenderTexture(render, compositeTex, nullptr, nullptr);
    }
    SDL_RenderPresent(render);
}

void UpdateAllScreen() {
    if (screen)
        UpdateScreen(screen, 0, 0, screen->w, screen->h);
}

void TransBlackScreen() {
    if (!screen) return;
    SDL_LockSurface(screen);
    uint32_t* pixels = (uint32_t*)screen->pixels;
    int total = (screen->pitch / 4) * screen->h;
    for (int i = 0; i < total; i++) {
        uint32_t c = pixels[i];
        uint8_t r = ((c >> 16) & 0xFF) / 2;
        uint8_t g = ((c >> 8) & 0xFF) / 2;
        uint8_t b = (c & 0xFF) / 2;
        pixels[i] = (c & 0xFF000000) | (r << 16) | (g << 8) | b;
    }
    SDL_UnlockSurface(screen);
}

void ResizeWindow(int w, int h) {
    if (window) SDL_SetWindowSize(window, w, h);
}

void SwitchFullscreen() {
    if (!window) return;
    FULLSCREEN = 1 - FULLSCREEN;
    if (FULLSCREEN)
        SDL_SetWindowFullscreen(window, true);
    else
        SDL_SetWindowFullscreen(window, false);
}

void SDL_GetMouseState2(int& x, int& y) {
    float fx, fy;
    SDL_GetMouseState(&fx, &fy);
    int curW, curH;
    SDL_GetWindowSize(window, &curW, &curH);
    x = (int)(fx * CENTER_X * 2 / curW);
    y = (int)(fy * CENTER_Y * 2 / curH);
}

void GetMousePosition(int& x, int& y, int x0, int y0, int yp) {
    int mx, my;
    SDL_GetMouseState2(mx, my);
    // 屏幕坐标→游戏坐标
    mx -= x0;
    my -= y0;
    x = (my / 9 - mx / 18) / 2;
    y = (mx / 18 + my / 9) / 2;
}

bool MouseInRegion(int x, int y, int w, int h) {
    int mx, my;
    SDL_GetMouseState2(mx, my);
    return mx >= x && mx < x + w && my >= y && my < y + h;
}

bool MouseInRegion(int x, int y, int w, int h, int& x1, int& y1) {
    SDL_GetMouseState2(x1, y1);
    return x1 >= x && x1 < x + w && y1 >= y && y1 < y + h;
}

void CleanKeyValue() {
    event.key.key = 0;
    event.button.button = 0;
}

// ---- 事件处理 ----

bool EventFilter(void* p, SDL_Event* e) {
    switch (e->type) {
        case SDL_EVENT_FINGER_UP:
        case SDL_EVENT_FINGER_DOWN:
        case SDL_EVENT_GAMEPAD_AXIS_MOTION:
        case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
        case SDL_EVENT_GAMEPAD_BUTTON_UP:
            return false;
        case SDL_EVENT_DID_ENTER_FOREGROUND:
            PlayMP3(NowMusic, -1, 0);
            return true;
        case SDL_EVENT_DID_ENTER_BACKGROUND:
            StopMP3();
            return true;
    }
    return true;
}

uint32_t CheckBasicEvent() {
    // 处理基本事件: 退出、手柄映射等
    switch (event.type) {
        case SDL_EVENT_QUIT:
            QuitConfirm();
            break;
        case SDL_EVENT_WINDOW_RESIZED:
            RESOLUTIONX = event.window.data1;
            RESOLUTIONY = event.window.data2;
            break;
    }
    return event.type;
}

void QuitConfirm() {
    // 直接退出或弹出确认
    Quit();
}

int AngleToDirection(double y, double x) {
    double angle = atan2(y, x) * 180.0 / M_PI;
    if (angle < 0) angle += 360;
    if (angle < 45) return 2;
    if (angle < 135) return 0;
    if (angle < 225) return 3;
    if (angle < 315) return 1;
    return 2;
}

// ---- 辅助函数 ----

int DrawLength(const std::string& str) {
    int len = 0;
    int i = 0;
    int slen = (int)str.size();
    while (i < slen) {
        int charlen = utf8follow(str[i]);
        len += (charlen >= 3) ? 2 : 1;
        i += charlen;
    }
    return len;
}

int DrawLength(const char* p) {
    if (!p) return 0;
    return DrawLength(std::string(p));
}

void swap(uint32_t& x, uint32_t& y) {
    uint32_t t = x; x = y; y = t;
}

int RegionParameter(int x, int x1, int x2) {
    if (x < x1) return x1;
    if (x > x2) return x2;
    return x;
}

void QuickSortB(TBuildInfo* a, int l, int r) {
    if (l >= r) return;
    int i = l, j = r;
    TBuildInfo pivot = a[(l + r) / 2];
    while (i <= j) {
        while (a[i].c < pivot.c) i++;
        while (a[j].c > pivot.c) j--;
        if (i <= j) {
            TBuildInfo tmp = a[i]; a[i] = a[j]; a[j] = tmp;
            i++; j--;
        }
    }
    if (l < j) QuickSortB(a, l, j);
    if (i < r) QuickSortB(a, i, r);
}

void ClearQueuedHiResText() {
    TextQueue.clear();
}

void ChangeCol() {
    // 调色板动画 - 暂简化
}

// ---- 简繁转换 ----

std::string Simplified2Traditional(const std::string& str) {
    if (!sccS2T_loaded) {
        sccS2T.init({AppPath + "cc/STCharacters.txt", AppPath + "cc/STPhrases.txt"});
        sccS2T_loaded = true;
    }
    return sccS2T.conv(str);
}

std::string Traditional2Simplified(const std::string& str) {
    if (!sccT2S_loaded) {
        sccT2S.init({AppPath + "cc/TSCharacters.txt", AppPath + "cc/TSPhrases.txt"});
        sccT2S_loaded = true;
    }
    return sccT2S.conv(str);
}

// ---- 调试 ----

void tic() {
    tic_time = SDL_GetTicksNS();
}

void toc() {
    uint64_t now = SDL_GetTicksNS();
    kyslog("toc: %llu ms", (unsigned long long)(now - tic_time) / 1000000);
}

void kyslog(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
    fflush(stdout);
}

std::string checkFileName(const std::string& f) {
    // 直接返回，Windows不区分大小写
    return f;
}

bool InRegion(int x1, int y1, int x, int y, int w, int h) {
    return x1 >= x && x1 < x + w && y1 >= y && y1 < y + h;
}
