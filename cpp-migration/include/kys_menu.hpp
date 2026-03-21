#pragma once
/// In-game menu / UI state machine.
/// Extracted from sdl_runtime.cpp; loosely mirrors the ShowMenu / CommonMenu
/// logic in kys_main.pas.

#include <chrono>
#include <string>
#include <vector>

namespace kys {

struct MainMenuState {
    enum class Page {
        Title,
        Root,
        System,
        LoadSlots,
        SaveSlots,
        QuitConfirm,
        Medical,
        Detox,
        ItemType,
        ItemList,
        ItemBrowse,
        ItemTarget,
        Status,
        StatusDetail,
        LeaveTeam,
        Teleport
    };

    bool open = true;   // Start with menu open (title screen)
    int selected = 0;
    Page page = Page::Title;
    std::vector<Page> stack;
    std::string status;
    std::chrono::steady_clock::time_point statusTime{};
    int selectedItemType = -1;
    int selectedItemNumber = -1;
    int selectedRole = -1;

    // Item browse grid state
    int itemBrowseRow = 0;
    int itemBrowseCols = 0;
    int itemBrowseRows = 0;
    int itemStartIndex = 0;
    std::vector<int> itemBrowseList;

    // Teleport map state
    int teleportSelectedScene = -1;  // scene index under cursor, -1 if none

    static std::string pageTitle(Page p) {
        switch (p) {
            case Page::Title:        return "乾宇傳說";
            case Page::Root:         return "主選單";
            case Page::System:       return "系統";
            case Page::LoadSlots:    return "讀取";
            case Page::SaveSlots:    return "存檔";
            case Page::QuitConfirm:  return "離開";
            case Page::Medical:      return "醫療";
            case Page::Detox:        return "解毒";
            case Page::ItemType:     return "物品分類";
            case Page::ItemList:     return "物品列表";
            case Page::ItemBrowse:   return "物品浏覽";
            case Page::ItemTarget:   return "選擇對象";
            case Page::Status:       return "狀態";
            case Page::StatusDetail: return "角色詳情";
            case Page::LeaveTeam:    return "離隊";
            case Page::Teleport:     return "傳送";
            default:                 return "Menu";
        }
    }

    void enter(Page p) {
        stack.push_back(page);
        page = p;
        selected = 0;
    }

    bool back() {
        if (stack.empty()) {
            open = false;
            return false;
        }
        page = stack.back();
        stack.pop_back();
        selected = 0;
        return true;
    }

    void resetToRoot() {
        open = true;
        page = Page::Root;
        selected = 0;
        stack.clear();
    }

    void setStatus(const std::string& s) {
        status = s;
        statusTime = std::chrono::steady_clock::now();
    }

    bool statusVisible() const {
        if (status.empty()) {
            return false;
        }
        const auto now = std::chrono::steady_clock::now();
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - statusTime).count();
        return ms < 2500;
    }
};

} // namespace kys
