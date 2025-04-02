start cmd /k moon\moon.exe main_hub.lua 10000 node.json
timeout /t 5
start cmd /k moon\moon.exe main_mgr.lua 9999
timeout /t 5
start cmd /k moon\moon.exe main_game.lua 1
timeout /t 5
start cmd /k moon\moon.exe main_robot.lua 20000