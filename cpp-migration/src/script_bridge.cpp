#include "script_bridge.hpp"
#include "kys_state.hpp"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <fstream>
#include <iostream>
#include <iterator>
#include <thread>

#if __has_include(<lua.hpp>)
#include <lua.hpp>
#define KYS_HAS_LUA 1
#else
#define KYS_HAS_LUA 0
struct lua_State;
#endif

namespace kys {
namespace {

#if KYS_HAS_LUA
ScriptBridge* getBridge(lua_State* L) {
    auto* p = lua_touserdata(L, lua_upvalueindex(1));
       // "displaytalk"
}

int LuaNotImplemented(lua_State*) {
    return 0;
}

int LuaGetTime(lua_State* L) {
    const auto now = std::chrono::steady_clock::now().time_since_epoch();
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
    lua_pushinteger(L, static_cast<lua_Integer>(ms));
    return 1;
}

int LuaPause(lua_State* L) {
    int ms = 0;
    if (lua_gettop(L) >= 1 && lua_isnumber(L, 1)) {
        ms = static_cast<int>(lua_tointeger(L, 1));
    }
    if (ms < 0) {
        ms = 0;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(ms));
    return 0;
}

int LuaGetRole(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int role = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    lua_pushinteger(L, bridge->state()->getRoleData(role, idx));
    return 1;
}

int LuaSetRole(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        return 0;
    }
    const int role = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    const int value = static_cast<int>(lua_tointeger(L, 3));
    bridge->state()->setRoleData(role, idx, value);
    return 0;
}

int LuaGetItem(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int item = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    lua_pushinteger(L, bridge->state()->getItemData(item, idx));
    return 1;
}

int LuaSetItem(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        return 0;
    }
    const int item = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    const int value = static_cast<int>(lua_tointeger(L, 3));
    bridge->state()->setItemData(item, idx, value);
    return 0;
}

int LuaGetMagic(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int magic = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    lua_pushinteger(L, bridge->state()->getMagicData(magic, idx));
    return 1;
}

int LuaSetMagic(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        return 0;
    }
    const int magic = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    const int value = static_cast<int>(lua_tointeger(L, 3));
    bridge->state()->setMagicData(magic, idx, value);
    return 0;
}

int LuaSetTeam(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        return 0;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const int value = static_cast<int>(lua_tointeger(L, 2));
    bridge->state()->setTeam(idx, value);
    return 0;
}

int LuaGetTeam(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    lua_pushinteger(L, bridge->state()->getTeam(idx));
    return 1;
}

int LuaReadMem(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int addr = static_cast<int>(lua_tointeger(L, 1));
    lua_pushinteger(L, bridge->state()->readMem(addr));
    return 1;
}

int LuaWriteMem(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        return 0;
    }
    const int addr = static_cast<int>(lua_tointeger(L, 1));
    const int value = static_cast<int>(lua_tointeger(L, 2));
    bridge->state()->writeMem(addr, value);
    return 0;
}

int LuaGetScene(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    lua_pushinteger(L, bridge->state()->getSceneData(scene, idx));
    return 1;
}

int LuaSetScene(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        return 0;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int idx = static_cast<int>(lua_tointeger(L, 2));
    const int value = static_cast<int>(lua_tointeger(L, 3));
    bridge->state()->setSceneData(scene, idx, value);
    return 0;
}

int LuaGetS(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 4) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int layer = static_cast<int>(lua_tointeger(L, 2));
    const int x = static_cast<int>(lua_tointeger(L, 3));
    const int y = static_cast<int>(lua_tointeger(L, 4));
    lua_pushinteger(L, bridge->state()->getSData(scene, layer, x, y));
    return 1;
}

int LuaSetS(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 5) {
        return 0;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int layer = static_cast<int>(lua_tointeger(L, 2));
    const int x = static_cast<int>(lua_tointeger(L, 3));
    const int y = static_cast<int>(lua_tointeger(L, 4));
    const int value = static_cast<int>(lua_tointeger(L, 5));
    bridge->state()->setSData(scene, layer, x, y, value);
    return 0;
}

int LuaGetD(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int eventIndex = static_cast<int>(lua_tointeger(L, 2));
    const int idx = static_cast<int>(lua_tointeger(L, 3));
    lua_pushinteger(L, bridge->state()->getDData(scene, eventIndex, idx));
    return 1;
}

