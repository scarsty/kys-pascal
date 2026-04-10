cmake_minimum_required(VERSION 3.16)
project(kys LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- mlcc 辅助库 (filefunc / PotConv / strfunc / INIReader 等) ---
if(NOT DEFINED MLCC_DIR)
    if(DEFINED ENV{MLCC_DIR})
        set(MLCC_DIR "$ENV{MLCC_DIR}")
    elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../mlcc/filefunc.cpp")
        set(MLCC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mlcc")
    elseif(EXISTS "C:/project/mlcc/filefunc.cpp")
        set(MLCC_DIR "C:/project/mlcc")
    else()
        message(FATAL_ERROR "Cannot find mlcc. Set -DMLCC_DIR=<path> or clone https://github.com/scarsty/mlcc")
    endif()
endif()
file(TO_CMAKE_PATH "${MLCC_DIR}" MLCC_DIR)
message(STATUS "Using mlcc from: ${MLCC_DIR}")

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
    "${MLCC_DIR}/filefunc.cpp"
    "${MLCC_DIR}/PotConv.cpp"
    "${MLCC_DIR}/SimpleCC.cpp"
    "${MLCC_DIR}/strfunc.cpp"
)

# --- 依赖库查找 ---
find_package(SDL3 REQUIRED)
find_package(SDL3_ttf REQUIRED)
find_package(SDL3_mixer REQUIRED)
find_package(Lua REQUIRED)
find_package(Iconv REQUIRED)

target_include_directories(kys PRIVATE
    ${LUA_INCLUDE_DIR}
    "${MLCC_DIR}"
)

target_link_libraries(kys PRIVATE
    SDL3::SDL3
    SDL3_ttf::SDL3_ttf
    SDL3_mixer::SDL3_mixer
    ${LUA_LIBRARIES}
    Iconv::Iconv
)

# simplecc 动态加载 (SDL_LoadObject)，不需要链接

if(MSVC)
    target_compile_options(kys PRIVATE /utf-8)
endif()
