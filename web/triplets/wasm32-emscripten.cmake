set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Emscripten)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake")
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSDK PATH)
set(VCPKG_BUILD_TYPE release)

# musl can decode Big5 but cannot encode it, which is required for player names.
set(X_VCPKG_BUILD_GNU_LIBICONV 1)

# FluidSynth requires exception support in its WebAssembly build.
set(VCPKG_C_FLAGS "-fexceptions")
set(VCPKG_CXX_FLAGS "-fexceptions")
