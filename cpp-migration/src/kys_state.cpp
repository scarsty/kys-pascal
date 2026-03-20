#include "kys_state.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#endif

namespace kys {
namespace {

int signInt(int v) {
    if (v > 0) {
        return 1;
    }
    if (v < 0) {
        return -1;
    }
    return 0;
}

std::string joinPath(const std::string& base, const std::string& rel) {
    if (base.empty()) {
        return rel;
    }
    if (base.back() == '/' || base.back() == '\\') {
        return base + rel;
    }
    return base + "/" + rel;
}

std::string saveFileName(const std::string& prefix, int num, const std::string& zeroName) {
    if (num == 0) {
        return zeroName;
    }
    std::ostringstream oss;
    oss << prefix << num;
    return oss.str();
}

std::string fixedBufToString(const char* buf, std::size_t n) {
    std::size_t len = 0;
    while (len < n && buf[len] != '\0') {
        ++len;
    }
    return std::string(buf, buf + len);
}

std::string cp950ToUtf8(const std::string& cp950) {
#ifdef _WIN32
    if (cp950.empty()) {
        return {};
    }
    const int wlen = MultiByteToWideChar(950, 0, cp950.data(), static_cast<int>(cp950.size()), nullptr, 0);
    if (wlen <= 0) {
        return cp950;
    }
    std::wstring ws(static_cast<std::size_t>(wlen), L'\0');
    MultiByteToWideChar(950, 0, cp950.data(), static_cast<int>(cp950.size()), ws.data(), wlen);

    const int u8len = WideCharToMultiByte(CP_UTF8, 0, ws.data(), static_cast<int>(ws.size()), nullptr, 0, nullptr, nullptr);
    if (u8len <= 0) {
        return cp950;
    }
    std::string out(static_cast<std::size_t>(u8len), '\0');
    WideCharToMultiByte(CP_UTF8, 0, ws.data(), static_cast<int>(ws.size()), out.data(), u8len, nullptr, nullptr);
    return out;
#else
    return cp950;
#endif
}

} // namespace

KysState::KysState(std::string appPath) : appPath_(std::move(appPath)) {
    std::fill(entrance_.begin(), entrance_.end(), static_cast<i16>(-1));
    earth_.assign(static_cast<std::size_t>(kWorldSize) * static_cast<std::size_t>(kWorldSize), 0);
    surface_.assign(static_cast<std::size_t>(kWorldSize) * static_cast<std::size_t>(kWorldSize), 0);
    building_.assign(static_cast<std::size_t>(kWorldSize) * static_cast<std::size_t>(kWorldSize), 0);
}

bool KysState::readExact(std::ifstream& in, void* dst, std::size_t size) {
    in.read(reinterpret_cast<char*>(dst), static_cast<std::streamsize>(size));
    return in.good();
}

bool KysState::writeExact(std::ofstream& out, const void* src, std::size_t size) {
    out.write(reinterpret_cast<const char*>(src), static_cast<std::streamsize>(size));
    return out.good();
}

bool KysState::readOffsets(SaveOffsets& offsets) const {
    std::ifstream idx(joinPath(appPath_, "save/ranger.idx"), std::ios::binary);
    if (!idx) {
        return false;
    }
    return readExact(idx, &offsets.roleOffset, sizeof(offsets.roleOffset)) &&
           readExact(idx, &offsets.itemOffset, sizeof(offsets.itemOffset)) &&
           readExact(idx, &offsets.sceneOffset, sizeof(offsets.sceneOffset)) &&
           readExact(idx, &offsets.magicOffset, sizeof(offsets.magicOffset)) &&
           readExact(idx, &offsets.weiShopOffset, sizeof(offsets.weiShopOffset)) &&
           readExact(idx, &offsets.totalLen, sizeof(offsets.totalLen));
}

bool KysState::loadR(int num) {
    SaveOffsets offsets;
    if (!readOffsets(offsets)) {
        return false;
    }

    const auto rName = saveFileName("r", num, "ranger");
    std::ifstream grp(joinPath(appPath_, "save/" + rName + ".grp"), std::ios::binary);
    if (!grp) {
        return false;
    }

    if (!readExact(grp, &inShip_, sizeof(inShip_)) ||
        !readExact(grp, &useLess1_, sizeof(useLess1_)) ||
        !readExact(grp, &my_, sizeof(my_)) ||
        !readExact(grp, &mx_, sizeof(mx_)) ||
        !readExact(grp, &sy_, sizeof(sy_)) ||
        !readExact(grp, &sx_, sizeof(sx_)) ||
        !readExact(grp, &mFace_, sizeof(mFace_)) ||
        !readExact(grp, &shipX_, sizeof(shipX_)) ||
        !readExact(grp, &shipY_, sizeof(shipY_)) ||
        !readExact(grp, &shipX1_, sizeof(shipX1_)) ||
        !readExact(grp, &shipY1_, sizeof(shipY1_)) ||
        !readExact(grp, &shipFace_, sizeof(shipFace_)) ||
        !readExact(grp, teamList_.data(), sizeof(i16) * kTeamSize)) {
        return false;
    }

    rItemList_.assign(maxItemAmount_, TItemList{-1, 0});
    if (!readExact(grp, rItemList_.data(), sizeof(TItemList) * rItemList_.size())) {
        return false;
    }

    const auto roleBytes = static_cast<std::size_t>(offsets.itemOffset - offsets.roleOffset);
    const auto itemBytes = static_cast<std::size_t>(offsets.sceneOffset - offsets.itemOffset);
    const auto sceneBytes = static_cast<std::size_t>(offsets.magicOffset - offsets.sceneOffset);
    const auto magicBytes = static_cast<std::size_t>(offsets.weiShopOffset - offsets.magicOffset);
    const auto shopBytes = static_cast<std::size_t>(offsets.totalLen - offsets.weiShopOffset);

    if (roleBytes > sizeof(rRole_) || itemBytes > sizeof(rItem_) || sceneBytes > sizeof(rScene_) ||
        magicBytes > sizeof(rMagic_) || shopBytes > sizeof(rShop_)) {
        return false;
    }

    if (!readExact(grp, rRole_.data(), roleBytes) ||
        !readExact(grp, rItem_.data(), itemBytes) ||
        !readExact(grp, rScene_.data(), sceneBytes) ||
        !readExact(grp, rMagic_.data(), magicBytes) ||
        !readExact(grp, rShop_.data(), shopBytes)) {
        return false;
    }

    sceneAmount_ = static_cast<int>(sceneBytes / sizeof(TScene));
    std::fill(entrance_.begin(), entrance_.end(), static_cast<i16>(-1));
    for (int i = 0; i < sceneAmount_; ++i) {
        const auto& s = rScene_[i].element;
        if (s.mainEntranceX1 >= 0 && s.mainEntranceX1 < kWorldSize && s.mainEntranceY1 >= 0 && s.mainEntranceY1 < kWorldSize) {
            entrance_[s.mainEntranceX1 * kWorldSize + s.mainEntranceY1] = static_cast<i16>(i);
        }
        if (s.mainEntranceX2 >= 0 && s.mainEntranceX2 < kWorldSize && s.mainEntranceY2 >= 0 && s.mainEntranceY2 < kWorldSize) {
            entrance_[s.mainEntranceX2 * kWorldSize + s.mainEntranceY2] = static_cast<i16>(i);
        }
    }

    if (useLess1_ > 0) {
        curScene_ = useLess1_ - 1;
        where_ = 1;
    } else {
        curScene_ = -1;
        where_ = 0;
    }

    const auto sName = saveFileName("s", num, "allsin");
    std::ifstream sFile(joinPath(appPath_, "save/" + sName + ".grp"), std::ios::binary);
    if (!sFile) {
        return false;
    }
    const auto sBytes = static_cast<std::size_t>(sceneAmount_) * 64U * 64U * 6U * sizeof(i16);
    if (sBytes > sizeof(sData_)) {
        return false;
    }
    if (!readExact(sFile, sData_.data(), sBytes)) {
        return false;
    }

    const auto dName = saveFileName("d", num, "alldef");
    std::ifstream dFile(joinPath(appPath_, "save/" + dName + ".grp"), std::ios::binary);
    if (!dFile) {
        return false;
    }
    const auto dBytes = static_cast<std::size_t>(sceneAmount_) * 200U * 11U * sizeof(i16);
    if (dBytes > sizeof(dData_)) {
        return false;
    }
    return readExact(dFile, dData_.data(), dBytes);
}

bool KysState::saveR(int num) {
    SaveOffsets offsets;
    if (!readOffsets(offsets)) {
        return false;
    }

    const auto rName = saveFileName("r", num, "ranger");
    std::ofstream grp(joinPath(appPath_, "save/" + rName + ".grp"), std::ios::binary | std::ios::trunc);
    if (!grp) {
        return false;
    }

    if (where_ == 1) {
        useLess1_ = static_cast<i16>(curScene_ + 1);
    } else {
        useLess1_ = 0;
    }

    if (!writeExact(grp, &inShip_, sizeof(inShip_)) ||
        !writeExact(grp, &useLess1_, sizeof(useLess1_)) ||
        !writeExact(grp, &my_, sizeof(my_)) ||
        !writeExact(grp, &mx_, sizeof(mx_)) ||
        !writeExact(grp, &sy_, sizeof(sy_)) ||
        !writeExact(grp, &sx_, sizeof(sx_)) ||
        !writeExact(grp, &mFace_, sizeof(mFace_)) ||
        !writeExact(grp, &shipX_, sizeof(shipX_)) ||
        !writeExact(grp, &shipY_, sizeof(shipY_)) ||
        !writeExact(grp, &shipX1_, sizeof(shipX1_)) ||
        !writeExact(grp, &shipY1_, sizeof(shipY1_)) ||
        !writeExact(grp, &shipFace_, sizeof(shipFace_)) ||
        !writeExact(grp, teamList_.data(), sizeof(i16) * kTeamSize) ||
        !writeExact(grp, rItemList_.data(), sizeof(TItemList) * rItemList_.size())) {
        return false;
    }

    const auto roleBytes = static_cast<std::size_t>(offsets.itemOffset - offsets.roleOffset);
    const auto itemBytes = static_cast<std::size_t>(offsets.sceneOffset - offsets.itemOffset);
    const auto sceneBytes = static_cast<std::size_t>(offsets.magicOffset - offsets.sceneOffset);
    const auto magicBytes = static_cast<std::size_t>(offsets.weiShopOffset - offsets.magicOffset);
    const auto shopBytes = static_cast<std::size_t>(offsets.totalLen - offsets.weiShopOffset);

    if (roleBytes > sizeof(rRole_) || itemBytes > sizeof(rItem_) || sceneBytes > sizeof(rScene_) ||
        magicBytes > sizeof(rMagic_) || shopBytes > sizeof(rShop_)) {
        return false;
    }

    if (!writeExact(grp, rRole_.data(), roleBytes) ||
        !writeExact(grp, rItem_.data(), itemBytes) ||
        !writeExact(grp, rScene_.data(), sceneBytes) ||
        !writeExact(grp, rMagic_.data(), magicBytes) ||
        !writeExact(grp, rShop_.data(), shopBytes)) {
        return false;
    }

    sceneAmount_ = static_cast<int>(sceneBytes / sizeof(TScene));

    const auto sName = saveFileName("s", num, "allsin");
    std::ofstream sFile(joinPath(appPath_, "save/" + sName + ".grp"), std::ios::binary | std::ios::trunc);
    if (!sFile) {
        return false;
    }
    const auto sBytes = static_cast<std::size_t>(sceneAmount_) * 64U * 64U * 6U * sizeof(i16);
    if (sBytes > sizeof(sData_)) {
        return false;
    }
    if (!writeExact(sFile, sData_.data(), sBytes)) {
        return false;
    }

    const auto dName = saveFileName("d", num, "alldef");
    std::ofstream dFile(joinPath(appPath_, "save/" + dName + ".grp"), std::ios::binary | std::ios::trunc);
    if (!dFile) {
        return false;
    }
    const auto dBytes = static_cast<std::size_t>(sceneAmount_) * 200U * 11U * sizeof(i16);
    if (dBytes > sizeof(dData_)) {
        return false;
    }
    return writeExact(dFile, dData_.data(), dBytes);
}

bool KysState::newGame() {
    // Load initial game state from the default empty save (slot 0 = "ranger.grp")
    if (!loadR(0)) {
        return false;
    }
    
    // Initialize world position (on map, not in scene)
    where_ = 0;
    curScene_ = -1;
    inShip_ = 0;
    
    // BEGIN position constants (from kysmod.ini)
    // These would typically be read from config, but hardcoding for now
    const int BEGIN_SCENE = 70;
    const int BEGIN_Sx = 20;
    const int BEGIN_Sy = 19;
    
    // Enter the initial scene at the beginning position
    changeScene(BEGIN_SCENE, BEGIN_Sx, BEGIN_Sy);
    
    return true;
}

bool KysState::loadWorldData() {
    const auto count = static_cast<std::size_t>(kWorldSize) * static_cast<std::size_t>(kWorldSize);
    const auto bytes = count * sizeof(i16);

    auto loadOne = [this, bytes](const std::string& rel, std::vector<i16>& out) -> bool {
        std::ifstream in(joinPath(appPath_, rel), std::ios::binary);
        if (!in) {
            return false;
        }
        in.read(reinterpret_cast<char*>(out.data()), static_cast<std::streamsize>(bytes));
        return in.good();
    };

    return loadOne("resource/earth.002", earth_) &&
           loadOne("resource/surface.002", surface_) &&
           loadOne("resource/building.002", building_);
}

int KysState::getRoleData(int roleIndex, int dataIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles || dataIndex < 0 || dataIndex >= 91) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].data[dataIndex];
}

