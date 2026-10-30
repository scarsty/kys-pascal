cmake_minimum_required(VERSION 3.16)
project(kys LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(EMSCRIPTEN AND WASM_DEPS_DIR)
    list(PREPEND CMAKE_PREFIX_PATH "${WASM_DEPS_DIR}")
    list(PREPEND CMAKE_FIND_ROOT_PATH "${WASM_DEPS_DIR}")
    set(SDL3_DIR "${WASM_DEPS_DIR}/share/sdl3")
endif()

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
add_library(kys_core STATIC
    kys_frontend.cpp
    kys_script.cpp
    kys_type.cpp
    kys_engine.cpp
    kys_draw.cpp
    kys_main.cpp
    kys_event.cpp
    kys_battle.cpp
    kys_rules.cpp
    rules/remake.cpp
    rules/dragon_dos12.cpp
    "${MLCC_DIR}/filefunc.cpp"
    "${MLCC_DIR}/PotConv.cpp"
    "${MLCC_DIR}/SimpleCC.cpp"
    "${MLCC_DIR}/strfunc.cpp"
)

# --- 依赖库查找 ---
find_package(SDL3 REQUIRED)
find_package(SDL3_ttf REQUIRED)
find_package(SDL3_mixer REQUIRED)
if(EMSCRIPTEN)
    if(NOT EXISTS "${WASM_ICONV_DIR}/lib/libiconv.a")
        message(FATAL_ERROR "GNU libiconv is required for Big5 encoding; build with web/build.ps1")
    endif()
    set(Iconv_IS_BUILT_IN FALSE CACHE BOOL "Use GNU libiconv for Big5 output" FORCE)
    set(Iconv_INCLUDE_DIR "${WASM_ICONV_DIR}/include" CACHE PATH "GNU libiconv headers" FORCE)
    set(Iconv_LIBRARY "${WASM_ICONV_DIR}/lib/libiconv.a" CACHE FILEPATH "GNU libiconv" FORCE)
endif()
find_package(Iconv REQUIRED)

target_include_directories(kys_core PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${MLCC_DIR}"
)

target_link_libraries(kys_core PUBLIC
    SDL3::SDL3
    SDL3_ttf::SDL3_ttf
    SDL3_mixer::SDL3_mixer
    Iconv::Iconv
)

# simplecc 动态加载 (SDL_LoadObject)，不需要链接

if(MSVC)
    target_compile_options(kys_core PRIVATE /utf-8)
endif()

option(KYS_BUILD_MCP "Build the native stdio MCP frontend" ON)
add_executable(kys main.cpp)
target_link_libraries(kys PRIVATE kys_core)
if(EMSCRIPTEN)
    target_sources(kys PRIVATE kys_web.cpp)
    target_sources(kys_core PRIVATE kys_presenter.cpp)
    find_package(SDL3_image CONFIG REQUIRED)
    target_link_libraries(kys_core PUBLIC SDL3_image::SDL3_image bz2 brotlidec brotlicommon)
    target_link_directories(kys PRIVATE "${WASM_DEPS_DIR}/lib")
    target_compile_options(kys_core PRIVATE -O3 -fexceptions)
    target_link_options(kys PRIVATE
        -O3 -sASYNCIFY -sASYNCIFY_STACK_SIZE=262144 -sSTACK_SIZE=1048576
        -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=134217728
        -sFORCE_FILESYSTEM=1 -lidbfs.js -sASYNCIFY_IMPORTS=__syscall_openat
        -sNO_DISABLE_EXCEPTION_CATCHING -sASSERTIONS=1
        "-sEXPORTED_RUNTIME_METHODS=['FS','IDBFS','ccall','UTF8ToString','stringToUTF8']"
        --pre-js "${CMAKE_CURRENT_SOURCE_DIR}/../web/runtime.js")
    set_target_properties(kys PROPERTIES OUTPUT_NAME kys-dragon SUFFIX .js
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../web/dist"
        LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../web/runtime.js")
endif()
if(KYS_BUILD_MCP)
    find_package(glaze CONFIG REQUIRED)
    add_executable(kys_mcp kys_mcp.cpp)
    target_link_libraries(kys_mcp PRIVATE kys_core glaze::glaze)
    if(MSVC)
        target_compile_options(kys_mcp PRIVATE /utf-8)
    endif()
endif()

include(CTest)
if(BUILD_TESTING AND NOT EMSCRIPTEN)
    add_executable(kys_dragon_rules_tests tests/dragon_rules_tests.cpp)
    target_link_libraries(kys_dragon_rules_tests PRIVATE kys_core)
    add_test(NAME dragon_rules_regressions COMMAND kys_dragon_rules_tests
        "${CMAKE_CURRENT_SOURCE_DIR}/presets/dragon_dos12.ini")
endif()
