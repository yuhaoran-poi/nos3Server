# 删除log目录下所有.log文件
del /s /q log\*.log
start cmd /k moon\moon.exe main_hub.lua 10000 node.json
timeout /t 5
start cmd /k moon\moon.exe main_mgr.lua 3999
timeout /t 5
start cmd /k moon\moon.exe main_chat.lua 3001
timeout /t 5
start cmd /k moon\moon.exe main_match.lua 3002
timeout /t 5
start cmd /k moon\moon.exe main_social.lua 1001
timeout /t 5
start cmd /k moon\moon.exe main_game.lua 1
timeout /t 5
start cmd /k moon\moon.exe main_robot.lua 2001
