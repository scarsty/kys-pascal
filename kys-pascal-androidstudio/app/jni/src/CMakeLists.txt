cmake_minimum_required(VERSION 3.6)

project(main)

find_library(SDL2 SDL2)

link_directories(. ../../lib/${ANDROID_ABI})

add_library(main SHARED)

target_sources(main PRIVATE main.c)

target_link_libraries(main SDL2 kys log m)