void KysState::setRoleData(int roleIndex, int dataIndex, int value) {
    if (roleIndex < 0 || roleIndex >= kMaxRoles || dataIndex < 0 || dataIndex >= 91) {
        return;
    }
    rRole_[static_cast<std::size_t>(roleIndex)].data[dataIndex] = static_cast<i16>(value);
}

int KysState::getItemData(int itemIndex, int dataIndex) const {
    if (itemIndex < 0 || itemIndex >= kMaxItems || dataIndex < 0 || dataIndex >= 95) {
        return 0;
    }
    return rItem_[static_cast<std::size_t>(itemIndex)].data[dataIndex];
}

void KysState::setItemData(int itemIndex, int dataIndex, int value) {
    if (itemIndex < 0 || itemIndex >= kMaxItems || dataIndex < 0 || dataIndex >= 95) {
        return;
    }
    rItem_[static_cast<std::size_t>(itemIndex)].data[dataIndex] = static_cast<i16>(value);
}

int KysState::getMagicData(int magicIndex, int dataIndex) const {
    if (magicIndex < 0 || magicIndex >= kMaxMagics || dataIndex < 0 || dataIndex >= 68) {
        return 0;
    }
    return rMagic_[static_cast<std::size_t>(magicIndex)].data[dataIndex];
}

