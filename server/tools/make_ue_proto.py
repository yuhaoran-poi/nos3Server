import os
import re
from google.protobuf import descriptor_pb2

# 基础类型映射表
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
    descriptor_pb2.FieldDescriptorProto.TYPE_BYTES: "TArray<uint8>",
    descriptor_pb2.FieldDescriptorProto.TYPE_UINT32: "uint32",
    descriptor_pb2.FieldDescriptorProto.TYPE_SFIXED32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_SFIXED64: "int64",
    descriptor_pb2.FieldDescriptorProto.TYPE_SINT32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_SINT64: "int64"
}

ENUM_TYPE_MAP = {
    descriptor_pb2.FieldDescriptorProto.TYPE_INT32: "int32",
    descriptor_pb2.FieldDescriptorProto.TYPE_FIXED32: "uint32",
    descriptor_pb2.FieldDescriptorProto.TYPE_INT64: "int64",
    descriptor_pb2.FieldDescriptorProto.TYPE_UINT64: "uint64",
}

# 默认值映射表（新增）
DEFAULT_VALUE_MAP = {
    "double": "0.0",
    "float": "0.0f",
    "int32": "0",
    "int64": "0LL",
    "uint32": "0U",
    "uint64": "0ULL",
    "bool": "false",
    "FString": 'TEXT("")',
    "TArray": "{}",
    "TMap": "{}",
    "struct": "{}"  # 结构体默认初始化
}

# 在全局范围新增枚举收集逻辑
all_enums = []  # 需要确保在parse_proto时收集所有枚举
def parse_proto(file_path):
    with open(file_path, 'rb') as f:
        data = f.read()
    file_set = descriptor_pb2.FileDescriptorSet.FromString(data)
    target_name = os.path.basename(file_path)
    filename_without_extension = os.path.splitext(target_name)[0] 
    # 加载所有依赖的proto文件描述符
    all_messages = []
     # 收集所有枚举类型
    global all_enums
    all_enums = []

    for file_desc in file_set.file:
        all_messages.extend(file_desc.message_type)
        all_enums.extend(file_desc.enum_type)
        # 递归处理嵌套消息
        def collect_nested_messages(messages):
            for msg in messages:
                all_messages.append(msg)
                collect_nested_messages(msg.nested_type)
         # 递归收集嵌套枚举
        def collect_enums(messages):
            for msg in messages:
                all_enums.extend(msg.enum_type)
                collect_enums(msg.nested_type)

        collect_enums(file_desc.message_type)
        collect_nested_messages(file_desc.message_type)

    # 查找目标文件描述符
   
    for file_desc in file_set.file:
        cur_name = os.path.basename(file_desc.name)
        cur_name = os.path.splitext(cur_name)[0] 
        if cur_name == filename_without_extension:
            # 将收集到的所有消息附加到目标文件描述符
            return file_desc,all_messages
    raise ValueError(f"File descriptor for {target_name} not found")
     

def is_map_entry(message_type):
    """判断是否为Protobuf自动生成的Map Entry类型"""
    return message_type.options and message_type.options.map_entry

def get_map_entry_type(field, message_types):
    type_name = field.type_name.lstrip('.')
    # 解析完整的消息层级（例如："PBGetMailItemRspCmd.MailDatasEntry"）
    parent_message, entry_name = type_name.rsplit('.', 1) if '.' in type_name else ('', type_name)
    
    # 遍历所有已知消息类型
    for msg in message_types:
        # 匹配嵌套消息中的Map Entry
        if msg.name == entry_name and msg.options.map_entry:
            return msg
        # 处理父消息嵌套的情况（如PBGetMailItemRspCmd嵌套在其它消息中）
        if parent_message and msg.name == parent_message.split('.')[-1]:
            for nested_msg in msg.nested_type:
                if nested_msg.name == entry_name and nested_msg.options.map_entry:
                    return nested_msg
    return None

def is_map_field(field, message_types):
    if field.type != descriptor_pb2.FieldDescriptorProto.TYPE_MESSAGE:
        return False
     # 通过命名规则匹配Map类型（兼容不同protobuf版本的生成规则）
    if field.type_name.endswith("Entry"):
        return True
    # Get the nested message type by name
    nested_message_name = field.type_name.split('.')[-1]
    for msg in message_types:
        if msg.name == nested_message_name:
            if msg.options and msg.options.map_entry:
                return True
    return False

