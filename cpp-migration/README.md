# C++ migration bootstrap

This folder contains the first direct migration slice from Pascal to C++.

## What is migrated now

- Binary-compatible core save data structs from `kys_type.pas`.
- Equivalent `LoadR/SaveR` workflow from `kys_main.pas` for:
  - `save/r*.grp`
  - `save/s*.grp`
  - `save/d*.grp`
  - offsets from `save/ranger.idx`
- A CLI tool to validate the migrated save path.
  - Main-map SDL drawing and walking loop now renders from `resource/mmap.idx` + `resource/mmap.grp` + `resource/mmap.col` (RLE8 decode), with isometric tile positioning and building sort close to Pascal `DrawMMap`.

## Build

Requires CMake and a C++17 compiler.

```powershell
cd cpp-migration
cmake -S . -B build
cmake --build build -j
```

## Run

```powershell
# load slot 0
./build/kys_save_tool ../ load 0

# load + write back slot 1
./build/kys_save_tool ../ save 1

# resource scan in PNG mode (equivalent to PNG_TILE=1)
./build/kys_save_tool ../ resource-scan 1

# resource scan in GRP mode (equivalent to PNG_TILE=0)
./build/kys_save_tool ../ resource-scan 0

# list migrated Lua APIs
./build/kys_save_tool ../ script-api-list

# run Lua script and optional entry function
./build/kys_save_tool ../ script-run ../script/ka0.lua main

# run Lua script with a specific save slot loaded as context (no auto-save)
./build/kys_save_tool ../ script-run ../script/ka0.lua main 1

# run SDL event loop + drawing for 1.2s
./build/kys_save_tool ../ sdl-loop 1200

Note: if you pass a slot, also pass a function name first.
```

## Next migration steps

1. Fill remaining real implementations for migrated Lua APIs (role/item/magic/team/mem/scene-map-event/text-name-talk/basic input/execevent-callevent-changescene-move and battle role get/set are now implemented).
2. Expand SDL runtime from current map-layer loop to full engine loop parity (battle field layers, UI menus, animation timing).
3. Extend GRP/IDX decode path from `mmap` to more tilesets (`smp/sdx`, `wmp/wdx`, effects) and add parity-level animation timing.
