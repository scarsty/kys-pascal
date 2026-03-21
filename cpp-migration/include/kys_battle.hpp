#pragma once
/// Battle system for KYS — ported from kys_battle.pas.
/// KysBattle is designed to run within the SDL render thread, taking over the
/// event loop for the duration of combat.

#include "kys_types.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#if __has_include(<SDL3/SDL.h>)
#include <SDL3/SDL.h>
#define KYS_BATTLE_HAS_SDL 1
#else
#define KYS_BATTLE_HAS_SDL 0
#endif

namespace kys {

class KysState;
struct MMapGrpCache;
struct FontOverlay;

// ---------------------------------------------------------------------------
// Battle constants (matching Pascal kys_type.pas)
// ---------------------------------------------------------------------------
static constexpr int kMaxBattleRoles = 100;
static constexpr int kBFieldSize = 64;
static constexpr int kBFieldLayers = 8;
static constexpr int kMaxLevel = 30;
static constexpr int kMaxPhysicalPower = 100;
static constexpr int kMaxHP = 999;
static constexpr int kMaxMP = 999;
static constexpr int kLifeHurt = 10;
static constexpr int kPoisonHurt = 10;
static constexpr int kMedLife = 4;
static constexpr int kMinKnowledge = 80;
static constexpr int kMaxWeaponMatch = 7;
static constexpr int kBattleSpeed = 40;  // ms delay per animation step
static constexpr int kBeginBattleRolePic = 2553;

// MaxProList[43..58] caps for role stat indices
static constexpr int kMaxProList[] = {
    100, 100, 100, 100, 100, 100, 100, 100,
    100, 100, 100, 100, 100, 100, 100, 1
};

// Level-up experience table (30 levels)
static constexpr int kLevelUpList[] = {
    0, 50, 100, 200, 350, 550, 800, 1100, 1450, 1850,
    2300, 2800, 3400, 4100, 4900, 5800, 6800, 7900, 9100, 10500,
    12100, 13900, 15900, 18200, 20800, 23800, 27200, 31100, 35600, 65535
};

// ---------------------------------------------------------------------------
// KysBattle — self‑contained battle handler
// ---------------------------------------------------------------------------
class KysBattle {
public:
    KysBattle(KysState& state, SDL_Renderer* renderer, SDL_Texture* frameTexture,
              int renderWidth, int renderHeight,
              MMapGrpCache& warCache, MMapGrpCache& sceneCache,
              FontOverlay* font);

    /// Run a battle. Returns true on player victory, false on defeat.
    bool run(int battleNum, int getexp);

private:
    // -- Data -----------------------------------------------------------------
    KysState& state_;
    SDL_Renderer* renderer_;
    SDL_Texture* frameTexture_;
    int renderW_;
    int renderH_;
    MMapGrpCache& warCache_;
    MMapGrpCache& sceneCache_;
    FontOverlay* font_;

    // Head portrait texture cache (loaded on demand)
    std::unordered_map<int, SDL_Texture*> headCache_;
    std::unordered_map<int, bool> headMissing_;
    SDL_Texture* loadHeadTexture(int headNum);

    TWarData warSta_{};
    std::array<TBattleRole, kMaxBattleRoles> brole_{};
    int broleAmount_ = 0;
    int bStatus_ = 0;        // 0=continue, 1=victory, 2=defeat
    int battleRound_ = 1;
    int bx_ = 0, by_ = 0;   // View center grid coords

    // Battle field: 8 layers x 64 x 64
    // [0]=ground, [1]=building, [2]=role index (-1=empty), [3]=BFS distance,
    // [4]=effect area, [5]=unused, [6]=first-move, [7]=enemy-adjacent
    i16 bField_[kBFieldLayers][kBFieldSize][kBFieldSize]{};

    // Target selection
    int ax_ = 0, ay_ = 0;   // Cursor / target position

    // -- Initialization -------------------------------------------------------
    bool loadBattleField(int battleNum);
    void initBattleRole(int i, int rnum, int team, int x, int y);
    void selectAndPlaceTeam();

    // -- Turn system ----------------------------------------------------------
    void battleMainControl();
    void reArrangeBRole();
    void calMoveAbility();
    int battleStatus() const;
    void calPoiHurtLife();
    void clearDeadRoles();

    // -- Movement -------------------------------------------------------------
    void seekPath(int x, int y, int step, int myteam, int mode);
    bool moveAnimation(int bnum);
    void calCanSelect(int bnum, int mode, int step);

    // -- Targeting / Action selection ------------------------------------------
    int selectAim(int bnum, int step, int areaType = 0, int range = 0);
    void setEffectArea(int cx, int cy, int areaType, int distance, int range);
    void setEffectAreaFrom(int sx, int sy, int cx, int cy, int areaType, int distance, int range);

    // -- Attack / Magic -------------------------------------------------------
    int selectMagic(int rnum);
    void attack(int bnum);
    void attackAction(int bnum, int mnum, int level);
    void calHurtRole(int bnum, int mnum, int level);
    int calHurtValue(int bnum1, int bnum2, int mnum, int level) const;

    // -- Support actions ------------------------------------------------------
    void usePoison(int bnum);
    void medPoison(int bnum);
    void medcine(int bnum);
    void rest(int bnum);
    void wait(int bnum);

    // -- AI -------------------------------------------------------------------
    void autoBattle(int bnum);
    void nearestMove(int& mx, int& my, int bnum);
    void tryMoveAttack(int& mx1, int& my1, int& ax1, int& ay1, int& bestHurt,
                       int bnum, int mnum, int level);

    // -- Experience / Leveling ------------------------------------------------
    void addExp();
    void checkLevelUp();
    void levelUp(int bnum);
    void restoreRoleStatus();

    // -- Rendering ------------------------------------------------------------
    void redraw();
    void drawBField();
    void drawRoleOnField(int gx, int gy, int alpha = 255);
    void drawCursor(int gx, int gy);
    void drawReachable();
    void drawEffectArea();
    void drawHurtNumbers();
    void showBattleMenu(int bnum, int& choice);
    void showSimpleStatus(int rnum, int sx, int sy);
    void showDamageNumber(int x, int y, int value);
    void presentFrame();

    // -- Helpers --------------------------------------------------------------
    std::pair<int, int> gridToScreen(int gx, int gy) const;
    void pumpEvents();
    bool waitForKey(int& outKey);
    int clamp(int v, int lo, int hi) const { return v < lo ? lo : (v > hi ? hi : v); }
};

} // namespace kys
