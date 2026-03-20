#pragma once

#include <string>
#include <vector>

namespace kys {

class KysState;

class ScriptBridge {
public:
    ScriptBridge() = default;
    ~ScriptBridge();

    bool initialize();
    void destroy();
    void attachState(KysState* state) { state_ = state; }
    KysState* state() const { return state_; }

    int execScript(const std::string& fileName, const std::string& functionName);
    int execScriptString(std::string script, const std::string& functionName);

    const std::vector<std::string>& registeredApi() const { return apiNames_; }
    bool hasLuaBackend() const { return hasLuaBackend_; }

private:
    void registerAllApis();

private:
    std::vector<std::string> apiNames_;
    bool initialized_ = false;
    bool hasLuaBackend_ = false;
    void* luaState_ = nullptr;
    KysState* state_ = nullptr;
};

} // namespace kys
