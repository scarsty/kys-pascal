// kys_event.cpp
// Event bytecode execution engine, split from kys_state.cpp for maintainability.
// All functions here are methods of KysState defined in kys_state.hpp.

#include "kys_state.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
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
// instruct_50e helpers and implementation
// ---------------------------------------------------------------------------

int KysState::e50GetValue(int bit, int t, int x) const {
    const int mask = 1 << bit;
    if ((t & mask) == 0) {
        return x;
    }
    if (x >= 0 && x < kX50Size) {
        return static_cast<int>(x50_[static_cast<std::size_t>(x)]);
    }
    return 0;
}

int KysState::e50CutRegion(int x) {
    if (x >= 0x8000 || x < -0x8000) {
        return (x + 0x8000) % 0x10000 - 0x8000;
    }
    return x;
}

bool KysState::haveMagic(int person, int magicNum, int level) const {
    if (person < 0 || person >= kMaxRoles) { return false; }
    const auto& r = rRole_[static_cast<std::size_t>(person)].element;
    for (int i = 0; i < 10; ++i) {
        if (r.magic[i] == magicNum && r.magLevel[i] >= level) {
            return true;
        }
    }
    return false;
}

int KysState::execInstruct50e(int code, int e1, int e2, int e3, int e4, int e5, int e6) {
    int result = 0;

    auto safeX50 = [&](int idx) -> i16& {
        static i16 dummy = 0;
        if (idx >= 0 && idx < kX50Size) { return x50_[static_cast<std::size_t>(idx)]; }
        dummy = 0;
        return dummy;
    };

    switch (code) {
    case 0: // Set variable: x50[e1] = e2
        safeX50(e1) = static_cast<i16>(e2);
        break;

    case 1: { // Set array element: x50[e3 + getValue(e4)] = getValue(e5)
        int t1 = e3 + e50GetValue(0, e1, e4);
        t1 = e50CutRegion(t1);
        i16 v = static_cast<i16>(e50GetValue(1, e1, e5));
        safeX50(t1) = v;
        if (e2 == 1) { safeX50(t1) = static_cast<i16>(safeX50(t1) & 0xFF); }
        break;
    }

    case 2: { // Get array element: x50[e5] = x50[e3 + getValue(e4)]
        int t1 = e3 + e50GetValue(0, e1, e4);
        t1 = e50CutRegion(t1);
        safeX50(e5) = safeX50(t1);
        if (e2 == 1) { safeX50(t1) = static_cast<i16>(safeX50(t1) & 0xFF); }
        break;
    }

    case 3: { // Arithmetic: x50[e3] = x50[e4] OP getValue(e5)
        const int t1 = e50GetValue(0, e1, e5);
        const int a = static_cast<int>(safeX50(e4));
        int r = 0;
        switch (e2) {
            case 0: r = a + t1; break;
            case 1: r = a - t1; break;
            case 2: r = a * t1; break;
            case 3: r = (t1 != 0) ? a / t1 : a; break;
            case 4: r = (t1 != 0) ? a % t1 : 0; break;
            case 5: r = (t1 != 0) ? static_cast<int>(static_cast<std::uint16_t>(a)) / t1 : a; break;
            default: break;
        }
        safeX50(e3) = static_cast<i16>(r);
        break;
    }

    case 4: { // Compare: x50[0x7000] = 0 if condition true, 1 otherwise
        safeX50(0x7000) = 0;
        const int t1 = e50GetValue(0, e1, e4);
        const int a = static_cast<int>(safeX50(e3));
        bool condTrue = false;
        switch (e2) {
            case 0: condTrue = (a < t1); break;
            case 1: condTrue = (a <= t1); break;
            case 2: condTrue = (a == t1); break;
            case 3: condTrue = (a != t1); break;
            case 4: condTrue = (a >= t1); break;
            case 5: condTrue = (a > t1); break;
            case 6: condTrue = true; break;
            case 7: condTrue = false; break;
            default: break;
        }
        if (!condTrue) { safeX50(0x7000) = 1; }
        break;
    }

    case 5: // Clear all x50 variables
        x50_.fill(0);
        break;

    case 8: { // Read talk to string buffer at x50[e3]
        const int talkIdx = e50GetValue(0, e1, e2);
        const std::string talk = getTalk(talkIdx);
        char* dst = reinterpret_cast<char*>(&x50_[static_cast<std::size_t>(std::max(0, e3))]);
        const std::size_t maxBytes = static_cast<std::size_t>((kX50Size - std::max(0, e3))) * 2;
        std::size_t copyLen = std::min(talk.size(), maxBytes - 1);
        std::memcpy(dst, talk.data(), copyLen);
        dst[copyLen] = '\0';
        break;
    }

    case 9: { // Format string: x50[e2] = sprintf(x50[e3], e4)
        const int fmtVal = e50GetValue(0, e1, e4);
        const char* fmtStr = reinterpret_cast<const char*>(&safeX50(e3));
        char* dst = reinterpret_cast<char*>(&safeX50(e2));
        // Simple integer substitution: replace %d with the value
        std::string fmt(fmtStr);
        auto dpos = fmt.find("%d");
        std::string out;
        if (dpos != std::string::npos) {
            out = fmt.substr(0, dpos) + std::to_string(fmtVal) + fmt.substr(dpos + 2);
        } else {
            out = fmt;
        }
        const std::size_t maxBytes = static_cast<std::size_t>((kX50Size - std::max(0, e2))) * 2;
        std::size_t copyLen = std::min(out.size(), maxBytes - 1);
        std::memcpy(dst, out.data(), copyLen);
        dst[copyLen] = '\0';
        break;
    }

    case 10: { // String length: x50[e2] = strlen(x50[e1])
        const char* p = reinterpret_cast<const char*>(&x50_[static_cast<std::size_t>(std::max(0, e1))]);
        safeX50(e2) = static_cast<i16>(std::strlen(p));
        break;
    }

    case 11: { // Concatenate strings: x50[e1] = x50[e2] + x50[e3]
        char* dst = reinterpret_cast<char*>(&safeX50(e1));
        const char* s1 = reinterpret_cast<const char*>(&safeX50(e2));
        const char* s2 = reinterpret_cast<const char*>(&safeX50(e3));
        const std::size_t len1 = std::strlen(s1);
        std::memcpy(dst, s1, len1);
        std::size_t off = len1;
        if (len1 % 2 == 1) { dst[off] = ' '; ++off; }
        const std::size_t len2 = std::strlen(s2);
        std::memcpy(dst + off, s2, len2 + 1);
        break;
    }

    case 12: { // Build string with spaces: x50[e2] = string of (e3/2) spaces
        const int count = e50GetValue(0, e1, e3);
        char* dst = reinterpret_cast<char*>(&safeX50(e2));
        const int numSpaces = count / 2;
        for (int i = 0; i < numSpaces && i < kX50Size; ++i) {
            dst[i] = ' ';
        }
        dst[numSpaces] = '\0';
        break;
    }

    case 16: { // Write R-data: RData[e2][e3][e4/2] = e5
        const int idx = e50GetValue(0, e1, e3);
        const int field = e50GetValue(1, e1, e4);
        const int val = e50GetValue(2, e1, e5);
        if (idx >= 0) {
            switch (e2) {
                case 0: setRoleData(idx, field / 2, val); break;
                case 1: setItemData(idx, field / 2, val); break;
                case 2: setSceneData(idx, field / 2, val); break;
                case 3: setMagicData(idx, field / 2, val); break;
                case 4: if (idx < kMaxShops) {
                    rShop_[static_cast<std::size_t>(idx)].data[field / 2] = static_cast<i16>(val);
                } break;
                default: break;
            }
        }
        break;
    }

    case 17: { // Read R-data: x50[e5] = RData[e2][e3][e4/2]
        const int idx = e50GetValue(0, e1, e3);
        const int field = e50GetValue(1, e1, e4);
        int val = 0;
        if (idx >= 0) {
            switch (e2) {
                case 0: val = getRoleData(idx, field / 2); break;
                case 1: val = getItemData(idx, field / 2); break;
                case 2: val = getSceneData(idx, field / 2); break;
                case 3: val = getMagicData(idx, field / 2); break;
                case 4: if (idx < kMaxShops) {
                    val = rShop_[static_cast<std::size_t>(idx)].data[field / 2];
                } break;
                default: break;
            }
        }
        safeX50(e5) = static_cast<i16>(val);
        break;
    }

    case 18: { // Write team data: teamList[e2] = e3
        const int idx = e50GetValue(0, e1, e2);
        const int val = e50GetValue(1, e1, e3);
        if (idx >= 0 && idx < kTeamSize) {
            teamList_[static_cast<std::size_t>(idx)] = static_cast<i16>(val);
        }
        break;
    }

    case 19: { // Read team data: x50[e3] = teamList[e2]
        const int idx = e50GetValue(0, e1, e2);
        if (idx >= 0 && idx < kTeamSize) {
            safeX50(e3) = static_cast<i16>(teamList_[static_cast<std::size_t>(idx)]);
        }
        break;
    }

    case 20: { // Get item amount: x50[e3] = amount of item e2
        const int inum = e50GetValue(0, e1, e2);
        i16 amt = 0;
        for (const auto& it : rItemList_) {
            if (it.number == inum) {
                amt = static_cast<i16>(it.amount);
                break;
            }
        }
        safeX50(e3) = amt;
        break;
    }

    case 21: { // Write DData: DData[e2, e3, e4] = e5
        const int s = e50GetValue(0, e1, e2);
        const int ev = e50GetValue(1, e1, e3);
        const int di = e50GetValue(2, e1, e4);
        const int val = e50GetValue(3, e1, e5);
        setDData(s, ev, di, val);
        break;
    }

    case 22: { // Read DData: x50[e5] = DData[e2, e3, e4]
        const int s = e50GetValue(0, e1, e2);
        const int ev = e50GetValue(1, e1, e3);
        const int di = e50GetValue(2, e1, e4);
        safeX50(e5) = static_cast<i16>(getDData(s, ev, di));
        break;
    }

    case 23: { // Write SData: SData[e2, e3, e5, e4] = e6
        const int s = e50GetValue(0, e1, e2);
        const int ly = e50GetValue(1, e1, e3);
        const int x = e50GetValue(2, e1, e4);
        const int y = e50GetValue(3, e1, e5);
        const int val = e50GetValue(4, e1, e6);
        setSData(s, ly, x, y, val);
        break;
    }

    case 24: { // Read SData: x50[e6] = SData[e2, e3, e5, e4]
        const int s = e50GetValue(0, e1, e2);
        const int ly = e50GetValue(1, e1, e3);
        const int x = e50GetValue(2, e1, e4);
        const int y = e50GetValue(3, e1, e5);
        safeX50(e6) = static_cast<i16>(getSData(s, ly, x, y));
        break;
    }

    case 25: { // Write special addresses (memory-mapped game state)
        const int val = e50GetValue(0, e1, e5);
        const int addr = e50GetValue(1, e1, e6);
        const std::uint32_t t1 = static_cast<std::uint32_t>(static_cast<std::uint16_t>(e3))
                               + static_cast<std::uint32_t>(static_cast<std::uint16_t>(e4)) * 0x10000u
                               + static_cast<std::uint32_t>(static_cast<std::uint16_t>(addr));
        const std::uint32_t base = static_cast<std::uint32_t>(static_cast<std::uint16_t>(e3))
                                 + static_cast<std::uint32_t>(static_cast<std::uint16_t>(e4)) * 0x10000u;
        if (t1 == 0x1D295Au) { sx_ = static_cast<i16>(val); }
        else if (t1 == 0x1D295Cu) { sy_ = static_cast<i16>(val); }
        else if (t1 == 0x1D295Eu) { curScene_ = val; }
        else if (base == 0x18FE2Cu) {
            const int i = addr;
            if (i % 4 <= 1 && i / 4 >= 0 && i / 4 < static_cast<int>(rItemList_.size())) {
                rItemList_[static_cast<std::size_t>(i / 4)].number = static_cast<i16>(val);
            } else if (i / 4 >= 0 && i / 4 < static_cast<int>(rItemList_.size())) {
                rItemList_[static_cast<std::size_t>(i / 4)].amount = static_cast<i16>(val);
            }
        }
        break;
    }

    case 26: { // Read special addresses (memory-mapped game state)
        const int addr = e50GetValue(0, e1, e6);
        const std::uint32_t t1 = static_cast<std::uint32_t>(static_cast<std::uint16_t>(e3))
                               + static_cast<std::uint32_t>(static_cast<std::uint16_t>(e4)) * 0x10000u
                               + static_cast<std::uint32_t>(static_cast<std::uint16_t>(addr));
        int val = 0;
        if (t1 == 0x1D295Eu) { val = curScene_; }
        else if (t1 == 0x1D295Au) { val = sx_; }
        else if (t1 == 0x1D295Cu) { val = sy_; }
        else if (t1 == 0x1C0B88u) { val = mx_; }
        else if (t1 == 0x1C0B8Cu) { val = my_; }
        else if (t1 == 0x05B53Au) { val = 1; }
        else if (t1 == 0x0544F2u) { val = sFace_; }
        else if (t1 == 0x1C0B90u) { val = static_cast<int>(std::rand() % 65536); }
        // Item list memory range
        if (t1 >= 0x18FE2Cu && t1 - 0x18FE2Cu < 800u) {
            const int i = static_cast<int>(t1 - 0x18FE2Cu);
            if (i % 4 <= 1 && i / 4 >= 0 && i / 4 < static_cast<int>(rItemList_.size())) {
                val = rItemList_[static_cast<std::size_t>(i / 4)].number;
            } else if (i / 4 >= 0 && i / 4 < static_cast<int>(rItemList_.size())) {
                val = rItemList_[static_cast<std::size_t>(i / 4)].amount;
            }
        }
        safeX50(e5) = static_cast<i16>(val);
        break;
    }

    case 27: { // Read name to string buffer at x50[e4]
        const int idx = e50GetValue(0, e1, e3);
        std::string name;
        if (idx >= 0) {
            switch (e2) {
                case 0: name = getRoleName(idx); break;
                case 1: name = getItemName(idx); break;
                case 2: name = getSceneName(idx); break;
                case 3: name = getMagicName(idx); break;
                default: break;
            }
        }
        char* dst = reinterpret_cast<char*>(&safeX50(e4));
        const std::size_t maxBytes = static_cast<std::size_t>((kX50Size - std::max(0, e4))) * 2;
        std::size_t copyLen = std::min(name.size(), maxBytes - 1);
        std::memcpy(dst, name.data(), copyLen);
        // Pad to even length
        if (copyLen % 2 == 1) { dst[copyLen] = ' '; ++copyLen; }
        dst[copyLen] = '\0';
        break;
    }

    case 28: // Get battle number: x50[e1] = x50[28005]
        safeX50(e1) = safeX50(28005);
        break;

    case 32: { // Modify next instruction: returns special jump value
        const int pos = e50GetValue(0, e1, e3);
        result = 655360 * (pos + 1) + static_cast<int>(safeX50(e2));
        p5032pos_ = pos;
        p5032value_ = static_cast<int>(safeX50(e2));
        break;
    }

    case 33: { // Draw string at (e3, e4) with color e5 from x50[e2]
        const int dx = e50GetValue(0, e1, e3);
        const int dy = e50GetValue(1, e1, e4);
        const int col = e50GetValue(2, e1, e5);
        const char* p = reinterpret_cast<const char*>(&safeX50(e2));
        // Split at '*' line breaks, draw each line
        std::string text(p);
        if (drawStringCallback_) {
            std::string::size_type pos = 0;
            int lineIdx = 0;
            while (pos < text.size()) {
                auto star = text.find('*', pos);
                std::string line = (star != std::string::npos) ? text.substr(pos, star - pos) : text.substr(pos);
                drawStringCallback_(line, dx - 2, dy + 22 * lineIdx - 3, col);
                ++lineIdx;
                if (star == std::string::npos) break;
                pos = star + 1;
            }
        }
        break;
    }

    case 34: { // Draw rectangle at (e2, e3) size (e4, e5)
        const int rx = e50GetValue(0, e1, e2);
        const int ry = e50GetValue(1, e1, e3);
        const int rw = e50GetValue(2, e1, e4);
        const int rh = e50GetValue(3, e1, e5);
        if (drawRectCallback_) {
            drawRectCallback_(rx, ry, rw, rh);
        }
        break;
    }

    case 35: { // Wait for key press, return key code in x50[e1]
        if (waitKeyCallback_) {
            int key = waitKeyCallback_();
            safeX50(e1) = static_cast<i16>(key);
        } else {
            safeX50(e1) = 0;
        }
        break;
    }

    case 36: { // Draw text with background rectangle, then wait for key
        const int dx = e50GetValue(0, e1, e3);
        const int dy = e50GetValue(1, e1, e4);
        const int col = e50GetValue(2, e1, e5);
        const char* p = reinterpret_cast<const char*>(&safeX50(e2));
        std::string text(p);
        // Count lines to determine rectangle height
        int lineCount = 1;
        for (char c : text) { if (c == '*') ++lineCount; }
        if (drawRectCallback_) {
            drawRectCallback_(dx - 10, dy - 10, 500, lineCount * 22 + 20);
        }
        if (drawStringCallback_) {
            std::string::size_type pos = 0;
            int lineIdx = 0;
            while (pos < text.size()) {
                auto star = text.find('*', pos);
                std::string line = (star != std::string::npos) ? text.substr(pos, star - pos) : text.substr(pos);
                drawStringCallback_(line, dx - 2, dy + 22 * lineIdx - 3, col);
                ++lineIdx;
                if (star == std::string::npos) break;
                pos = star + 1;
            }
        }
        if (waitKeyCallback_) {
            waitKeyCallback_();
        }
        break;
    }

    case 37: { // Delay for e2 milliseconds
        const int ms = e50GetValue(0, e1, e2);
        if (delayCallback_) {
            delayCallback_(ms);
        }
        break;
    }

    case 38: { // Random number: x50[e3] = random(e2)
        const int range = e50GetValue(0, e1, e2);
        safeX50(e3) = (range > 0) ? static_cast<i16>(std::rand() % range) : 0;
        break;
    }

    case 39: { // Show menu for selection
        const int count = e50GetValue(0, e1, e2);
        const int mx = e50GetValue(1, e1, e5);
        const int my = e50GetValue(2, e1, e6);
        std::vector<std::string> items;
        int maxLen = 0;
        for (int i = 0; i < count; ++i) {
            const int strIdx = static_cast<int>(safeX50(e3 + i));
            const char* p = reinterpret_cast<const char*>(&safeX50(strIdx));
            std::string item(p);
            items.push_back(item);
            if (static_cast<int>(item.size()) > maxLen) maxLen = static_cast<int>(item.size());
        }
        if (menuSelectCallback_ && !items.empty()) {
            safeX50(e4) = static_cast<i16>(menuSelectCallback_(mx, my, items) + 1);
        } else {
            safeX50(e4) = 1; // Default to first option
        }
        break;
    }

    case 40: { // Show scroll menu for selection
        const int count = e50GetValue(0, e1, e2);
        const int mx = e50GetValue(1, e1, e5);
        const int my = e50GetValue(2, e1, e6);
        std::vector<std::string> items;
        for (int i = 0; i < count; ++i) {
            const int strIdx = static_cast<int>(safeX50(e3 + i));
            const char* p = reinterpret_cast<const char*>(&safeX50(strIdx));
            items.emplace_back(p);
        }
        if (menuSelectCallback_ && !items.empty()) {
            safeX50(e4) = static_cast<i16>(menuSelectCallback_(mx, my, items) + 1);
        } else {
            safeX50(e4) = 1;
        }
        break;
    }

    case 41: { // Draw picture: type=e2, picNum=e5, at (e3, e4)
        const int dx = e50GetValue(0, e1, e3);
        const int dy = e50GetValue(1, e1, e4);
        const int picNum = e50GetValue(2, e1, e5);
        if (drawPicCallback_) {
            drawPicCallback_(e2, picNum, dx, dy);
        }
        break;
    }

    case 42: { // Change world map position
        const int newMx = e50GetValue(0, e1, e3);
        const int newMy = e50GetValue(0, e1, e2);
        mx_ = static_cast<i16>(newMx);
        my_ = static_cast<i16>(newMy);
        break;
    }

    case 43: { // Call another event
        const int evId = e50GetValue(0, e1, e2);
        const int arg1 = e50GetValue(1, e1, e3);
        const int arg2 = e50GetValue(2, e1, e4);
        const int arg3 = e50GetValue(3, e1, e5);
        const int arg4 = e50GetValue(4, e1, e6);
        safeX50(0x7100) = static_cast<i16>(arg1);
        safeX50(0x7101) = static_cast<i16>(arg2);
        safeX50(0x7102) = static_cast<i16>(arg3);
        safeX50(0x7103) = static_cast<i16>(arg4);
        if (evId == 202) {
            // Give/remove item: arg3==0 means show notification
            if (arg3 == 0) {
                addItemAmount(arg1, arg2);
                if (getItemCallback_) { getItemCallback_(getItemName(arg1), arg2); }
            } else {
                addItemAmount(arg1, arg2);
            }
        } else if (evId == 201) {
            // NewTalk: arg1=headnum, arg2=talknum, arg3=namenum
            // arg4 encodes place/showhead/color: place=arg4%100, color=arg4/100
            if (talkCallback_) {
                std::string text;
                if (arg2 >= 0) {
                    text = getTalk(arg2);
                } else {
                    // Negative talknum: read from x50 buffer
                    const char* p = reinterpret_cast<const char*>(&x50_[static_cast<std::size_t>(std::max(0, -arg2))]);
                    text = std::string(p);
                }
                const int place = arg4 % 10;
                // Map place to dismode: 0(left)→5, 1(right)→1, 2(no head)→3
                int dismode = 0;
                switch (place) {
                    case 0: dismode = 5; break; // bottom, head left
                    case 1: dismode = 1; break; // bottom, head right
                    case 2: dismode = 3; break; // bottom, no head
                    default: dismode = 0; break;
                }
                talkCallback_(text, arg1, dismode);
            }
        } else {
            callEvent(evId);
        }
        break;
    }

    case 44: // Play animation (battle system — stub)
    case 45: // Show hurt values (battle system — stub)
    case 46: // Set effect layer (battle system — stub)
        break;

    case 47: // NOP
    case 48: // Debug show params — NOP in release
    case 49: // NOP (PE file constraint)
        break;

    case 52: { // Check if role has magic at level
        const int person = e50GetValue(0, e1, e2);
        const int mnum = e50GetValue(1, e1, e3);
        const int lv = e50GetValue(2, e1, e4);
        safeX50(0x7000) = haveMagic(person, mnum, lv) ? 0 : 1;
        break;
    }

    case 60: { // Execute Lua script — stub (no Lua engine)
        break;
    }

    default:
        break;
    }

    return result;
}

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
            // p5032 mechanism: substitute parameter value if position matches
            if (p5032pos_ >= 0 && p == pc + p5032pos_) {
                const int val = p5032value_;
                p5032pos_ = -100;
                return val;
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
                // battle(battlenum, jump1, jump2, getexp)
                if (pc + 4 >= n) { return; }
                currentBattle_ = readAt(pc + 1);
                int getexp = readAt(pc + 4);
                bool victory = true;
                if (battleCallback_) {
                    victory = battleCallback_(currentBattle_, getexp);
                }
                branchOffset(pc + 2, pc + 3, victory);
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
                // bright screen: redraw the scene
                if (redrawCallback_) { redrawCallback_(); }
                pc += 1;
                break;
            }
            case 14: {
                // black screen: fill display with black (used before battle)
                if (blackScreenCallback_) { blackScreenCallback_(); }
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
                // animation: loop event sprite from beginPic to endPic
                // Pascal loops each frame with SDL_Delay(20), setting DData[5,6,7]
                if (pc + 3 >= n) { return; }
                const int ev = readAt(pc + 1);
                const int beginPic = readAt(pc + 2);
                const int endPic = readAt(pc + 3);
                if (animationCallback_) {
                    animationCallback_(ev, beginPic, endPic, 20);
                } else if (curScene_ >= 0 && curScene_ <= 400) {
                    if (ev == -1) {
                        // protagonist animation: just set final frame
                    } else if (ev >= 0 && ev <= 199) {
                        setDData(curScene_, ev, 5, endPic);
                        setDData(curScene_, ev, 6, endPic);
                        setDData(curScene_, ev, 7, endPic);
                    }
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
                // dual event animation
                // Pascal loops both events simultaneously from beginPic to endPic
                if (pc + 6 >= n) { return; }
                int e1 = readAt(pc + 1);
                const int beginPic1 = readAt(pc + 2);
                const int endPic1 = readAt(pc + 3);
                int e2 = readAt(pc + 4);
                const int beginPic2 = readAt(pc + 5);
                const int endPic2 = readAt(pc + 6);
                if (e1 == -1) { e1 = currentEvent_; }
                if (e2 == -1) { e2 = currentEvent_; }
                if (curScene_ >= 0 && curScene_ <= 400) {
                    // Ensure SData mapping for both events
                    if (e1 >= 0 && e1 <= 199) {
                        const int dx1 = getDData(curScene_, e1, 9);
                        const int dy1 = getDData(curScene_, e1, 10);
                        if (dx1 >= 0 && dx1 <= 63 && dy1 >= 0 && dy1 <= 63) {
                            setSData(curScene_, 3, dx1, dy1, e1);
                        }
                    }
                    if (e2 >= 0 && e2 <= 199) {
                        const int dx2 = getDData(curScene_, e2, 9);
                        const int dy2 = getDData(curScene_, e2, 10);
                        if (dx2 >= 0 && dx2 <= 63 && dy2 >= 0 && dy2 <= 63) {
                            setSData(curScene_, 3, dx2, dy2, e2);
                        }
                    }
                    // Set final frames (fallback when no animation callback)
                    if (e1 >= 0 && e1 <= 199) { setDData(curScene_, e1, 5, endPic1); }
                    if (e2 >= 0 && e2 <= 199) { setDData(curScene_, e2, 5, endPic2); }
                }
                (void)beginPic1;
                (void)beginPic2;
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
            case 50: {
                // Extended instructions: if list[0] > 128, check 5 items; else instruct_50e
                if (pc + 7 >= n) { return; }
                const int list0 = readAt(pc + 1);
                int result = 0;
                if (list0 > 128) {
                    // Check if all 5 items are present
                    result = readAt(pc + 7); // default: list[6] = jump2
                    int count = 0;
                    for (int k = 0; k < 5; ++k) {
                        const int inum = readAt(pc + 1 + k);
                        bool found = false;
                        for (const auto& it : rItemList_) {
                            if (it.number == inum && it.amount > 0) {
                                found = true;
                                break;
                            }
                        }
                        if (found) { ++count; }
                    }
                    if (count == 5) {
                        result = readAt(pc + 6); // list[5] = jump1
                    }
                } else {
                    // instruct_50e: extended VM
                    result = execInstruct50e(
                        readAt(pc + 1), readAt(pc + 2), readAt(pc + 3),
                        readAt(pc + 4), readAt(pc + 5), readAt(pc + 6), readAt(pc + 7));
                }
                pc += 8;
                if (result >= 0 && result < 622592) {
                    pc += result;
                }
                // p5032: if result >= 622592, the pos/value are stored in p5032pos_/p5032value_
                // and will modify the next opcode's parameter read via readAt override
                break;
            }
            case 51: {
                // Random Softstar NPC talk
                // Pascal: instruct_1(SOFTSTAR_BEGIN_TALK + random(SOFTSTAR_NUM_TALK), $72, 0)
                constexpr int softstarBegin = 2547;
                constexpr int softstarNum = 18;
                const int talkIdx = softstarBegin + (std::rand() % softstarNum);
                const std::string talk = getTalk(talkIdx);
                if (talkCallback_) {
                    talkCallback_(talk, 0x72, 0);
                }
                pc += 1;
                break;
            }
            case 52: {
                // Display protagonist ethics value
                if (talkCallback_) {
                    const int ethics = rRole_[0].element.ethics;
                    talkCallback_("你的品德指數為：" + std::to_string(ethics), -1, 0);
                }
                pc += 1;
                break;
            }
            case 53: {
                // Display protagonist repute value
                if (talkCallback_) {
                    const int repute = rRole_[0].element.repute;
                    talkCallback_("你的聲望指數為：" + std::to_string(repute), -1, 0);
                }
                pc += 1;
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
                // Pascal: when crossing 200 threshold, trigger event 70/11
                if (pc + 1 >= n) { return; }
                const int addRepute = readAt(pc + 1);
                auto& r = rRole_[0].element;
                const int oldRepute = r.repute;
                r.repute = static_cast<i16>(static_cast<int>(r.repute) + addRepute);
                if (r.repute > 200 && oldRepute <= 200) {
                    // 声望刚超过200: 家中出现请帖
                    std::array<int, 13> list = {70, 11, 0, 11, 0x3A4, -1, -1, 0x1F20, 0x1F20, 0x1F20, 0, 18, 21};
                    execInstruct3(list);
                }
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
            case 57: {
                // special animation: instruct_27(-1, 3832*2, 3844*2) then instruct_44e(...)
                // instruct_27 part: animate event currentEvent_ from pic 7664 to 7688
                {
                    int ev27 = currentEvent_;
                    if (ev27 >= 0 && ev27 <= 199 && curScene_ >= 0 && curScene_ <= 400) {
                        if (animationCallback_) {
                            animationCallback_(ev27, 3832 * 2, 3844 * 2, 20);
                        }
                        setDData(curScene_, ev27, 5, 3844 * 2);
                    }
                }
                // instruct_44e part: 3 events (2, 3, 4) simultaneous animation
                if (curScene_ >= 0 && curScene_ <= 400) {
                    constexpr int enum1 = 2, beginpic1 = 3845 * 2, endpic1 = 3873 * 2;
                    constexpr int enum2 = 3, beginpic2 = 3874 * 2;
                    constexpr int enum3 = 4, beginpic3 = 3903 * 2;
                    // SData mapping
                    for (int evn : {enum1, enum2, enum3}) {
                        const int dx = getDData(curScene_, evn, 9);
                        const int dy = getDData(curScene_, evn, 10);
                        if (dx >= 0 && dx <= 63 && dy >= 0 && dy <= 63) {
                            setSData(curScene_, 3, dx, dy, evn);
                        }
                    }
                    // Set final frames (animation duration = endpic1 - beginpic1)
                    const int dur = endpic1 - beginpic1;
                    setDData(curScene_, enum1, 5, endpic1);
                    setDData(curScene_, enum2, 5, beginpic2 + dur);
                    setDData(curScene_, enum3, 5, beginpic3 + dur);
                }
                pc += 1;
                break;
            }
            case 58: {
                // 华山论剑 tournament: 15 battles
                // Since Battle() is not yet implemented, auto-win all rounds
                constexpr int headarray[30] = {
                    8, 21, 23, 31, 32, 43, 7, 11, 14, 20,
                    33, 34, 10, 12, 19, 22, 56, 68, 13, 55,
                    62, 67, 70, 71, 26, 57, 60, 64, 3, 69
                };
                bool lost = false;
                for (int i = 0; i < 15 && !lost; ++i) {
                    const int p = std::rand() % 2;
                    // instruct_1: show pre-battle talk
                    if (talkCallback_) {
                        const std::string talk = getTalk(2854 + i * 2 + p);
                        talkCallback_(talk, headarray[i * 2 + p], std::rand() % 2 * 4 + std::rand() % 2);
                    }
                    // Battle(102 + i*2+p, 0) — auto-win since not implemented
                    // On loss: instruct_15 (where_=4, return)
                    // instruct_14 (black screen) + instruct_13 (bright screen) — renderer nops
                    // Every 3 rounds: heal
                    if (i % 3 == 2) {
                        if (talkCallback_) {
                            talkCallback_(getTalk(2891), 70, 4);
                        }
                        // instruct_12: heal team
                        for (int t = 0; t < kTeamSize; ++t) {
                            const int rn = teamList_[static_cast<std::size_t>(t)];
                            if (rn < 0 || rn >= kMaxRoles) { continue; }
                            auto& r = rRole_[static_cast<std::size_t>(rn)].element;
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
                    }
                }
                // Victory talks and reward
                if (where_ != 3) {
                    const int victoryTalks[] = {2884, 2885, 2886, 2887, 2888, 2889};
                    const int victoryHeads[] = {0, 0, 0, 0, 0, 0};
                    const int victoryModes[] = {3, 3, 3, 3, 3, 1};
                    for (int i = 0; i < 6; ++i) {
                        if (talkCallback_) {
                            talkCallback_(getTalk(victoryTalks[i]), victoryHeads[i], victoryModes[i]);
                        }
                    }
                    // instruct_2(0x8F, 1) — give item 143
                    addItemAmount(0x8F, 1);
                    if (getItemCallback_) {
                        getItemCallback_(getItemName(0x8F), 1);
                    }
                }
                pc += 1;
                break;
            }
            case 60: {
                // check DData[snum, enum, 5/6/7] == pic
                if (pc + 5 >= n) { return; }
                int snum = readAt(pc + 1);
                const int evnum = readAt(pc + 2);
                const int pic = readAt(pc + 3);
                if (snum == -2) { snum = curScene_; }
                bool match = false;
                if (snum >= 0 && snum <= 400 && evnum >= 0 && evnum <= 199) {
                    match = (getDData(snum, evnum, 5) == pic)
                         || (getDData(snum, evnum, 6) == pic)
                         || (getDData(snum, evnum, 7) == pic);
                }
                branchOffset(pc + 4, pc + 5, match);
                pc += 6;
                break;
            }
            case 61: {
                // check current scene events 11-24 all have DData[curScene,i,5]==4664
                if (pc + 2 >= n) { return; }
                bool allMatch = true;
                if (curScene_ >= 0 && curScene_ <= 400) {
                    for (int i = 11; i <= 24; ++i) {
                        if (getDData(curScene_, i, 5) != 4664) {
                            allMatch = false;
                        }
                    }
                }
                branchOffset(pc + 1, pc + 2, allMatch);
                pc += 3;
                break;
            }
            case 62: {
                // game ending
                if (pc + 6 >= n) { return; }
                const int enum1 = readAt(pc + 1);
                const int beginpic1 = readAt(pc + 2);
                const int endpic1 = readAt(pc + 3);
                const int enum2 = readAt(pc + 4);
                const int beginpic2 = readAt(pc + 5);
                const int endpic2 = readAt(pc + 6);
                // CurSceneRolePic := -1 (hide protagonist in scene)
                if (curScene_ >= 0 && curScene_ <= 400) {
                    // Execute instruct_44 logic: SData mapping + set final pics
                    for (int evn : {enum1, enum2}) {
                        int e = evn;
                        if (e == -1) { e = currentEvent_; }
                        if (e >= 0 && e <= 199) {
                            const int dx = getDData(curScene_, e, 9);
                            const int dy = getDData(curScene_, e, 10);
                            if (dx >= 0 && dx <= 63 && dy >= 0 && dy <= 63) {
                                setSData(curScene_, 3, dx, dy, e);
                            }
                        }
                    }
                    int e1 = enum1; if (e1 == -1) { e1 = currentEvent_; }
                    int e2 = enum2; if (e2 == -1) { e2 = currentEvent_; }
                    if (e1 >= 0 && e1 <= 199) { setDData(curScene_, e1, 5, endpic1); }
                    if (e2 >= 0 && e2 <= 199) { setDData(curScene_, e2, 5, endpic2); }
                }
                (void)beginpic1;
                (void)beginpic2;
                where_ = 3;
                // EndAmi (ending credits/image) would be handled by renderer
                pc += 7;
                return; // break out of event loop (Pascal: break)
            }
            case 63: {
                // set role sexual
                if (pc + 2 >= n) { return; }
                const int rnum = readAt(pc + 1);
                const int sexual = readAt(pc + 2);
                if (rnum >= 0 && rnum < kMaxRoles) {
                    rRole_[static_cast<std::size_t>(rnum)].element.sexual = static_cast<i16>(sexual);
                }
                pc += 3;
                break;
            }
            case 64: {
                // 韦小宝的随机商店
                constexpr int MONEY_ID = 174;
                const int shopnum = std::rand() % 5;
                if (shopnum >= 0 && shopnum < kMaxShops) {
                    // Show shop greeting talk
                    if (talkCallback_) {
                        talkCallback_(getTalk(0xB9E), 0x6F, 0);
                    }
                    // Find available items in this shop
                    const auto& shop = rShop_[static_cast<std::size_t>(shopnum)].element;
                    int firstAvail = -1;
                    for (int i = 0; i < 5; ++i) {
                        if (shop.amount[i] > 0) {
                            firstAvail = i;
                            break;
                        }
                    }
                    if (firstAvail >= 0) {
                        // Simplified: auto-buy first available item if affordable
                        // Full implementation would need shopCallback_ for menu
                        const int itemIdx = shop.item[firstAvail];
                        const int price = shop.price[firstAvail];
                        // Check money
                        int money = 0;
                        for (const auto& it : rItemList_) {
                            if (it.number == MONEY_ID) {
                                money = it.amount;
                                break;
                            }
                        }
                        if (money >= price) {
                            addItemAmount(itemIdx, 1);
                            if (getItemCallback_) {
                                getItemCallback_(getItemName(itemIdx), 1);
                            }
                            addItemAmount(MONEY_ID, -price);
                            rShop_[static_cast<std::size_t>(shopnum)].element.amount[firstAvail] -= 1;
                            if (talkCallback_) {
                                talkCallback_(getTalk(0xBA0), 0x6F, 0);
                            }
                        } else {
                            if (talkCallback_) {
                                talkCallback_(getTalk(0xB9F), 0x6F, 0);
                            }
                        }
                    }
                }
                pc += 1;
                break;
            }
            case 65: {
                // NOP
                pc += 1;
                break;
            }
            case 66: {
                // play music
                if (pc + 1 >= n) { return; }
                const int musicNum = readAt(pc + 1);
                if (musicCallback_) {
                    musicCallback_(musicNum);
                }
                pc += 2;
                break;
            }
            case 67: {
                // play sound effect
                if (pc + 1 >= n) { return; }
                const int soundNum = readAt(pc + 1);
                if (soundCallback_) {
                    soundCallback_(soundNum);
                }
                pc += 2;
                break;
            }
            default: {
                // Unknown opcode: skip it (advance pc by 1) to avoid aborting entire event
                pc += 1;
                break;
            }
        }
    }
}

} // namespace kys
