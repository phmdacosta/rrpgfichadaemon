require('util.lua')

local dbDir = 'database/'
local lineDelimiter = '\r\n'

SQL = {
    ANSI = 'ansi',
    UTF8 = 'utf8'
}

Content = {
    name = nil,
    rawHeader = nil,
    header = {},
    rawData = {},
    objMap = {}
}

Object = {}

local SEPARATOR = ';'

-- Divide o conteúdo do arquivo em linhas, retornando uma table contendo as linhas.
local function splitLines(s, delimiter)
    local result = {};
    if s ~= nil and delimiter ~= nil then
        for match in (s..delimiter):gmatch("[^"..delimiter.."]+") do
            table.insert(result, match);
        end;
    end;
    return result;
end;

-- Transforma o texto em objeto lua.
local function getObjectFromRaw(rawHeader, rawData)
    local headColumns = Util.split(rawHeader, SEPARATOR)
    local dataColumns = Util.split(rawData, SEPARATOR)
    local obj = Object:new()

    -- Procurar através das colunas
    for j = 1, #headColumns do
        if j <= #dataColumns then
            obj[headColumns[j]] = dataColumns[j]
        end
    end

    return obj;
end

-- Transforma o texto do cabeçalho em uma tabela contendo os titulos das colunas.
local function getHeaderFromRaw(rawHeader)
    local headColumns = Util.split(rawHeader, SEPARATOR)
    local headerTable = {}

    -- Procurar através das colunas
    for j = 1, #headColumns do
        table.insert(headerTable, headColumns[j])
    end

    return headerTable;
end

local function insertObjectIfNotExist(content, data)
    if data == nil then
        return;
    end

    local key = Utils.tableToStr(data)
    
    if content.objMap[key] == nil then
        content.objMap[key] = data;
    end
end

-- Recupera o cabeçalho do conteúdo da table lua
local function getTableHeader(content)
    if content == nil or type(content) ~= 'table' then
        return '';
    end;

    local header = '';

    if content.id == nil then
        header = 'id;';
    end;
    
    local i = 0;
    for k,v in pairs(content) do
        if i > 0 then
            header = header .. ';'
        end;
        header = header .. k;
        i = i + 1;
    end;

    return header
end

-- Tranforma o conteúdo de uma table lua em texto para ser salvo no arquivo CSV.
local function getTableContent(index, content)
    if content == nil or type(content) ~= 'table' then
        return '';
    end;

    local body = '';

    if content.id == nil then
        body = index..';';
    end;
    
    local i = 0;
    for k,v in pairs(content) do
        if i > 0 then
            body = body .. ';'
        end;
        body = body .. v
        i = i + 1;
    end;

    return lineDelimiter..body
end

function SQL.getSeparator()
    return SEPARATOR;
end

function SQL.exists(path)
    return VHD.fileExists(path);
end

-- Lê um arquivo no VHD
function SQL.readFile(fileName, encode)
    if fileName == nil then
        return nil;
    end;

    if encode == nil then
        encode = SQL.ANSI -- encoding padrão é ANSI
    end

    local path = dbDir..fileName;
    local content = nil;
    if SQL.exists(path) then
        local filestream = VHD.openFile(path);

        if(filestream ~= nil) then
            local rawContent = filestream:readBinary(encode);
            local lines = splitLines(rawContent, lineDelimiter);
            content = Content:new();

            -- pagando headers
            content.rawHeader = lines[1];
            content.header = getHeaderFromRaw(lines[1]);

            -- pegando as informações de cada registro
            for i = 2, #lines do
                content.rawData[i-1] = lines[i];
                local obj = getObjectFromRaw(content.rawHeader, lines[i]);
                if obj ~= nil then
                    insertObjectIfNotExist(content, Util.copy(obj));
                end
            end
            filestream:close()
        end;
    end;

    return content;
end;

-- Criar um arquivo no VHD
function SQL.create(fileName)
    local path = dbDir..fileName;
    return VHD.openFile(path, "w+");
end;

-- Salva o conteúdo em um arquivo n VHD
function SQL.save(fileName, content, encoding)
    if fileName == nil or content == nil then
        return;
    end;

    if type(content) == 'table' then
        SQL.saveTable(fileName, content);
        return;
    end;

    SQL.doSave(fileName, content, encoding);
end;

-- Salva o conteúdo de uma table em um arquivo n VHD
function SQL.saveTable(fileName, content, encoding)
    if fileName == nil or content == nil or type(content) ~= 'table' then
        return;
    end;

    local contenTxt = '';

    -- se for array, precisamos criar diferentes linhas com ids
    if Util.isArray(content) then
        for i,v in ipairs(content) do
            local iContTxt = '';
            if i == 1 then
                iContTxt = getTableHeader(v)
            end

            local id = i;
            if v.id ~= nil then
                id = v.id;
            end

            iContTxt = iContTxt .. getTableContent(id, v)
            contenTxt = contenTxt .. iContTxt;
        end
    else
        contenTxt = getTableHeader(content)
        contenTxt = contenTxt .. getTableContent(1, content) -- no caso de um objeto, id será 1
    end;

    --showMessage(contenTxt)

    SQL.doSave(fileName, contenTxt, encoding);
end;

-- Efetua o salvamento do conteúdo no arquivo no VHD
function SQL.doSave(fileName, content, encoding)
    if encoding == nil then
        encoding = SQL.ANSI -- encoding padrão é ANSI
    end;

    local path = dbDir..fileName;
    local filestream = VHD.openFile(path, "w+");
    filestream:writeBinary(encoding, content);
    filestream:close();
end;

-- Recupera a lista de arquivos existentes no VHD
function SQL.listFiles()
    return VHD.enumerateContent('/'..dbDir);
end;

-- Remove um arquivo do VHD
function SQL.deleteFile(fileName)
    VHD.deleteFile(fileName);
end

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

--[[
    Lista todos os registros encontrados.
    A estrutura do objeto de registro é:
        campo -> cabeçalho da coluna
        valor -> informação do registro respectivo à coluna.
        Ex:
            ---------------------
            | id | nome | idade |
            |  1 | José |    33 |
            ---------------------

            objeto = {
                id = 1,
                nome = "José",
                idade = 33
            }
]]
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
            --showMessage(Utils.tableToStr(o))
            if o[column] ~= nil and o[column] == vStr then
                return Util.copy(o);
            end
        end
    end

    return nil;
end;

-- Object functions
function Object:new()
    local newObj = {}
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end;

function Object:equals(o)
    if o == nil or o.id == nil then
        return false
    end
    return Util.toNumber(self.id) == Util.toNumber(o.id)
end

return SQL;