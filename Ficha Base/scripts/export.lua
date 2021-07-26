Export={};

local SCRIPTS_PATH = '/scripts'

local SCRIPTS = {
    'base.lua',
    'atributos.lua',
    'armas.lua',
    'aprim.lua',
    'pericias.lua',
    'background.lua'
}

local function getChildList()
    local files = VHD.enumerateContent(SCRIPTS_PATH)

    for _,v in ipairs(files) do
        if v ~= 'export.lua' 
            and (Util.startsWith(v, 'export') or Util.endsWith(v, 'export')) then
                local child = require(SCRIPTS_PATH..'/'..v)
                return child.SCRIPTS
        end
    end
end

function Export:exportToTXT(sheet)
    if sheet ~= nil then
        local scriptList = getChildList()

        if scriptList == nil then
            scriptList = SCRIPTS
        end

        local txt = Text:new()

        for _,v in ipairs(scriptList) do
            local filePath = SCRIPTS_PATH..'/'..v;
            if VHD.fileExists(filePath) then
                local script = require(filePath)
                if script ~= nil and script.export ~= nil then
                    txt:appendLine(script.export(sheet))
                    txt:breakLine()
                end
            end
        end

        sheet.exportTxt = txt:toString()
    end
end