cmake_minimum_required(VERSION 3.16)
project(kys LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- 源文件 ---
add_executable(kys
    main.cpp
    kys_type.cpp
    kys_engine.cpp
    kys_draw.cpp
    kys_main.cpp
    kys_event.cpp
    kys_battle.cpp
    kys_script.cpp
)

# --- 依赖库查找 ---
find_package(SDL3 REQUIRED)
find_package(SDL3_ttf REQUIRED)
find_package(SDL3_mixer REQUIRED)
find_package(Lua REQUIRED)

target_include_directories(kys PRIVATE ${LUA_INCLUDE_DIR})

target_link_libraries(kys PRIVATE
    SDL3::SDL3
    SDL3_ttf::SDL3_ttf
    SDL3_mixer::SDL3_mixer
    ${LUA_LIBRARIES}
)

# simplecc 动态加载 (SDL_LoadObject)，不需要链接

if(WIN32)
    # Windows 下设置为 Win32 应用 (可选)
    # set_target_properties(kys PROPERTIES WIN32_EXECUTABLE TRUE)
endif()