int LuaSetD(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 4) {
        return 0;
    }
    const int scene = static_cast<int>(lua_tointeger(L, 1));
    const int eventIndex = static_cast<int>(lua_tointeger(L, 2));
    const int idx = static_cast<int>(lua_tointeger(L, 3));
    const int value = static_cast<int>(lua_tointeger(L, 4));
    bridge->state()->setDData(scene, eventIndex, idx, value);
    return 0;
}

int LuaJudgeSceneEvent(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int eventIndex = static_cast<int>(lua_tointeger(L, 1));
    const int offset = static_cast<int>(lua_tointeger(L, 2));
    const int expected = static_cast<int>(lua_tointeger(L, 3));
    lua_pushinteger(L, bridge->state()->judgeSceneEvent(eventIndex, offset, expected));
    return 1;
}

int LuaGetRoleName(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushstring(L, "");
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const auto s = bridge->state()->getRoleName(idx);
    lua_pushlstring(L, s.data(), s.size());
    return 1;
}

int LuaGetItemName(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushstring(L, "");
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const auto s = bridge->state()->getItemName(idx);
    lua_pushlstring(L, s.data(), s.size());
    return 1;
}

int LuaGetMagicName(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushstring(L, "");
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const auto s = bridge->state()->getMagicName(idx);
    lua_pushlstring(L, s.data(), s.size());
    return 1;
}

int LuaGetSceneName(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushstring(L, "");
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const auto s = bridge->state()->getSceneName(idx);
    lua_pushlstring(L, s.data(), s.size());
    return 1;
}

int LuaDrawLength(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushinteger(L, 0);
        return 1;
    }
    size_t len = 0;
    const char* s = lua_tolstring(L, 1, &len);
    if (!s) {
        lua_pushinteger(L, 0);
        return 1;
    }
    lua_pushinteger(L, bridge->state()->drawLength(std::string(s, len)));
    return 1;
}

int LuaGetKey(lua_State* L) {
    auto* bridge = getBridge(L);
    const int key = (!bridge || !bridge->state()) ? 0 : bridge->state()->waitAnyKey();
    lua_pushinteger(L, key);
    return 1;
}

int LuaGetTalk(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        lua_pushstring(L, "");
        return 1;
    }
    const int idx = static_cast<int>(lua_tointeger(L, 1));
    const auto s = bridge->state()->getTalk(idx);
    lua_pushlstring(L, s.data(), s.size());
    return 1;
}

int LuaGetMousePosition(lua_State* L) {
    auto* bridge = getBridge(L);
    int x = 0;
    int y = 0;
    if (bridge && bridge->state()) {
        x = bridge->state()->mouseX();
        y = bridge->state()->mouseY();
    }
    lua_pushinteger(L, x);
    lua_pushinteger(L, y);
    return 2;
}

int LuaClearButton(lua_State* L) {
    auto* bridge = getBridge(L);
    if (bridge && bridge->state()) {
        bridge->state()->clearButtonState();
    }
    return 0;
}

int LuaCheckButton(lua_State* L) {
    auto* bridge = getBridge(L);
    const int t = (!bridge || !bridge->state()) ? 0 : bridge->state()->checkButtonState();
    lua_pushinteger(L, t);
    return 1;
}

int LuaGetButton(lua_State* L) {
    auto* bridge = getBridge(L);
    int key = 0;
    int button = 0;
    if (bridge && bridge->state()) {
        key = bridge->state()->currentKey();
        button = bridge->state()->currentButton();
    }
    lua_pushinteger(L, key);
    lua_pushinteger(L, button);
    return 2;
}

int LuaExecEvent(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state()) {
        return 0;
    }
    const int n = lua_gettop(L);
    if (n < 1) {
        return 0;
    }
    const int eventId = static_cast<int>(lua_tointeger(L, 1));
    std::vector<int> args;
    args.reserve(static_cast<std::size_t>(n > 1 ? n - 1 : 0));
    for (int i = 2; i <= n; ++i) {
        args.push_back(static_cast<int>(lua_tointeger(L, i)));
    }
    bridge->state()->execEvent(eventId, args);
    return 0;
}

int LuaCallEvent(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 1) {
        return 0;
    }
    const int eventId = static_cast<int>(lua_tointeger(L, 1));
    bridge->state()->callEvent(eventId);
    return 0;
}

int LuaChangeScene(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state()) {
        return 0;
    }
    const int n = lua_gettop(L);
    if (n < 1) {
        return 0;
    }
    const int sceneId = static_cast<int>(lua_tointeger(L, 1));
    int x = 0;
    int y = 0;
    if (n >= 3) {
        x = static_cast<int>(lua_tointeger(L, 2));
        y = static_cast<int>(lua_tointeger(L, 3));
    }
    bridge->state()->changeScene(sceneId, x, y);
    return 0;
}

