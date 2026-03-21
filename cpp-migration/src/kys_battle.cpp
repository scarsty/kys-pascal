#include "kys_battle.hpp"
#include "kys_draw.hpp"
#include "kys_state.hpp"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>

namespace kys {

// ===========================================================================
// Construction
// ===========================================================================

KysBattle::KysBattle(KysState& state, SDL_Renderer* renderer,
                     SDL_Texture* frameTexture, int renderWidth, int renderHeight,
                     MMapGrpCache& warCache, MMapGrpCache& sceneCache,
                     FontOverlay* font)
    : state_(state), renderer_(renderer), frameTexture_(frameTexture),
      renderW_(renderWidth), renderH_(renderHeight),
      warCache_(warCache), sceneCache_(sceneCache), font_(font) {
    std::memset(bField_, 0xFF, sizeof(bField_)); // -1 fill
    std::memset(bField_[0], 0, sizeof(bField_[0])); // ground = 0
    std::memset(bField_[1], 0, sizeof(bField_[1])); // building = 0
}

// ===========================================================================
// Main entry
// ===========================================================================

bool KysBattle::run(int battleNum, int getexp) {
    bStatus_ = 0;
    battleRound_ = 1;
    broleAmount_ = 0;

    if (!loadBattleField(battleNum)) {
        return true; // can't load → auto-win
    }

    selectAndPlaceTeam();

    // Set where = 2 (battle mode)
    // (state tracks this for external queries)

    // Initialize auto modes
    for (int i = 0; i < broleAmount_; ++i) {
        brole_[i].element.autoMode = 1; // all-attack by default
    }

    // Center view on first player role
    if (broleAmount_ > 0) {
        bx_ = brole_[0].element.x;
        by_ = brole_[0].element.y;
    }

    // Main battle loop
    battleMainControl();

    // Restore role status
    restoreRoleStatus();

    // Award experience on victory
    if (bStatus_ == 1 || (bStatus_ == 2 && getexp != 0)) {
        addExp();
        checkLevelUp();
    }

    return bStatus_ == 1;
}

// ===========================================================================
// Initialization
// ===========================================================================

bool KysBattle::loadBattleField(int battleNum) {
    // Read war.sta
    std::string warPath = state_.appPath_ + "/resource/War.sta";
    std::ifstream fwar(warPath, std::ios::binary);
    if (!fwar) return false;

    std::streamoff offset = static_cast<std::streamoff>(battleNum) * static_cast<std::streamoff>(sizeof(TWarData));
    fwar.seekg(offset);
    if (!fwar) return false;
    fwar.read(reinterpret_cast<char*>(&warSta_), sizeof(TWarData));
    if (!fwar) return false;
    fwar.close();

    int fieldNum = warSta_.element.bFieldNum;

    // Read warfld.grp/idx
    std::streamoff grpOffset = 0;
    if (fieldNum > 0) {
        std::string idxPath = state_.appPath_ + "/resource/warfld.idx";
        std::ifstream fidx(idxPath, std::ios::binary);
        if (fidx) {
            fidx.seekg(static_cast<std::streamoff>((fieldNum - 1) * 4));
            std::int32_t off32 = 0;
            fidx.read(reinterpret_cast<char*>(&off32), 4);
            grpOffset = off32;
        }
    }

    std::string grpPath = state_.appPath_ + "/resource/warfld.grp";
    std::ifstream fgrp(grpPath, std::ios::binary);
    if (!fgrp) return false;
    fgrp.seekg(grpOffset);
    // Read 2 layers (ground + building), each 64x64 i16
    fgrp.read(reinterpret_cast<char*>(&bField_[0][0][0]), 2 * kBFieldSize * kBFieldSize * sizeof(i16));
    fgrp.close();

    // Clear role layer
    for (int y = 0; y < kBFieldSize; ++y)
        for (int x = 0; x < kBFieldSize; ++x)
            bField_[2][y][x] = -1;

    // Clear other layers
    std::memset(bField_[3], 0xFF, sizeof(bField_[3])); // BFS = -1
    std::memset(bField_[4], 0, sizeof(bField_[4]));     // effect = 0
    std::memset(bField_[5], 0, sizeof(bField_[5]));
    std::memset(bField_[6], 0, sizeof(bField_[6]));
    std::memset(bField_[7], 0, sizeof(bField_[7]));

    broleAmount_ = 0;

    // Add auto team members
    for (int i = 0; i < 6; ++i) {
        int x = warSta_.element.teamX[i];
        int y = warSta_.element.teamY[i];
        if (warSta_.element.autoTeamMate[i] >= 0) {
            initBattleRole(broleAmount_, warSta_.element.autoTeamMate[i], 0, x, y);
            broleAmount_++;
        }
    }

    // Add enemies
    for (int i = 0; i < 20; ++i) {
        int x = warSta_.element.enemyX[i];
        int y = warSta_.element.enemyY[i];
        if (warSta_.element.enemy[i] >= 0) {
            initBattleRole(broleAmount_, warSta_.element.enemy[i], 1, x, y);
            broleAmount_++;
        }
    }

    return true;
}

void KysBattle::initBattleRole(int i, int rnum, int team, int x, int y) {
    if (i < 0 || i >= kMaxBattleRoles) return;
    auto& br = brole_[i].element;
    br.rnum = static_cast<i16>(rnum);
    br.team = static_cast<i16>(team);
    br.y = static_cast<i16>(y);
    br.x = static_cast<i16>(x);
    br.face = (team == 0) ? 2 : 1; // player faces up, enemy faces down
    br.dead = 0;
    br.step = 0;
    br.acted = 0;
    br.pic = 0;
    br.showNumber = -1;
    br.expGot = 0;
    br.autoFlag = 0;
    br.realSpeed = 0;
    br.realProgress = static_cast<i16>(std::rand() % 7000);
    br.bHead = 0;
    br.autoMode = 0;

    // Place on field
    if (x >= 0 && x < kBFieldSize && y >= 0 && y < kBFieldSize) {
        bField_[2][x][y] = static_cast<i16>(i);
    }
}

void KysBattle::selectAndPlaceTeam() {
    // Check if any auto-team members were set (placed in loadBattleField).
    // If auto-team exists, Pascal skips the whole team-selection/teamMate block.
    bool hasAutoTeam = false;
    for (int i = 0; i < 6; ++i) {
        if (warSta_.element.autoTeamMate[i] >= 0) {
            hasAutoTeam = true;
            break;
        }
    }

    if (hasAutoTeam) {
        // Pascal: InitialBField returns False → entire selection block skipped.
        // Only auto-team-mates + enemies are placed (done in loadBattleField).
        return;
    }

    // No auto-team: place the player's current team members.
    // Pascal uses SelectTeamMembers bitmask UI; for now we add all alive members.
    for (int i = 0; i < KysState::kTeamSize; ++i) {
        int rnum = state_.teamList_[static_cast<std::size_t>(i)];
        if (rnum < 0) continue;
        if (rnum >= KysState::kMaxRoles) continue;
        if (state_.rRole_[static_cast<std::size_t>(rnum)].element.currentHP <= 0) continue;

        int x = warSta_.element.teamX[i];
        int y = warSta_.element.teamY[i];
        initBattleRole(broleAmount_, rnum, 0, x, y);
        broleAmount_++;
    }

    // Add TeamMate NPCs specified in war data (instruct_16 check: only if NOT
    // already in the player's teamList).
    for (int i = 0; i < 6; ++i) {
        if (warSta_.element.teamMate[i] > 0) {
            int rnum = warSta_.element.teamMate[i];
            if (rnum < 0 || rnum >= KysState::kMaxRoles) continue;

            // instruct_16(rnum, 1, 0) == 0 means "rnum is NOT in teamList"
            bool inTeam = false;
            for (int t = 0; t < KysState::kTeamSize; ++t) {
                if (state_.teamList_[static_cast<std::size_t>(t)] == rnum) {
                    inTeam = true;
                    break;
                }
            }
            if (inTeam) continue; // already placed via teamList above

            int x = warSta_.element.teamX[i];
            int y = warSta_.element.teamY[i] + 1;
            initBattleRole(broleAmount_, rnum, 0, x, y);
            broleAmount_++;
        }
    }
}

// ===========================================================================
// Turn System
// ===========================================================================

void KysBattle::battleMainControl() {
    if (broleAmount_ <= 0) { bStatus_ = 1; return; }

    bx_ = brole_[0].element.x;
    by_ = brole_[0].element.y;

    while (bStatus_ == 0) {
        calMoveAbility();
        reArrangeBRole();
        clearDeadRoles();

        // Reset acted for this round
        for (int i = 0; i < broleAmount_; ++i) {
            brole_[i].element.acted = 0;
            brole_[i].element.showNumber = 0;
        }
        // Clear effect layer
        std::memset(bField_[4], 0, sizeof(bField_[4]));

        int i = 0;
        while (i < broleAmount_ && bStatus_ == 0) {
            pumpEvents();

            state_.writeMem(0x6D95, i); // x50[28005] = current battle role number

            if (brole_[i].element.dead == 0) {
                bx_ = brole_[i].element.x;
                by_ = brole_[i].element.y;
                redraw();

                if (brole_[i].element.team == 0 && brole_[i].element.autoFlag == 0) {
                    // Player-controlled role
                    TBattleRole saved = brole_[i];
                    int choice = -1;
                    showBattleMenu(i, choice);

                    switch (choice) {
                        case 0: { // Move
                            calCanSelect(i, 0, brole_[i].element.step);
                            if (selectAim(i, brole_[i].element.step)) {
                                moveAnimation(i);
                            }
                            break;
                        }
                        case 1: // Attack
                            attack(i);
                            break;
                        case 2: // Use Poison
                            usePoison(i);
                            break;
                        case 3: // Remove Poison
                            medPoison(i);
                            break;
                        case 4: // Heal
                            medcine(i);
                            break;
                        case 5: // Wait
                            wait(i);
                            break;
                        case 6: // Rest
                            rest(i);
                            break;
                        case 7: // Auto mode
                            brole_[i].element.autoFlag = 1;
                            autoBattle(i);
                            brole_[i].element.acted = 1;
                            break;
                        default: {
                            // ESC/cancel: undo movement
                            if (saved.element.rnum == brole_[i].element.rnum) {
                                bField_[2][saved.element.x][saved.element.y] = static_cast<i16>(i);
                                bField_[2][brole_[i].element.x][brole_[i].element.y] = -1;
                                brole_[i] = saved;
                            }
                            break;
                        }
                    }
                } else {
                    // Enemy or auto battle
                    autoBattle(i);
                    brole_[i].element.acted = 1;
                }
            } else {
                brole_[i].element.acted = 1;
            }

            clearDeadRoles();
            redraw();
            bStatus_ = battleStatus();

            if (brole_[i].element.acted == 1) {
                i++;
            }
        }

        battleRound_++;
        calPoiHurtLife();
    }
}

void KysBattle::reArrangeBRole() {
    // Bubble sort by speed (faster = earlier turn)
    for (int i1 = 0; i1 < broleAmount_ - 1; ++i1) {
        for (int i2 = i1 + 1; i2 < broleAmount_; ++i2) {
            int rnum1 = brole_[i1].element.rnum;
            int rnum2 = brole_[i2].element.rnum;
            int sp1 = state_.getRoleData(rnum1, 44) * 10 + std::rand() % 10;
            int sp2 = state_.getRoleData(rnum2, 44) * 10 + std::rand() % 10;
            if (sp1 < sp2) {
                std::swap(brole_[i1], brole_[i2]);
            }
        }
    }

    // Rebuild role layer
    for (int y = 0; y < kBFieldSize; ++y)
        for (int x = 0; x < kBFieldSize; ++x)
            bField_[2][y][x] = -1;

    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.dead == 0) {
            int gx = brole_[i].element.x;
            int gy = brole_[i].element.y;
            if (gx >= 0 && gx < kBFieldSize && gy >= 0 && gy < kBFieldSize) {
                bField_[2][gx][gy] = static_cast<i16>(i);
            }
        }
    }
}

