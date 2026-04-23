cmake_minimum_required(VERSION 4.1)
project(sl_wasm_bullet3 C CXX)

#set(CMAKE_C_STANDARD 11)
#set(CMAKE_C_STANDARD_REQUIRED ON)

set (CMAKE_CXX_STANDARD 17)

add_executable(sl_wasm_bullet3 bullet3.cpp)

target_link_options(sl_wasm_bullet3 PRIVATE
    "--no-entry"
    "-sMODULARIZE=1"
    "-sEXPORT_NAME='SLWasmBullet3'"
    "-sALLOW_MEMORY_GROWTH=1"
    "-sEXPORTED_RUNTIME_METHODS=HEAPU8"
    "-sEXPORTED_FUNCTIONS=@${CMAKE_CURRENT_SOURCE_DIR}/exports.txt"
)

find_package(Bullet REQUIRED)
target_include_directories(sl_wasm_bullet3 PRIVATE ${BULLET_INCLUDE_DIRS})
target_link_libraries(sl_wasm_bullet3 PRIVATE ${BULLET_LIBRARIES})