int LuaWalkFromTo(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 4) {
        return 0;
    }
    const int x1 = static_cast<int>(lua_tointeger(L, 1));
    const int y1 = static_cast<int>(lua_tointeger(L, 2));
    const int x2 = static_cast<int>(lua_tointeger(L, 3));
    const int y2 = static_cast<int>(lua_tointeger(L, 4));
    bridge->state()->walkFromTo(x1, y1, x2, y2);
    return 0;
}

int LuaSceneFromTo(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 4) {
        return 0;
    }
    const int x1 = static_cast<int>(lua_tointeger(L, 1));
    const int y1 = static_cast<int>(lua_tointeger(L, 2));
    const int x2 = static_cast<int>(lua_tointeger(L, 3));
    const int y2 = static_cast<int>(lua_tointeger(L, 4));
    bridge->state()->sceneFromTo(x1, y1, x2, y2);
    return 0;
}

int LuaGetBattleNumber(lua_State* L) {
    auto* bridge = getBridge(L);
    const int n = (!bridge || !bridge->state()) ? 0 : bridge->state()->currentBattle();
    lua_pushinteger(L, n);
    return 1;
}

int LuaGetBattleRolePro(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 2) {
        lua_pushinteger(L, 0);
        return 1;
    }
    const int b = static_cast<int>(lua_tointeger(L, 1));
    const int p = static_cast<int>(lua_tointeger(L, 2));
    lua_pushinteger(L, bridge->state()->getBattleRoleData(b, p));
    return 1;
}

int LuaPutBattleRolePro(lua_State* L) {
    auto* bridge = getBridge(L);
    if (!bridge || !bridge->state() || lua_gettop(L) < 3) {
        return 0;
    }
    const int b = static_cast<int>(lua_tointeger(L, 1));
    const int p = static_cast<int>(lua_tointeger(L, 2));
    const int v = static_cast<int>(lua_tointeger(L, 3));
    bridge->state()->setBattleRoleData(b, p, v);
    return 0;
}

void RegisterApi(lua_State* L, const char* name, lua_CFunction fn, ScriptBridge* bridge) {
    lua_pushlightuserdata(L, bridge);
    lua_pushcclosure(L, fn, 1);
    lua_setglobal(L, name);
}
#endif

std::vector<std::string> buildApiNameList() {
    return {
        "pause", "getmouseposition", "clearbutton", "checkbutton", "getbutton", "gettime", "execevent", "callevent",
        "clear", "talk", "getitem", "additem", "showstring", "drawstring", "showstringwithbox", "showmessage", "menu", "askyesorno",
        "modifyevent", "useitem", "haveitem", "haveitembool", "anothergetitem", "compareprointeam", "allleave", "askbattle", "trybattle",
        "askjoin", "join", "askrest", "rest", "lightscene", "darkscene", "dead", "inteam", "teamisfull", "leaveteam", "learnmagic",
        "getmainmapposition", "setmainmapposition", "getsceneposition", "setsceneposition", "getsceneface", "setsceneface", "delay", "lib.delay",
        "drawrect", "memberamount", "getmember", "setmember", "getrole", "setrole", "setitem", "getmagic", "setmagic", "getsubmapinfo",
        "setsubmapinfo", "gets", "sets", "getd", "setd", "judgesceneevent", "playmusic", "playwave", "walkfromto", "scenefromto",
        "playanimation", "getnameasstring", "changescene", "showpicture", "getitemlist", "getcurrentscene", "getcurrentevent", "getbattlenumber",
        "selectoneaim", "getbattlerolepro", "putbattlerolepro", "playaction", "playhurtvalue", "setaminationlayer", "clearrolefrombattle",
        "addroleintobattle", "forcebattleresult", "changemmapmusic", "changemainmapmusic", "asksoftstar", "showethics", "showrepute", "openallscene",
        "instruct_0", "instruct_1", "instruct_2", "instruct_3", "instruct_4", "instruct_5", "instruct_6", "instruct_7", "instruct_8", "instruct_9",
        "instruct_10", "instruct_11", "instruct_12", "instruct_13", "instruct_14", "instruct_15", "instruct_16", "instruct_17", "setsubmaplayerdata",
        "instruct_18", "instruct_19", "oldsetsceneposition", "instruct_20", "instruct_21", "instruct_22", "zeroallmp", "instruct_23", "setroleusepoison",
        "instruct_24", "submapviewfromto", "instruct_25", "instruct_26", "add3eventnum", "instruct_27", "instruct_28", "checkrolemorality", "instruct_29",
        "checkroleattack", "instruct_30", "instruct_31", "checkenoughmoney", "instruct_32", "additemwithouthint", "instruct_33", "oldlearnmagic", "instruct_34",
        "addiq", "instruct_35", "setrolemagic", "instruct_36", "checkrolesexual", "instruct_37", "addmorality", "instruct_38", "changesubmappic", "instruct_39",
        "opensubmap", "instruct_40", "settowards", "instruct_41", "roleadditem", "instruct_42", "checkfemaleinteam", "instruct_43", "instruct_44", "instruct_45",
        "addspeed", "instruct_46", "addmaxmp", "instruct_47", "addattack", "instruct_48", "addmaxhp", "instruct_49", "setmptype", "instruct_50", "instruct_50e",
        "instruct_51", "showmorality", "instruct_52", "instruct_53", "showfame", "instruct_54", "openallsubmap", "instruct_55", "checkeventid", "instruct_56",
        "addfame", "instruct_57", "breakstonegate", "instruct_58", "instruct_59", "instruct_60", "checksubmappic", "instruct_61", "check14booksplaced", "instruct_62",
        "backhome", "instruct_63", "setsexual", "instruct_64", "shop", "instruct_65", "instruct_66", "instruct_67", "eatoneitem", "selectoneteammember", "setteam",
        "getteam", "read_mem", "write_mem", "getrolename", "getitemname", "getmagicname", "getsubmapname", "drawlength", "getkey", "gettalk"
    };
}

