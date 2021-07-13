Util = {};

function Util.split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end;

function Util.trim(s)
    return s:gsub("%s+", "")
end;

function Util.handleNil(s)
    if s == nil then
        return ''
    end
    return s
end

function Util.copy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = setmetatable({}, getmetatable(obj))
    for k, v in pairs(obj) do res[Util.copy(k)] = Util.copy(v) end
    return res
end