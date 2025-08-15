# 1. premake5 生成makefile
# 2. make 编译
./premake5 --file=premake5.lua --cc=gcc gmake
# cd ../
# make config=release_x64