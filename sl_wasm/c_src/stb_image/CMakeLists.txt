cmake_minimum_required(VERSION 4.1)
project(sl_wasm_stb_image C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_executable(sl_wasm_stb_image stb_image_impl.c)

target_link_options(sl_wasm_stb_image PRIVATE
    "--no-entry"
    "-sMODULARIZE=1"
    "-sEXPORT_NAME='SLWasmStbImage'"
    "-sALLOW_MEMORY_GROWTH=1"
    "-sEXPORTED_RUNTIME_METHODS=HEAPU8"
    "-sEXPORTED_FUNCTIONS=['_malloc', '_free', '_stbi_set_flip_vertically_on_load', '_stbi_loadf_from_memory', '_stbi_load_from_memory', '_stbi_image_free']"
)