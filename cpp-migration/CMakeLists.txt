cmake_minimum_required(VERSION 3.16)
project(kys_cpp_migration LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set up vcpkg toolchain if available
if(NOT CMAKE_TOOLCHAIN_FILE)
    # Try to auto-detect vcpkg
    find_file(VCPKG_TOOLCHAIN 
        NAMES vcpkg.cmake 
        PATHS "$ENV{VCPKG_ROOT}" "$ENV{UserProfile}/vcpkg"
        NO_DEFAULT_PATH
    )
    if(VCPKG_TOOLCHAIN)
        set(CMAKE_TOOLCHAIN_FILE "${VCPKG_TOOLCHAIN}" CACHE FILEPATH "vcpkg toolchain")
    endif()
endif()

add_executable(kys_save_tool
    src/main.cpp
    src/kys_state.cpp
    src/resource_loader.cpp
    src/script_bridge.cpp
    src/sdl_runtime.cpp
)

target_include_directories(kys_save_tool PRIVATE include)

if (MSVC)
    target_compile_options(kys_save_tool PRIVATE /utf-8)
endif()

# Find SDL3 and related libraries
find_package(SDL3 CONFIG QUIET)
find_package(SDL3_image CONFIG QUIET)
find_package(SDL3_ttf CONFIG QUIET)

# Find Lua library
find_package(Lua CONFIG QUIET)
if(NOT Lua_FOUND)
    find_package(Lua 5.4 QUIET)
endif()
if(NOT Lua_FOUND)
    find_package(Lua 5.3 QUIET)
endif()

# Link libraries
if(TARGET SDL3::SDL3)
    target_link_libraries(kys_save_tool PRIVATE SDL3::SDL3)
endif()

if(TARGET SDL3_image::SDL3_image)
    target_link_libraries(kys_save_tool PRIVATE SDL3_image::SDL3_image)
endif()

if(TARGET SDL3_ttf::SDL3_ttf)
    target_link_libraries(kys_save_tool PRIVATE SDL3_ttf::SDL3_ttf)
endif()

# Link Lua library if found
if(TARGET Lua::Lua)
    target_link_libraries(kys_save_tool PRIVATE Lua::Lua)
elseif(LUA_LIBRARIES)
    target_link_libraries(kys_save_tool PRIVATE ${LUA_LIBRARIES})
    target_include_directories(kys_save_tool PRIVATE ${LUA_INCLUDE_DIR})
endif()

# Windows-specific: Copy DLLs to target output directory.
if(WIN32)
    add_custom_command(TARGET kys_save_tool POST_BUILD
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/copy_runtime_deps.ps1"
            -ExePath "$<TARGET_FILE:kys_save_tool>"
            -OutputDir "$<TARGET_FILE_DIR:kys_save_tool>"
        COMMAND ${CMAKE_COMMAND}
            -DOUTPUT_DIR=$<TARGET_FILE_DIR:kys_save_tool>
            -P "${CMAKE_CURRENT_SOURCE_DIR}/copy_dlls.cmake"
        COMMENT "Copying DLL dependencies..."
    )
endif()
