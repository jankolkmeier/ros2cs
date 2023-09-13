import shutil
import os

target = "install/lib"
output_target = "install/Plugins/Android"

os.makedirs(output_target, exist_ok=True)

i = 0
for root, dirs, files in os.walk(top=target):
    for file in files:
        ext = os.path.splitext(file)[-1]
        filePath = os.path.join(root, file)
        if (ext == ".so" or ext == ".a") and not ("_python.so" in file):
            print("{:3d} filePath = {}".format(i, filePath))
            shutil.copyfile(filePath, os.path.join(output_target, file))
            i += 1