void KysBattle::calMoveAbility() {
    for (int i = 0; i < broleAmount_; ++i) {
        int rnum = brole_[i].element.rnum;
        int addSpeed = 0;
        // Equipment speed bonuses
        int eq0 = state_.getRoleData(rnum, 23); // equip[0]
        int eq1 = state_.getRoleData(rnum, 24); // equip[1]
        if (eq0 >= 0 && eq0 < KysState::kMaxItems)
            addSpeed += state_.getItemData(eq0, 53); // addSpeed
        if (eq1 >= 0 && eq1 < KysState::kMaxItems)
            addSpeed += state_.getItemData(eq1, 53); // addSpeed

        int speed = state_.getRoleData(rnum, 44) + addSpeed;
        brole_[i].element.step = static_cast<i16>(std::min(speed / 15, 15));
    }
}

int KysBattle::battleStatus() const {
    int alive0 = 0, alive1 = 0;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.dead == 0) {
            if (brole_[i].element.team == 0) alive0++;
            else alive1++;
        }
    }
    if (alive0 > 0 && alive1 == 0) return 1; // victory
    if (alive0 == 0 && alive1 > 0) return 2; // defeat
    return 0;
}

void KysBattle::calPoiHurtLife() {
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.dead != 0) continue;
        int rnum = brole_[i].element.rnum;
        int poison = state_.getRoleData(rnum, 20); // poison
        if (poison > 0) {
            int hp = state_.getRoleData(rnum, 17); // currentHP
            hp -= poison / kPoisonHurt;
            state_.setRoleData(rnum, 17, hp);
        }
    }
}

void KysBattle::clearDeadRoles() {
    for (int i = 0; i < broleAmount_; ++i) {
        int rnum = brole_[i].element.rnum;
        int hp = state_.getRoleData(rnum, 17);
        if (hp <= 0 && brole_[i].element.dead == 0) {
            brole_[i].element.dead = 1;
            int gx = brole_[i].element.x;
            int gy = brole_[i].element.y;
            if (gx >= 0 && gx < kBFieldSize && gy >= 0 && gy < kBFieldSize) {
                bField_[2][gx][gy] = -1;
            }
        }
    }
    // Restore living roles on grid
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.dead == 0) {
            int gx = brole_[i].element.x;
            int gy = brole_[i].element.y;
            if (gx >= 0 && gx < kBFieldSize && gy >= 0 && gy < kBFieldSize) {
                bField_[2][gx][gy] = static_cast<i16>(i);
            }
        }
    }
}

// ===========================================================================
// Movement
// ===========================================================================

void KysBattle::calCanSelect(int bnum, int mode, int step) {
    // Clear BFS layer
    for (int y = 0; y < kBFieldSize; ++y)
        for (int x = 0; x < kBFieldSize; ++x)
            bField_[3][y][x] = -1;
    std::memset(bField_[7], 0, sizeof(bField_[7]));

    int startX = brole_[bnum].element.x;
    int startY = brole_[bnum].element.y;
    bField_[3][startX][startY] = 0;
    seekPath(startX, startY, step, brole_[bnum].element.team, mode);
}

void KysBattle::seekPath(int x, int y, int step, int myteam, int mode) {
    static const int dx[] = {1, -1, 0, 0};
    static const int dy[] = {0, 0, 1, -1};

    struct Node { int x, y, step; };
    std::vector<Node> queue;
    queue.reserve(4096);
    queue.push_back({x, y, 0});

    std::size_t cur = 0;
    while (cur < queue.size()) {
        int cx = queue[cur].x;
        int cy = queue[cur].y;
        int cs = queue[cur].step;
        cur++;

        if (cs >= step) continue;

        // Check adjacency for enemies (for mode 0 movement restriction)
        bool enemyAdjacent = false;
        if (mode == 0 && cs > 0) {
            for (int d = 0; d < 4; ++d) {
                int nx = cx + dx[d];
                int ny = cy + dy[d];
                if (nx < 0 || nx >= kBFieldSize || ny < 0 || ny >= kBFieldSize) continue;
                int ri = bField_[2][nx][ny];
                if (ri >= 0 && ri < broleAmount_ && brole_[ri].element.dead == 0 &&
                    brole_[ri].element.team != myteam) {
                    enemyAdjacent = true;
                    break;
                }
            }
        }
        if (mode == 0 && cs > 0 && enemyAdjacent) continue;

        for (int d = 0; d < 4; ++d) {
            int nx = cx + dx[d];
            int ny = cy + dy[d];
            if (nx < 0 || nx >= kBFieldSize || ny < 0 || ny >= kBFieldSize) continue;
            if (bField_[3][nx][ny] >= 0) continue; // already visited
            if (bField_[1][nx][ny] > 0) continue;  // building

            int ri = bField_[2][nx][ny];
            if (ri >= 0 && ri < broleAmount_ && brole_[ri].element.dead == 0) {
                if (mode == 0) {
                    continue; // can't walk through others in move mode
                }
                // In non-move mode, can walk through allies/enemies
            }

            bField_[3][nx][ny] = static_cast<i16>(cs + 1);
            queue.push_back({nx, ny, cs + 1});

            // Mark enemy adjacency for this cell
            for (int d2 = 0; d2 < 4; ++d2) {
                int nnx = nx + dx[d2];
                int nny = ny + dy[d2];
                if (nnx < 0 || nnx >= kBFieldSize || nny < 0 || nny >= kBFieldSize) continue;
                int ri2 = bField_[2][nnx][nny];
                if (ri2 >= 0 && ri2 < broleAmount_ && brole_[ri2].element.dead == 0 &&
                    brole_[ri2].element.team != myteam) {
                    bField_[7][nx][ny] = 1;
                }
            }
        }
    }
}

