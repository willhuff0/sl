cmake_minimum_required(VERSION 3.28.3)
project(sl_wasm_bullet3 C CXX)

set(CMAKE_CXX_STANDARD 17)

add_executable(sl_wasm_bullet3 bullet3.cpp)

target_link_options(sl_wasm_bullet3 PRIVATE
    "--no-entry"
    "-sMODULARIZE=1"
    "-sEXPORT_NAME='SLWasmBullet3'"
    "-sALLOW_MEMORY_GROWTH=1"
    "-sEXPORTED_RUNTIME_METHODS=HEAPU8"
    "-sEXPORTED_FUNCTIONS=@${CMAKE_CURRENT_SOURCE_DIR}/exports.txt"
)

add_subdirectory(bullet3)
target_include_directories(sl_wasm_bullet3 PRIVATE bullet3/src)
target_link_libraries(sl_wasm_bullet3 PRIVATE BulletDynamics BulletCollision LinearMath)