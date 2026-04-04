// kys_script.h - Lua脚本系统
// 对应 kys_script.pas

#pragma once
#include <string>

// Forward declare lua_State
struct lua_State;

void InitialScript();
void DestroyScript();
int ExecScript(const std::string& filename, const std::string& functionname);
int ExecScriptString(const std::string& script, const std::string& functionname);

// 自定义lua_tointeger，处理instruct_50e code 32改写参数
long long lua_tointeger_custom(lua_State* L, int pos);
