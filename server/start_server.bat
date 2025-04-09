start cmd /k moon\moon.exe main_hub.lua 10000 node.json
timeout /t 3
start cmd /k moon\moon.exe main_mgr.lua 3999
timeout /t 3
start cmd /k moon\moon.exe main_social.lua 1001
timeout /t 3
start cmd /k moon\moon.exe main_game.lua 1
timeout /t 1
start cmd /k moon\moon.exe main_robot.lua 2001