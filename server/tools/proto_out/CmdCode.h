// Automatically generated,do not modify.
#pragma once
#include "CoreMinimal.h"
#include <map>
namespace google::protobuf
{
	class Message;
}
class UProtobufMessage;
namespace CommonNetCmd
{
	UENUM()
	enum class CmdCode : int32
	{
        None = 0,
		PBPacketCmd = 1,
		PBClientLoginReqCmd = 2,
		Any = 3,
		PBApplyFriendReqCmd = 100,
		PBApplyFriendRspCmd = 101,
		PBApplyGuildReqCmd = 102,
		PBApplyGuildRspCmd = 103,
		PBApplyTeamReqCmd = 104,
		PBApplyTeamRspCmd = 105,
		PBApplyTeamSyncCmd = 106,
		PBClientGetUsrSimInfoReqCmd = 107,
		PBClientGetUsrSimInfoRspCmd = 108,
		PBClientLoginRspCmd = 109,
		PBGetActivityInfoReqCmd = 110,
		PBGetActivityInfoRspCmd = 111,
		PBGetFriendInfoReqCmd = 112,
		PBGetFriendInfoRspCmd = 113,
		PBGetMailItemReqCmd = 114,
		PBGetMailItemRspCmd = 115,
		PBGetOpenBoxReqCmd = 116,
		PBGetOpenBoxRspCmd = 117,
		PBGetRankInfoReqCmd = 118,
		PBGetRankInfoRspCmd = 119,
		PBGetTradeBankInfoReqCmd = 120,
		PBGetTradeBankInfoRspCmd = 121,
		PBPingCmd = 122,
		PBPongCmd = 123,
		PBUpdateMissionClientSyncCmd = 124,
		PBUpdateMissionSeverSyncCmd = 125,

	};
	const FString CmdVersion = TEXT("1777581865");
    extern const TMap<CmdCode, google::protobuf::Message*> ID2Cmd;
    extern std::map<std::string,CmdCode> Cmd2ID;
	extern TMap<CmdCode,TSubclassOf<UProtobufMessage>> ID2Proto;
    extern CmdCode GetCmdCode(const google::protobuf::Message &Msg);
	extern CmdCode GetProtoMsgType(const UProtobufMessage* Msg);
	extern TSubclassOf<UProtobufMessage> GetProtoByCmd(CmdCode Cmd);
    extern CmdCode GetCmdCodeByName(const std::string& MsgName);
}