void KysState::setMagicData(int magicIndex, int dataIndex, int value) {
    if (magicIndex < 0 || magicIndex >= kMaxMagics || dataIndex < 0 || dataIndex >= 68) {
        return;
    }
    rMagic_[static_cast<std::size_t>(magicIndex)].data[dataIndex] = static_cast<i16>(value);
}

int KysState::getSceneData(int sceneIndex, int dataIndex) const {
    if (sceneIndex < 0 || sceneIndex >= kMaxScenes || dataIndex < 0 || dataIndex >= 26) {
        return 0;
    }
    return rScene_[static_cast<std::size_t>(sceneIndex)].data[dataIndex];
}

void KysState::setSceneData(int sceneIndex, int dataIndex, int value) {
    if (sceneIndex < 0 || sceneIndex >= kMaxScenes || dataIndex < 0 || dataIndex >= 26) {
        return;
    }
    rScene_[static_cast<std::size_t>(sceneIndex)].data[dataIndex] = static_cast<i16>(value);
}

int KysState::getSData(int sceneIndex, int layer, int x, int y) const {
    if (sceneIndex < 0 || sceneIndex > 400 || layer < 0 || layer > 5 || y < 0 || y > 63 || x < 0 || x > 63) {
        return 0;
    }
    const std::size_t idx = (((static_cast<std::size_t>(sceneIndex) * 6 + static_cast<std::size_t>(layer)) * 64 +
                              static_cast<std::size_t>(x)) * 64 +
                             static_cast<std::size_t>(y));
    return sData_[idx];
}

void KysState::setSData(int sceneIndex, int layer, int x, int y, int value) {
    if (sceneIndex < 0 || sceneIndex > 400 || layer < 0 || layer > 5 || y < 0 || y > 63 || x < 0 || x > 63) {
        return;
    }
    const std::size_t idx = (((static_cast<std::size_t>(sceneIndex) * 6 + static_cast<std::size_t>(layer)) * 64 +
                              static_cast<std::size_t>(x)) * 64 +
                             static_cast<std::size_t>(y));
    sData_[idx] = static_cast<i16>(value);
}

