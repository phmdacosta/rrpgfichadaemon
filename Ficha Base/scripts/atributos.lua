require('base.lua');

Atributos = {
    sheet = nil,
    array = {'CON', 'FOR', 'DEX', 'AGI', 'INT', 'WILL', 'PER', 'CAR'},
    default = 'CON',
    prefixCampoAtrib = 'atrib',
    prefixCampoMod = 'modAtrib',
    prefixCampoPercent = 'percentAtrib',
    prefixCampoBonus = 'bonus'
};

function Atributos:setSheet(sheet)
    self.sheet = sheet;
end

function Atributos:getSheet()
    return self.sheet;
end

function Atributos.getTotalAtributo(valorBase, modificador)
    return (tonumber(valorBase) or 0) + (tonumber(modificador) or 0);
end;

function Atributos.getPercentualAtributo(valorBase, modificador)
    local valorTotal = Atributos.getTotalAtributo(valorBase, modificador);
    return valorTotal * 4;
end;

function Atributos.getBonusAtributo(valorBase, modificador)
    local valorTotal = Atributos.getTotalAtributo(valorBase, modificador);
    if valorTotal >= 12 then
        return math.floor(((valorTotal - 12) / 2) + 1);
    end
    return 0;
end;

function Atributos:onChange(sheet, atributo)
    if sheet ~= nil then
        local nomeCampoAtrib = 'atrib' .. atributo;
        local nomeCampoMod = 'modAtrib' .. atributo;
        local nomeCampoPercent = 'percentAtrib' .. atributo;
        local nomeCampoBonus = 'bonus' .. atributo;

        sheet[nomeCampoPercent] = Atributos.getPercentualAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);
		sheet[nomeCampoBonus] = Atributos.getBonusAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);

        if atributo == 'FOR' or atributo == 'CON' then
		    sheet = Atributos.calcularPV(sheet, sheet.level, sheet.percentAtribCON, 
                                                sheet.percentAtribFOR, sheet.bonusCON);
        elseif atributo == 'WILL' then
            sheet = Atributos.calcularPM(sheet, sheet.level, sheet[nomeCampoBonus]);
        end;

        Atributos:setSheet(sheet);
    end;
end;

function Atributos.calcularPV(sheet, level, percentFOR, percentCON, bonusCON)
    local updatedSheet = sheet;

    if percentCON ~= nil then
        local valAtribFor = (tonumber(percentFOR) or 0) / 4;
        local valAtribCon = (tonumber(percentCON) or 0) / 4;
        local resultadoPV = ((valAtribFor + valAtribCon) / 2) 
            + (tonumber(level) or 0) + (tonumber(bonusCON) or 0);
        
        updatedSheet = Base.atualizarPV(sheet, 1, math.floor(resultadoPV));
    end

    return updatedSheet;
end;

function Atributos.calcularPM(sheet, level, bonusWill)
    local updatedSheet = sheet;

    local numLevel = tonumber(level);
    if numLevel == 1 then
        local pm = tonumber(bonusWill) + 1;
        updatedSheet = Base.atualizarPM(sheet, 1, pm);
    end

    return updatedSheet;
end;

function Atributos.efetuarTeste(sheet, atributo)
    local nomeAtrib = atributo;

    local nomePercent = 'percentAtrib' .. atributo;
    local percentAtrib = sheet[nomePercent];
    
    local mesa = Firecast.getMesaDe(sheet);
    mesa.chat:rolarDados("1d100", "Rolando " .. nomeAtrib,
        function(rolagem)
            local resultado = rolagem.resultado;
            if percentAtrib >= resultado then
                local dificil = percentAtrib / 2;
                local critico = percentAtrib / 4;

                if critico >= resultado  then
                    mesa.chat:enviarMensagem("Crítico! " .. resultado);
                elseif dificil >= resultado then
                    mesa.chat:enviarMensagem("Passou no difícil: " .. resultado);
                else
                    mesa.chat:enviarMensagem("Passou: " .. resultado);
                end;
            else
                if resultado >= Base.erroCritico then
                    mesa.chat:enviarMensagem("Erro crítico! " .. resultado);
                else
                    mesa.chat:enviarMensagem("Errou: " .. resultado);
                end;
            end;
        end
    );
end;