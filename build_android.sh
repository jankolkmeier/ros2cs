#!/bin/sh

display_usage() {
    echo "Usage: "
    echo "source build_android.sh -p <path-to-android-NDK>"
}

if [ -z "${ROS_DISTRO}" ]; then
    echo "Source your ros2 distro first (foxy, galactic, humble or rolling are supported)"
    exit 1
fi

TESTS=0
MSG="Build started."
STANDALONE=OFF

ANDROID_NDK=""

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -p|--ndk-path)
      ANDROID_NDK="$2"
      shift # past argument
      shift # past argument
      ;;
    -s|--standalone)
      STANDALONE=ON
      MSG="$MSG (standalone)"
      shift # past argument
      ;;
    -h|--help)
      display_usage
      exit 0
      shift # past argument
      ;;
    *)    # unknown option
      display_usage
      exit 0
      ;;
  esac
done

echo $MSG


echo "#################### Host build of Ament ####################"

AMENT_LINT=$(echo ament_{lint_common,lint_auto,lint_cmake,flake8,pep257,copyright})
AMENT_CMAKE=$(echo ament_cmake_{test,gmock,gtest,pytest,libraries,nose,python,pytest})
AMENT_INDEX="ament_index_python"
AMENT_DOTNET="ament_cmake_export_assemblies dotnet_cmake_module"

PKG_AMENT="${AMENT_CMAKE} ${AMENT_LINT} ${AMENT_INDEX} ${AMENT_DOTNET} ament_cmake_ros ament_package ament_pclint ament_clang_format"

colcon build --symlink-install \
--build-base build/host \
--install-base install/host \
--cmake-clean-cache \
--packages-skip-build \
--packages-up-to ${PKG_AMENT}

source install/host/setup.bash

echo "#################### Device build of ROS2 ####################"

# export ANDROID_SDK=/home/uowner/Unity/Hub/Editor/2021.3.20f1/Editor/Data/PlaybackEngines/AndroidPlayer/SDK
# export ANDROID_NDK=/home/uowner/Unity/Hub/Editor/2021.3.20f1/Editor/Data/PlaybackEngines/AndroidPlayer/NDK

# export PATH=$ANDROID_SDK/tools/bin:${PATH}
# export PATH=$ANDROID_SDK/platform-tools:${PATH}
export ANDROID_ABI=arm64-v8a
export ANDROID_NATIVE_API_LEVEL=28
export ANDROID_TOOLCHAIN_NAME=aarch64-linux-android-clang


PKG_PYTHON="python_cmake_module rosidl_generator_py rclpy rosidl_runtime_py launch launch_ros launch_testing_ament_cmake"
PKG_EXTRAS="intra_process_demo orocos_kdl rclpy resource_retriever tf2_ros libcurl_vendor"
PKG_CONNEXT="rosidl_typesupport_connext_c rosidl_typesupport_connext_cpp rmw_connext_cpp rmw_connext_shared_cpp" 
PKG_OPENSPLICE="rosidl_typesupport_opensplice_c rmw_opensplice_cpp rosidl_typesupport_opensplice_cpp"

AMENT_ADD_IGNORE=$(echo ament_cmake_{export_libraries,export_dependencies,include_directories})
PKG_IGNORE="rcl_logging_log4cxx ${PKG_PYTHON} ${PKG_EXTRAS} ${PKG_CONNEXT} ${PKG_OPENSPLICE} ${PKG_AMENT} ${AMENT_ADD_IGNORE}"
PKG_EXAMPLES=$(echo examples_rclcpp_minimal_{action_client,action_server,client,composition,publisher,subscriber,service,timer})
PKG_TARGET="${PKG_EXAMPLES} ament_index_cpp composition demo_nodes_cpp_native lifecycle logging_demo example_interfaces"


AMENT_CMAKE_PATH_HOOK=$(echo $(python3 hook_ament_cmake.py))
ANDROID_CMAKE_ROOT_PATH="${AMENT_CMAKE_PATH_HOOK};${PWD}/install/host;${PWD}/install/device;"
# echo ${ANDROID_CMAKE_ROOT_PATH}

# --event-handlers console_direct+ \

colcon build \
--build-base build/device \
--install-base install/device \
--event-handlers console_direct+ \
--packages-ignore-regex ament_cmake* ${PKG_IGNORE} ament_lint ament_xmllint rosidl_cli tf2 \
--merge-install \
--cmake-clean-cache \
--cmake-args \
-DCMAKE_BUILD_TYPE=Release \
-DTRACETOOLS_DISABLED=ON \
-DTRACETOOLS_STATUS_CHECKING_TOOL=OFF \
-DRCL_COMMAND_LINE_ENABLED=OFF \
-DRCL_LOGGING_ENABLED=OFF \
-DSTANDALONE_BUILD=$STANDALONE \
-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
-DCMAKE_ANDROID_NDK=${ANDROID_NDK} \
-DANDROID_NDK=${ANDROID_NDK} \
-DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} \
-DANDROID_ABI=${ANDROID_ABI} \
-DANDROID_PLATFORM=android-${ANDROID_NATIVE_API_LEVEL} \
-DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL} \
-DTHIRDPARTY=ON \
-DTHIRDPARTY_TinyXML2=FORCE \
-DCOMPILE_EXAMPLES=OFF \
-DBUILD_TESTING=OFF \
-DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN',-rpath=.,--disable-new-dtags" \
-DCMAKE_FIND_ROOT_PATH=${ANDROID_CMAKE_ROOT_PATH} \
--no-warn-unused-cli

rm -rf install/device/Plugins/Android
python3 deploy_plugin.py