bool KysBattle::moveAnimation(int bnum) {
    static const int dx[] = {1, -1, 0, 0};
    static const int dy[] = {0, 0, 1, -1};

    int startX = brole_[bnum].element.x;
    int startY = brole_[bnum].element.y;
    int endX = ax_;
    int endY = ay_;

    if (startX == endX && startY == endY) return false;
    if (bField_[3][endX][endY] <= 0) return false;

    // Backtrack path from end to start
    int pathLen = bField_[3][endX][endY];
    std::vector<int> pathX(pathLen + 1), pathY(pathLen + 1);
    pathX[0] = startX;
    pathY[0] = startY;
    pathX[pathLen] = endX;
    pathY[pathLen] = endY;

    for (int a = pathLen - 1; a >= 1; --a) {
        bool found = false;
        for (int d = 0; d < 4; ++d) {
            int nx = pathX[a + 1] + dx[d];
            int ny = pathY[a + 1] + dy[d];
            if (nx < 0 || nx >= kBFieldSize || ny < 0 || ny >= kBFieldSize) continue;
            if (bField_[3][nx][ny] == bField_[3][pathX[a + 1]][pathY[a + 1]] - 1) {
                pathX[a] = nx;
                pathY[a] = ny;
                found = true;
                break;
            }
        }
        if (!found) return false;
    }

    // Animate along path
    for (int a = 1; a <= pathLen; ++a) {
        if (brole_[bnum].element.step <= 0) break;

        // Set face
        int ddx = pathX[a] - bx_;
        int ddy = pathY[a] - by_;
        if (ddx > 0) brole_[bnum].element.face = 3;
        else if (ddx < 0) brole_[bnum].element.face = 0;
        else if (ddy < 0) brole_[bnum].element.face = 2;
        else brole_[bnum].element.face = 1;

        // Move
        if (bField_[2][bx_][by_] == bnum)
            bField_[2][bx_][by_] = -1;

        bx_ = pathX[a];
        by_ = pathY[a];

        if (bField_[2][bx_][by_] == -1)
            bField_[2][bx_][by_] = static_cast<i16>(bnum);

        brole_[bnum].element.step--;

        redraw();
        presentFrame();
        SDL_Delay(kBattleSpeed);
    }

    brole_[bnum].element.x = static_cast<i16>(bx_);
    brole_[bnum].element.y = static_cast<i16>(by_);
    brole_[bnum].element.acted = 2;
    return true;
}

// ===========================================================================
// Targeting
// ===========================================================================

int KysBattle::selectAim(int bnum, int step, int areaType, int range) {
    ax_ = brole_[bnum].element.x;
    ay_ = brole_[bnum].element.y;

    while (true) {
        drawBField();
        drawReachable();
        drawCursor(ax_, ay_);
        presentFrame();

        int key = 0;
        if (!waitForKey(key)) return 0;

        if (key == SDLK_ESCAPE) return 0;
        if (key == SDLK_RETURN || key == SDLK_SPACE) {
            // Check valid target
            if (bField_[3][ax_][ay_] >= 0 && bField_[3][ax_][ay_] <= step) {
                return 1;
            }
        }

        if (key == SDLK_LEFT || key == SDLK_A) { if (ax_ > 0) ax_--; }
        if (key == SDLK_RIGHT || key == SDLK_D) { if (ax_ < kBFieldSize - 1) ax_++; }
        if (key == SDLK_UP || key == SDLK_W) { if (ay_ > 0) ay_--; }
        if (key == SDLK_DOWN || key == SDLK_S) { if (ay_ < kBFieldSize - 1) ay_++; }
    }
}

void KysBattle::setEffectArea(int cx, int cy, int areaType, int distance, int range) {
    std::memset(bField_[4], 0, sizeof(bField_[4]));

    switch (areaType) {
        case 0: // Point
            if (cx >= 0 && cx < kBFieldSize && cy >= 0 && cy < kBFieldSize)
                bField_[4][cx][cy] = 1;
            break;
        case 1: { // Line (4 directions from center)
            for (int d = 1; d <= distance; ++d) {
                int nx, ny;
                // All four directions
                nx = cx + d; ny = cy;
                if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                    bField_[4][nx][ny] = 1;
                nx = cx - d;
                if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                    bField_[4][nx][ny] = 1;
                nx = cx; ny = cy + d;
                if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                    bField_[4][nx][ny] = 1;
                ny = cy - d;
                if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                    bField_[4][nx][ny] = 1;
            }
            break;
        }
        case 2: { // Cross centered on caster
            for (int dx = -distance; dx <= distance; ++dx) {
                for (int dy = -distance; dy <= distance; ++dy) {
                    if (dx == 0 || dy == 0) {
                        int nx = cx + dx;
                        int ny = cy + dy;
                        if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                            bField_[4][nx][ny] = 1;
                    }
                }
            }
            break;
        }
        case 3: { // Area (square)
            for (int dx = -range; dx <= range; ++dx) {
                for (int dy = -range; dy <= range; ++dy) {
                    int nx = cx + dx;
                    int ny = cy + dy;
                    if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                        bField_[4][nx][ny] = 1;
                }
            }
            break;
        }
    }
}

void KysBattle::setEffectAreaFrom(int sx, int sy, int cx, int cy,
                                   int areaType, int distance, int range) {
    std::memset(bField_[4], 0, sizeof(bField_[4]));

    if (areaType == 0 || areaType == 3) {
        setEffectArea(cx, cy, areaType, distance, range);
    } else if (areaType == 1) {
        // Line from sx,sy through cx,cy
        int ddx = 0, ddy = 0;
        if (cx > sx) ddx = 1;
        else if (cx < sx) ddx = -1;
        if (cy > sy) ddy = 1;
        else if (cy < sy) ddy = -1;
        // Make sure it's a cardinal direction
        if (ddx != 0 && ddy != 0) {
            if (std::abs(cx - sx) >= std::abs(cy - sy)) ddy = 0;
            else ddx = 0;
        }
        for (int d = 1; d <= distance; ++d) {
            int nx = sx + ddx * d;
            int ny = sy + ddy * d;
            if (nx >= 0 && nx < kBFieldSize && ny >= 0 && ny < kBFieldSize)
                bField_[4][nx][ny] = 1;
        }
    } else if (areaType == 2) {
        setEffectArea(sx, sy, 2, distance, range);
    }
}

// ===========================================================================
// Attack / Magic
// ===========================================================================

int KysBattle::selectMagic(int rnum) {
    // Build list of available magics
    std::vector<std::pair<int, int>> magics; // (slot index, magic number)
    for (int i = 0; i < 10; ++i) {
        int mnum = state_.getRoleData(rnum, 63 + i); // magic[0..9]
        if (mnum > 0) {
            magics.push_back({i, mnum});
        }
    }
    if (magics.empty()) return -1;

    // Show magic selection menu
    int sel = 0;
    while (true) {
        drawBField();

        // Draw magic list panel
        int panelX = renderW_ / 2 - 150;
        int panelY = 40;
        SDL_SetRenderTarget(renderer_, frameTexture_);
        SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
        SDL_FRect bg{static_cast<float>(panelX), static_cast<float>(panelY),
                     300.0f, static_cast<float>(28 * static_cast<int>(magics.size()) + 16)};
        SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 200);
        SDL_RenderFillRect(renderer_, &bg);
        SDL_SetRenderDrawColor(renderer_, 236, 216, 142, 220);
        SDL_RenderRect(renderer_, &bg);

        for (std::size_t i = 0; i < magics.size(); ++i) {
            int mnum = magics[i].second;
            std::string name = state_.getMagicName(mnum);
            int level = state_.getRoleData(rnum, 73 + magics[i].first) / 100 + 1; // magLevel
            int mp = state_.getMagicData(mnum, 16); // needMP
            std::ostringstream oss;
            oss << name << " Lv" << level << " MP:" << mp * ((level + 1) / 2);
            int ty = panelY + 8 + static_cast<int>(i) * 28;
            if (font_) {
                if (static_cast<int>(i) == sel) {
                    font_->draw(renderer_, "> " + oss.str(), panelX + 8, ty, 255, 255, 100);
                } else {
                    font_->draw(renderer_, "  " + oss.str(), panelX + 8, ty, 200, 200, 200);
                }
            }
        }

        SDL_SetRenderTarget(renderer_, nullptr);
        presentFrame();

        int key = 0;
        if (!waitForKey(key)) return -1;
        if (key == SDLK_ESCAPE) return -1;
        if (key == SDLK_UP || key == SDLK_W) { if (sel > 0) sel--; }
        if (key == SDLK_DOWN || key == SDLK_S) { if (sel < static_cast<int>(magics.size()) - 1) sel++; }
        if (key == SDLK_RETURN || key == SDLK_SPACE) {
            return magics[static_cast<std::size_t>(sel)].first;
        }
    }
}