def convert_type(field, is_repeated=False, is_map=False, message_types=None, prefix=""):
    """返回类型和类型分类（map/array/struct/primitive）"""
    if is_map:
        entry_type = get_map_entry_type(field, message_types)
        if not entry_type or len(entry_type.field) < 2:
            return ("TMap<InvalidKey,InvalidValue>", 'map')
        
        key_field = entry_type.field[0]
        value_field = entry_type.field[1]
        
        # 递归解析Key类型（确保基本类型映射）
        key_type, _ = convert_type(key_field, message_types=message_types, prefix=prefix)
        # 递归解析Value类型（处理自定义消息）
        value_type, _ = convert_type(value_field, message_types=message_types, prefix=prefix)
        
        # 增强前缀处理逻辑
        if value_type.startswith("PB") or (value_type in [msg.name for msg in message_types]):
            value_type = f"F{value_type}"
        
        return (f"TMap<{key_type}, {value_type}>", 'map')
    
    if is_repeated:
        base_type = TYPE_MAP.get(field.type, "/* Unknown repeated type */")
        if field.type_name:
            nested_type_name = field.type_name.split('.')[-1]
            if any(msg.name == nested_type_name for msg in message_types):
                base_type = f'{prefix}{nested_type_name}'
        return (f'TArray<{base_type}>', 'array')
    
    if field.type_name:
        nested_type_name = field.type_name.split('.')[-1]
        # 检测是否为嵌套结构体
        # 检测是否为枚举类型
        if any(enum.name == nested_type_name for enum in all_enums):
            return (f'E{nested_type_name}', 'enum')
        # 检测是否为结构体类型
        elif any(msg.name == nested_type_name for msg in message_types):
            return (f'{prefix}{nested_type_name}', 'struct')
        # 否则视为枚举类型
        return (f'E{nested_type_name}', 'enum')
    
    return (TYPE_MAP.get(field.type, "/* Unknown type */"), 'primitive')

def extract_comments(content, start_line, max_lines=5):
    lines = content.splitlines()
    comments = []
   
    # Search forward for comments on the same line or after the target line
    for i in range(start_line - 2, 0,-1):
        line = lines[i].strip()
        if line.startswith("//"):
            comments.insert(0,line)
        elif line.strip() == "" or not line.startswith("//"):
            break
        if len(comments) >= max_lines:
            break
    # 查找当前行注释
    code_line = lines[start_line-1].strip()    
    match = re.search(r'//.*', code_line)
    if match:
        comments.append(match.group(0))   # 返回匹配到的注释部分
    return "\n".join(comments)

def find_position(content, target, start_line=1):
    lines = content.splitlines()
    current_line = start_line
    for line in lines[start_line-1:]:
        if target in line:
            return current_line
        current_line += 1
    return -1

def generate_struct(message, content, message_types, prefix="F"):
    struct_name = message.name
    fields = []
    has_fields = []
    IsCmdMessage = struct_name.endswith("Cmd")
    # Find the starting line of the message
    start_line = find_position(content, f'message {message.name}')

    for field in message.field:
        is_map = is_map_field(field, message_types)
        field_type, type_category = convert_type(field, field.label == field.LABEL_REPEATED,is_map, message_types, prefix)
        field_start_line = find_position(content, field.name, start_line)
        field_comment = extract_comments(content, field_start_line, field_start_line)
        field_name = ''.join(word.capitalize() or '_' for word in field.name.split('_'))  # Convert snake_case to CamelCase
        default_value = None
        if type_category in ('map', 'array'):
            default_value = DEFAULT_VALUE_MAP.get(type_category, "{}")
        elif type_category == 'struct':
            default_value = "{}"
        elif type_category =='enum':
             # 获取原始枚举类型名称（不带E前缀）
            enum_name = field_type.replace('E', '', 1)
            # 查找匹配的枚举描述符
            enum_desc = next((e for e in all_enums if e.name == enum_name), None)
            
            if enum_desc and enum_desc.value:
                # 获取protobuf中定义的第一个枚举值（按声明顺序）
                first_value = enum_desc.value[0].name
            else:
                first_value = 'Unknown'  # 安全回退值
            
            # 生成带命名空间的枚举初始化
            default_value = f'{field_type}::{first_value}'
        else:
            default_value = DEFAULT_VALUE_MAP.get(field_type.split('<')[0], "")  # 处理模板类型

         # 生成字段定义（添加默认值）
        field_def = f'\tUPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Protobuf|Property",Transient)\n\t{field_type} {field_name} = {default_value};'
        # Has属性默认false
        has_field_def = f'\tUPROPERTY(EditAnywhere, BlueprintReadWrite,Category="HasProperty")\n\tbool bHas{field_name} = false;'
        if field_comment:
            # 使用列表推导式为每一行添加制表符
            indented_comment = "\n".join([f"\t{line}" for line in field_comment.splitlines()])
            field_def = f'{indented_comment}\n{field_def}'
        fields.append(field_def)
        has_fields.append(has_field_def)
    # 添加分隔注释和has字段
    fields.append('\t// ---------- 属性存在标志 ----------')
    fields.extend(has_fields)


    struct_comment = extract_comments(content, start_line, start_line)
    struct_definition = []
    if IsCmdMessage:
        struct_definition = [
        f'{struct_comment}',
        f'UCLASS(BlueprintType)',
        f'class U{struct_name} : public UProtobufMessage',
        '{',
        '\tGENERATED_BODY()',
        'public:',
        ''
    ] + fields + [
        '};'
    ]
    else:
        struct_definition = [
        f'{struct_comment}',
        f'USTRUCT(BlueprintType)',
        f'struct {prefix}{struct_name}',
        '{',
        '\tGENERATED_BODY()',
        ''
    ] + fields + [
        '};'
    ]
  
    return '\n'.join(struct_definition)

