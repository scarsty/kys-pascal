cmake_minimum_required(VERSION 3.22)

project(kys_pascal_c_android LANGUAGES C CXX)

set(KYS_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../")
set(KYS_CPP_DIR "${KYS_ROOT_DIR}/bin-c")
set(KYS_MLCC_DIR "C:/project/mlcc")

set(VCPKG_ROOT_DIR "$ENV{VCPKG_ROOT}")
if(NOT VCPKG_ROOT_DIR AND EXISTS "D:/project/vcpkg")
    set(VCPKG_ROOT_DIR "D:/project/vcpkg")
endif()

set(VCPKG_TRIPLET "arm64-android-dynamic")
set(VCPKG_INSTALLED_DIR "${VCPKG_ROOT_DIR}/installed/${VCPKG_TRIPLET}")
set(VCPKG_INCLUDE_DIR "${VCPKG_INSTALLED_DIR}/include")
set(VCPKG_LIB_DIR "${VCPKG_INSTALLED_DIR}/lib")

if(NOT EXISTS "${KYS_CPP_DIR}/main.cpp")
    message(FATAL_ERROR "Cannot find C++ sources: ${KYS_CPP_DIR}")
endif()

if(NOT EXISTS "${KYS_MLCC_DIR}/filefunc.cpp")
    message(FATAL_ERROR "Cannot find mlcc sources: ${KYS_MLCC_DIR}")
endif()

if(NOT EXISTS "${VCPKG_INCLUDE_DIR}")
    message(FATAL_ERROR "Cannot find vcpkg include directory: ${VCPKG_INCLUDE_DIR}")
endif()

if(NOT EXISTS "${VCPKG_LIB_DIR}")
    message(FATAL_ERROR "Cannot find vcpkg lib directory: ${VCPKG_LIB_DIR}")
endif()

set(KYS_GAME_SOURCES
    "${KYS_CPP_DIR}/main.cpp"
    "${KYS_CPP_DIR}/kys_type.cpp"
    "${KYS_CPP_DIR}/kys_engine.cpp"
    "${KYS_CPP_DIR}/kys_draw.cpp"
    "${KYS_CPP_DIR}/kys_main.cpp"
    "${KYS_CPP_DIR}/kys_event.cpp"
    "${KYS_CPP_DIR}/kys_battle.cpp"
    "${KYS_CPP_DIR}/kys_script.cpp"
)

set(KYS_MLCC_SOURCES
    "${KYS_MLCC_DIR}/filefunc.cpp"
    "${KYS_MLCC_DIR}/PotConv.cpp"
    "${KYS_MLCC_DIR}/SimpleCC.cpp"
    "${KYS_MLCC_DIR}/strfunc.cpp"
)

add_library(kys_pascal_c SHARED
    ${KYS_GAME_SOURCES}
    ${KYS_MLCC_SOURCES}
)

set_target_properties(kys_pascal_c PROPERTIES OUTPUT_NAME "kys_pascal_c")

target_compile_features(kys_pascal_c PRIVATE cxx_std_23)
target_compile_options(kys_pascal_c PRIVATE -O2 -DNDEBUG)

target_include_directories(kys_pascal_c PRIVATE
    "${KYS_CPP_DIR}"
    "${KYS_MLCC_DIR}"
    "${VCPKG_INCLUDE_DIR}"
)

function(import_vcpkg_shared target soname)
    set(lib_path "${VCPKG_LIB_DIR}/lib${soname}.so")
    if(NOT EXISTS "${lib_path}")
        message(FATAL_ERROR "Missing dependency: ${lib_path}")
    endif()
    add_library(${target} SHARED IMPORTED)
    set_property(TARGET ${target} PROPERTY IMPORTED_LOCATION "${lib_path}")
endfunction()

function(import_vcpkg_static target libname)
    set(lib_path "${VCPKG_LIB_DIR}/lib${libname}.a")
    if(NOT EXISTS "${lib_path}")
        message(FATAL_ERROR "Missing static dependency: ${lib_path}")
    endif()
    add_library(${target} STATIC IMPORTED)
    set_property(TARGET ${target} PROPERTY IMPORTED_LOCATION "${lib_path}")
endfunction()

import_vcpkg_shared(vcpkg_sdl3 SDL3)
import_vcpkg_shared(vcpkg_sdl3_mixer SDL3_mixer)
import_vcpkg_shared(vcpkg_sdl3_ttf SDL3_ttf)
import_vcpkg_shared(vcpkg_fluidsynth fluidsynth)
import_vcpkg_shared(vcpkg_mpg123 mpg123)
import_vcpkg_shared(vcpkg_freetype freetype)
import_vcpkg_shared(vcpkg_png16 png16)
import_vcpkg_shared(vcpkg_png png)
import_vcpkg_shared(vcpkg_sqlite3 sqlite3)
import_vcpkg_shared(vcpkg_lua lua)
import_vcpkg_shared(vcpkg_yaml_cpp yaml-cpp)
import_vcpkg_shared(vcpkg_zip zip)
import_vcpkg_shared(vcpkg_z z)
import_vcpkg_static(vcpkg_iconv iconv)
import_vcpkg_static(vcpkg_charset charset)

find_library(ANDROID_LOG_LIB log)
find_library(ANDROID_M_LIB m)

target_link_libraries(kys_pascal_c PRIVATE
    vcpkg_sdl3
    vcpkg_sdl3_mixer
    vcpkg_sdl3_ttf
    vcpkg_fluidsynth
    vcpkg_mpg123
    vcpkg_freetype
    vcpkg_png16
    vcpkg_png
    vcpkg_sqlite3
    vcpkg_lua
    vcpkg_yaml_cpp
    vcpkg_zip
    vcpkg_z
    vcpkg_iconv
    vcpkg_charset
    ${ANDROID_M_LIB}
    ${ANDROID_LOG_LIB}
)
