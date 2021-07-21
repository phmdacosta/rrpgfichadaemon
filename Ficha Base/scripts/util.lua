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