int KysState::getDData(int sceneIndex, int eventIndex, int dataIndex) const {
    if (sceneIndex < 0 || sceneIndex > 400 || eventIndex < 0 || eventIndex > 199 || dataIndex < 0 || dataIndex > 10) {
        return 0;
    }
    const std::size_t idx = ((static_cast<std::size_t>(sceneIndex) * 200 + static_cast<std::size_t>(eventIndex)) * 11 +
                             static_cast<std::size_t>(dataIndex));
    return dData_[idx];
}

void KysState::setDData(int sceneIndex, int eventIndex, int dataIndex, int value) {
    if (sceneIndex < 0 || sceneIndex > 400 || eventIndex < 0 || eventIndex > 199 || dataIndex < 0 || dataIndex > 10) {
        return;
    }
    const std::size_t idx = ((static_cast<std::size_t>(sceneIndex) * 200 + static_cast<std::size_t>(eventIndex)) * 11 +
                             static_cast<std::size_t>(dataIndex));
    dData_[idx] = static_cast<i16>(value);
}

int KysState::judgeSceneEvent(int eventIndex, int offset, int expected) const {
    if (curScene_ < 0 || curScene_ > 400 || eventIndex < 0 || eventIndex > 199) {
        return 0;
    }
    const int dataIndex = 2 + offset;
    if (dataIndex < 0 || dataIndex > 10) {
        return 0;
    }
    return getDData(curScene_, eventIndex, dataIndex) == expected ? 1 : 0;
}

int KysState::getTeam(int index) const {
    if (index < 0 || index >= kTeamSize) {
        return 0;
    }
    return teamList_[static_cast<std::size_t>(index)];
}

void KysState::setTeam(int index, int value) {
    if (index < 0 || index >= kTeamSize) {
        return;
    }
    teamList_[static_cast<std::size_t>(index)] = static_cast<i16>(value);
}

int KysState::readMem(int address) const {
    const auto it = memMap_.find(address);
    if (it == memMap_.end()) {
        return 0;
    }
    return it->second;
}

void KysState::writeMem(int address, int value) {
    memMap_[address] = value;
}

std::string KysState::getRoleName(int index) const {
    if (index < 0 || index >= kMaxRoles) {
        return {};
    }
    return cp950ToUtf8(fixedBufToString(rRole_[static_cast<std::size_t>(index)].element.name, 10));
}

std::string KysState::getItemName(int index) const {
    if (index < 0 || index >= kMaxItems) {
        return {};
    }
    return cp950ToUtf8(fixedBufToString(rItem_[static_cast<std::size_t>(index)].element.name, 20));
}

std::string KysState::getMagicName(int index) const {
    if (index < 0 || index >= kMaxMagics) {
        return {};
    }
    return cp950ToUtf8(fixedBufToString(rMagic_[static_cast<std::size_t>(index)].element.name, 10));
}

std::string KysState::getSceneName(int index) const {
    if (index < 0 || index >= kMaxScenes) {
        return {};
    }
    return cp950ToUtf8(fixedBufToString(rScene_[static_cast<std::size_t>(index)].element.name, 10));
}

std::string KysState::getTalk(int talkNum) {
    if (!talkLoaded_) {
        std::ifstream idx(joinPath(appPath_, "resource/talk.idx"), std::ios::binary);
        std::ifstream grp(joinPath(appPath_, "resource/talk.grp"), std::ios::binary);
        if (!idx || !grp) {
            talkLoaded_ = true;
            return {};
        }

        idx.seekg(0, std::ios::end);
        const auto idxSize = static_cast<std::size_t>(idx.tellg());
        idx.seekg(0, std::ios::beg);
        tIdx_.assign(idxSize / sizeof(std::int32_t), 0);
        if (!tIdx_.empty()) {
            idx.read(reinterpret_cast<char*>(tIdx_.data()), static_cast<std::streamsize>(tIdx_.size() * sizeof(std::int32_t)));
        }

        grp.seekg(0, std::ios::end);
        const auto grpSize = static_cast<std::size_t>(grp.tellg());
        grp.seekg(0, std::ios::beg);
        tDef_.assign(grpSize, 0);
        if (!tDef_.empty()) {
            grp.read(reinterpret_cast<char*>(tDef_.data()), static_cast<std::streamsize>(tDef_.size()));
        }
        talkLoaded_ = true;
    }

    if (tIdx_.empty() || tDef_.empty()) {
        return {};
    }

    int offset = 0;
    int len = 0;
    if (talkNum == 0) {
        len = tIdx_[0];
    } else if (talkNum > 0 && static_cast<std::size_t>(talkNum) < tIdx_.size()) {
        offset = tIdx_[static_cast<std::size_t>(talkNum - 1)];
        len = tIdx_[static_cast<std::size_t>(talkNum)] - offset;
    } else {
        return {};
    }

    if (offset < 0 || len < 0 || static_cast<std::size_t>(offset + len) > tDef_.size()) {
        return {};
    }

    std::string decoded;
    decoded.resize(static_cast<std::size_t>(len));
    for (int i = 0; i < len; ++i) {
        decoded[static_cast<std::size_t>(i)] = static_cast<char>(tDef_[static_cast<std::size_t>(offset + i)] ^ 0xFF);
    }
    return cp950ToUtf8(decoded);
}

int KysState::drawLength(const std::string& s) const {
    return static_cast<int>(s.size());
}

void KysState::clearButtonState() {
    currentKey_ = 0;
    currentButton_ = 0;
}

int KysState::checkButtonState() const {
    return currentButton_ > 0 ? 1 : 0;
}

