import shutil
import os

target = "install/host"

for root, dirs, files in os.walk(top=target):
    for dir in dirs:
        if dir == "cmake":
            full_dir = os.path.join(root, dir)
            full_dir = os.path.abspath(full_dir)
            print("{};".format(full_dir), end="")
            #print(f'full_dir = {os.path.abspath(full_dir)}')