bool ScriptBridge::initialize() {
    if (initialized_) {
        return true;
    }

#if KYS_HAS_LUA
    auto* L = luaL_newstate();
    if (!L) {
        return false;
    }
    luaL_openlibs(L);
    luaState_ = L;
    hasLuaBackend_ = true;
#else
    luaState_ = nullptr;
    hasLuaBackend_ = false;
#endif

    registerAllApis();

    // Keep the original bootstrap behavior.
    (void)execScriptString("x={}; for i=0,30000 do x[i]=0; end;", "");

    initialized_ = true;
    return true;
}

void ScriptBridge::destroy() {
#if KYS_HAS_LUA
    if (luaState_) {
        lua_close(static_cast<lua_State*>(luaState_));
    }
#endif
    luaState_ = nullptr;
    initialized_ = false;
    hasLuaBackend_ = false;
}

void ScriptBridge::registerAllApis() {
    apiNames_ = buildApiNameList();

#if KYS_HAS_LUA
    auto* L = static_cast<lua_State*>(luaState_);
    for (const auto& n : apiNames_) {
        if (n == "gettime") {
            RegisterApi(L, n.c_str(), LuaGetTime, this);
        } else if (n == "pause" || n == "delay" || n == "lib.delay") {
            RegisterApi(L, n.c_str(), LuaPause, this);
        } else if (n == "getmouseposition") {
            RegisterApi(L, n.c_str(), LuaGetMousePosition, this);
        } else if (n == "execevent") {
            RegisterApi(L, n.c_str(), LuaExecEvent, this);
        } else if (n == "callevent") {
            RegisterApi(L, n.c_str(), LuaCallEvent, this);
        } else if (n == "changescene") {
            RegisterApi(L, n.c_str(), LuaChangeScene, this);
        } else if (n == "walkfromto") {
            RegisterApi(L, n.c_str(), LuaWalkFromTo, this);
        } else if (n == "scenefromto") {
            RegisterApi(L, n.c_str(), LuaSceneFromTo, this);
        } else if (n == "getbattlenumber") {
            RegisterApi(L, n.c_str(), LuaGetBattleNumber, this);
        } else if (n == "getbattlerolepro") {
            RegisterApi(L, n.c_str(), LuaGetBattleRolePro, this);
        } else if (n == "putbattlerolepro") {
            RegisterApi(L, n.c_str(), LuaPutBattleRolePro, this);
        } else if (n == "clearbutton") {
            RegisterApi(L, n.c_str(), LuaClearButton, this);
        } else if (n == "checkbutton") {
            RegisterApi(L, n.c_str(), LuaCheckButton, this);
        } else if (n == "getbutton") {
            RegisterApi(L, n.c_str(), LuaGetButton, this);
        } else if (n == "getrole") {
            RegisterApi(L, n.c_str(), LuaGetRole, this);
        } else if (n == "setrole") {
            RegisterApi(L, n.c_str(), LuaSetRole, this);
        } else if (n == "getitem") {
            RegisterApi(L, n.c_str(), LuaGetItem, this);
        } else if (n == "setitem") {
            RegisterApi(L, n.c_str(), LuaSetItem, this);
        } else if (n == "getmagic") {
            RegisterApi(L, n.c_str(), LuaGetMagic, this);
        } else if (n == "setmagic") {
            RegisterApi(L, n.c_str(), LuaSetMagic, this);
        } else if (n == "setteam") {
            RegisterApi(L, n.c_str(), LuaSetTeam, this);
        } else if (n == "getteam") {
            RegisterApi(L, n.c_str(), LuaGetTeam, this);
        } else if (n == "read_mem") {
            RegisterApi(L, n.c_str(), LuaReadMem, this);
        } else if (n == "write_mem") {
            RegisterApi(L, n.c_str(), LuaWriteMem, this);
        } else if (n == "getsubmapinfo") {
            RegisterApi(L, n.c_str(), LuaGetScene, this);
        } else if (n == "setsubmapinfo") {
            RegisterApi(L, n.c_str(), LuaSetScene, this);
        } else if (n == "gets") {
            RegisterApi(L, n.c_str(), LuaGetS, this);
        } else if (n == "sets") {
            RegisterApi(L, n.c_str(), LuaSetS, this);
        } else if (n == "getd") {
            RegisterApi(L, n.c_str(), LuaGetD, this);
        } else if (n == "setd") {
            RegisterApi(L, n.c_str(), LuaSetD, this);
        } else if (n == "judgesceneevent") {
            RegisterApi(L, n.c_str(), LuaJudgeSceneEvent, this);
        } else if (n == "getrolename") {
            RegisterApi(L, n.c_str(), LuaGetRoleName, this);
        } else if (n == "getitemname") {
            RegisterApi(L, n.c_str(), LuaGetItemName, this);
        } else if (n == "getmagicname") {
            RegisterApi(L, n.c_str(), LuaGetMagicName, this);
        } else if (n == "getsubmapname") {
            RegisterApi(L, n.c_str(), LuaGetSceneName, this);
        } else if (n == "drawlength") {
            RegisterApi(L, n.c_str(), LuaDrawLength, this);
        } else if (n == "getkey") {
            RegisterApi(L, n.c_str(), LuaGetKey, this);
        } else if (n == "gettalk") {
            RegisterApi(L, n.c_str(), LuaGetTalk, this);
        } else {
            RegisterApi(L, n.c_str(), LuaNotImplemented, this);
        }
    }
#endif
}

