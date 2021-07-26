Background={}

function Background.export(sheet)
    local txt = Text:new()
    txt:appendLine('----- Background -----')

    if sheet.backgroundTxt ~= nil 
        and sheet.backgroundTxt.p ~= nil 
        and sheet.backgroundTxt.p.e ~= nil then
            txt:breakLine()
            txt:appendLine(sheet.backgroundTxt.p.e.text)
    end
    
    return txt:toString()
end

return Background