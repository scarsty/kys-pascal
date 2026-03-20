#pragma once

#include <string>

namespace kys {

class KysState;

class SdlRuntime {
public:
    SdlRuntime(KysState* state, std::string appPath);

    // Run a minimal SDL loop. Returns 0 on clean exit.
    int runLoop(int milliseconds = 5000);

private:
    KysState* state_ = nullptr;
    std::string appPath_;
};

} // namespace kys