void KysBattle::attack(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    int magicSlot = selectMagic(rnum);
    if (magicSlot < 0) return;

    int mnum = state_.getRoleData(rnum, 63 + magicSlot);
    int level = state_.getRoleData(rnum, 73 + magicSlot) / 100 + 1;
    if (level > 10) level = 10;

    int areaType = state_.getMagicData(mnum, 15); // attAreaType
    int distance = 0;
    int range = 0;
    if (level >= 1 && level <= 10) {
        distance = state_.getMagicData(mnum, 28 + level - 1); // moveDistance[level-1]
        range = state_.getMagicData(mnum, 38 + level - 1);    // attDistance[level-1]
    }

    // Calculate attack range
    calCanSelect(bnum, 1, distance);

    // Select target
    ax_ = brole_[bnum].element.x;
    ay_ = brole_[bnum].element.y;

    bool targetSelected = false;
    while (true) {
        setEffectArea(ax_, ay_, areaType, distance, range);
        drawBField();
        drawReachable();
        drawEffectArea();
        drawCursor(ax_, ay_);
        presentFrame();

        int key = 0;
        if (!waitForKey(key)) return;
        if (key == SDLK_ESCAPE) return;
        if (key == SDLK_LEFT || key == SDLK_A) { if (ax_ > 0) ax_--; }
        if (key == SDLK_RIGHT || key == SDLK_D) { if (ax_ < kBFieldSize - 1) ax_++; }
        if (key == SDLK_UP || key == SDLK_W) { if (ay_ > 0) ay_--; }
        if (key == SDLK_DOWN || key == SDLK_S) { if (ay_ < kBFieldSize - 1) ay_++; }
        if (key == SDLK_RETURN || key == SDLK_SPACE) {
            targetSelected = true;
            break;
        }
    }

    if (targetSelected) {
        // Apply attack
        setEffectArea(ax_, ay_, areaType, distance, range);
        brole_[bnum].element.acted = 1;

        // Level up magic skill
        int magLev = state_.getRoleData(rnum, 73 + magicSlot);
        magLev += std::rand() % 2 + 1;
        if (magLev > 999) magLev = 999;
        state_.setRoleData(rnum, 73 + magicSlot, magLev);

        attackAction(bnum, mnum, level);
    }
}

void KysBattle::attackAction(int bnum, int mnum, int level) {
    // Reduce physical power
    int rnum = brole_[bnum].element.rnum;
    int phy = state_.getRoleData(rnum, 21); // phyPower
    state_.setRoleData(rnum, 21, phy - 3);

    calHurtRole(bnum, mnum, level);

    // Display damage numbers
    redraw();
    drawHurtNumbers();
    presentFrame();
    SDL_Delay(800);

    // Clear show numbers
    for (int i = 0; i < broleAmount_; ++i)
        brole_[i].element.showNumber = -1;
}

void KysBattle::calHurtRole(int bnum, int mnum, int level) {
    int rnum = brole_[bnum].element.rnum;

    // Check MP
    int needMP = state_.getMagicData(mnum, 16); // needMP
    int curMP = state_.getRoleData(rnum, 41);   // currentMP
    int actualLevel = level;
    if (curMP < needMP * ((level + 1) / 2)) {
        actualLevel = curMP / needMP * 2;
    }
    if (actualLevel > 10) actualLevel = 10;

    // Consume MP
    int consumed = needMP * ((actualLevel + 1) / 2);
    state_.setRoleData(rnum, 41, curMP - consumed);

    int hurtType = state_.getMagicData(mnum, 14); // hurtType

    for (int i = 0; i < broleAmount_; ++i) {
        brole_[i].element.showNumber = -1;

        int ix = brole_[i].element.x;
        int iy = brole_[i].element.y;
        if (ix < 0 || ix >= kBFieldSize || iy < 0 || iy >= kBFieldSize) continue;

        if (bField_[4][ix][iy] != 0 &&
            brole_[bnum].element.team != brole_[i].element.team &&
            brole_[i].element.dead == 0) {

            if (hurtType == 0) {
                // HP damage
                int hurt = calHurtValue(bnum, i, mnum, actualLevel);
                brole_[i].element.showNumber = static_cast<i16>(hurt);

                int targetRnum = brole_[i].element.rnum;
                int hp = state_.getRoleData(targetRnum, 17);
                hp -= hurt;
                state_.setRoleData(targetRnum, 17, hp);

                // Increase injury
                int injury = state_.getRoleData(targetRnum, 19);
                injury += hurt / kLifeHurt;
                if (injury > 99) injury = 99;
                state_.setRoleData(targetRnum, 19, injury);

                // Award experience
                int expGot = brole_[bnum].element.expGot + hurt / 2;
                if (hp <= 0) expGot += hurt / 2;
                if (expGot > 32767) expGot = 32767;
                brole_[bnum].element.expGot = static_cast<i16>(expGot);

            } else if (hurtType == 1) {
                // MP damage
                int hurtMP = 0;
                if (actualLevel >= 1 && actualLevel <= 10) {
                    hurtMP = state_.getMagicData(mnum, 58 + actualLevel - 1); // hurtMP[level-1]
                }
                hurtMP += std::rand() % 5 - std::rand() % 5;
                brole_[i].element.showNumber = static_cast<i16>(hurtMP);

                int targetRnum = brole_[i].element.rnum;
                int tMP = state_.getRoleData(targetRnum, 41);
                tMP -= hurtMP;
                if (tMP < 0) tMP = 0;
                state_.setRoleData(targetRnum, 41, tMP);

                // Gain stolen MP
                int aMP = state_.getRoleData(rnum, 41);
                aMP += hurtMP;
                int aMaxMP = state_.getRoleData(rnum, 42);
                if (aMP > aMaxMP) aMP = aMaxMP;
                state_.setRoleData(rnum, 41, aMP);
            }

            // Apply poison
            int attPoi = state_.getRoleData(rnum, 57);     // attPoi
            int magicPoi = state_.getMagicData(mnum, 17);   // poison
            int targetRnum = brole_[i].element.rnum;
            int defPoi = state_.getRoleData(targetRnum, 49); // defPoi
            int curPoi = state_.getRoleData(targetRnum, 20);

            int addPoi = attPoi / 5 + magicPoi * actualLevel / 2 * (100 - defPoi) / 100;
            if (addPoi + curPoi > 99) addPoi = 99 - curPoi;
            if (addPoi < 0) addPoi = 0;
            if (defPoi >= 99) addPoi = 0;
            state_.setRoleData(targetRnum, 20, curPoi + addPoi);
        }
    }
}

