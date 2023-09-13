# ros2cs - for Android shared library cross compilitation on Ubuntu 22.04

## Building

### Prerequisites

```
sudo apt-get update; \
  sudo apt install mono-complete dotnet-sdk-6.0
```


### Steps

- Clone this project
  ```
  git clone https://github.com/Kotakku/ros2cs
  ```
- Source your ROS2 installation
  ```bash
  # Change humble to whatever version you are using
  source /opt/ros/humble/setup.bash
  ```
- Navigate to the top project folder and pull required repositories
  ```bash
  cd ros2cs
  ./get_repos.sh --get-custom-messages 
  ```
  - You **must** run `get_repos` script with `--get-custom-messages argument` to fetch extra messages from `custom_messages.repos` file.
  - It will use `vcstool` to download required ROS2 packages. By default, this will get repositories as set in `ros2_${ROS_DISTRO}.repos`.
- Apply patch
  ```sh
  source android_patch.sh
  ```
- Build package in _overlay_ mode:
  ```bash
  source ./build_android.sh -p <path-to-android-NDK>
  ```

  - It invokes `colcon_build` with `--merge-install` argument to simplify libraries installation.

- (for ros2-for-unity) Copy `install/device/Plugins/Android` into `<ros2-for-unity asset directorry>/Plugins`