int KysState::currentKey() const {
    return currentKey_;
}

int KysState::currentButton() const {
    return currentButton_;
}

int KysState::waitAnyKey() const {
    return currentKey_;
}

int KysState::mouseX() const {
    return mouseX_;
}

int KysState::mouseY() const {
    return mouseY_;
}

void KysState::setInputState(int key, int button, int x, int y) {
    currentKey_ = key;
    currentButton_ = button;
    mouseX_ = x;
    mouseY_ = y;
}

void KysState::execEvent(int eventId, const std::vector<int>& args) {
    currentEvent_ = eventId;
    for (std::size_t i = 0; i < args.size(); ++i) {
        eventArgMap_[0x7100 + static_cast<int>(i)] = args[i];
    }
}

void KysState::callEvent(int eventId) {
    currentEvent_ = eventId;
}

void KysState::changeScene(int sceneId, int x, int y) {
    curScene_ = sceneId;
    sx_ = static_cast<i16>(x);
    sy_ = static_cast<i16>(y);
    where_ = sceneId >= 0 ? 1 : 0;
}

void KysState::walkFromTo(int x1, int y1, int x2, int y2) {
    (void)x1;
    (void)y1;
    mx_ = static_cast<i16>(x2);
    my_ = static_cast<i16>(y2);
}

void KysState::sceneFromTo(int x1, int y1, int x2, int y2) {
    (void)x1;
    (void)y1;
    sx_ = static_cast<i16>(x2);
    sy_ = static_cast<i16>(y2);
}

int KysState::getBattleRoleData(int roleIndex, int dataIndex) const {
    if (dataIndex < 0 || dataIndex >= 19) {
        return 0;
    }
    const auto it = battleRoleData_.find(roleIndex);
    if (it == battleRoleData_.end()) {
        return 0;
    }
    return it->second[static_cast<std::size_t>(dataIndex)];
}

void KysState::setBattleRoleData(int roleIndex, int dataIndex, int value) {
    if (dataIndex < 0 || dataIndex >= 19) {
        return;
    }
    auto& row = battleRoleData_[roleIndex];
    row[static_cast<std::size_t>(dataIndex)] = static_cast<i16>(value);
}

void KysState::setMapPosition(int x, int y) {
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= kWorldSize) x = kWorldSize - 1;
    if (y >= kWorldSize) y = kWorldSize - 1;
    mx_ = static_cast<i16>(x);
    my_ = static_cast<i16>(y);
}

void KysState::setMapFace(int face) {
    if (face < 0) {
        face = 0;
    }
    if (face > 3) {
        face = 3;
    }
    mFace_ = static_cast<i16>(face);
}

void KysState::setScenePosition(int x, int y) {
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x > 63) x = 63;
    if (y > 63) y = 63;
    sx_ = static_cast<i16>(x);
    sy_ = static_cast<i16>(y);
}

void KysState::setSceneFace(int face) {
    if (face < 0) {
        face = 0;
    }
    if (face > 3) {
        face = 3;
    }
    sFace_ = static_cast<i16>(face);
}

int KysState::entranceSceneAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= kWorldSize || y >= kWorldSize) {
        return -1;
    }
    return entrance_[static_cast<std::size_t>(x) * static_cast<std::size_t>(kWorldSize) + static_cast<std::size_t>(y)];
}

bool KysState::tryEnterScene() {
    if (where_ != 0) {
        return false;
    }
    
    // Check entrance based on facing direction (Mface)
    // Following original CheckEntrance logic:
    // Mface: 0=up(x-1), 1=right(y+1), 2=left(y-1), 3=down(x+1)
    int x = mx_;
    int y = my_;
    switch (mFace_) {
        case 0: x -= 1; break;  // up
        case 1: y += 1; break;  // right
        case 2: y -= 1; break;  // left
        case 3: x += 1; break;  // down
    }
    
    const int sceneId = entranceSceneAt(x, y);
    if (sceneId < 0 || sceneId >= sceneAmount_ || sceneId >= kMaxScenes) {
        return false;
    }
    
    // Enter the scene
    curScene_ = sceneId;
    where_ = 1;
    sx_ = rScene_[static_cast<std::size_t>(sceneId)].element.entranceX;
    sy_ = rScene_[static_cast<std::size_t>(sceneId)].element.entranceY;
    sFace_ = mFace_;
    // Reverse facing direction when entering: Mface := 3 - Mface
    sFace_ = 3 - sFace_;
    setScenePosition(sx_, sy_);
    return true;
}

void KysState::leaveScene() {
    if (where_ != 1 || curScene_ < 0 || curScene_ >= kMaxScenes) {
        return;
    }
    const auto& s = rScene_[static_cast<std::size_t>(curScene_)].element;
    setMapPosition(s.mainEntranceX1, s.mainEntranceY1);
    where_ = 0;
}

bool KysState::tryLeaveSceneAtCurrentPosition() {
    if (where_ != 1 || curScene_ < 0 || curScene_ >= kMaxScenes) {
        return false;
    }
    const auto& s = rScene_[static_cast<std::size_t>(curScene_)].element;
    for (int i = 0; i < 3; ++i) {
        if (sx_ == s.exitX[i] && sy_ == s.exitY[i]) {
            where_ = 0;
            return true;
        }
    }
    return false;
}