int KysBattle::calHurtValue(int bnum1, int bnum2, int mnum, int level) const {
    // Calculate team knowledge modifier
    int k1 = 0, k2 = 0;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.dead != 0) continue;
        int rn = brole_[i].element.rnum;
        int knowledge = state_.getRoleData(rn, 55); // knowledge
        if (brole_[i].element.team == brole_[bnum1].element.team && knowledge > kMinKnowledge)
            k1 += knowledge;
        if (brole_[i].element.team == brole_[bnum2].element.team && knowledge > kMinKnowledge)
            k2 += knowledge;
    }

    int rnum1 = brole_[bnum1].element.rnum;
    int rnum2 = brole_[bnum2].element.rnum;

    int mhurt = 0;
    if (level > 0 && level <= 10) {
        mhurt = state_.getMagicData(mnum, 18 + level - 1); // attack[level-1]
    }

    int att = state_.getRoleData(rnum1, 43) + k1 * 3 / 2 + mhurt / 3; // attack
    int def = state_.getRoleData(rnum2, 45) * 2 + k2 * 3;              // defence

    // Weapon type bonuses
    int magicType = state_.getMagicData(mnum, 12); // magicType
    int atkBonus = 0, defBonus = 0;
    switch (magicType) {
        case 1: atkBonus = state_.getRoleData(rnum1, 50); defBonus = state_.getRoleData(rnum2, 50); break; // fist
        case 2: atkBonus = state_.getRoleData(rnum1, 51); defBonus = state_.getRoleData(rnum2, 51); break; // sword
        case 3: atkBonus = state_.getRoleData(rnum1, 52); defBonus = state_.getRoleData(rnum2, 52); break; // knife
        case 4: atkBonus = state_.getRoleData(rnum1, 53); defBonus = state_.getRoleData(rnum2, 53); break; // unusual
    }
    att += atkBonus;
    def += defBonus;

    // Injury reduces effectiveness
    int hurt1 = state_.getRoleData(rnum1, 19);
    int hurt2 = state_.getRoleData(rnum2, 19);
    att = att * (100 - hurt1 / 2) / 100;
    def = def * (100 - hurt2 / 2) / 100;

    // Equipment bonuses
    int eq0a = state_.getRoleData(rnum1, 23);
    int eq1a = state_.getRoleData(rnum1, 24);
    if (eq0a >= 0 && eq0a < KysState::kMaxItems)
        att += state_.getItemData(eq0a, 52); // addAttack
    if (eq1a >= 0 && eq1a < KysState::kMaxItems)
        att += state_.getItemData(eq1a, 52);

    int eq0d = state_.getRoleData(rnum2, 23);
    int eq1d = state_.getRoleData(rnum2, 24);
    if (eq0d >= 0 && eq0d < KysState::kMaxItems)
        def += state_.getItemData(eq0d, 54); // addDefence
    if (eq1d >= 0 && eq1d < KysState::kMaxItems)
        def += state_.getItemData(eq1d, 54);

    int result = att - def + std::rand() % 20 - std::rand() % 20;

    // Distance penalty
    int dis = std::abs(brole_[bnum1].element.x - brole_[bnum2].element.x) +
              std::abs(brole_[bnum1].element.y - brole_[bnum2].element.y);
    if (dis > 10) dis = 10;

    result = std::max(result, att / 10 + std::rand() % 10 - std::rand() % 10);
    result = result * (100 - (dis - 1) * 3) / 100;

    if (result <= 0 || level <= 0) result = std::rand() % 10 + 1;
    if (result > 9999) result = 9999;

    return result;
}

// ===========================================================================
// Support Actions
// ===========================================================================

void KysBattle::usePoison(int bnum) {
    // Simplified: find nearest enemy and apply poison
    int rnum = brole_[bnum].element.rnum;
    int usePoi = state_.getRoleData(rnum, 47); // usePoi
    if (usePoi <= 0) return;

    int best = -1;
    int bestDis = 9999;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team == brole_[bnum].element.team) continue;
        if (brole_[i].element.dead != 0) continue;
        int dis = std::abs(brole_[i].element.x - brole_[bnum].element.x) +
                  std::abs(brole_[i].element.y - brole_[bnum].element.y);
        if (dis <= 1 && dis < bestDis) {
            bestDis = dis;
            best = i;
        }
    }

    if (best >= 0) {
        int targetRnum = brole_[best].element.rnum;
        int defPoi = state_.getRoleData(targetRnum, 49);
        int curPoi = state_.getRoleData(targetRnum, 20);
        int addPoi = usePoi * (100 - defPoi) / 100;
        if (addPoi + curPoi > 99) addPoi = 99 - curPoi;
        if (addPoi < 0) addPoi = 0;
        state_.setRoleData(targetRnum, 20, curPoi + addPoi);
        brole_[bnum].element.acted = 1;

        int phy = state_.getRoleData(rnum, 21);
        state_.setRoleData(rnum, 21, phy - 3);
    }
}

void KysBattle::medPoison(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    int medPoiSkill = state_.getRoleData(rnum, 48); // medPoi
    if (medPoiSkill <= 0) return;

    int best = -1;
    int bestPoi = 0;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team != brole_[bnum].element.team) continue;
        if (brole_[i].element.dead != 0) continue;
        int dis = std::abs(brole_[i].element.x - brole_[bnum].element.x) +
                  std::abs(brole_[i].element.y - brole_[bnum].element.y);
        if (dis > 1) continue;
        int poi = state_.getRoleData(brole_[i].element.rnum, 20);
        if (poi > bestPoi) {
            bestPoi = poi;
            best = i;
        }
    }

    if (best >= 0) {
        int targetRnum = brole_[best].element.rnum;
        int curPoi = state_.getRoleData(targetRnum, 20);
        int removed = medPoiSkill * 2 / 3;
        curPoi -= removed;
        if (curPoi < 0) curPoi = 0;
        state_.setRoleData(targetRnum, 20, curPoi);
        brole_[bnum].element.acted = 1;

        int phy = state_.getRoleData(rnum, 21);
        state_.setRoleData(rnum, 21, phy - 5);
    }
}

void KysBattle::medcine(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    int medSkill = state_.getRoleData(rnum, 46); // medcine
    if (medSkill <= 0) return;

    int best = -1;
    int bestNeed = 0;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team != brole_[bnum].element.team) continue;
        if (brole_[i].element.dead != 0) continue;
        int dis = std::abs(brole_[i].element.x - brole_[bnum].element.x) +
                  std::abs(brole_[i].element.y - brole_[bnum].element.y);
        if (dis > 1) continue;
        int rn = brole_[i].element.rnum;
        int hp = state_.getRoleData(rn, 17);
        int maxHp = state_.getRoleData(rn, 18);
        int need = maxHp - hp;
        if (need > bestNeed) {
            bestNeed = need;
            best = i;
        }
    }

    if (best >= 0) {
        int targetRnum = brole_[best].element.rnum;
        int hp = state_.getRoleData(targetRnum, 17);
        int maxHp = state_.getRoleData(targetRnum, 18);
        int heal = medSkill * kMedLife;
        hp += heal;
        if (hp > maxHp) hp = maxHp;
        state_.setRoleData(targetRnum, 17, hp);
        brole_[bnum].element.acted = 1;

        int phy = state_.getRoleData(rnum, 21);
        state_.setRoleData(rnum, 21, phy - 5);
    }
}

void KysBattle::rest(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    // Restore some HP and PhyPower
    int hp = state_.getRoleData(rnum, 17);
    int maxHp = state_.getRoleData(rnum, 18);
    int phy = state_.getRoleData(rnum, 21);
    hp += maxHp / 15 + 1;
    if (hp > maxHp) hp = maxHp;
    phy += 5;
    if (phy > kMaxPhysicalPower) phy = kMaxPhysicalPower;
    state_.setRoleData(rnum, 17, hp);
    state_.setRoleData(rnum, 21, phy);
    brole_[bnum].element.acted = 1;
}

void KysBattle::wait(int bnum) {
    brole_[bnum].element.acted = 1;
}

// ===========================================================================
// AI
// ===========================================================================

void KysBattle::autoBattle(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    int phy = state_.getRoleData(rnum, 21);

    // Self-healing: if HP < 20%
    if (brole_[bnum].element.acted != 1) {
        int hp = state_.getRoleData(rnum, 17);
        int maxHp = state_.getRoleData(rnum, 18);
        if (hp < maxHp / 5) {
            int medSkill = state_.getRoleData(rnum, 46);
            if (medSkill > 50 && phy >= 50) {
                medcine(bnum);
            }
        }
    }

    // Try attack
    if (brole_[bnum].element.acted != 1 && phy >= 10) {
        calCanSelect(bnum, 0, brole_[bnum].element.step);

        int bestMx = -1, bestMy = -1, bestAx = -1, bestAy = -1;
        int bestHurt = 0;
        int bestMnum = -1, bestLevel = 1, bestSlot = -1;

        for (int slot = 0; slot < 10; ++slot) {
            int mnum = state_.getRoleData(rnum, 63 + slot);
            if (mnum <= 0) continue;

            int level = state_.getRoleData(rnum, 73 + slot) / 100 + 1;
            if (level > 10) level = 10;
            if (level <= 0) level = 1;

            int mx1, my1, ax1, ay1, hurt;
            tryMoveAttack(mx1, my1, ax1, ay1, hurt, bnum, mnum, level);

            if (hurt > bestHurt) {
                bestHurt = hurt;
                bestMx = mx1; bestMy = my1;
                bestAx = ax1; bestAy = ay1;
                bestMnum = mnum; bestLevel = level;
                bestSlot = slot;
            }
        }

        if (bestHurt > 0 && bestMnum >= 0) {
            // Move to best position
            ax_ = bestMx; ay_ = bestMy;
            moveAnimation(bnum);

            // Set effect area and attack
            int areaType = state_.getMagicData(bestMnum, 15);
            int distance = 0, range = 0;
            if (bestLevel >= 1 && bestLevel <= 10) {
                distance = state_.getMagicData(bestMnum, 28 + bestLevel - 1);
                range = state_.getMagicData(bestMnum, 38 + bestLevel - 1);
            }
            setEffectArea(bestAx, bestAy, areaType, distance, range);

            brole_[bnum].element.acted = 1;

            // Level up magic
            int magLev = state_.getRoleData(rnum, 73 + bestSlot);
            magLev += std::rand() % 2 + 1;
            if (magLev > 999) magLev = 999;
            state_.setRoleData(rnum, 73 + bestSlot, magLev);

            attackAction(bnum, bestMnum, bestLevel);
        }
    }

    // Fallback: move toward nearest enemy and rest
    if (brole_[bnum].element.acted != 1) {
        calCanSelect(bnum, 0, brole_[bnum].element.step);
        nearestMove(ax_, ay_, bnum);
        moveAnimation(bnum);
        rest(bnum);
    }
}

