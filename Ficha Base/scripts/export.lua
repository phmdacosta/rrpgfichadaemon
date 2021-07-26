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

function Export:exportToTXT(sheet)
    if sheet ~= nil then
        local txt = Text:new()

        for _,v in ipairs(SCRIPTS) do
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