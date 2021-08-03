Util = {};

function Util.split(s, delimiter)
    local result = {s};
    if s ~= nil 
        and delimiter ~= nil 
        and string.find(s, delimiter)then
            result = {};
            for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                table.insert(result, match);
            end;
    end;
    return result;
end;

function Util.trim(s)
    if s == nil then
        return s;
    end;
    return s:gsub("%s+", "");
end;

function Util.handleNil(s)
    if s == nil then
        return ''
    end
    return s
end

function Util.copy(obj)
    if type(obj) ~= 'table' then 
        return obj
    end
    local res = setmetatable({}, getmetatable(obj))
    for k, v in pairs(obj) do 
        res[Util.copy(k)] = Util.copy(v)
    end
    return res
end

function Util.startsWith(str, start)
    return str:sub(1, #start) == start
end

function Util.endsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

function Util.capitalize(str)
    local result = string.lower(str)
    return (result:gsub("^%l", string.upper))
end

function Util.orderTableAsc(t, fieldName)
    table.sort(t, function (left, right)
        return left[fieldName] < right[fieldName]
    end)
 end

function Util.isEmptyTable(t)
     for _,v in pairs(t) do
         if v ~= nil then
             return false;
         end
     end
     return true;
 end

function Util.isTable(obj)
    return type(obj) == 'table';
end

--[[
    Transforma string em número.
    Caso não consiga transformar, retorna zero.
]]
function Util.toNumber(str)
    return (tonumber(str) or 0)
end

function Util.strConcat(args)
    local res = ''
    for _,v in ipairs(args) do
        res = res..Util.handleNil(v)
    end
    return res
end

function Util.isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

function Util.arrayContains(arr, obj)
    if arr == nil 
        or not Util.isArray(arr) 
        or obj == nil then
            return false
    end

    for _,o in ipairs(arr) do
        if obj['equals'] ~= nil and obj:equals(o) then
            return true
        end
    end

    return false
end

function Util.getTableLength(t)
    local count = 0

    if Util.isTable(t) then
        for _,_ in pairs(t) do
            count = count + 1
        end
    end
    
    return count
end

 return Util;