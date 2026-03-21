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
    src/kys_event.cpp
    src/resource_loader.cpp
    src/sdl_runtime.cpp
)

target_include_directories(kys_save_tool PRIVATE include)

if (MSVC)
    target_compile_options(kys_save_tool PRIVATE /utf-8 /FS)
endif()

# Find SDL3 and related libraries
find_package(SDL3 CONFIG QUIET)
find_package(SDL3_image CONFIG QUIET)
find_package(SDL3_ttf CONFIG QUIET)


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

