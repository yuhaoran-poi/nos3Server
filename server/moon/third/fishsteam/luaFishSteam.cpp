#include "luaFishSteam.h"
//#include "sol/sol.hpp"
//#include "FishSteam.h"
#include <fstream>

//namespace luaFishSteam {
//    sol::table open_luaFishSteam(sol::this_state L) {
//			sol::state::state_view state(L);
//			sol::table module = state.create_table();
//			module.new_usertype<FishSteam>("FishSteam",
//				//"InitFishSteam", &FishSteam::InitFishSteam,
//				//"GetIsInit", &FishSteam::GetIsInit,
//				//"GetFishSteam", &FishSteam::GetFishSteam,
//				"CheckSteamAuthSessionTicket", &FishSteam::CheckSteamAuthSessionTicket,
//				"CheckFishSteam", &FishSteam::CheckFishSteam
//				);
//			return module;
//	}
//}
 
//extern "C"  int luaopen_libfishsteam(lua_State * L) {
//    return sol::stack::call_lua(
//		L, 1, luaFishSteam::open_luaFishSteam);
//}

int hex2bin(const char* pSrc, unsigned char* pDst, unsigned int nSrcLength, unsigned int& nDstLength)
{
    if (pSrc == 0)
    {
        return -1;
    }

    nDstLength = 0;

    if (pSrc[0] == 0) // nothing to convert  
        return 0;

    // 计算需要转换的字节数  
    for (int j = 0; pSrc[j]; j++)
    {
        if (isxdigit(pSrc[j]))
            nDstLength++;
    }

    // 判断待转换字节数是否为奇数，然后加一  
    if (nDstLength & 0x01) nDstLength++;
    nDstLength /= 2;

    if (nDstLength > nSrcLength)
        return -1;

    nDstLength = 0;

    int phase = 0;

    for (int i = 0; pSrc[i]; i++)
    {
        if (!isxdigit(pSrc[i]))
            continue;

        unsigned char val = pSrc[i] - (isdigit(pSrc[i]) ? 0x30 : (isupper(pSrc[i]) ? 0x37 : 0x57));

        if (phase == 0)
        {
            pDst[nDstLength] = val << 4;
            phase++;
        }
        else
        {
            pDst[nDstLength] |= val;
            phase = 0;
            nDstLength++;
        }
    }

    return 0;
}

//string rgubTicket, uint32 ticketLength, string steamKey, uint32 appId, uint32 begValidTimem, uint32 endValidTime, uint64 player_steamid
static int CheckSteamAuthSessionTicket(lua_State* L)
{
	string rgubTicket = luaL_checkstring(L, 1);
	uint32 ticketLength = (uint32)luaL_checkinteger(L, 2);
	string steamKey = luaL_checkstring(L, 3);
	uint32 appId = (uint32)luaL_checkinteger(L, 4);
	uint32 begValidTimem = (uint32)luaL_checkinteger(L, 5);
	uint32 endValidTime = (uint32)luaL_checkinteger(L, 6);
	uint64 player_steamid = (uint64)luaL_checkinteger(L, 7);

	ofstream ofile;
	ofile.open("fishsteam.log", ios::app);
	ofile << "rgubTicket = " << rgubTicket << " ticketLength = " << ticketLength << " steamKey = " << steamKey << " appId = " << appId << " begValidTimem = " << begValidTimem << " endValidTime = " << endValidTime << " player_steamid = " << player_steamid << endl;


	uint8 rgubTicket_arr[1024];
	uint32 rgubTicket_arr_length = 1024;
	int temp1 = hex2bin(rgubTicket.c_str(), rgubTicket_arr, rgubTicket.size(), rgubTicket_arr_length);

	uint8 decrypted[1024];
	uint32 real_size = sizeof(decrypted);
	CSteamID* targetSteamid = new CSteamID(player_steamid);

	uint8 rgubKey[k_nSteamEncryptedAppTicketSymmetricKeyLen];
	uint32 rgubKey_length = 1024;
	int temp2 = hex2bin(steamKey.c_str(), rgubKey, steamKey.size(), rgubKey_length);

	//解密票证
	bool succ = SteamEncryptedAppTicket_BDecryptTicket(rgubTicket_arr, rgubTicket_arr_length, decrypted, &real_size, rgubKey, rgubKey_length);
	if (succ == false)
	{
		ofile << "return 0" << endl;
		ofile.close();
		return 0;
	}
	//验证APPID
	if (!SteamEncryptedAppTicket_BIsTicketForApp(&decrypted[0], real_size, (AppId_t)appId))
	{
		ofile << "return 1" << endl;
		ofile.close();
		return 0;
	}
	//验证票证有效期
	//uint32 ticketTime = SteamEncryptedAppTicket_GetTicketIssueTime(&decrypted[0], real_size);
	//if (ticketTime < begValidTimem || ticketTime > endValidTime)
	//{
	//	ofile << "return 2" << endl;
	//	ofile.close();
	//	return 2;
	//}
	//获取steamid
	SteamEncryptedAppTicket_GetTicketSteamID(&decrypted[0], real_size, targetSteamid);

	ofile << "return" << endl;
	ofile.close();
	uint64 res = targetSteamid->ConvertToUint64();

	lua_pushinteger(L, res);
	return 1;
}

static int CheckFishSteam(lua_State* L)
{
	ofstream ofile;
	ofile.open("fishsteam.log");
	ofile << "CheckFishSteam " << endl;
	ofile.close();

	return 0;
}

extern "C" int luaopen_libfishsteam(lua_State* L) {
	// luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "CheckSteamAuthSessionTicket", CheckSteamAuthSessionTicket },
		{ "CheckFishSteam", CheckFishSteam },
		{ NULL, NULL }
	};
	luaL_newlib(L, l);
	return 1;
}

//LUAMOD_API int luaopen_libfishsteam(lua_State* L) {
//	luaL_checkversion(L);
//	luaL_Reg l[] = {
//		{ "hashkey", lhashkey },
//		{ "randomkey", lrandomkey },
//		{ "desencode", ldesencode },
//		{ "desdecode", ldesdecode },
//		{ "hexencode", ltohex },
//		{ "hexdecode", lfromhex },
//		{ "hmac64", lhmac64 },
//		{ "hmac64_md5", lhmac64_md5 },
//		{ "dhexchange", ldhexchange },
//		{ "dhsecret", ldhsecret },
//		{ "base64encode", lb64encode },
//		{ "base64decode", lb64decode },
//		{ "sha1", lsha1 },
//		{ "hmac_sha1", lhmac_sha1 },
//		{ "hmac_hash", lhmac_hash },
//		{ "xor_str", lxor_str },
//		{ "padding", NULL },
//		{ NULL, NULL },
//	};
//	luaL_newlib(L, l);
//
//	padding_mode_table(L);
//	lua_setfield(L, -2, "padding");
//
//	return 1;
//}