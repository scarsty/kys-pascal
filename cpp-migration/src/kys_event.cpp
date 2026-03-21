// kys_event.cpp
// Event bytecode execution engine, split from kys_state.cpp for maintainability.
// All functions here are methods of KysState defined in kys_state.hpp.

#include "kys_state.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

namespace kys {
namespace {

// Path join helper (mirrors the one in kys_state.cpp)
std::string evJoinPath(const std::string& base, const std::string& rel) {
    if (base.empty()) {
        return rel;
    }
    if (base.back() == '/' || base.back() == '\\') {
        return base + rel;
    }
    return base + "/" + rel;
}

} // namespace

// ---------------------------------------------------------------------------
// Event queue / dispatch
// ---------------------------------------------------------------------------

void KysState::execEvent(int eventId, const std::vector<int>& args) {
    currentEvent_ = eventId;
    if (eventId >= 0) {
        pendingEvents_.push_back(eventId);
    }
    for (std::size_t i = 0; i < args.size(); ++i) {
        eventArgMap_[0x7100 + static_cast<int>(i)] = args[i];
    }
}

void KysState::callEvent(int eventId) {
    currentEvent_ = eventId;
    if (eventId >= 0) {
        executeEventCode(eventId);
        pendingEvents_.push_back(eventId);
    }
}

bool KysState::hasPendingEvent() const {
    return !pendingEvents_.empty();
}

int KysState::popPendingEvent() {
    if (pendingEvents_.empty()) {
        return -1;
    }
    const int eventId = pendingEvents_.front();
    pendingEvents_.erase(pendingEvents_.begin());
    return eventId;
}

// ---------------------------------------------------------------------------
// Scene event triggers
// ---------------------------------------------------------------------------

int KysState::tryTriggerCurrentSceneEvent() {
    if (where_ != 1 || curScene_ < 0 || curScene_ > 400) {
        return -1;
    }
    for (int eventIndex = 0; eventIndex < 200; ++eventIndex) {
        const int ex = getDData(curScene_, eventIndex, 9);
        const int ey = getDData(curScene_, eventIndex, 10);
        if (ex == sx_ && ey == sy_) {
            const int eventId = getDData(curScene_, eventIndex, 4);
            if (eventId > 0) {
                currentEvent_ = eventIndex;
                callEvent(eventId);
                return eventId;
            }
        }
    }
    return -1;
}

int KysState::tryTriggerFacingSceneEvent() {
    if (where_ != 1 || curScene_ < 0 || curScene_ > 400) {
        return -1;
    }
    int x = sx_;
    int y = sy_;
    switch (sFace_) {
        case 0: x -= 1; break;
        case 1: y += 1; break;
        case 2: y -= 1; break;
        case 3: x += 1; break;
        default: break;
    }
    if (x < 0 || x > 63 || y < 0 || y > 63) {
        return -1;
    }
    const int ev = getSData(curScene_, 3, x, y);
    if (ev >= 0) {
        const int eventId = getDData(curScene_, ev, 2);
        if (eventId >= 0) {
            currentEvent_ = ev;
            callEvent(eventId);
            return eventId;
        }
    }
    return -1;
}

// ---------------------------------------------------------------------------
// Story item use -> event trigger
// ---------------------------------------------------------------------------

std::string KysState::useStoryItem(int itemNumber) {
    if (itemNumber < 0 || itemNumber >= kMaxItems) {
        return "物品無效";
    }

    currentItem_ = itemNumber;

    const auto& item = rItem_[static_cast<std::size_t>(itemNumber)].element;
    if (item.itemType != 0) {
        return "非劇情物品";
    }

    if (item.unKnow7 > 0) {
        callEvent(item.unKnow7);
        return "已觸發劇情事件";
    }

    if (where_ != 1 || curScene_ < 0 || curScene_ > 400) {
        return "此處無法使用";
    }

    int x = sx_;
    int y = sy_;
    switch (sFace_) {
        case 0: x -= 1; break;
        case 1: y += 1; break;
        case 2: y -= 1; break;
        case 3: x += 1; break;
        default: break;
    }

    if (x < 0 || x > 63 || y < 0 || y > 63) {
        return "前方無事件";
    }

    const int sceneEvent = getSData(curScene_, 3, x, y);
    if (sceneEvent < 0) {
        return "前方無事件";
    }

    currentEvent_ = sceneEvent;
    const int eventId = getDData(curScene_, currentEvent_, 3);
    if (eventId >= 0) {
        callEvent(eventId);
        currentEvent_ = -1;
        return "事件觸發成功";
    }

    currentEvent_ = -1;
    return "事件條件不足";
}

// ---------------------------------------------------------------------------
// kdef data loading
// ---------------------------------------------------------------------------

bool KysState::ensureEventDefsLoaded() {
    if (eventDefLoaded_) {
        return !kIdx_.empty() && !kDef_.empty();
    }

    std::ifstream idx(evJoinPath(appPath_, "resource/kdef.idx"), std::ios::binary);
    std::ifstream grp(evJoinPath(appPath_, "resource/kdef.grp"), std::ios::binary);
    if (!idx || !grp) {
        eventDefLoaded_ = true;
        return false;
    }

    idx.seekg(0, std::ios::end);
    const auto idxSize = static_cast<std::size_t>(idx.tellg());
    idx.seekg(0, std::ios::beg);
    kIdx_.assign(idxSize / sizeof(std::int32_t), 0);
    if (!kIdx_.empty()) {
        idx.read(reinterpret_cast<char*>(kIdx_.data()),
                 static_cast<std::streamsize>(kIdx_.size() * sizeof(std::int32_t)));
    }

    grp.seekg(0, std::ios::end);
    const auto grpSize = static_cast<std::size_t>(grp.tellg());
    grp.seekg(0, std::ios::beg);
    kDef_.assign(grpSize, 0);
    if (!kDef_.empty()) {
        grp.read(reinterpret_cast<char*>(kDef_.data()),
                 static_cast<std::streamsize>(kDef_.size()));
    }

    eventDefLoaded_ = true;
    return !kIdx_.empty() && !kDef_.empty();
}

std::vector<i16> KysState::readEventCode(int eventId) {
    if (!ensureEventDefsLoaded()) {
        return {};
    }
    if (eventId < 0 || static_cast<std::size_t>(eventId) >= kIdx_.size()) {
        return {};
    }

    int offset = 0;
    int len = 0;
    if (eventId == 0) {
        len = kIdx_[0];
    } else {
        offset = kIdx_[static_cast<std::size_t>(eventId - 1)];
        len = kIdx_[static_cast<std::size_t>(eventId)] - offset;
    }

    if (offset < 0 || len <= 0 || (len % 2) != 0) {
        return {};
    }
    if (static_cast<std::size_t>(offset + len) > kDef_.size()) {
        return {};
    }

    const std::size_t count = static_cast<std::size_t>(len / 2);
    std::vector<i16> code(count, 0);
    for (std::size_t i = 0; i < count; ++i) {
        const std::size_t p = static_cast<std::size_t>(offset) + i * 2;
        const std::uint16_t lo = static_cast<std::uint16_t>(kDef_[p]);
        const std::uint16_t hi = static_cast<std::uint16_t>(kDef_[p + 1]);
        code[i] = static_cast<i16>((hi << 8) | lo);
    }
    return code;
}

// ---------------------------------------------------------------------------
// execInstruct3: opcode 3 helper - manages scene event data and sprite layer
// ---------------------------------------------------------------------------

void KysState::execInstruct3(const std::array<int, 13>& list) {
    int s = list[0];
    int e = list[1];
    if (s == -2) {
        s = curScene_;
    }
    if (e == -2) {
        e = currentEvent_;
    }
    if (s < 0 || s > 400 || e < 0 || e > 199) {
        return;
    }

    int x = list[11];
    int y = list[12];
    if (x == -2) {
        x = getDData(s, e, 9);
    }
    if (y == -2) {
        y = getDData(s, e, 10);
    }
    (void)x;
    (void)y;

    const int oldX = getDData(s, e, 9);
    const int oldY = getDData(s, e, 10);
    if (oldX >= 0 && oldX <= 63 && oldY >= 0 && oldY <= 63) {
        setSData(s, 3, oldX, oldY, -1);
    }

    for (int i = 0; i <= 10; ++i) {
        const int v = list[2 + i];
        if (v != -2) {
            setDData(s, e, i, v);
        }
    }

    const int nx = getDData(s, e, 9);
    const int ny = getDData(s, e, 10);
    if (nx >= 0 && nx <= 63 && ny >= 0 && ny <= 63) {
        setSData(s, 3, nx, ny, e);
    }
}

// ---------------------------------------------------------------------------
// executeEventCode: main event bytecode interpreter
// Opcodes match the original Pascal callevent implementation.
// ---------------------------------------------------------------------------

void KysState::executeEventCode(int eventId) {
    auto code = readEventCode(eventId);
    if (code.empty()) {
        return;
    }

    int pc = 0;
    const int n = static_cast<int>(code.size());
    while (pc >= 0 && pc < n) {
        const int op = code[static_cast<std::size_t>(pc)];
        if (op < 0) {
            break;
        }

        auto readAt = [&](int p) -> int {
            if (p < 0 || p >= n) {
                return 0;
            }
            return code[static_cast<std::size_t>(p)];
        };

        auto branchOffset = [&](int jump1Pos, int jump2Pos, bool cond) {
            const int off = cond ? readAt(jump1Pos) : readAt(jump2Pos);
            pc += off;
        };

        switch (op) {
            case 0: {
                // NOP
                pc += 1;
                break;
            }
            case 1: {
                // talk(talkNum, headNum, dismode)
                if (pc + 3 >= n) { return; }
                const int talkNum = readAt(pc + 1);
                const int headNum = readAt(pc + 2);
                const int dismode = readAt(pc + 3);
                const std::string talk = getTalk(talkNum);
                if (talkCallback_) {
                    talkCallback_(talk, headNum, dismode);
                }
                pc += 4;
                break;
            }
            case 2: {
                // getItem: add item + show notification
                if (pc + 2 >= n) { return; }
                const int inum2 = readAt(pc + 1);
                const int amount2 = readAt(pc + 2);
                addItemAmount(inum2, amount2);
                if (getItemCallback_) {
                    getItemCallback_(getItemName(inum2), amount2);
                }
                pc += 3;
                break;
            }
            case 3: {
                // setEventData(13 params)
                if (pc + 13 >= n) { return; }
                std::array<int, 13> list{};
                for (int i = 0; i < 13; ++i) {
                    list[static_cast<std::size_t>(i)] = readAt(pc + 1 + i);
                }
                execInstruct3(list);
                pc += 14;
                break;
            }
            case 4: {
                // if usedItem == inum jump1 else jump2
                if (pc + 3 >= n) { return; }
                const int inum = readAt(pc + 1);
                branchOffset(pc + 2, pc + 3, inum == currentItem_);
                pc += 4;
                break;
            }
            case 5: {
                // ask battle
                if (pc + 2 >= n) { return; }
                bool yes = true;
                if (yesNoCallback_) {
                    yes = yesNoCallback_("事件選擇", "是否與之战鬥？", true);
                }
                branchOffset(pc + 1, pc + 2, yes);
                pc += 3;
                break;
            }
            case 6: {
                // battle(battlenum, jump1, jump2, getexp): simulate success
                if (pc + 4 >= n) { return; }
                currentBattle_ = readAt(pc + 1);
                (void)readAt(pc + 4); // getexp – unused for now
                branchOffset(pc + 2, pc + 3, true);
                pc += 5;
                break;
            }
            case 7: {
                // end / return
                return;
            }
            case 8: {
                // set exit-scene music (stored in memory map)
                if (pc + 1 >= n) { return; }
                writeMem(0x7300, readAt(pc + 1));
                pc += 2;
                break;
            }
            case 9: {
                // ask join team
                if (pc + 2 >= n) { return; }
                bool yes = true;
                if (yesNoCallback_) {
                    yes = yesNoCallback_("事件選擇", "是否要求加入？", true);
                }
                branchOffset(pc + 1, pc + 2, yes);
                pc += 3;
                break;
            }
            case 10: {
                // join team member + transfer taking items
                if (pc + 1 >= n) { return; }
                const int rnum = readAt(pc + 1);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    for (int i = 0; i < kTeamSize; ++i) {
                        if (teamList_[static_cast<std::size_t>(i)] < 0) {
                            teamList_[static_cast<std::size_t>(i)] = static_cast<i16>(rnum);
                            for (int t = 0; t < 4; ++t) {
                                const int item = rRole_[static_cast<std::size_t>(rnum)].element.takingItem[t];
                                int amount = rRole_[static_cast<std::size_t>(rnum)].element.takingItemAmount[t];
                                if (item >= 0 && amount <= 0) { amount = 1; }
                                if (item >= 0 && amount > 0) {
                                    addItemAmount(item, amount);
                                    rRole_[static_cast<std::size_t>(rnum)].element.takingItem[t] = -1;
                                    rRole_[static_cast<std::size_t>(rnum)].element.takingItemAmount[t] = 0;
                                }
                            }
                            break;
                        }
                    }
                }
                pc += 2;
                break;
            }
            case 11: {
                // ask stay at inn
                if (pc + 2 >= n) { return; }
                bool yes = true;
                if (yesNoCallback_) {
                    yes = yesNoCallback_("事件選擇", "是否需要住宿？", true);
                }
                branchOffset(pc + 1, pc + 2, yes);
                pc += 3;
                break;
            }
            case 12: {
                // stay: recover whole team
                for (int i = 0; i < kTeamSize; ++i) {
                    const int rnum = teamList_[static_cast<std::size_t>(i)];
                    if (rnum < 0 || rnum >= kMaxRoles) { continue; }
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    if (!(r.hurt > 33 || r.poison > 0)) {
                        r.currentHP = r.maxHP;
                        r.currentMP = r.maxMP;
                        r.phyPower = 100;
                        int hurt = static_cast<int>(r.hurt) - 33;
                        int poison = static_cast<int>(r.poison) - 33;
                        if (hurt < 0) { hurt = 0; }
                        if (poison < 0) { poison = 0; }
                        r.hurt = static_cast<i16>(hurt);
                        r.poison = static_cast<i16>(poison);
                    }
                }
                pc += 1;
                break;
            }
            case 13: {
                // bright screen (renderer-side effect, ignored here)
                pc += 1;
                break;
            }
            case 14: {
                // black screen (renderer-side effect, ignored here)
                pc += 1;
                break;
            }
            case 15: {
                return;
            }
            case 16: {
                // is role in team?  jump1=yes  jump2=no
                if (pc + 3 >= n) { return; }
                const int rnum = readAt(pc + 1);
                bool inTeam = false;
                for (int i = 0; i < kTeamSize; ++i) {
                    if (teamList_[static_cast<std::size_t>(i)] == rnum) {
                        inTeam = true;
                        break;
                    }
                }
                branchOffset(pc + 2, pc + 3, inTeam);
                pc += 4;
                break;
            }
            case 17: {
                // set sData tile
                if (pc + 5 >= n) { return; }
                int s = readAt(pc + 1);
                if (s == -2) { s = curScene_; }
                const int layer = readAt(pc + 2);
                const int y = readAt(pc + 3);
                const int x = readAt(pc + 4);
                const int value = readAt(pc + 5);
                setSData(s, layer, x, y, value);
                pc += 6;
                break;
            }
            case 18: {
                // has item?  jump1=yes  jump2=no
                if (pc + 3 >= n) { return; }
                const int inum = readAt(pc + 1);
                bool hasItem = false;
                for (const auto& it : rItemList_) {
                    if (it.number == inum && it.amount > 0) {
                        hasItem = true;
                        break;
                    }
                }
                branchOffset(pc + 2, pc + 3, hasItem);
                pc += 4;
                break;
            }
            case 19: {
                // set scene position (note: args are y, x order in bytecode)
                if (pc + 2 >= n) { return; }
                setScenePosition(readAt(pc + 2), readAt(pc + 1));
                pc += 3;
                break;
            }
            case 20: {
                // team full?  jump1=full  jump2=has empty slot
                if (pc + 2 >= n) { return; }
                bool full = true;
                for (int i = 0; i < kTeamSize; ++i) {
                    if (teamList_[static_cast<std::size_t>(i)] < 0) {
                        full = false;
                        break;
                    }
                }
                branchOffset(pc + 1, pc + 2, full);
                pc += 3;
                break;
            }
            case 21: {
                // remove team member by role id
                if (pc + 1 >= n) { return; }
                const int rnum = readAt(pc + 1);
                int p = 0;
                std::array<i16, kTeamSize> newTeam{};
                for (int i = 0; i < kTeamSize; ++i) {
                    newTeam[static_cast<std::size_t>(i)] = -1;
                }
                for (int i = 0; i < kTeamSize; ++i) {
                    const int t = teamList_[static_cast<std::size_t>(i)];
                    if (t != rnum && p < kTeamSize) {
                        newTeam[static_cast<std::size_t>(p)] = static_cast<i16>(t);
                        ++p;
                    }
                }
                teamList_ = newTeam;
                pc += 2;
                break;
            }
            case 22: {
                // zero all team MP
                for (int i = 0; i < kTeamSize; ++i) {
                    const int rnum = teamList_[static_cast<std::size_t>(i)];
                    if (rnum >= 0 && rnum < kMaxRoles) {
                        rRole_[static_cast<std::size_t>(rnum)].element.currentMP = 0;
                    }
                }
                pc += 1;
                break;
            }
            case 23: {
                // set role usePoi
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int poi = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    rRole_[static_cast<std::size_t>(rnum)].element.usePoi = static_cast<i16>(poi);
                }
                pc += 3;
                break;
            }
            case 24: {
                pc += 1;
                break;
            }
            case 25: {
                // sceneFromTo(y1, x1, y2, x2) — positional warp with animation
                if (pc + 4 >= n) { return; }
                sceneFromTo(readAt(pc + 1), readAt(pc + 2), readAt(pc + 3), readAt(pc + 4));
                pc += 5;
                break;
            }
            case 26: {
                // add dData[s,e,2..4] by delta values
                if (pc + 5 >= n) { return; }
                int s = readAt(pc + 1);
                const int e = readAt(pc + 2);
                if (s == -2) { s = curScene_; }
                if (s >= 0 && s <= 400 && e >= 0 && e <= 199) {
                    for (int i = 0; i < 3; ++i) {
                        const int add = readAt(pc + 3 + i);
                        if (add != -2) {
                            const int cur = getDData(s, e, i + 2);
                            setDData(s, e, i + 2, cur + add);
                        }
                    }
                }
                pc += 6;
                break;
            }
            case 27: {
                // animation: advance event sprite frame to endPic
                if (pc + 3 >= n) { return; }
                const int ev = readAt(pc + 1);
                const int endPic = readAt(pc + 3);
                if (ev >= 0 && ev <= 199 && curScene_ >= 0 && curScene_ <= 400) {
                    setDData(curScene_, ev, 5, endPic);
                    setDData(curScene_, ev, 6, endPic);
                    setDData(curScene_, ev, 7, endPic);
                }
                pc += 4;
                break;
            }
            case 28: {
                // role ethics in range [e1, e2]?
                if (pc + 5 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int e1 = readAt(pc + 2);
                const int e2 = readAt(pc + 3);
                bool ok = false;
                if (rnum >= 0 && rnum < kMaxRoles) {
                    const int ethics = rRole_[static_cast<std::size_t>(rnum)].element.ethics;
                    ok = ethics >= e1 && ethics <= e2;
                }
                branchOffset(pc + 4, pc + 5, ok);
                pc += 6;
                break;
            }
            case 29: {
                // role attack in range [r1, r2]?
                if (pc + 5 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int r1 = readAt(pc + 2);
                const int r2 = readAt(pc + 3);
                bool ok = false;
                if (rnum >= 0 && rnum < kMaxRoles) {
                    const int att = rRole_[static_cast<std::size_t>(rnum)].element.attack;
                    ok = att >= r1 && att <= r2;
                }
                branchOffset(pc + 4, pc + 5, ok);
                pc += 6;
                break;
            }
            case 30: {
                // role move path final position update
                if (pc + 4 >= n) { return; }
                const int x2 = readAt(pc + 3);
                const int y2 = readAt(pc + 4);
                setScenePosition(y2, x2);
                pc += 5;
                break;
            }
            case 31: {
                // money check (item 174 = money)
                if (pc + 3 >= n) { return; }
                const int moneyNeed = readAt(pc + 1);
                int money = 0;
                for (const auto& it : rItemList_) {
                    if (it.number == 174) {
                        money = it.amount;
                        break;
                    }
                }
                branchOffset(pc + 2, pc + 3, money >= moneyNeed);
                pc += 4;
                break;
            }
            case 32: {
                // addItem (silent, no UI notification)
                if (pc + 2 >= n) { return; }
                addItemAmount(readAt(pc + 1), readAt(pc + 2));
                pc += 3;
                break;
            }
            case 33: {
                // learn magic / level-up existing magic
                if (pc + 3 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int magicNum = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    int slot = -1;
                    for (int i = 0; i < 10; ++i) {
                        if (r.magic[i] == magicNum) {
                            int lvl = static_cast<int>(r.magLevel[i]) + 100;
                            if (lvl > 999) { lvl = 999; }
                            r.magLevel[i] = static_cast<i16>(lvl);
                            slot = i;
                            break;
                        }
                    }
                    if (slot < 0) {
                        for (int i = 0; i < 10; ++i) {
                            if (r.magic[i] <= 0) {
                                r.magic[i] = static_cast<i16>(magicNum);
                                if (r.magLevel[i] <= 0) { r.magLevel[i] = 100; }
                                break;
                            }
                        }
                    }
                }
                pc += 4;
                break;
            }
            case 34: {
                // add aptitude, cap at 100
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int iq = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    int next = static_cast<int>(r.aptitude) + iq;
                    if (next > 100) { next = 100; }
                    if (next < 0) { next = 0; }
                    r.aptitude = static_cast<i16>(next);
                }
                pc += 3;
                break;
            }
            case 35: {
                // set/assign magic to role
                if (pc + 4 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int magicSlot = readAt(pc + 2);
                const int magicNum = readAt(pc + 3);
                const int exp = readAt(pc + 4);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    if (magicSlot >= 0 && magicSlot < 10) {
                        r.magic[magicSlot] = static_cast<i16>(magicNum);
                        r.magLevel[magicSlot] = static_cast<i16>(exp);
                    } else {
                        int p = -1;
                        for (int i = 0; i < 10; ++i) {
                            if (r.magic[i] <= 0) { p = i; break; }
                        }
                        if (p < 0) { p = 0; }
                        r.magic[p] = static_cast<i16>(magicNum);
                        r.magLevel[p] = static_cast<i16>(exp);
                    }
                }
                pc += 5;
                break;
            }
            case 36: {
                // protagonist sexual check
                if (pc + 3 >= n) { return; }
                const int sexual = readAt(pc + 1);
                bool ok = false;
                if (sexual > 255) {
                    ok = (readMem(0x7000) == 0);
                } else if (0 < kMaxRoles) {
                    ok = (rRole_[0].element.sexual == sexual);
                }
                branchOffset(pc + 2, pc + 3, ok);
                pc += 4;
                break;
            }
            case 37: {
                // add ethics to role 0
                if (pc + 1 >= n) { return; }
                int ethics = static_cast<int>(rRole_[0].element.ethics) + readAt(pc + 1);
                if (ethics > 100) { ethics = 100; }
                if (ethics < 0) { ethics = 0; }
                rRole_[0].element.ethics = static_cast<i16>(ethics);
                pc += 2;
                break;
            }
            case 38: {
                // bulk-replace tile in scene layer
                if (pc + 4 >= n) { return; }
                int s = readAt(pc + 1);
                const int layer = readAt(pc + 2);
                const int oldPic = readAt(pc + 3);
                const int newPic = readAt(pc + 4);
                if (s == -2) { s = curScene_; }
                if (s >= 0 && s <= 400 && layer >= 0 && layer <= 5) {
                    for (int x = 0; x < 64; ++x) {
                        for (int y = 0; y < 64; ++y) {
                            if (getSData(s, layer, x, y) == oldPic) {
                                setSData(s, layer, x, y, newPic);
                            }
                        }
                    }
                }
                pc += 5;
                break;
            }
            case 39: {
                // clear scene entrance condition
                if (pc + 1 >= n) { return; }
                const int s = readAt(pc + 1);
                if (s >= 0 && s < kMaxScenes) {
                    rScene_[static_cast<std::size_t>(s)].element.enCondition = 0;
                }
                pc += 2;
                break;
            }
            case 40: {
                // set scene facing direction
                if (pc + 1 >= n) { return; }
                setSceneFace(readAt(pc + 1));
                pc += 2;
                break;
            }
            case 41: {
                // modify role taking-item list
                if (pc + 3 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int inum = readAt(pc + 2);
                const int amount = readAt(pc + 3);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    bool found = false;
                    for (int i = 0; i < 4; ++i) {
                        if (r.takingItem[i] == inum) {
                            r.takingItemAmount[i] = static_cast<i16>(
                                static_cast<int>(r.takingItemAmount[i]) + amount);
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        for (int i = 0; i < 4; ++i) {
                            if (r.takingItem[i] == -1) {
                                r.takingItem[i] = static_cast<i16>(inum);
                                r.takingItemAmount[i] = static_cast<i16>(amount);
                                break;
                            }
                        }
                    }
                    for (int i = 0; i < 4; ++i) {
                        if (r.takingItemAmount[i] <= 0) {
                            r.takingItem[i] = -1;
                            r.takingItemAmount[i] = 0;
                        }
                    }
                }
                pc += 4;
                break;
            }
            case 42: {
                // any female in team?
                if (pc + 2 >= n) { return; }
                bool hasFemale = false;
                for (int i = 0; i < kTeamSize; ++i) {
                    const int rnum = teamList_[static_cast<std::size_t>(i)];
                    if (rnum >= 0 && rnum < kMaxRoles &&
                        rRole_[static_cast<std::size_t>(rnum)].element.sexual == 1) {
                        hasFemale = true;
                        break;
                    }
                }
                branchOffset(pc + 1, pc + 2, hasFemale);
                pc += 3;
                break;
            }
            case 43: {
                // has item alias
                if (pc + 3 >= n) { return; }
                const int inum = readAt(pc + 1);
                bool hasItem = false;
                for (const auto& it : rItemList_) {
                    if (it.number == inum && it.amount > 0) {
                        hasItem = true;
                        break;
                    }
                }
                branchOffset(pc + 2, pc + 3, hasItem);
                pc += 4;
                break;
            }
            case 44: {
                // dual event animation final frame
                if (pc + 6 >= n) { return; }
                int e1 = readAt(pc + 1);
                const int end1 = readAt(pc + 3);
                int e2 = readAt(pc + 4);
                const int end2 = readAt(pc + 6);
                if (e1 == -1) { e1 = currentEvent_; }
                if (e2 == -1) { e2 = currentEvent_; }
                if (curScene_ >= 0 && curScene_ <= 400) {
                    if (e1 >= 0 && e1 <= 199) { setDData(curScene_, e1, 5, end1); }
                    if (e2 >= 0 && e2 <= 199) { setDData(curScene_, e2, 5, end2); }
                }
                pc += 7;
                break;
            }
            case 45: {
                // add speed to role
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int v = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    rRole_[static_cast<std::size_t>(rnum)].element.speed =
                        static_cast<i16>(static_cast<int>(
                            rRole_[static_cast<std::size_t>(rnum)].element.speed) + v);
                }
                pc += 3;
                break;
            }
            case 46: {
                // add maxMP (and restore current MP)
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int v = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    r.maxMP = static_cast<i16>(static_cast<int>(r.maxMP) + v);
                    r.currentMP = r.maxMP;
                }
                pc += 3;
                break;
            }
            case 47: {
                // add attack to role
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int v = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    rRole_[static_cast<std::size_t>(rnum)].element.attack =
                        static_cast<i16>(static_cast<int>(
                            rRole_[static_cast<std::size_t>(rnum)].element.attack) + v);
                }
                pc += 3;
                break;
            }
            case 48: {
                // add maxHP (and restore current HP)
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int v = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    auto& r = rRole_[static_cast<std::size_t>(rnum)].element;
                    r.maxHP = static_cast<i16>(static_cast<int>(r.maxHP) + v);
                    r.currentHP = r.maxHP;
                }
                pc += 3;
                break;
            }
            case 49: {
                // set role mpType
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int v = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    rRole_[static_cast<std::size_t>(rnum)].element.mpType = static_cast<i16>(v);
                }
                pc += 3;
                break;
            }
            case 54: {
                // open all major scenes (unlock up to scene 101)
                int maxScene = sceneAmount_;
                if (maxScene > 101) { maxScene = 101; }
                for (int i = 0; i < maxScene; ++i) {
                    rScene_[static_cast<std::size_t>(i)].element.enCondition = 0;
                }
                if (2 < kMaxScenes) { rScene_[2].element.enCondition = 2; }
                if (38 < kMaxScenes) { rScene_[38].element.enCondition = 2; }
                if (75 < kMaxScenes) { rScene_[75].element.enCondition = 1; }
                if (80 < kMaxScenes) { rScene_[80].element.enCondition = 1; }
                pc += 1;
                break;
            }
            case 55: {
                // judge event dData[curScene,ev,2] == value
                if (pc + 4 >= n) { return; }
                const int ev = readAt(pc + 1);
                const int value = readAt(pc + 2);
                bool ok = false;
                if (curScene_ >= 0 && curScene_ <= 400 && ev >= 0 && ev <= 199) {
                    ok = (getDData(curScene_, ev, 2) == value);
                }
                branchOffset(pc + 3, pc + 4, ok);
                pc += 5;
                break;
            }
            case 56: {
                // add repute to protagonist (role 0)
                if (pc + 1 >= n) { return; }
                auto& r = rRole_[0].element;
                r.repute = static_cast<i16>(static_cast<int>(r.repute) + readAt(pc + 1));
                pc += 2;
                break;
            }
            case 59: {
                // all leave team except role 0
                for (int i = 1; i < kTeamSize; ++i) {
                    teamList_[static_cast<std::size_t>(i)] = -1;
                }
                pc += 1;
                break;
            }
            default: {
                // Unknown opcode: stop to avoid desynchronising the stream
                return;
            }
        }
    }
}

} // namespace kys
