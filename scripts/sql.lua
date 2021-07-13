require('util.lua')

SQL = {}

Content = {
    rawHeader = nil,
    header = {},
    rawData = {},
    objMap = {}
}

Object = {}

local function splitLines(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch(delimiter) do
        table.insert(result, match);
    end
    return result;
end;

local function getObjectFromRaw(rawHeader, rawData)
    local headColumns = Util.split(rawHeader, ";")
    local dataColumns = Util.split(rawData, ";")
    local obj = Object

    -- Search between columns
    for j = 1, #headColumns do
        obj[headColumns[j]] = dataColumns[j]
    end

    return obj;
end

local function getHeaderFromRaw(rawHeader)
    local headColumns = Util.split(rawHeader, ";")
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

function SQL.readFile(path)
    local content = nil;
    if VHD.fileExists(path) then
        local filestream = VHD.openFile(path);

        if(filestream ~= nil) then
            local rawContent = filestream:readBinary("ansi");
            local lines = splitLines(rawContent, "[^\r\n]+");
            content = Content;

            -- setting headers
            Content.rawHeader = lines[1];
            Content.header = getHeaderFromRaw(lines[1]);

            --setting data
            for i = 2, #lines do
                Content.rawData[i-1] = lines[i];
                local obj = getObjectFromRaw(content.rawHeader, lines[i]);
                if obj ~= nil and obj.id ~= nil and obj.nome ~= nil then
                    insertObjectIfNotExist(content, Util.copy(obj));
                end
            end
        end;
    end;
    return content;
end;

-- Content functions
function Content:new()
    self.rawHeader = nil
    self.header = {}
    self.rawData = {}
    self.objMap = {}
    return self
end;

function Content:getObjects()
    local objects = {};
    for _,o in pairs(self.objMap) do
        table.insert(objects, o);
    end
    return objects;
end;


function Content:getObjectById(id)
    return Content:getObject('id', id);
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