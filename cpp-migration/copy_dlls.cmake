# Copy DLL dependencies to the executable output directory
# This script is run as a post-build step

# Get the executable output directory.
# When invoked from add_custom_command, OUTPUT_DIR should be provided.
if(NOT DEFINED OUTPUT_DIR OR OUTPUT_DIR STREQUAL "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(OUTPUT_DIR "${CMAKE_BINARY_DIR}/Debug")
    elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(OUTPUT_DIR "${CMAKE_BINARY_DIR}/RelWithDebInfo")
    elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
        set(OUTPUT_DIR "${CMAKE_BINARY_DIR}/MinSizeRel")
    else()
        set(OUTPUT_DIR "${CMAKE_BINARY_DIR}/Release")
    endif()
endif()

# List of DLL files to copy
set(DLLS_TO_COPY
    "SDL3.dll"
    "SDL3_image.dll"
    "SDL3_ttf.dll"
    "SDL3_mixer.dll"
    "libpng16.dll"
    "zlib1.dll"
    "freetype.dll"
    "lua.dll"
    "lua54.dll"
    "lua53.dll"
    "brotlicommon.dll"
    "brotlidec.dll"
    "bz2.dll"
)

# Search paths in priority order.
# Prefer project/vcpkg runtime binaries first to avoid mixing incompatible DLL versions.
set(SEARCH_PATHS
    "${CMAKE_BINARY_DIR}/Debug"
    "$ENV{VCPKG_ROOT}/installed/x64-windows/bin"
    "$ENV{UserProfile}/vcpkg/installed/x64-windows/bin"
    "$ENV{UserProfile}/AppData/Local/vcpkg/installed/x64-windows/bin"
    "C:/vcpkg/installed/x64-windows/bin"
    "C:/project/smallpot/smallpot-x64"
    "C:/project/smallpot/x64/Release"
    "C:/project/smallpot/x64/Debug"
    "C:/Program Files (x86)/Steam"
    "/opt/vcpkg/installed/x64-windows/bin"
)

message(STATUS "Output directory: ${OUTPUT_DIR}")
message(STATUS "Looking for DLL files in:")
foreach(path ${SEARCH_PATHS})
    if(EXISTS "${path}")
        message(STATUS "  [EXISTS] ${path}")
    endif()
endforeach()

# Find and copy DLLs
set(DLLS_COPIED 0)
foreach(dll_name ${DLLS_TO_COPY})
    set(found FALSE)
    foreach(search_path ${SEARCH_PATHS})
        set(dll_path "${search_path}/${dll_name}")
        if(EXISTS "${dll_path}")
            file(COPY "${dll_path}" DESTINATION "${OUTPUT_DIR}")
            message(STATUS "Copied: ${dll_name} from ${search_path}")
            math(EXPR DLLS_COPIED "${DLLS_COPIED} + 1")
            set(found TRUE)
            break()
        endif()
    endforeach()
    if(NOT found)
        message(STATUS "Not found: ${dll_name}")
    endif()
endforeach()

if(DLLS_COPIED GREATER 0)
    message(STATUS "Successfully copied ${DLLS_COPIED} DLL file(s)")
else()
    message(STATUS "No new DLL files needed to be copied")
endif()
