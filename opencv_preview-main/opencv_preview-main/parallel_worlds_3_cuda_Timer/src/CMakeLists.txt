cmake_minimum_required(VERSION 3.18)

project(parallel_worlds_cuda LANGUAGES CXX CUDA)

file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/*.cpp"
  "${CMAKE_SOURCE_DIR}/*.cu"
)

configure_file(
    ${CMAKE_SOURCE_DIR}/../preview.png
    ${CMAKE_BINARY_DIR}/preview.png
    COPYONLY
)

add_executable(parallel_worlds
    main.cu
    GreyFilter.cu
    SobelFilter.cu
    EffectFilter.cu
    PixelationFilter.cu
)

find_path(CUDA_INCLUDE_DIR cuda.h
  PATHS
  "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.3/include"
  /usr/include
  /usr/local/cuda/include
)

find_library(CUDART_LIBRARY NAMES cudart libcudart
  PATHS
  "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.3/lib/x64"
  /usr/lib
  /usr/local/cuda/lib64
)

if(NOT CUDA_INCLUDE_DIR OR NOT CUDART_LIBRARY)
  message(FATAL_ERROR "CUDA headers/libs not found.")
endif()

message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "CUDA include: ${CUDA_INCLUDE_DIR}")
message(STATUS "CUDART lib: ${CUDART_LIBRARY}")

include_directories(${CUDA_INCLUDE_DIR})

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${CMAKE_SOURCE_DIR})
include_directories(src)

target_include_directories(parallel_worlds PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CUDA_INCLUDE_DIR}
    ${OpenCV_INCLUDE_DIRS}
)

# GTX 1650 = Turing = 7.5
set(CMAKE_CUDA_ARCHITECTURES 75)

set_target_properties(parallel_worlds PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
    LINKER_LANGUAGE CUDA
)

target_link_libraries(parallel_worlds
    ${OpenCV_LIBS}
    ${CUDART_LIBRARY}
)