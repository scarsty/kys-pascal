#pragma once
// simplecc.h - Chinese Traditional/Simplified conversion wrapper
// 对应 simplecc.pas

#ifdef _WIN32
#define SIMPLECC_API __declspec(dllimport)
#else
#define SIMPLECC_API
#endif

#include <string>

extern "C" {
    SIMPLECC_API void* simplecc_create();
    SIMPLECC_API int simplecc_load(void* handle, const char* filename);
    SIMPLECC_API const char* simplecc_convert(void* handle, const char* input);
}

// 便捷函数
std::string simplecc_convert1(void* handle, const std::string& input);
std::string simplecc_load1(void* handle, const std::string& filename);
