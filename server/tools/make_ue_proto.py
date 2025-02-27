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

def parse_proto(file_path):
    with open(file_path, 'rb') as f:
        data = f.read()
    file_set = descriptor_pb2.FileDescriptorSet.FromString(data)
    return file_set.file[0]

def is_map_field(field, message_types):
    if field.type != descriptor_pb2.FieldDescriptorProto.TYPE_MESSAGE:
        return False
    # Get the nested message type by name
    nested_message_name = field.type_name.split('.')[-1]
    for msg in message_types:
        if msg.name == nested_message_name:
            if msg.options and msg.options.map_entry:
                return True
    return False

def convert_type(field, is_repeated=False, is_map=False, message_types=None, prefix=""):
    if is_map:
        key_type = TYPE_MAP.get(field.message_type.field[0].type, "/* Unknown key type */")
        value_type = convert_type(field.message_type.field[1], field.message_type.field[1].label == field.LABEL_REPEATED, message_types=message_types, prefix=prefix)
        return f'TMap<{key_type}, {value_type}>'
    elif is_repeated:
        base_type = TYPE_MAP.get(field.type, "/* Unknown repeated type */")
        if field.type_name:
            # For nested messages or enums
            nested_type_name = field.type_name.split('.')[-1]
            if any(msg.name == nested_type_name for msg in message_types):
                base_type = f'{prefix}{nested_type_name}'
            else:
                base_type = nested_type_name
        return f'TArray<{base_type}>'
    else:
        if field.type_name:
            # For nested messages or enums
            nested_type_name = field.type_name.split('.')[-1]
            if any(msg.name == nested_type_name for msg in message_types):
                return f'{prefix}{nested_type_name}'
            else:
                return nested_type_name
        else:
            base_type = TYPE_MAP.get(field.type, "/* Unknown type */")
            return base_type

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

    # Find the starting line of the message
    start_line = find_position(content, f'message {message.name}')

    for field in message.field:
        is_map = is_map_field(field, message_types)
        field_type = convert_type(field, field.label == field.LABEL_REPEATED, is_map, message_types, prefix)
        field_start_line = find_position(content, field.name, start_line)
        field_comment = extract_comments(content, field_start_line, field_start_line)
        field_name = ''.join(word.capitalize() or '_' for word in field.name.split('_'))  # Convert snake_case to CamelCase
        field_def = f'\tUPROPERTY(EditAnywhere, BlueprintReadWrite, Category="{struct_name}")\n\t{field_type} {field_name};'
        if field_comment:
            # 使用列表推导式为每一行添加制表符
            indented_comment = "\n".join([f"\t{line}" for line in field_comment.splitlines()])
            field_def = f'{indented_comment}\n{field_def}'
        fields.append(field_def)

    struct_comment = extract_comments(content, start_line, start_line)
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
        f'enum class {enum_name}',
        '{',
        *values,
        '};'
    ]
    return '\n'.join(enum_definition)

def process_file(file_descriptor, content):
    includes = set()
    structs = []
    enums = []
    message_types = file_descriptor.message_type

    def process_message(descriptor, prefix="F"):
        nonlocal includes, structs, enums
        structs.append(generate_struct(descriptor, content, message_types, prefix))
        for nested_message in descriptor.nested_type:
            process_message(nested_message, prefix + descriptor.name + "_")
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
        *[f'#include "{inc}"' for inc in sorted(includes)],
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
    file_descriptor = parse_proto(input_pb)
    with open(input_file, 'r',encoding='utf-8') as f:
        content = f.read()

    includes, structs, enums = process_file(file_descriptor, content)

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
 