void KysBattle::nearestMove(int& mx, int& my, int bnum) {
    int myteam = brole_[bnum].element.team;
    int bestDis = 99999;
    int targetX = bx_, targetY = by_;

    // Find nearest enemy
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team == myteam) continue;
        if (brole_[i].element.dead != 0) continue;
        int dis = std::abs(brole_[i].element.x - bx_) + std::abs(brole_[i].element.y - by_);
        if (dis < bestDis) {
            bestDis = dis;
            targetX = brole_[i].element.x;
            targetY = brole_[i].element.y;
        }
    }

    // Find reachable position closest to target
    int minDist = 99999;
    mx = bx_;
    my = by_;
    for (int gx = 0; gx < kBFieldSize; ++gx) {
        for (int gy = 0; gy < kBFieldSize; ++gy) {
            if (bField_[3][gx][gy] >= 0 && bField_[3][gx][gy] <= brole_[bnum].element.step) {
                int dis = std::abs(gx - targetX) + std::abs(gy - targetY);
                if (dis < minDist) {
                    minDist = dis;
                    mx = gx;
                    my = gy;
                }
            }
        }
    }
}

void KysBattle::tryMoveAttack(int& mx1, int& my1, int& ax1, int& ay1,
                               int& bestHurt, int bnum, int mnum, int level) {
    mx1 = my1 = ax1 = ay1 = -1;
    bestHurt = 0;

    int myteam = brole_[bnum].element.team;
    int step = brole_[bnum].element.step;
    int areaType = state_.getMagicData(mnum, 15);
    int distance = 0, range = 0;
    if (level >= 1 && level <= 10) {
        distance = state_.getMagicData(mnum, 28 + level - 1);
        range = state_.getMagicData(mnum, 38 + level - 1);
    }

    // For each reachable position
    for (int cx = 0; cx < kBFieldSize; ++cx) {
        for (int cy = 0; cy < kBFieldSize; ++cy) {
            if (bField_[3][cx][cy] < 0 || bField_[3][cx][cy] > step) continue;

            // For each target within attack range
            for (int tx = std::max(0, cx - distance); tx <= std::min(kBFieldSize - 1, cx + distance); ++tx) {
                int rem = distance - std::abs(tx - cx);
                for (int ty = std::max(0, cy - rem); ty <= std::min(kBFieldSize - 1, cy + rem); ++ty) {
                    // Calculate total damage at this target
                    setEffectAreaFrom(cx, cy, tx, ty, areaType, distance, range);

                    int totalHurt = 0;
                    for (int i = 0; i < broleAmount_; ++i) {
                        if (brole_[i].element.team == myteam) continue;
                        if (brole_[i].element.dead != 0) continue;
                        int ix = brole_[i].element.x;
                        int iy = brole_[i].element.y;
                        if (ix >= 0 && ix < kBFieldSize && iy >= 0 && iy < kBFieldSize &&
                            bField_[4][ix][iy] != 0) {
                            totalHurt += calHurtValue(bnum, i, mnum, level);
                        }
                    }

                    if (totalHurt > bestHurt) {
                        bestHurt = totalHurt;
                        mx1 = cx; my1 = cy;
                        ax1 = tx; ay1 = ty;
                    }
                }
            }
        }
    }
}

// ===========================================================================
// Experience / Leveling
// ===========================================================================

void KysBattle::addExp() {
    // Count player survivors
    int aliveCount = 0;
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team == 0 && brole_[i].element.dead == 0)
            aliveCount++;
    }

    int baseExp = (aliveCount > 0) ? warSta_.element.expGot / aliveCount : 0;

    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team != 0) continue;
        int rnum = brole_[i].element.rnum;

        // Experience from dealing damage
        int combatExp = brole_[i].element.expGot;
        int exp = state_.getRoleData(rnum, 16); // exp (u16)
        int expBook = state_.getRoleData(rnum, 62); // expForBook (u16)
        int expItem = state_.getRoleData(rnum, 22); // expForItem (u16)

        exp = std::min(exp + combatExp, 65535);
        expBook = std::min(expBook + combatExp * 4 / 5, 65535);
        expItem = std::min(expItem + combatExp * 3 / 5, 65535);

        // Base battle exp for survivors
        if (brole_[i].element.dead == 0) {
            exp = std::min(exp + baseExp, 65535);
            expBook = std::min(expBook + baseExp * 4 / 5, 65535);
            expItem = std::min(expItem + baseExp * 3 / 5, 65535);
        }

        state_.setRoleData(rnum, 16, exp);
        state_.setRoleData(rnum, 62, expBook);
        state_.setRoleData(rnum, 22, expItem);
    }
}

void KysBattle::checkLevelUp() {
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.team != 0) continue;
        int rnum = brole_[i].element.rnum;

        int exp = static_cast<u16>(state_.getRoleData(rnum, 16));
        int lev = state_.getRoleData(rnum, 15); // level

        while (lev > 0 && lev <= kMaxLevel &&
               exp >= static_cast<u16>(kLevelUpList[lev - 1]) && lev < kMaxLevel) {
            exp -= kLevelUpList[lev - 1];
            lev++;
            state_.setRoleData(rnum, 16, exp);
            state_.setRoleData(rnum, 15, lev);
            levelUp(i);
            exp = static_cast<u16>(state_.getRoleData(rnum, 16));
        }
    }
}

void KysBattle::levelUp(int bnum) {
    int rnum = brole_[bnum].element.rnum;
    int incLife = state_.getRoleData(rnum, 2); // incLife
    int aptitude = state_.getRoleData(rnum, 60); // aptitude

    // HP increase
    int maxHP = state_.getRoleData(rnum, 18);
    maxHP += incLife * 3 + std::rand() % 6;
    if (maxHP > kMaxHP) maxHP = kMaxHP;
    state_.setRoleData(rnum, 18, maxHP);
    state_.setRoleData(rnum, 17, maxHP); // full heal

    int add = aptitude / 15 + 1;
    add = std::rand() % add + 1;

    // MP increase
    int maxMP = state_.getRoleData(rnum, 42);
    maxMP += (9 - add) * 3;
    if (maxMP > kMaxMP) maxMP = kMaxMP;
    state_.setRoleData(rnum, 42, maxMP);
    state_.setRoleData(rnum, 41, maxMP);

    // Stat increases
    state_.setRoleData(rnum, 43, state_.getRoleData(rnum, 43) + add); // attack
    state_.setRoleData(rnum, 44, state_.getRoleData(rnum, 44) + add); // speed
    state_.setRoleData(rnum, 45, state_.getRoleData(rnum, 45) + add); // defence

    // Skills increase (indices 46-54 in Pascal = weapon skills etc.)
    for (int p = 46; p <= 54; ++p) {
        int v = state_.getRoleData(rnum, p);
        if (v > 0) {
            v += std::rand() % 3 + 1;
        }
        state_.setRoleData(rnum, p, v);
    }

    // Cap stats
    for (int p = 43; p <= 58; ++p) {
        int v = state_.getRoleData(rnum, p);
        int cap = kMaxProList[p - 43];
        if (v > cap) state_.setRoleData(rnum, p, cap);
    }

    // Reset temporary states
    state_.setRoleData(rnum, 21, kMaxPhysicalPower); // phyPower
    state_.setRoleData(rnum, 19, 0); // hurt = 0
    state_.setRoleData(rnum, 20, 0); // poison = 0
}

