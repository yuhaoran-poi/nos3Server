// Automatically generated,do not modify.
#include "CmdCode.h"
#include "Protos/AllProto.h"
#include "Net/ProtobufMessage.h"

namespace CommonNetCmd
{
	const TMap<CmdCode, google::protobuf::Message*> ID2Cmd = {
		{CmdCode::PBPacketCmd,new PBPacketCmd()},
		{CmdCode::PBClientLoginReqCmd,new PBClientLoginReqCmd()},
		{CmdCode::Any,new google::protobuf::Any()},
		{CmdCode::PBApplyFriendReqCmd,new PBApplyFriendReqCmd()},
		{CmdCode::PBApplyFriendRspCmd,new PBApplyFriendRspCmd()},
		{CmdCode::PBApplyGuildReqCmd,new PBApplyGuildReqCmd()},
		{CmdCode::PBApplyGuildRspCmd,new PBApplyGuildRspCmd()},
		{CmdCode::PBApplyTeamReqCmd,new PBApplyTeamReqCmd()},
		{CmdCode::PBApplyTeamRspCmd,new PBApplyTeamRspCmd()},
		{CmdCode::PBApplyTeamSyncCmd,new PBApplyTeamSyncCmd()},
		{CmdCode::PBClientGetUsrSimInfoReqCmd,new PBClientGetUsrSimInfoReqCmd()},
		{CmdCode::PBClientGetUsrSimInfoRspCmd,new PBClientGetUsrSimInfoRspCmd()},
		{CmdCode::PBClientLoginRspCmd,new PBClientLoginRspCmd()},
		{CmdCode::PBGetActivityInfoReqCmd,new PBGetActivityInfoReqCmd()},
		{CmdCode::PBGetActivityInfoRspCmd,new PBGetActivityInfoRspCmd()},
		{CmdCode::PBGetFriendInfoReqCmd,new PBGetFriendInfoReqCmd()},
		{CmdCode::PBGetFriendInfoRspCmd,new PBGetFriendInfoRspCmd()},
		{CmdCode::PBGetMailItemReqCmd,new PBGetMailItemReqCmd()},
		{CmdCode::PBGetMailItemRspCmd,new PBGetMailItemRspCmd()},
		{CmdCode::PBGetOpenBoxReqCmd,new PBGetOpenBoxReqCmd()},
		{CmdCode::PBGetOpenBoxRspCmd,new PBGetOpenBoxRspCmd()},
		{CmdCode::PBGetRankInfoReqCmd,new PBGetRankInfoReqCmd()},
		{CmdCode::PBGetRankInfoRspCmd,new PBGetRankInfoRspCmd()},
		{CmdCode::PBGetTradeBankInfoReqCmd,new PBGetTradeBankInfoReqCmd()},
		{CmdCode::PBGetTradeBankInfoRspCmd,new PBGetTradeBankInfoRspCmd()},
		{CmdCode::PBPingCmd,new PBPingCmd()},
		{CmdCode::PBPongCmd,new PBPongCmd()},
		{CmdCode::PBUpdateMissionClientSyncCmd,new PBUpdateMissionClientSyncCmd()},
		{CmdCode::PBUpdateMissionSeverSyncCmd,new PBUpdateMissionSeverSyncCmd()},

	};
    TMap<CmdCode,TSubclassOf<UProtobufMessage>> ID2Proto = {};
    std::map<std::string,CmdCode> Cmd2ID = {};
	CmdCode GetCmdCodeByName(const std::string& MsgName)
	{
		if(Cmd2ID.size() == 0)
		{
			for(const auto& Iter : ID2Cmd)
			{
				Cmd2ID[Iter.Value->GetTypeName()] = Iter.Key;
			}
		}
		const auto Iter = Cmd2ID.find(MsgName);
		if(Iter!=Cmd2ID.end())
		{
			return Iter->second;
		}
		return CmdCode::None;
	}

	CmdCode GetCmdCode(const google::protobuf::Message& Msg)
	{
		return GetCmdCodeByName(Msg.GetTypeName());
	}

    CmdCode GetProtoMsgType(const UProtobufMessage* Msg)
    {
	    if (Msg)
	    {
		    FString ClassName = Msg->GetName();
	    	ClassName = UProtobufMessage::GetClassNameWithoutSuffix(ClassName);
	    	const ANSICHAR* AnsiStr = TCHAR_TO_UTF8(*ClassName);
	    	const std::string Str(AnsiStr);
	    	return GetCmdCodeByName(Str); 
	    	
	    }
	    return CmdCode::None;
    }

	TSubclassOf<UProtobufMessage> GetProtoByCmd(CmdCode Cmd)
	{
		if (!ID2Proto.Contains(Cmd))
		  return nullptr;
		return ID2Proto[Cmd];
	}
 
}
