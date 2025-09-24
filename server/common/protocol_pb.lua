local moon = require "moon"
local pb = require "pb"
local json = require "json"
local buffer = require "buffer"
local seri = require "seri"
local CmdCode = require "common.CmdCode"

local concats = buffer.concat_string

local concat = buffer.concat

local pencode = pb.encode
local pdecode = pb.decode

local bunpack = buffer.unpack

local type = type

-- used for find message name by id
local id_name = {}
-- used for id bytes cache
local id_bytes = {}

for k, v in pairs(CmdCode) do
    assert(not id_name[v], "msgcode repeated")
    id_name[v] = k
    id_bytes[v] = string.pack("<H", v)
end

local M = {}

function M.encode(uid, id, t)
    if type(id) == 'string' then
        id = CmdCode[id]
    end
    local bytes = id_bytes[id]
    if t then
        local name = id_name[id]
        if not name then
            error("Unknown cmdcode: "..id)
        end
        return concat(seri.packs(uid), bytes, pencode(name, t))
    else
        return seri.packs(uid) .. bytes
    end
end

function M.encodeMessagePacket(GnId, id, t, stub_id)
    if type(id) == 'string' then
        id = CmdCode[id]
    end
    local name = id_name[id]
    assert(name, id)
    local MessagePack = {
           net_id = GnId,
           broadcast = 0,
           stub_id =    stub_id,
           msg_type =   id,
           msg_body =   pencode(name, t)
    }
    return MessagePack
end

function M.encodePacket(GnId, id, t, stub_id)
    local mid = CmdCode["PBPacketCmd"]
    local mdata = id_bytes[mid]
    if type(id) == 'string' then
        id = CmdCode[id]
    end
    local name = id_name[id]
    assert(name, id)
    local MessagePack = {
           net_id = GnId,
           broadcast = 0,
           stub_id =    stub_id,
           msg_type =   id,
           msg_body =   pencode(name, t)
    }
    local messages = {MessagePack}
    return concat(seri.packs(GnId), mdata, pencode("PBPacketCmd", { messages = messages }))
end

function M.encodestring(id, t)
    if type(id) == 'string' then
        id = CmdCode[id]
    end
    local bytes = id_bytes[id]
    if t then
        local name = id_name[id]
        assert(name, id)
        return concats(bytes, pencode(name, t))
    else
        return bytes
    end
end

function M.decode(buf)
    local id, p, n = bunpack(buf, "<HC")
    local name = id_name[id]
    if not name then
        error(string.format("Received unknown message CmdCode: %d. The client and server versions might not match.", id))
    end
    return name, pdecode(name, p, n)
end

function M.DecodeMessagePack(msg)
   local id = msg.msg_type
    local name = id_name[id]
    if not name then
        error(string.format("recv unknown message CmdCode: %d. client server version mismatch", id))
    end
    return name, pdecode(name, msg.msg_body, msg.msg_body.len)
end
function M.RobotDecodeMessagePack(msg)
    local id = msg.msg_type
    local name = id_name[id]
    if not name then
        error(string.format("recv unknown message CmdCode: %d. client server version mismatch", id))
    end
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    pb.option("no_default_values")
    local msg, err = pdecode(name, msg.msg_body, msg.msg_body.len)
    pb.option("use_default_values")
    return name, msg
end
function M.decodestring(data)
    local id = string.unpack("<H", data)
    local pbdata = string.sub(data, 3)
    local name = id_name[id]
    if not name then
        error(string.format("Received unknown message CmdCode: %d. The client and server versions might not match.", id))
    end
    return name, pdecode(name, pbdata), id
end

function M.encodewithname(name, data)
    return name, pencode(name, data)
end

function M.decodewithname(name, pbdata)
    return name, pdecode(name, pbdata)
end

---@return string
function M.name(id)
    return id_name[id]
end

local ignore_print = {
    ["S2CXXX"] = true
}
---@param uid integer
---@param buf buffer_ptr
function M.print_message(uid, buf, str, isRecv)
    local size = buffer.size(buf)
    local offset = 0

    while true do
        local len = size
        local id, p, n = bunpack(buf, "<HC", offset)
        local name = id_name[id]
        offset = offset + 2
        if size >= offset then
            if not ignore_print[name] then
                local t = (size > offset) and pdecode(name, p, len - 2) or {}
                if name == "PBPacketCmd" then
                    for _, MessagePack in ipairs(t.messages) do
                        local subname, submsg = M.DecodeMessagePack(MessagePack)
                        if not ignore_print[subname] then
                            if isRecv then
                                moon.debug(string.format(
                                "[%s] Recv[from:%d][%d] MessagePack[stub_id:%d,net_id:%d]  Message:%s \n%s", str, uid,
                                    len, MessagePack.stub_id, MessagePack.net_id, subname, json.pretty_encode(submsg)))
                            else
                                moon.debug(string.format(
                                "[%s] Send[to:%d][%d] MessagePack[stub_id:%d,net_id:%d] Message:%s \n%s", str, uid, len,
                                    MessagePack.stub_id, MessagePack.net_id, subname, json.pretty_encode(submsg)))
                            end
                        end
                    end
                else
                    if isRecv then
                        moon.debug(string.format("[%s]Recv %d Message:%s size %d \n%s", str, uid, name, len,
                            json.pretty_encode(t)))
                    else
                        moon.debug(string.format("[%s]Send %d Message:%s size %d \n%s", str, uid, name, len,
                            json.pretty_encode(t)))
                    end
                end
            end
            offset = offset + len - 2
        end

        if size == offset then
            break
        end
    end
end

-- -- 解码消息
-- local msg = pb.decode("MyMessageType", encoded_data)

-- -- 判断字段是否被显式设置（非默认值）
-- local has_name = pb.has_field("MyMessageType", msg, "name")
-- local has_age = pb.has_field("MyMessageType", msg, "age")

-- if has_name then
--     print("name字段被显式设置过")
-- else
--     print("name字段使用默认值或未设置")
-- end

return M