void KysBattle::restoreRoleStatus() {
    for (int i = 0; i < broleAmount_; ++i) {
        int rnum = brole_[i].element.rnum;

        if (brole_[i].element.team == 0) {
            int hp = state_.getRoleData(rnum, 17);
            int maxHp = state_.getRoleData(rnum, 18);
            hp += maxHp / 2;
            if (hp <= 0) hp = 1;
            if (hp > maxHp) hp = maxHp;
            state_.setRoleData(rnum, 17, hp);

            int mp = state_.getRoleData(rnum, 41);
            int maxMp = state_.getRoleData(rnum, 42);
            mp += maxMp / 20;
            if (mp > maxMp) mp = maxMp;
            state_.setRoleData(rnum, 41, mp);

            int phy = state_.getRoleData(rnum, 21);
            phy += kMaxPhysicalPower / 10;
            if (phy > kMaxPhysicalPower) phy = kMaxPhysicalPower;
            state_.setRoleData(rnum, 21, phy);
        } else {
            state_.setRoleData(rnum, 19, 0); // hurt = 0
            state_.setRoleData(rnum, 20, 0); // poison = 0
            int maxHp = state_.getRoleData(rnum, 18);
            state_.setRoleData(rnum, 17, maxHp);
            int maxMp = state_.getRoleData(rnum, 42);
            state_.setRoleData(rnum, 41, maxMp);
            state_.setRoleData(rnum, 21, kMaxPhysicalPower * 9 / 10);
        }
    }

    // Sync brole data to battleRoleData_ for Lua bridge
    state_.battleRoleData_.clear();
    for (int i = 0; i < broleAmount_; ++i) {
        std::array<i16, 19> row;
        std::memcpy(row.data(), brole_[i].data, sizeof(row));
        state_.battleRoleData_[i] = row;
    }
}

// ===========================================================================
// Rendering
// ===========================================================================

std::pair<int, int> KysBattle::gridToScreen(int gx, int gy) const {
    return getPositionOnScreen(gx, gy, bx_, by_, renderW_ / 2, renderH_ / 2);
}

void KysBattle::redraw() {
    drawBField();
    presentFrame();
}

void KysBattle::drawBField() {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    SDL_SetRenderDrawColor(renderer_, 18, 24, 32, 255);
    SDL_RenderClear(renderer_);

    int cx = renderW_ / 2;
    int cy = renderH_ / 2;
    int widthRegion = cx / 36 + 3;
    int sumRegion = cy / 9 + 2;

    // Draw ground layer
    for (int sum = -sumRegion; sum <= sumRegion + 15; ++sum) {
        for (int i = -widthRegion; i <= widthRegion; ++i) {
            int gx = bx_ + i + (sum / 2);
            int gy = by_ - i + (sum - sum / 2);
            if (gx < 0 || gx >= kBFieldSize || gy < 0 || gy >= kBFieldSize) continue;

            auto [px, py] = gridToScreen(gx, gy);
            int groundTile = bField_[0][gx][gy] / 2;
            if (groundTile > 0) {
                if (!warCache_.renderTile(groundTile, px, py)) {
                    // Fallback colored rectangle
                    SDL_FRect r{static_cast<float>(px), static_cast<float>(py), 36.0f, 18.0f};
                    SDL_SetRenderDrawColor(renderer_, 60, 90, 40, 255);
                    SDL_RenderFillRect(renderer_, &r);
                }
            }
        }
    }

    // Draw buildings + roles (depth-sorted)
    for (int sum = -sumRegion; sum <= sumRegion + 15; ++sum) {
        for (int i = -widthRegion; i <= widthRegion; ++i) {
            int gx = bx_ + i + (sum / 2);
            int gy = by_ - i + (sum - sum / 2);
            if (gx < 0 || gx >= kBFieldSize || gy < 0 || gy >= kBFieldSize) continue;

            auto [px, py] = gridToScreen(gx, gy);
            int buildTile = bField_[1][gx][gy] / 2;
            if (buildTile > 0) {
                if (!warCache_.renderTile(buildTile, px, py)) {
                    SDL_FRect r{static_cast<float>(px), static_cast<float>(py - 10), 36.0f, 28.0f};
                    SDL_SetRenderDrawColor(renderer_, 100, 70, 50, 255);
                    SDL_RenderFillRect(renderer_, &r);
                }
            }

            // Draw role at this cell
            int ri = bField_[2][gx][gy];
            if (ri >= 0 && ri < broleAmount_ && brole_[ri].element.dead == 0) {
                drawRoleOnField(gx, gy);
            }
        }
    }

    // HUD: round number and team status
    SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
    SDL_FRect hudBg{8.0f, 8.0f, 320.0f, 30.0f};
    SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 160);
    SDL_RenderFillRect(renderer_, &hudBg);
    if (font_) {
        std::ostringstream oss;
        oss << "回合 " << battleRound_ << "  戰鬥中";
        font_->draw(renderer_, oss.str(), 16, 14, 255, 255, 255);
    }

    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::drawRoleOnField(int gx, int gy, int alpha) {
    auto [px, py] = gridToScreen(gx, gy);
    int ri = bField_[2][gx][gy];
    if (ri < 0 || ri >= broleAmount_) return;

    int rnum = brole_[ri].element.rnum;
    int headNum = state_.getRoleData(rnum, 1); // headNum
    int face = brole_[ri].element.face;
    int team = brole_[ri].element.team;

    // Try rendering battle sprite (wdx/wmp tiles, matching Pascal DrawBPic)
    int tile = headNum * 4 + face + kBeginBattleRolePic;
    bool drawn = warCache_.renderTile(tile, px, py - 20);

    if (!drawn) {
        // Fallback: colored diamond
        float cx = static_cast<float>(px) + 18.0f;
        float cy = static_cast<float>(py) - 4.0f;

        SDL_Vertex verts[4];
        const float hw = 12.0f, hh = 8.0f;

        // Color based on team
        Uint8 r = (team == 0) ? 80 : 220;
        Uint8 g = (team == 0) ? 180 : 60;
        Uint8 b = (team == 0) ? 255 : 60;
        Uint8 a = static_cast<Uint8>(alpha);

        verts[0] = {{cx, cy - hh}, {static_cast<float>(r)/255.0f, static_cast<float>(g)/255.0f, static_cast<float>(b)/255.0f, static_cast<float>(a)/255.0f}, {0, 0}};
        verts[1] = {{cx + hw, cy}, {static_cast<float>(r)/255.0f, static_cast<float>(g)/255.0f, static_cast<float>(b)/255.0f, static_cast<float>(a)/255.0f}, {0, 0}};
        verts[2] = {{cx, cy + hh}, {static_cast<float>(r)/255.0f, static_cast<float>(g)/255.0f, static_cast<float>(b)/255.0f, static_cast<float>(a)/255.0f}, {0, 0}};
        verts[3] = {{cx - hw, cy}, {static_cast<float>(r)/255.0f, static_cast<float>(g)/255.0f, static_cast<float>(b)/255.0f, static_cast<float>(a)/255.0f}, {0, 0}};

        int indices[] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(renderer_, nullptr, verts, 4, indices, 6);

        // Draw head portrait over diamond
        {
            SDL_Texture* headTex = loadHeadTexture(headNum);
            if (headTex) {
                float texW, texH;
                SDL_GetTextureSize(headTex, &texW, &texH);
                float scale = 24.0f / std::max(texW, texH);
                float dw = texW * scale, dh = texH * scale;
                SDL_FRect headDst{cx - dw / 2, cy - hh - dh + 2, dw, dh};
                SDL_RenderTexture(renderer_, headTex, nullptr, &headDst);
            }
        }
    }

    // HP bar
    int hp = state_.getRoleData(rnum, 17);
    int maxHp = state_.getRoleData(rnum, 18);
    if (maxHp > 0) {
        float barW = 24.0f;
        float barH = 3.0f;
        float barX = static_cast<float>(px) + 6.0f;
        float barY = static_cast<float>(py) + 6.0f;
        SDL_FRect bgBar{barX, barY, barW, barH};
        SDL_SetRenderDrawColor(renderer_, 40, 40, 40, 200);
        SDL_RenderFillRect(renderer_, &bgBar);
        float ratio = static_cast<float>(std::max(0, hp)) / static_cast<float>(maxHp);
        SDL_FRect hpBar{barX, barY, barW * ratio, barH};
        if (team == 0)
            SDL_SetRenderDrawColor(renderer_, 60, 220, 60, 220);
        else
            SDL_SetRenderDrawColor(renderer_, 220, 60, 60, 220);
        SDL_RenderFillRect(renderer_, &hpBar);
    }
}