bool KysState::canWalkInScene(int x, int y) const {
    if (where_ != 1 || curScene_ < 0 || curScene_ >= kMaxScenes) {
        return false;
    }
    if (x < 0 || x > 63 || y < 0 || y > 63) {
        return false;
    }

    // Blocking layer: 0 means walkable.
    if (getSData(curScene_, 1, x, y) != 0) {
        return false;
    }

    // Some tile IDs are explicitly non-walkable in original logic.
    const int tile = getSData(curScene_, 0, x, y);
    if (tile >= 358 && tile <= 362) {
        return false;
    }

    // Event cell can block movement when event flag[0] == 1.
    const int ev = getSData(curScene_, 3, x, y);
    if (ev >= 0 && getDData(curScene_, ev, 0) == 1) {
        return false;
    }

    // Height difference limit (<=10) for adjacent movement.
    if (sx_ >= 0 && sx_ <= 63 && sy_ >= 0 && sy_ <= 63) {
        const int hFrom = getSData(curScene_, 4, sx_, sy_);
        const int hTo = getSData(curScene_, 4, x, y);
        const int diff = hTo - hFrom;
        if (diff > 10 || diff < -10) {
            return false;
        }
    }

    return true;
}

int KysState::tryTriggerCurrentSceneEvent() {
    if (where_ != 1 || curScene_ < 0 || curScene_ > 400) {
        return -1;
    }
    for (int eventIndex = 0; eventIndex < 200; ++eventIndex) {
        const int ex = getDData(curScene_, eventIndex, 9);
        const int ey = getDData(curScene_, eventIndex, 10);
        if (ex == sx_ && ey == sy_) {
            currentEvent_ = eventIndex;
            return eventIndex;
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
        currentEvent_ = ev;
        return ev;
    }
    return -1;
}

int KysState::earthAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= kWorldSize || y >= kWorldSize) {
        return 0;
    }
    const auto idx = static_cast<std::size_t>(x) * static_cast<std::size_t>(kWorldSize) + static_cast<std::size_t>(y);
    return earth_[idx];
}

int KysState::surfaceAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= kWorldSize || y >= kWorldSize) {
        return 0;
    }
    const auto idx = static_cast<std::size_t>(x) * static_cast<std::size_t>(kWorldSize) + static_cast<std::size_t>(y);
    return surface_[idx];
}

int KysState::buildingAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= kWorldSize || y >= kWorldSize) {
        return 0;
    }
    const auto idx = static_cast<std::size_t>(x) * static_cast<std::size_t>(kWorldSize) + static_cast<std::size_t>(y);
    return building_[idx];
}

int KysState::roleCurrentHp(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.currentHP;
}

int KysState::roleMaxHp(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.maxHP;
}

int KysState::rolePoison(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.poison;
}

int KysState::roleLevel(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.level;
}

int KysState::roleCurrentMp(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.currentMP;
}

int KysState::roleMaxMp(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.maxMP;
}

int KysState::roleCurrentExp(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.exp;
}

int KysState::roleExpForItem(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.expForItem;
}

int KysState::roleExpForBook(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.expForBook;
}

int KysState::roleAptitude(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.aptitude;
}

int KysState::rolePhyPower(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.phyPower;
}

int KysState::roleAttack(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.attack;
}

int KysState::roleDefence(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.defence;
}

int KysState::roleSpeed(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.speed;
}

int KysState::roleMedcine(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.medcine;
}

int KysState::roleUsePoi(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.usePoi;
}

int KysState::roleMedPoi(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.medPoi;
}

int KysState::roleFist(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.fist;
}

int KysState::roleSword(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.sword;
}

int KysState::roleKnife(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.knife;
}

int KysState::roleUnusual(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.unusual;
}

int KysState::roleHidWeapon(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.hidWeapon;
}

int KysState::roleEthics(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.ethics;
}

int KysState::roleEquip(int roleIndex, int equipSlot) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles || equipSlot < 0 || equipSlot > 1) {
        return -1;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.equip[equipSlot];
}

int KysState::rolePracticeBook(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return -1;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.practiceBook;
}

int KysState::roleMagic(int roleIndex, int magicSlot) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles || magicSlot < 0 || magicSlot >= 10) {
        return -1;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.magic[magicSlot];
}

int KysState::roleMagicLevel(int roleIndex, int magicSlot) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles || magicSlot < 0 || magicSlot >= 10) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.magLevel[magicSlot];
}

int KysState::roleHurt(int roleIndex) const {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return 0;
    }
    return rRole_[static_cast<std::size_t>(roleIndex)].element.hurt;
}

void KysState::healRoleFull(int roleIndex) {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return;
    }
    auto& r = rRole_[static_cast<std::size_t>(roleIndex)].element;
    r.currentHP = r.maxHP;
    r.hurt = 0;
}

void KysState::detoxRole(int roleIndex) {
    if (roleIndex < 0 || roleIndex >= kMaxRoles) {
        return;
    }
    rRole_[static_cast<std::size_t>(roleIndex)].element.poison = 0;
}

int KysState::itemListCount() const {
    return static_cast<int>(rItemList_.size());
}

int KysState::itemListNumber(int index) const {
    if (index < 0 || static_cast<std::size_t>(index) >= rItemList_.size()) {
        return -1;
    }
    return rItemList_[static_cast<std::size_t>(index)].number;
}

int KysState::itemListAmount(int index) const {
    if (index < 0 || static_cast<std::size_t>(index) >= rItemList_.size()) {
        return 0;
    }
    return rItemList_[static_cast<std::size_t>(index)].amount;
}

int KysState::itemType(int itemNumber) const {
    if (itemNumber < 0 || itemNumber >= kMaxItems) {
        return -1;
    }
    return rItem_[static_cast<std::size_t>(itemNumber)].element.itemType;
}

int KysState::itemUser(int itemNumber) const {
    if (itemNumber < 0 || itemNumber >= kMaxItems) {
        return -1;
    }
    return rItem_[static_cast<std::size_t>(itemNumber)].element.user;
}

int KysState::itemMagic(int itemNumber) const {
    if (itemNumber < 0 || itemNumber >= kMaxItems) {
        return -1;
    }
    return rItem_[static_cast<std::size_t>(itemNumber)].element.magic;
}

