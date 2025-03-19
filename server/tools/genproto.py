import os
import sys
import subprocess
import re
import google.protobuf.descriptor_pb2 as descriptor_pb2
import time
import traceback
#from make_ue_proto import generate_header,generate_source
from make_ue_proto import gen_ue_proto 
import zlib
######################TEMPLATE BEGIN#######################


cmdcode_template = '''\
--- Automatically generated,do not modify.

local M={
%s
}

local forward = {
%s
}

local mt = { forward = forward }

mt.__newindex = function(_, name, _)
    local msg = "attemp index unknown message: " .. tostring(name)
    error(debug.traceback(msg, 2))
end

mt.__index = function(_, name)
    if name == "forward" then
        return forward
    end
    local msg = "attemp index unknown message: " .. tostring(name)
    error(debug.traceback(msg, 2))
end

return setmetatable(M,mt)
'''

cmdcode_h_template = '''\
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
%s
	};
	const FString CmdVersion = %s
    extern const TMap<CmdCode, google::protobuf::Message*> ID2Cmd;
    extern std::map<std::string,CmdCode> Cmd2ID;
	extern TMap<CmdCode,TSubclassOf<UProtobufMessage>> ID2Proto;
    extern CmdCode GetCmdCode(const google::protobuf::Message &Msg);
	extern CmdCode GetProtoMsgType(const UProtobufMessage* Msg);
	extern TSubclassOf<UProtobufMessage> GetProtoByCmd(CmdCode Cmd);
    extern CmdCode GetCmdCodeByName(const std::string& MsgName);
}
'''

cmdcode_cpp_template = '''\
// Automatically generated,do not modify.
#include "CmdCode.h"
#include "Protos/AllProto.h"
#include "Net/ProtobufMessage.h"

namespace CommonNetCmd
{
	const TMap<CmdCode, google::protobuf::Message*> ID2Cmd = {
%s
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
'''

######################TEMPLATE END#######################
special_file_list=["common"]
CommonNetUE = "D:\\p4_workpc\\ZGDSRelease\\Plugins\\CommonNetUE\\Source\\CommonNetUE\\Public\\Protos"
LuaPB = ""


def get_filename_without_extension(abs_path):
    # 获取文件名（包括扩展名）
    filename_with_extension = os.path.basename(abs_path)
    # 分离文件名和扩展名
    filename_without_extension = os.path.splitext(filename_with_extension)[0] 
    return filename_without_extension
 
def parse_proto_file(proto_file_path):
    with open(proto_file_path, 'rb') as f:
        proto_content = f.read()

    file_descriptor_set = descriptor_pb2.FileDescriptorSet()
    file_descriptor_set.ParseFromString(proto_content)

    return file_descriptor_set
 

def exec(command: str, input: str = None,
         encoding=None, errors='strict', silent=False) -> str:
    if silent == False:
        print("RUN CMD:", command)
    text_mode = (encoding is None)
    with subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE,
                          universal_newlines=text_mode) as p:
        if input is not None and not text_mode:
            input = input.encode(encoding, errors)  # convert to bytes
        output, err = p.communicate(input)
    if err or p.returncode != 0:
        raise EnvironmentError("Get stderr or exitcode != 0. "
                               "Error: {}, Return Value: {}".format( 
                                   ascii(err), p.returncode))
    return output if text_mode else output.decode(encoding, errors)

def generate_proto_desc(proto_path,proto_file_path, output_desc_path):
    exec("{0} -I{1} -o{2} {3}".format('protoc', proto_path,
             output_desc_path, proto_file_path))
    
def generate_json_desc(proto_path,proto_file_path, output_desc_path):
    exec("{0} -I{1} --include_imports --include_source_info --descriptor_set_out={2} {3}".format('protoc', proto_path,
             output_desc_path, proto_file_path))    
    
def generate_proto_CPlusPlus(proto_path,proto_file_path, output_cplus_path):
    #%PROTOC% --cpp_out=. --cpp_opt=dllexport_decl=DSGATEUE_API -I "%PLUGIN_ROOT%/Source/ThirdParty/proto" -I "%PROTOBUF_PATH%/include" dsgate.proto
    exec("{0} --cpp_out={1} --cpp_opt=dllexport_decl=COMMONNETUE_API -I{2} {3}".format('protoc',output_cplus_path, proto_path, proto_file_path))    

def calculate_crc32(file_path):
    """
    计算给定文件路径的CRC32校验值。
    
    :param file_path: 文件的路径
    :return: CRC32校验值
    """
    crc_value = 0  # 初始化CRC值
    
    try:
        with open(file_path, 'rb') as f:  # 以二进制模式打开文件
            for chunk in iter(lambda: f.read(4096), b''):  # 分块读取文件内容
                crc_value = zlib.crc32(chunk, crc_value)  # 更新CRC值
    except FileNotFoundError:
        print(f"文件未找到: {file_path}")
        return None
    except Exception as e:
        print(f"读取文件时出错: {e}")
        return None
    
    # 返回最终的CRC32值，确保返回值是非负数
    return crc_value & 0xFFFFFFFF

def extract_message_names(proto_file_path, suffix='Cmd'):
    # 获取文件名（不包括路径和扩展名）
    file_name = os.path.splitext(os.path.basename(proto_file_path))[0]

    with open(proto_file_path, 'r',encoding='utf-8') as file:
        content = file.read()

    # 使用正则表达式匹配消息定义
    message_pattern = re.compile(r'message\s+(\w+)\s*\{', re.DOTALL)
    matches = message_pattern.findall(content)

    # 过滤出以指定后缀结尾的消息名，并生成字典
    filtered_messages_dict = {message: file_name for message in matches if message.endswith(suffix)}

    return filtered_messages_dict


 
