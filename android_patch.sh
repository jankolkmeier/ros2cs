#!/bin/sh

TYPE_SUPPORT_COMMON_PATH="src/ros2/rmw_fastrtps/rmw_fastrtps_cpp/src/type_support_common.hpp"
NAMES_PATH="src/ros2/rmw_fastrtps/rmw_fastrtps_shared_cpp/include/rmw_fastrtps_shared_cpp/names.hpp"
CSBUILD_CMAKE_PATH="src/external/build_tools/dotnet_cmake_module/cmake/Modules/FindCSBuild.cmake"

patch -u ${TYPE_SUPPORT_COMMON_PATH} < patch/type_support_common.hpp.patch
patch -u ${NAMES_PATH} < patch/names.hpp.patch
patch -u ${CSBUILD_CMAKE_PATH} < patch/FindCSBuild.cmake.patch

# patch -R ${TYPE_SUPPORT_COMMON_PATH} < patch/type_support_common.hpp.patch
# patch -R ${NAMES_PATH} < patch/names.hpp.patch
# patch -R ${CSBUILD_CMAKE_PATH} < patch/FindCSBuild.cmake.patch