bool KysState::rearrangeItems() {
    std::vector<TItemList> valid;
    valid.reserve(rItemList_.size());
    for (const auto& it : rItemList_) {
        if (it.number >= 0 && it.amount > 0) {
            valid.push_back(it);
        }
    }
    std::sort(valid.begin(), valid.end(), [](const TItemList& a, const TItemList& b) {
        if (a.number == b.number) {
            return a.amount > b.amount;
        }
        return a.number < b.number;
    });
    std::fill(rItemList_.begin(), rItemList_.end(), TItemList{-1, 0});
    for (std::size_t i = 0; i < valid.size() && i < rItemList_.size(); ++i) {
        rItemList_[i] = valid[i];
    }
    return true;
}

std::string KysState::useItemOnRole(int itemNumber, int roleIndex) {
    if (itemNumber < 0 || itemNumber >= kMaxItems || roleIndex < 0 || roleIndex >= kMaxRoles) {
        return "使用失敗";
    }

    int slot = -1;
    for (int i = 0; i < static_cast<int>(rItemList_.size()); ++i) {
        if (rItemList_[static_cast<std::size_t>(i)].number == itemNumber && rItemList_[static_cast<std::size_t>(i)].amount > 0) {
            slot = i;
            break;
        }
    }
    if (slot < 0) {
        return "沒有此物品";
    }

    auto& item = rItem_[static_cast<std::size_t>(itemNumber)].element;
    auto& role = rRole_[static_cast<std::size_t>(roleIndex)].element;
    const int t = item.itemType;

    if (t == 0) {
        return "劇情物品，無法直接使用";
    }

    if (t == 1) {
        auto canEquip = [&](int rnum, int inum) -> bool {
            const auto& rr = rRole_[static_cast<std::size_t>(rnum)].element;
            const auto& it = rItem_[static_cast<std::size_t>(inum)].element;
            bool ok = true;

            if (signInt(it.needMP) * rr.currentMP < it.needMP) ok = false;
            if (signInt(it.needAttack) * rr.attack < it.needAttack) ok = false;
            if (signInt(it.needSpeed) * rr.speed < it.needSpeed) ok = false;
            if (signInt(it.needUsePoi) * rr.usePoi < it.needUsePoi) ok = false;
            if (signInt(it.needMedcine) * rr.medcine < it.needMedcine) ok = false;
            if (signInt(it.needMedPoi) * rr.medPoi < it.needMedPoi) ok = false;
            if (signInt(it.needFist) * rr.fist < it.needFist) ok = false;
            if (signInt(it.needSword) * rr.sword < it.needSword) ok = false;
            if (signInt(it.needKnife) * rr.knife < it.needKnife) ok = false;
            if (signInt(it.needUnusual) * rr.unusual < it.needUnusual) ok = false;
            if (signInt(it.needHidWeapon) * rr.hidWeapon < it.needHidWeapon) ok = false;
            if (signInt(it.needAptitude) * rr.aptitude < it.needAptitude) ok = false;

            if (rr.mpType < 2 && it.needMPType < 2 && rr.mpType != it.needMPType) {
                ok = false;
            }

            if (it.onlyPracRole >= 0) {
                ok = (it.onlyPracRole == rnum);
            }

            int knownCount = 0;
            for (int i = 0; i < 10; ++i) {
                if (rr.magic[i] > 0) {
                    ++knownCount;
                }
            }
            if (knownCount >= 10 && it.magic > 0) {
                ok = false;
            }
            for (int i = 0; i < 10; ++i) {
                if (rr.magic[i] == it.magic && rr.magLevel[i] < 900) {
                    ok = true;
                    break;
                }
            }

            return ok;
        };

        if (!canEquip(roleIndex, itemNumber)) {
            return "此人不適合裝備此物品";
        }

        int equipSlot = item.equipType;
        if (equipSlot < 0 || equipSlot > 1) {
            equipSlot = 0;
        }
        const int oldUser = item.user;
        if (oldUser >= 0 && oldUser < kMaxRoles) {
            auto& r = rRole_[static_cast<std::size_t>(oldUser)].element;
            if (r.equip[equipSlot] == itemNumber) {
                r.equip[equipSlot] = -1;
            }
        }
        if (role.equip[equipSlot] >= 0 && role.equip[equipSlot] < kMaxItems) {
            rItem_[static_cast<std::size_t>(role.equip[equipSlot])].element.user = -1;
        }
        role.equip[equipSlot] = static_cast<i16>(itemNumber);
        item.user = static_cast<i16>(roleIndex);
        return "裝備成功";
    }

    if (t == 2) {
        auto canPractice = [&](int rnum, int inum) -> bool {
            const auto& rr = rRole_[static_cast<std::size_t>(rnum)].element;
            const auto& it = rItem_[static_cast<std::size_t>(inum)].element;
            bool ok = true;

            if (signInt(it.needMP) * rr.currentMP < it.needMP) ok = false;
            if (signInt(it.needAttack) * rr.attack < it.needAttack) ok = false;
            if (signInt(it.needSpeed) * rr.speed < it.needSpeed) ok = false;
            if (signInt(it.needUsePoi) * rr.usePoi < it.needUsePoi) ok = false;
            if (signInt(it.needMedcine) * rr.medcine < it.needMedcine) ok = false;
            if (signInt(it.needMedPoi) * rr.medPoi < it.needMedPoi) ok = false;
            if (signInt(it.needFist) * rr.fist < it.needFist) ok = false;
            if (signInt(it.needSword) * rr.sword < it.needSword) ok = false;
            if (signInt(it.needKnife) * rr.knife < it.needKnife) ok = false;
            if (signInt(it.needUnusual) * rr.unusual < it.needUnusual) ok = false;
            if (signInt(it.needHidWeapon) * rr.hidWeapon < it.needHidWeapon) ok = false;
            if (signInt(it.needAptitude) * rr.aptitude < it.needAptitude) ok = false;

            if (rr.mpType < 2 && it.needMPType < 2 && rr.mpType != it.needMPType) {
                ok = false;
            }
            if (it.onlyPracRole >= 0) {
                ok = (it.onlyPracRole == rnum);
            }

            int knownCount = 0;
            for (int i = 0; i < 10; ++i) {
                if (rr.magic[i] > 0) {
                    ++knownCount;
                }
            }
            if (knownCount >= 10 && it.magic > 0) {
                ok = false;
            }
            for (int i = 0; i < 10; ++i) {
                if (rr.magic[i] == it.magic && rr.magLevel[i] < 900) {
                    ok = true;
                    break;
                }
            }

            return ok;
        };

        if (!canPractice(roleIndex, itemNumber)) {
            return "此人不適合修煉此秘笈";
        }

        if (item.user >= 0 && item.user < kMaxRoles) {
            rRole_[static_cast<std::size_t>(item.user)].element.practiceBook = -1;
        }
        if (role.practiceBook >= 0 && role.practiceBook < kMaxItems) {
            rItem_[static_cast<std::size_t>(role.practiceBook)].element.user = -1;
        }
        role.practiceBook = static_cast<i16>(itemNumber);
        item.user = static_cast<i16>(roleIndex);
        return "修煉設定成功";
    }

    if (t == 3) {
        auto clampLow = [](int v, int low) -> int {
            return (v < low) ? low : v;
        };
        auto clampRange = [](int v, int low, int high) -> int {
            if (v < low) {
                return low;
            }
            if (v > high) {
                return high;
            }
            return v;
        };

        role.currentHP = static_cast<i16>(clampRange(role.currentHP + item.addCurrentHP, 0, role.maxHP));
        role.maxHP = static_cast<i16>(clampLow(role.maxHP + item.addMaxHP, 1));
        role.poison = static_cast<i16>(clampLow(role.poison + item.addPoi, 0));
        role.phyPower = static_cast<i16>(clampLow(role.phyPower + item.addPhyPower, 0));
        role.currentMP = static_cast<i16>(clampRange(role.currentMP + item.addCurrentMP, 0, role.maxMP));
        role.maxMP = static_cast<i16>(clampLow(role.maxMP + item.addMaxMP, 0));
        role.attack = static_cast<i16>(clampLow(role.attack + item.addAttack, 0));
        role.speed = static_cast<i16>(clampLow(role.speed + item.addSpeed, 0));
        role.defence = static_cast<i16>(clampLow(role.defence + item.addDefence, 0));
        role.medcine = static_cast<i16>(clampLow(role.medcine + item.addMedcine, 0));
        role.usePoi = static_cast<i16>(clampLow(role.usePoi + item.addUsePoi, 0));
        role.medPoi = static_cast<i16>(clampLow(role.medPoi + item.addMedPoi, 0));
        role.defPoi = static_cast<i16>(clampLow(role.defPoi + item.addDefPoi, 0));
        role.fist = static_cast<i16>(clampLow(role.fist + item.addFist, 0));
        role.sword = static_cast<i16>(clampLow(role.sword + item.addSword, 0));
        role.knife = static_cast<i16>(clampLow(role.knife + item.addKnife, 0));
        role.unusual = static_cast<i16>(clampLow(role.unusual + item.addUnusual, 0));
        role.hidWeapon = static_cast<i16>(clampLow(role.hidWeapon + item.addHidWeapon, 0));
        role.knowledge = static_cast<i16>(clampLow(role.knowledge + item.addKnowledge, 0));
        role.ethics = static_cast<i16>(clampLow(role.ethics + item.addEthics, 0));
        role.attTwice = static_cast<i16>(clampLow(role.attTwice + item.addAttTwice, 0));
        role.attPoi = static_cast<i16>(clampLow(role.attPoi + item.addAttPoi, 0));
        if (rItemList_[static_cast<std::size_t>(slot)].amount > 0) {
            rItemList_[static_cast<std::size_t>(slot)].amount -= 1;
        }
        if (rItemList_[static_cast<std::size_t>(slot)].amount <= 0) {
            rItemList_[static_cast<std::size_t>(slot)].number = -1;
            rItemList_[static_cast<std::size_t>(slot)].amount = 0;
        }
        return "服用成功";
    }

    if (t == 4) {
        return "暗器僅戰鬥可用";
    }

    return "未知物品類型";
}

std::string KysState::useStoryItem(int itemNumber) {
    if (itemNumber < 0 || itemNumber >= kMaxItems) {
        return "物品無效";
    }

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

void KysState::removeTeamMember(int teamIndex) {
    if (teamIndex < 0 || teamIndex >= kTeamSize) {
        return;
    }
    for (int i = teamIndex; i < kTeamSize - 1; ++i) {
        teamList_[static_cast<std::size_t>(i)] = teamList_[static_cast<std::size_t>(i + 1)];
    }
    teamList_[kTeamSize - 1] = -1;
}

bool KysState::teleportToScene(int sceneId) {
    if (sceneId < 0 || sceneId >= sceneAmount_ || sceneId >= kMaxScenes) {
        return false;
    }
    const auto& s = rScene_[static_cast<std::size_t>(sceneId)].element;
    if (s.mainEntranceX1 < 0 || s.mainEntranceX1 >= kWorldSize || s.mainEntranceY1 < 0 || s.mainEntranceY1 >= kWorldSize) {
        return false;
    }
    setMapPosition(s.mainEntranceX1, s.mainEntranceY1);
    where_ = 0;
    return true;
}

} // namespace kys
