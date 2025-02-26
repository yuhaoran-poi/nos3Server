import os
import sys
import subprocess
import re
import google.protobuf.descriptor_pb2 as descriptor_pb2
import time
import traceback
######################TEMPLATE BEGIN#######################


cmdcode_template = '''\
--- Automatically generated，do not modify.

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
// Automatically generated，do not modify.
#pragma once
#include "CoreMinimal.h"
#include <map>
namespace google::protobuf
{
	class Message;
}
namespace DSGateCmd
{
	UENUM()
	enum class CmdCode : int32
	{
%s
	};
	const FString CmdVersion = %s
	extern const TMap<CmdCode, google::protobuf::Message*> ID2Cmd;
    extern std::map<std::string,CmdCode> Cmd2ID;
}
'''

cmdcode_cpp_template = '''\
// Automatically generated，do not modify.
#include "CmdCode.h"
#include "Proto/AllProto.h"

namespace DSGateCmd
{
	const TMap<CmdCode, google::protobuf::Message*> ID2Cmd = {
%s
	};
    std::map<std::string,CmdCode> Cmd2ID = {};
 
}
'''

######################TEMPLATE END#######################
#########################################################
 # 基础类型映射
TYPE_MAP = {
    descriptor_pb2.FieldDescriptorProto.TYPE_DOUBLE: "double",
    descriptor_pb2.FieldDescriptorProto.TYPE_FLOAT: "float",
    descriptor_pb2.FieldDescriptorProto.TYPE_INT64: "int64",
    descriptor_pb2.FieldDescriptorProto.TYPE_UINT64: "uint64",
    descriptor_pb2.FieldDescriptorProto.TYPE_INT32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_FIXED64: "uint64",
    descriptor_pb2.FieldDescriptorProto.TYPE_FIXED32: "uint32",
    descriptor_pb2.FieldDescriptorProto.TYPE_BOOL: "bool",
    descriptor_pb2.FieldDescriptorProto.TYPE_STRING: "FString",
    descriptor_pb2.FieldDescriptorProto.TYPE_GROUP: "/* Group not supported */",
    descriptor_pb2.FieldDescriptorProto.TYPE_MESSAGE: "/* Message will be handled separately */",
    descriptor_pb2.FieldDescriptorProto.TYPE_BYTES: "FString",  # 或者使用 TArray<uint8>
    descriptor_pb2.FieldDescriptorProto.TYPE_UINT32: "uint32",
    descriptor_pb2.FieldDescriptorProto.TYPE_ENUM: "/* Enum will be handled separately */",
    descriptor_pb2.FieldDescriptorProto.TYPE_SFIXED32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_SFIXED64: "int64",
    descriptor_pb2.FieldDescriptorProto.TYPE_SINT32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_SINT64: "int64"
}

# 处理嵌套消息和枚举
def process_message(message_descriptor, indent=4):
    struct_name = message_descriptor.name
    lines = [f"USTRUCT(BlueprintType)", f"struct F{struct_name}", "{"]
    lines.append("    GENERATED_BODY()")

    for field in message_descriptor.field:
        field_type = map_field_type(field)
        field_name = field.name
        lines.append(f"    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category=\"{struct_name}\")")
        lines.append(f"    {field_type} {field_name};")

    lines.append("};")
    lines.append("\n")  # 空行分隔不同的结构体定义
    return "\n".join(" " * indent + line for line in lines)

def process_enum(enum_descriptor, indent=4):
    enum_name = enum_descriptor.name
    lines = [f"UENUM(BlueprintType)", f"enum class E{enum_name}", "{"]
    for value in enum_descriptor.value:
        lines.append(f"    {value.name} = {value.number},")
    lines.append("};")
    lines.append("\n")  # 空行分隔不同的枚举定义
    return "\n".join(" " * indent + line for line in lines)

def map_field_type(field):
    if field.label == descriptor_pb2.FieldDescriptorProto.LABEL_REPEATED:
        base_type = TYPE_MAP.get(field.type, "/* Unknown Type */")
        return f"TArray<{base_type}>"
    
    if field.type == descriptor_pb2.FieldDescriptorProto.TYPE_MESSAGE:
        return f"F{field.type_name.split('.')[-1]}"
    
    if field.type == descriptor_pb2.FieldDescriptorProto.TYPE_ENUM:
        return f"E{field.type_name.split('.')[-1]}"
    
    return TYPE_MAP.get(field.type, "/* Unknown Type */")

def parse_proto_file(proto_file_path):
    with open(proto_file_path, 'rb') as f:
        proto_content = f.read()

    file_descriptor_set = descriptor_pb2.FileDescriptorSet()
    file_descriptor_set.ParseFromString(proto_content)

    return file_descriptor_set