void KysBattle::drawCursor(int gx, int gy) {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    auto [px, py] = gridToScreen(gx, gy);
    SDL_FRect r{static_cast<float>(px) + 2.0f, static_cast<float>(py) - 2.0f, 32.0f, 16.0f};
    SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(renderer_, 255, 255, 0, 120);
    SDL_RenderFillRect(renderer_, &r);
    SDL_SetRenderDrawColor(renderer_, 255, 255, 0, 220);
    SDL_RenderRect(renderer_, &r);
    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::drawReachable() {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);

    for (int gx = 0; gx < kBFieldSize; ++gx) {
        for (int gy = 0; gy < kBFieldSize; ++gy) {
            if (bField_[3][gx][gy] > 0) {
                auto [px, py] = gridToScreen(gx, gy);
                SDL_FRect r{static_cast<float>(px) + 2.0f, static_cast<float>(py) - 2.0f, 32.0f, 16.0f};
                SDL_SetRenderDrawColor(renderer_, 0, 200, 255, 60);
                SDL_RenderFillRect(renderer_, &r);
            }
        }
    }
    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::drawEffectArea() {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);

    for (int gx = 0; gx < kBFieldSize; ++gx) {
        for (int gy = 0; gy < kBFieldSize; ++gy) {
            if (bField_[4][gx][gy] != 0) {
                auto [px, py] = gridToScreen(gx, gy);
                SDL_FRect r{static_cast<float>(px) + 2.0f, static_cast<float>(py) - 2.0f, 32.0f, 16.0f};
                SDL_SetRenderDrawColor(renderer_, 255, 60, 60, 80);
                SDL_RenderFillRect(renderer_, &r);
            }
        }
    }
    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::drawHurtNumbers() {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    for (int i = 0; i < broleAmount_; ++i) {
        if (brole_[i].element.showNumber > 0 && brole_[i].element.dead == 0) {
            auto [px, py] = gridToScreen(brole_[i].element.x, brole_[i].element.y);
            if (font_) {
                std::string num = std::to_string(brole_[i].element.showNumber);
                font_->draw(renderer_, num, px + 8, py - 20, 255, 50, 50);
            }
        }
    }
    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::showBattleMenu(int bnum, int& choice) {
    static const char* items[] = {
        "移動", "攻擊", "用毒", "解毒", "醫療", "等待", "休息", "自動"
    };
    constexpr int itemCount = 8;
    int sel = 0;

    while (true) {
        drawBField();

        // Show role status
        int rnum = brole_[bnum].element.rnum;
        showSimpleStatus(rnum, 10, renderH_ - 120);

        // Draw menu panel
        SDL_SetRenderTarget(renderer_, frameTexture_);
        SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
        float menuX = static_cast<float>(renderW_ - 160);
        float menuY = 60.0f;
        SDL_FRect menuBg{menuX, menuY, 150.0f, static_cast<float>(itemCount * 28 + 12)};
        SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 210);
        SDL_RenderFillRect(renderer_, &menuBg);
        SDL_SetRenderDrawColor(renderer_, 236, 216, 142, 220);
        SDL_RenderRect(renderer_, &menuBg);

        for (int i = 0; i < itemCount; ++i) {
            int ty = static_cast<int>(menuY) + 6 + i * 28;
            if (font_) {
                if (i == sel) {
                    font_->draw(renderer_, std::string("> ") + items[i],
                                static_cast<int>(menuX) + 8, ty, 255, 255, 100);
                } else {
                    font_->draw(renderer_, std::string("  ") + items[i],
                                static_cast<int>(menuX) + 8, ty, 200, 200, 200);
                }
            }
        }

        SDL_SetRenderTarget(renderer_, nullptr);
        presentFrame();

        int key = 0;
        if (!waitForKey(key)) { choice = -1; return; }

        if (key == SDLK_ESCAPE) { choice = -1; return; }
        if (key == SDLK_UP || key == SDLK_W) { if (sel > 0) sel--; }
        if (key == SDLK_DOWN || key == SDLK_S) { if (sel < itemCount - 1) sel++; }
        if (key == SDLK_RETURN || key == SDLK_SPACE) {
            choice = sel;
            return;
        }
    }
}

void KysBattle::showSimpleStatus(int rnum, int sx, int sy) {
    SDL_SetRenderTarget(renderer_, frameTexture_);
    SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);
    SDL_FRect bg{static_cast<float>(sx), static_cast<float>(sy), 240.0f, 110.0f};
    SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 200);
    SDL_RenderFillRect(renderer_, &bg);
    SDL_SetRenderDrawColor(renderer_, 236, 216, 142, 200);
    SDL_RenderRect(renderer_, &bg);

    if (font_) {
        std::string name = state_.getRoleName(rnum);
        int hp = state_.getRoleData(rnum, 17);
        int maxHp = state_.getRoleData(rnum, 18);
        int mp = state_.getRoleData(rnum, 41);
        int maxMp = state_.getRoleData(rnum, 42);
        int lev = state_.getRoleData(rnum, 15);

        font_->draw(renderer_, name, sx + 8, sy + 6, 255, 255, 200);

        std::ostringstream oss;
        oss << "等級 " << lev;
        font_->draw(renderer_, oss.str(), sx + 8, sy + 30, 200, 200, 200);

        oss.str(""); oss << "體力 " << hp << "/" << maxHp;
        font_->draw(renderer_, oss.str(), sx + 8, sy + 54, 200, 200, 200);

        oss.str(""); oss << "真氣 " << mp << "/" << maxMp;
        font_->draw(renderer_, oss.str(), sx + 8, sy + 78, 200, 200, 200);
    }

    // Draw head portrait
    int headNum = state_.getRoleData(rnum, 1);
    {
        SDL_Texture* headTex = loadHeadTexture(headNum);
        if (headTex) {
            float texW, texH;
            SDL_GetTextureSize(headTex, &texW, &texH);
            float scale = 64.0f / std::max(texW, texH);
            SDL_FRect dst{static_cast<float>(sx) + 170.0f, static_cast<float>(sy) + 8.0f,
                          texW * scale, texH * scale};
            SDL_RenderTexture(renderer_, headTex, nullptr, &dst);
        }
    }

    SDL_SetRenderTarget(renderer_, nullptr);
}

void KysBattle::showDamageNumber(int x, int y, int value) {
    if (font_) {
        font_->draw(renderer_, std::to_string(value), x, y, 255, 50, 50);
    }
}

void KysBattle::presentFrame() {
    if (frameTexture_) {
        SDL_SetRenderTarget(renderer_, nullptr);
        int ww = 0, wh = 0;
        SDL_Window* win = SDL_GetRenderWindow(renderer_);
        if (win) SDL_GetWindowSize(win, &ww, &wh);
        if (ww <= 0 || wh <= 0) { ww = renderW_; wh = renderH_; }

        float scale = std::min(static_cast<float>(ww) / renderW_,
                               static_cast<float>(wh) / renderH_);
        float dw = renderW_ * scale;
        float dh = renderH_ * scale;
        SDL_FRect dst{(ww - dw) * 0.5f, (wh - dh) * 0.5f, dw, dh};
        SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 255);
        SDL_RenderClear(renderer_);
        SDL_RenderTexture(renderer_, frameTexture_, nullptr, &dst);
        SDL_RenderPresent(renderer_);
    } else {
        SDL_RenderPresent(renderer_);
    }
}

void KysBattle::pumpEvents() {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_EVENT_QUIT) {
            bStatus_ = 2; // Treat quit as defeat
        }
    }
}

bool KysBattle::waitForKey(int& outKey) {
    SDL_Event ev;
    while (true) {
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_EVENT_QUIT) {
                bStatus_ = 2;
                return false;
            }
            if (ev.type == SDL_EVENT_KEY_DOWN) {
                outKey = static_cast<int>(ev.key.key);
                return true;
            }
        }
        SDL_Delay(8);
        if (bStatus_ != 0) return false;
    }
}

// ===========================================================================
// Head portrait texture loading (on-demand, cached)
// ===========================================================================

SDL_Texture* KysBattle::loadHeadTexture(int headNum) {
    if (headNum < 0) return nullptr;
    if (auto it = headCache_.find(headNum); it != headCache_.end()) return it->second;
    if (headMissing_.count(headNum)) return nullptr;

    const std::string fileName = std::to_string(headNum) + ".png";
    const std::array<std::string, 2> paths = {
        state_.appPath_ + "/head/" + fileName,
        "head/" + fileName
    };
    SDL_Surface* surface = nullptr;
    for (const auto& path : paths) {
        SDL_IOStream* stream = SDL_IOFromFile(path.c_str(), "rb");
        if (!stream) continue;
        surface = SDL_LoadPNG_IO(stream, true);
        if (surface) break;
    }
    if (!surface) { headMissing_[headNum] = true; return nullptr; }
    SDL_Texture* tex = SDL_CreateTextureFromSurface(renderer_, surface);
    SDL_DestroySurface(surface);
    if (!tex) { headMissing_[headNum] = true; return nullptr; }
    headCache_[headNum] = tex;
    return tex;
}

} // namespace kys
