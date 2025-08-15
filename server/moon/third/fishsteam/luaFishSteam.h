#pragma once
#include "lua.hpp"
#include <string>
#include <string_view>
#include <functional>

#include <iostream>
#include <map>
#include <string>
#include <vector>

#include "sdk/public/steam/steam_gameserver.h"
#include "sdk/public/steam/steamencryptedappticket.h"

using namespace std;
extern "C" int luaopen_libfishsteam(lua_State * L);
