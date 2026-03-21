#pragma once

#include "kys_types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <fstream>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

namespace kys {

struct SaveOffsets {
    i32 roleOffset = 0;
    i32 itemOffset = 0;
    i32 sceneOffset = 0;
    i32 magicOffset = 0;
    i32 weiShopOffset = 0;
    i32 totalLen = 0;
};

class KysState {
public:
    static constexpr int kWorldSize = 480;
    static constexpr int kTeamSize = 6;
    static constexpr int kMaxRoles = 2032;
    static constexpr int kMaxItems = 725;
    static constexpr int kMaxScenes = 201;
    static constexpr int kMaxMagics = 999;
    static constexpr int kMaxShops = 11;
    static constexpr int kDefaultMaxItemAmount = 200;

    explicit KysState(std::string appPath);

    bool loadR(int num);
    bool saveR(int num);
    bool newGame();
    bool loadWorldData();

    int getRoleData(int roleIndex, int dataIndex) const;
    void setRoleData(int roleIndex, int dataIndex, int value);

    int getItemData(int itemIndex, int dataIndex) const;
    void setItemData(int itemIndex, int dataIndex, int value);

    int getMagicData(int magicIndex, int dataIndex) const;
    void setMagicData(int magicIndex, int dataIndex, int value);

    int getSceneData(int sceneIndex, int dataIndex) const;
    void setSceneData(int sceneIndex, int dataIndex, int value);

    int getSData(int sceneIndex, int layer, int x, int y) const;
    void setSData(int sceneIndex, int layer, int x, int y, int value);

    int getDData(int sceneIndex, int eventIndex, int dataIndex) const;
    void setDData(int sceneIndex, int eventIndex, int dataIndex, int value);

    int judgeSceneEvent(int eventIndex, int offset, int expected) const;

    int getTeam(int index) const;
    void setTeam(int index, int value);

    int readMem(int address) const;
    void writeMem(int address, int value);

    std::string getRoleName(int index) const;
    std::string getItemName(int index) const;
    std::string getItemIntroduction(int index) const;
    std::string getMagicName(int index) const;
    std::string getSceneName(int index) const;
    std::string getTalk(int talkNum);

    int drawLength(const std::string& s) const;

    void clearButtonState();
    int checkButtonState() const;
    int currentKey() const;
    int currentButton() const;
    int waitAnyKey() const;
    int mouseX() const;
    int mouseY() const;
    void setInputState(int key, int button, int mouseX, int mouseY);

    void execEvent(int eventId, const std::vector<int>& args);
    void callEvent(int eventId);
    bool hasPendingEvent() const;
    int popPendingEvent();

    void changeScene(int sceneId, int x, int y);
    void walkFromTo(int x1, int y1, int x2, int y2);
    void sceneFromTo(int x1, int y1, int x2, int y2);

    int currentBattle() const { return currentBattle_; }
    int mapX() const { return mx_; }
    int mapY() const { return my_; }
    int mapFace() const { return mFace_; }
    int sceneX() const { return sx_; }
    int sceneY() const { return sy_; }
    void setMapPosition(int x, int y);
    void setMapFace(int face);
    void setScenePosition(int x, int y);
    bool canWalkOnMap(int x, int y);
    int entranceSceneAt(int x, int y) const;
    bool tryEnterScene();
    void leaveScene();
    bool tryLeaveSceneAtCurrentPosition();
    bool canWalkInScene(int x, int y) const;
    int tryTriggerCurrentSceneEvent();
    int tryTriggerFacingSceneEvent();
    int currentEvent() const { return currentEvent_; }

    int earthAt(int x, int y) const;
    int surfaceAt(int x, int y) const;
    int buildingAt(int x, int y) const;
    int getBattleRoleData(int roleIndex, int dataIndex) const;
    void setBattleRoleData(int roleIndex, int dataIndex, int value);

    int sceneAmount() const { return sceneAmount_; }
    int currentScene() const { return curScene_; }
    int where() const { return where_; }
    int inShip() const { return inShip_; }
    int sceneFace() const { return sFace_; }
    void setSceneFace(int face);