int ScriptBridge::execScript(const std::string& fileName, const std::string& functionName) {
    std::ifstream in(fileName, std::ios::binary);
    if (!in) {
        return 0;
    }
    std::string script((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    return execScriptString(std::move(script), functionName);
}

int ScriptBridge::execScriptString(std::string script, const std::string& functionName) {
    if (script.size() >= 3 &&
        static_cast<unsigned char>(script[0]) == 0xEF &&
        static_cast<unsigned char>(script[1]) == 0xBB &&
        static_cast<unsigned char>(script[2]) == 0xBF) {
        script[0] = ' ';
        script[1] = ' ';
        script[2] = ' ';
    }

    std::transform(script.begin(), script.end(), script.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });

#if KYS_HAS_LUA
    auto* L = static_cast<lua_State*>(luaState_);
    int rc = luaL_loadbuffer(L, script.data(), script.size(), "code");
    if (rc != 0) {
        if (const char* err = lua_tostring(L, -1)) {
            std::cerr << "lua load error: " << err << "\n";
        }
        lua_pop(L, 1);
        return rc;
    }

    rc = lua_pcall(L, 0, 0, 0);
    if (rc != 0) {
        if (const char* err = lua_tostring(L, -1)) {
            std::cerr << "lua runtime error: " << err << "\n";
        }
        lua_pop(L, 1);
        return rc;
    }

    if (!functionName.empty()) {
        lua_getglobal(L, functionName.c_str());
        rc = lua_pcall(L, 0, 1, 0);
        if (rc != 0) {
            if (const char* err = lua_tostring(L, -1)) {
                std::cerr << "lua function error: " << err << "\n";
            }
            lua_pop(L, 1);
            return rc;
        }
    }
    return rc;
#else
    (void)functionName;
    return 0;
#endif
}


} // namespace kys

std::vector<std::string> buildApiNameList() {
