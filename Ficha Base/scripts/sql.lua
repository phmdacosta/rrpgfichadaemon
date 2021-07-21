require('util.lua')

SQL = {}

Content = {
    name = nil,
    rawHeader = nil,
    header = {},
    rawData = {},
    objMap = {}
}

Object = {}

local SEPARATOR = ';'

local function splitLines(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch(delimiter) do
        table.insert(result, match);
    end
    return result;
end;

local function getObjectFromRaw(rawHeader, rawData)
    local headColumns = Util.split(rawHeader, SEPARATOR)
    local dataColumns = Util.split(rawData, SEPARATOR)
    local obj = Object

    -- Search between columns
    for j = 1, #headColumns do
        if j <= #dataColumns then
            obj[headColumns[j]] = dataColumns[j]
        end
    end

    return obj;
end

local function getHeaderFromRaw(rawHeader)
    local headColumns = Util.split(rawHeader, SEPARATOR)
    local headerTable = {}

    -- Search between columns
    for j = 1, #headColumns do
        table.insert(headerTable, headColumns[j])
    end

    return headerTable;
end

local function insertObjectIfNotExist(content, data)
    local key = data.id..'|'..data.nome;
    if content.objMap[key] == nil then
        content.objMap[key] = data;
    end
end

function SQL.getSeparator()
    return SEPARATOR;
end

function SQL.exists(path)
    return VHD.fileExists(path);
end

function SQL.readFile(path)
    local content = nil;
    if SQL.exists(path) then
        local filestream = VHD.openFile(path);

        if(filestream ~= nil) then
            local rawContent = filestream:readBinary("ansi");
            local lines = splitLines(rawContent, "[^\r\n]+");
            content = Content:new();

            -- setting headers
            content.rawHeader = lines[1];
            content.header = getHeaderFromRaw(lines[1]);

            --setting data
            for i = 2, #lines do
                content.rawData[i-1] = lines[i];
                local obj = getObjectFromRaw(content.rawHeader, lines[i]);
                if obj ~= nil and obj.id ~= nil and obj.nome ~= nil then
                    insertObjectIfNotExist(content, Util.copy(obj));
                end
            end
            filestream:close()
        end;
    end;
    return content;
end;

function SQL.save(path, content)
    local filestream = VHD.openFile(path, "w+");
    filestream:writeBase64(content);
    filestream:close();
end;

-- Content functions
function Content:new()
    local newObj = {}
    newObj.name = nil
    newObj.rawHeader = nil
    newObj.header = {}
    newObj.rawData = {}
    newObj.objMap = {}
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end;

function Content:getObjects()
    local objects = {};
    for _,o in pairs(self.objMap) do
        table.insert(objects, o);
    end
    return objects;
end;


function Content:getObjectById(id)
    return self:getObject('id', id);
end;


function Content:getObject(column, value)
    if value ~= nil then
        local objects = self:getObjects();
        local vStr = tostring(value);

        for _,o in ipairs(objects) do
            if o[column] ~= nil and o[column] == vStr then
                return Util.copy(o);
            end
        end
    end

    return nil;
end;