    int roleCurrentHp(int roleIndex) const;
    int roleMaxHp(int roleIndex) const;
    int roleHeadNum(int roleIndex) const;
    int rolePoison(int roleIndex) const;
    int roleLevel(int roleIndex) const;
    int roleCurrentMp(int roleIndex) const;
    int roleMaxMp(int roleIndex) const;
    int roleCurrentExp(int roleIndex) const;
    int roleExpForItem(int roleIndex) const;
    int roleExpForBook(int roleIndex) const;
    int roleAptitude(int roleIndex) const;
    int rolePhyPower(int roleIndex) const;
    int roleAttack(int roleIndex) const;
    int roleDefence(int roleIndex) const;
    int roleSpeed(int roleIndex) const;
    int roleMedcine(int roleIndex) const;
    int roleUsePoi(int roleIndex) const;
    int roleMedPoi(int roleIndex) const;
    int roleFist(int roleIndex) const;
    int roleSword(int roleIndex) const;
    int roleKnife(int roleIndex) const;
    int roleUnusual(int roleIndex) const;
    int roleHidWeapon(int roleIndex) const;
    int roleEthics(int roleIndex) const;
    int roleEquip(int roleIndex, int equipSlot) const;
    int rolePracticeBook(int roleIndex) const;
    int roleMagic(int roleIndex, int magicSlot) const;
    int roleMagicLevel(int roleIndex, int magicSlot) const;
    int roleHurt(int roleIndex) const;
    void healRoleFull(int roleIndex);
    void detoxRole(int roleIndex);

    int itemListCount() const;
    int itemListNumber(int index) const;
    int itemListAmount(int index) const;
    int itemType(int itemNumber) const;
    int itemUser(int itemNumber) const;
    int itemMagic(int itemNumber) const;

    bool rearrangeItems();
    std::string useItemOnRole(int itemNumber, int roleIndex);
    std::string useStoryItem(int itemNumber);

    using TalkCallback = std::function<void(const std::string& text, int headNum, int dismode)>;
    using YesNoCallback = std::function<bool(const std::string& title, const std::string& text, bool defaultYes)>;
    using GetItemCallback = std::function<bool(const std::string& itemName, int amount)>;
    void setTalkCallback(TalkCallback cb);
    void setYesNoCallback(YesNoCallback cb);
    void setGetItemCallback(GetItemCallback cb);

    void removeTeamMember(int teamIndex);
    bool teleportToScene(int sceneId);

private:
    bool readOffsets(SaveOffsets& offsets) const;
    bool ensureEventDefsLoaded();
    std::vector<i16> readEventCode(int eventId);
    void executeEventCode(int eventId);
    void execInstruct3(const std::array<int, 13>& list);
    void addItemAmount(int itemNumber, int amount);

    static bool readExact(std::ifstream& in, void* dst, std::size_t size);
    static bool writeExact(std::ofstream& out, const void* src, std::size_t size);

    std::string appPath_;

    int maxItemAmount_ = kDefaultMaxItemAmount;
    int sceneAmount_ = 0;
    int curScene_ = -1;
    int where_ = 0;

    i16 inShip_ = 0;
    i16 useLess1_ = 0;
    i16 mx_ = 0;
    i16 my_ = 0;
    i16 sx_ = 0;
    i16 sy_ = 0;
    i16 mFace_ = 0;
    i16 sFace_ = 0;
    i16 shipX_ = 0;
    i16 shipY_ = 0;
    i16 shipX1_ = 0;
    i16 shipY1_ = 0;
    i16 shipFace_ = 0;

    std::array<i16, kTeamSize> teamList_{};
    std::vector<TItemList> rItemList_;

    std::array<TRole, kMaxRoles> rRole_{};
    std::array<TItem, kMaxItems> rItem_{};
    std::array<TScene, kMaxScenes> rScene_{};
    std::array<TMagic, kMaxMagics> rMagic_{};
    std::array<TShop, kMaxShops> rShop_{};

    std::array<i16, kWorldSize * kWorldSize> entrance_{};
    std::vector<i16> earth_;
    std::vector<i16> surface_;
    std::vector<i16> building_;
    std::vector<i16> buildX_;
    std::vector<i16> buildY_;

    std::array<i16, 401 * 6 * 64 * 64> sData_{};
    std::array<i16, 401 * 200 * 11> dData_{};

    std::unordered_map<int, int> memMap_;

    std::vector<std::int32_t> tIdx_;
    std::vector<std::uint8_t> tDef_;
    bool talkLoaded_ = false;

    std::vector<std::int32_t> kIdx_;
    std::vector<std::uint8_t> kDef_;
    bool eventDefLoaded_ = false;

    int currentKey_ = 0;
    int currentButton_ = 0;
    int mouseX_ = 0;
    int mouseY_ = 0;

    int currentEvent_ = -1;
    int currentBattle_ = 0;
    int currentItem_ = -1;
    TalkCallback talkCallback_;
    YesNoCallback yesNoCallback_;
    GetItemCallback getItemCallback_;
    std::unordered_map<int, int> eventArgMap_;
    std::vector<int> pendingEvents_;
    std::map<int, std::array<i16, 19>> battleRoleData_;

};
} // namespace kys
