cmake_minimum_required(VERSION 3.18)
project(reanimated_dartnative LANGUAGES CXX)

add_library(reanimated_dartnative SHARED reanimated_dartnative.cpp)

find_library(log-lib log)
find_library(android-lib android)
target_link_libraries(reanimated_dartnative ${log-lib} ${android-lib})
target_compile_options(reanimated_dartnative PRIVATE -fvisibility=hidden)