def generate_enum(enum, content):
    enum_name = enum.name
    values = []

    # Find the starting line of the enum
    start_line = find_position(content, f'enum {enum.name}')

    for value in enum.value:
        value_start_line = find_position(content, value.name, start_line)
        value_comment = extract_comments(content, value_start_line, value_start_line)
        value_def = f'\t{value.name} = {value.number},'
        if value_comment:
             # 使用列表推导式为每一行添加制表符
            indented_comment = "\n".join([f"\t{line}" for line in value_comment.splitlines()])
            value_def = f'{indented_comment}\n{value_def}'
        values.append(value_def)

    enum_comment = extract_comments(content, start_line, start_line)
    enum_definition = [
        f'// {enum_comment}',
        f'UENUM(BlueprintType)',
        f'enum class E{enum_name} : uint8',
        '{',
        *values,
        '};'
    ]
    return '\n'.join(enum_definition)

def process_file(file_descriptor, content,all_message_types):
    includes = set()
    structs = []
    enums = []
    message_types = file_descriptor.message_type
   

    def process_message(descriptor, prefix="F"):
        nonlocal includes, structs, enums
        structs.append(generate_struct(descriptor, content, all_message_types, prefix))
        #for nested_message in descriptor.nested_type:
        #    process_message(nested_message, prefix + descriptor.name + "_")
        # 确保嵌套消息的前缀叠加
        new_prefix = f"{prefix}{descriptor.name}_"
        for nested in descriptor.nested_type:
            process_message(nested, new_prefix)
        for enum in descriptor.enum_type:
            enums.append(generate_enum(enum, content))

    for message in file_descriptor.message_type:
        process_message(message)
    for enum in file_descriptor.enum_type:
        enums.append(generate_enum(enum, content))

    for dep in file_descriptor.dependency:
        includes.add(dep.replace('.proto', '.h'))

    return includes, structs, enums

def generate_header(file_descriptor, includes, structs, enums):
    base_name = os.path.splitext(os.path.basename(file_descriptor.name))[0]
    header_guard = f'{base_name.upper()}_H'
    header_content = [
        f'#pragma once',
        '#include "CoreMinimal.h"',
        *[f'#include "Protos/{inc}"' for inc in sorted(includes)],
        f'#include "Net/ProtobufMessage.h"',  # Include base class
        f'#include "{base_name}.generated.h"',  # Include generated.h
        '',
        '// Generated by Proto3 to UE5 Struct Converter',
        '',
        *enums,
        '',
        *structs,
        ''
    ]
    return '\n'.join(header_content)

def generate_cpp(file_descriptor, structs, enums):
    base_name = os.path.splitext(os.path.basename(file_descriptor.name))[0]
    cpp_content = [
        f'#include "{base_name}.h"',
        '',
        '// Generated by Proto3 to UE5 Struct Converter',
        ''
    ]
    return '\n'.join(cpp_content)

 

 


 
 

def gen_ue_proto(input_file, input_pb,output_dir):
    file_descriptor,all_message_types = parse_proto(input_pb)
    with open(input_file, 'r',encoding='utf-8') as f:
        content = f.read()

    includes, structs, enums = process_file(file_descriptor, content,all_message_types)

    base_name = os.path.splitext(os.path.basename(input_file))[0]
    header_file = os.path.join(output_dir, f'{base_name}.h')
    cpp_file = os.path.join(output_dir, f'{base_name}.cpp')

    header_content = generate_header(file_descriptor, includes, structs, enums)
    cpp_content = generate_cpp(file_descriptor, structs, enums)

    with open(header_file, 'w',encoding='utf-8') as f:
        f.write(header_content)

    with open(cpp_file, 'w',encoding='utf-8') as f:
        f.write(cpp_content)

    print(f'Successfully generated {header_file} and {cpp_file}')
 