def generate_header(file_descriptor, output_header_path):
    with open(output_header_path, 'w') as f:
        f.write("#pragma once\n\n")
        f.write("#include \"CoreMinimal.h\"\n")
        f.write("#include \"UObject/NoExportTypes.h\"\n")

        # 处理导入的 .proto 文件
        for dependency in file_descriptor.file[0].dependency:
            dependency_h = os.path.splitext(dependency)[0] + ".h"
            f.write(f"#include \"{dependency_h}\"\n")
        
        f.write("\n")

        # 处理枚举
        for enum_descriptor in file_descriptor.file[0].enum_type:
            f.write(process_enum(enum_descriptor))
        
        # 处理消息
        for message_descriptor in file_descriptor.file[0].message_type:
            f.write(process_message(message_descriptor))

def generate_source(filename, output_source_path):
    with open(output_source_path, 'w') as f:
        f.write("#include \"CoreMinimal.h\"\n")
        f.write(f"#include \"{filename}.h\"\n")
        f.write("\n")

def get_filename_without_extension(abs_path):
    # 获取文件名（包括扩展名）
    filename_with_extension = os.path.basename(abs_path)
    # 分离文件名和扩展名
    filename_without_extension = os.path.splitext(filename_with_extension)[0]
    return filename_without_extension
#########################################################
 

 

DSGateUE = "D:\\code\\skywork\\UltimateGame\\Plugins\\DSGate\\Source\\DSGateUE\\Public\Proto"
LuaPB = ""

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
    
def generate_proto_CPlusPlus(proto_path,proto_file_path, output_cplus_path):
    #%PROTOC% --cpp_out=. --cpp_opt=dllexport_decl=DSGATEUE_API -I "%PLUGIN_ROOT%/Source/ThirdParty/proto" -I "%PROTOBUF_PATH%/include" dsgate.proto
    exec("{0} --cpp_out={1} --cpp_opt=dllexport_decl=DSGATEUE_API -I{2} {3}".format('protoc',output_cplus_path, proto_path, proto_file_path))    
 
def get_proto_message_names(directory):
    sys_message = {}
    custom_message = {}
    protofiles = list()
    obpath = os.path.abspath(directory)
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.proto'):
                proto_file_path = os.path.join(root, file)
                proto_file_path = os.path.abspath(proto_file_path)
                protofiles.append(proto_file_path)
                #if file == "dsgate.proto" or file == "unreal_common.proto":
                if file != "any.proto":
                  generate_proto_CPlusPlus(obpath,proto_file_path,DSGateUE)
                  filename = get_filename_without_extension(proto_file_path)
                  outpb =  os.path.join(obpath, filename + '.pb') 
                  generate_proto_desc(obpath,proto_file_path,outpb) 
                  file_descriptor_set = parse_proto_file(outpb)
                  # 输出文件名
                  output_header_path = DSGateUE + "\\" + filename + ".h"
                  output_source_path = DSGateUE + "\\" + filename +  ".cpp"
                  generate_header(file_descriptor_set, output_header_path)
                  generate_source(filename, output_source_path)

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
                if package_name=='unrealpb' or package_name=='dsgatepb' or package_name=='google.protobuf':
                  sys_message[full_message_name] = desc.name
                else:
                  custom_message[full_message_name] = desc.name

    return sys_message,custom_message

def gen_id_dict(sys_message,custom_message):
  # 初始化一个新的字典用于存储ID
  sys_id_dict = {}
  custom_id_dict = {}
  # 自定义ID起始值（这里设置为1） 
  sys_id_dict['dsgatepb.Packet'] = 1
  current_id = 2
  # 生成系统协议（消息以Message结尾,或者为Packet）
  for key in sorted(sys_message.keys()):
     name = sys_message[key]
     if name.endswith("Cmd") or name.startswith("Any"):
        print(name)
        sys_id_dict[key] = current_id
        current_id = current_id + 1
  
  #生成用户自定义协议
  current_id = 100
  order_list = list[str]()
  r = re.compile(r'([C,S][2,B][C,S]\w+)')  
  for key in sorted(custom_message.keys()):
        order_list = r.findall(custom_message[key])
        if len(order_list) > 0:
            custom_id_dict[key] = current_id
            current_id = current_id + 1
            print(key)

  lua_cmdcode_content = ""
  h_cmdcode_content = ""
  cpp_cmdcode_content = ""
  forward_content = ""
  version = int(time.time())
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
                 
  cmdcode_out_file="../common/CmdCode.lua"
  with open(cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_template % (
          lua_cmdcode_content, forward_content))
  h_version_content = "TEXT(\"" + str(version) + "\");"
 
  h_cmdcode_out_file= DSGateUE + "\\CmdCode.h"
  with open(h_cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_h_template % (
          h_cmdcode_content, h_version_content))
  cpp_cmdcode_out_file= DSGateUE + "\\CmdCode.cpp"
  with open(cpp_cmdcode_out_file, "w", encoding='utf-8') as fobj:
      fobj.write(cmdcode_cpp_template % (
          cpp_cmdcode_content))
                
  return sys_id_dict,custom_id_dict
          
if __name__ == "__main__":
    try:
      sys_message,custom_message = get_proto_message_names("../protocol")
      gen_id_dict(sys_message,custom_message)
    except Exception as e:
      traceback.print_exc()

    os.system("pause()")