def get_proto_message_names(directory):
    version_crc = 0
    sys_message = {}
    custom_message = {}
    protofiles = list()
    allprotofiles = list()
    all_messages_dict = {}
    obpath = os.path.abspath(directory)
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.proto'):
                proto_file_path = os.path.join(root, file)
                proto_file_path = os.path.abspath(proto_file_path)
                protofiles.append(proto_file_path) 
                #if file == "dsgate.proto" or file == "unreal_common.proto":
                if file != "any.proto":
                  messages_dict = extract_message_names(proto_file_path)
                  all_messages_dict.update(messages_dict)
                  generate_proto_CPlusPlus(obpath,proto_file_path,CommonNetUE) 
                  filename = get_filename_without_extension(proto_file_path)
                  outpb =  os.path.join(obpath, filename + '.pb.json') 
                  generate_json_desc(obpath,proto_file_path,outpb) 
                  gen_ue_proto(proto_file_path,outpb,CommonNetUE)
                  allprotofiles.append(filename)
    h_AllProto_out_file= CommonNetUE + "\\AllProto.h"
    with open(h_AllProto_out_file, "w", encoding='utf-8') as fobj:
           fobj.write("// Automatically generated,do not modify.\n")
           fobj.write("#pragma once\n")
           fobj.write("#include \"google/protobuf/any.pb.h\"\n")
           for filename in allprotofiles:
               fobj.write("#include \"" + filename + ".pb.h\"\n")

    tmp = " ".join(protofiles)
    outpb =  os.path.join(obpath, 'proto.pb')  
    generate_proto_desc(obpath,tmp,outpb) 
    # 解析.proto文件
    with open(outpb, 'rb') as f:
        file_descriptor_set = descriptor_pb2.FileDescriptorSet()
        file_descriptor_set.ParseFromString(f.read())
        # 遍历消息类型并添加名称
        for file_desc in file_descriptor_set.file:
            package_name = file_desc.package
            for desc in file_desc.message_type:
                full_message_name = '.'.join(filter(None, [package_name, desc.name]))
                if package_name=='google.protobuf' or full_message_name == 'PBPacketCmd' or full_message_name == 'PBClientLoginReqCmd':
                  sys_message[full_message_name] = desc.name
                else:
                  custom_message[full_message_name] = desc.name 

    version_crc = calculate_crc32(outpb)
    return sys_message,custom_message,version_crc,all_messages_dict

def gen_id_dict(sys_message,custom_message,version_crc,all_message):
  # 初始化一个新的字典用于存储ID
  sys_id_dict = {}
  custom_id_dict = {}
  # 自定义ID起始值（这里设置为1） 
  #sys_id_dict['PBPacketCmd'] = 1 
  current_id = 1
  # 生成系统协议（消息以Message结尾,或者为Packet）
  for key in sorted(sys_message.keys()):
     name = sys_message[key]
     sys_id_dict[key] = current_id
     current_id = current_id + 1
  
  #生成用户自定义协议
  current_id = 100
  order_list = list[str]()
  for key in sorted(custom_message.keys()):
        name = custom_message[key]
        if name.endswith("Cmd"):
           print(name)
           custom_id_dict[key] = current_id
           current_id = current_id + 1

  lua_cmdcode_content = ""
  h_cmdcode_content = ""
  cpp_cmdcode_content = ""
  forward_content = "" 
   
  #系统协议
  for cmd in sys_id_dict:
      lua_cmdcode_content += "    [\"" + cmd + "\"] = " + str(sys_id_dict[cmd]) + ",\n"
      h_cmdcode_content += "		" + sys_message[cmd] + " = " + str(sys_id_dict[cmd]) + ",\n"
       
  #用户协议
  for cmd in custom_id_dict:
      lua_cmdcode_content += "    [\"" + cmd + "\"] = " + str(custom_id_dict[cmd]) + ",\n"
      h_cmdcode_content += "		" + custom_message[cmd] + " = " + str(custom_id_dict[cmd]) + ",\n"
  #id-name
  #系统协议
  for cmd in sys_id_dict:
      #lua_cmdcode_content += "    [" + str(sys_id_dict[cmd]) + "] = \"" + cmd + "\",\n"
      cppcmd = cmd.replace(".","::")
      cpp_cmdcode_content += "		{CmdCode::" + sys_message[cmd] + ",new " + cppcmd + "()},\n"
  #用户协议
  for cmd in custom_id_dict:
      #lua_cmdcode_content += "    [" + str(custom_id_dict[cmd]) + "] = \"" + cmd + "\",\n"
      cppcmd = cmd.replace(".","::")
      cpp_cmdcode_content += "		{CmdCode::" + custom_message[cmd] + ",new " + cppcmd + "()},\n"
  #所有消息forward
  for cmd in all_message:
        service = all_message[cmd]
        if service not in special_file_list:
           forward_content += "    " + cmd + \
               " = 'addr_" + service + "',\n"
                                   
  cmdcode_out_file="../common/CmdCode.lua"
  with open(cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_template % (
          lua_cmdcode_content, forward_content))
  h_version_content = "TEXT(\"" + str(version_crc) + "\");"
 
  h_cmdcode_out_file= CommonNetUE + "\\CmdCode.h"
  with open(h_cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_h_template % (
          h_cmdcode_content, h_version_content))
  cpp_cmdcode_out_file= CommonNetUE + "\\CmdCode.cpp"
  with open(cpp_cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_cpp_template % (
          cpp_cmdcode_content))
                
  return sys_id_dict,custom_id_dict
          
if __name__ == "__main__":
    try:
      sys_message,custom_message,version_crc,all_message = get_proto_message_names("../protocol")
      gen_id_dict(sys_message,custom_message,version_crc,all_message)
    except Exception as e:
      traceback.print_exc()

    os.system("pause()")