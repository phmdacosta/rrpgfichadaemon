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