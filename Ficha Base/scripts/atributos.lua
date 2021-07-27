local base = require('base.lua');
local constants = require('constants.lua');

local atributos = constants.atributos;

local arrayAtrib = {
    atributos.CON,
    atributos.FOR,
    atributos.DEX,
    atributos.AGI,
    atributos.INT,
    atributos.WILL,
    atributos.PER,
    atributos.CAR
};

Atributos = {
    sheet = nil,
    CON = atributos.CON,
    FOR = atributos.FOR,
    DEX = atributos.DEX,
    AGI = atributos.AGI,
    INT = atributos.INT,
    WILL = atributos.WILL,
    PER = atributos.PER,
    CAR = atributos.CAR,
    array = arrayAtrib,
    default = atributos.CON,
    prefixCampoAtrib = 'atrib',
    prefixCampoMod = 'modAtrib',
    prefixCampoPercent = 'percentAtrib',
    prefixCampoBonus = 'bonus'
};

function Atributos:getNomeCampoAtrib(atributo)
    if atributo ~= nil then
        return self.prefixCampoAtrib .. atributo;
    end
end

function Atributos:getNomeCampoMod(atributo)
    if atributo ~= nil then
        return self.prefixCampoMod .. atributo;
    end
end

function Atributos:getNomeCampoPercent(atributo)
    if atributo ~= nil then
        return self.prefixCampoPercent .. atributo;
    end
end

function Atributos:getNomeCampoBonus(atributo)
    if atributo ~= nil then
        return self.prefixCampoBonus .. atributo;
    end
end

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
        local nomeCampoAtrib = Atributos:getNomeCampoAtrib(atributo);
        local nomeCampoMod = Atributos:getNomeCampoMod(atributo);
        local nomeCampoPercent = Atributos:getNomeCampoPercent(atributo);
        local nomeCampoBonus = Atributos:getNomeCampoBonus(atributo);

        sheet[nomeCampoPercent] = Atributos.getPercentualAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);
		sheet[nomeCampoBonus] = Atributos.getBonusAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);

        if atributo == atributos.FOR or atributo == atributos.CON then
		    sheet = base.calcularPV(sheet);
        elseif atributo == atributos.WILL then
            sheet = base.calcularPM(sheet);
        end;

        Atributos:setSheet(sheet);
    end;
end;

--[[
function Atributos.calcularPV(sheet, level)
    local updatedSheet = sheet;

    if sheet ~= nil and level ~= nil then
        -- Obetemos o valor do atributo com base no percentual para recuperar o total atributo + mod
        local valAtribFor = (tonumber(sheet[Atributos:getNomeCampoPercent(atributos.FOR)]) or 0) / 4;
        local valAtribCon = (tonumber(sheet[Atributos:getNomeCampoPercent(atributos.CON)]) or 0) / 4;
        local resultadoPV = ((valAtribFor + valAtribCon) / 2) 
            + ((tonumber(sheet[Atributos:getNomeCampoBonus(atributos.CON)]) or 0) * (tonumber(level) or 0));

        updatedSheet = Base.atualizarPV(sheet, 'atrib', math.floor(resultadoPV));
    end;

    return updatedSheet;
end;

function Atributos.calcularPM(sheet, level)
    local updatedSheet = sheet;

    local numLevel = tonumber(level);
    if numLevel == 1 then
        local pm = (tonumber(sheet[Atributos:getNomeCampoBonus(atributos.WILL)]) or 0) + 1;
        updatedSheet = Base.atualizarPM(sheet, 'atrib', pm);
    end

    return updatedSheet;
end;
]]

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
                if resultado >= base.erroCritico then
                    mesa.chat:enviarMensagem("Erro crítico! " .. resultado);
                else
                    mesa.chat:enviarMensagem("Errou: " .. resultado);
                end;
            end;
        end
    );
end;

function Atributos.export(sheet)
    local txt = Text:new();
    txt:appendLine('----- Atributos -----\n');

    local campoLabel = 'labelAtrib'
    local campoValor = 'atrib'
    local campoMod = 'modAtrib'
    local campoPerc = 'percentAtrib'

    --local atributos = {'CON','FOR','DEX','AGI','INT','WILL','PER','CAR'};

    for _,v in ipairs(arrayAtrib) do
        txt:appendLine(sheet[campoLabel..v]);
        txt:append('    ');
        txt:append(sheet[campoValor..v]);
        txt:append(' / ');
        txt:append(sheet[campoMod..v]);
        txt:append(' / ');
        txt:append(sheet[campoPerc..v]);
    end;

    return txt:toString();
end;

return Atributos;