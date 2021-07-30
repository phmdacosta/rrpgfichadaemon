local base = require('base.lua');
local constants = require('constants.lua');

local atributos = constants.atributos;
local nomeCampos = constants.nomeCampos.atributos;
local PONTOS_INICIAIS = 100;

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
    nomeCampos = nomeCampos
};

function Atributos:init(sheet)
    Atributos:setSheet(sheet);
end

function Atributos:getNomeCampoAtrib(atributo)
    if atributo ~= nil then
        return nomeCampos.prefixAtrib .. atributo;
    end
end

function Atributos:getNomeCampoMod(atributo)
    if atributo ~= nil then
        return nomeCampos.prefixMod .. atributo;
    end
end

function Atributos:getNomeCampoPercent(atributo)
    if atributo ~= nil then
        return nomeCampos.prefixPercent .. atributo;
    end
end

function Atributos:getNomeCampoBonus(atributo)
    if atributo ~= nil then
        return nomeCampos.prefixBonus .. atributo;
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

function Atributos.onChangePontosAtribMax(sheet, form, oldValue, newValue)
    if newValue <= 0 or newValue == nil then
        -- iniciando pontos max de atributos
        sheet.pontosAtribMax = PONTOS_INICIAIS;
        if sheet.level ~= nil then
            sheet.pontosAtribMax = sheet.pontosAtribMax + (sheet.level);
        end;
    end;

    -- calculando sobra
    if sheet.totalGastoAtrib < 0 then
        sheet.pontosAtribSobra = sheet.pontosAtribMax;
    elseif sheet.totalGastoAtrib < sheet.pontosAtribMax then
        sheet.pontosAtribSobra = Util.toNumber(sheet.pontosAtribMax) - Util.toNumber(sheet.totalGastoAtrib);
    end;

    Atributos:alternarVisibilidadePontosSobra(sheet, form);
end

function Atributos:onChange(sheet, atributo, form, field, oldValue, newValue)
    if sheet == nil or oldValue == nil or oldValue == newValue then
        return;
    end;

    if newValue == nil then
        if sheet[field] ~= nil then
            sheet[field] = 0;
        end;
        return;
    end;

    local sql = require('scripts/sql.lua');
    local fileName = 'array_atributos.csv';
    local atribArrDbContent = sql.readFile(fileName);
    local atribArr = nil;
    if atribArrDbContent ~= nil then
        atribArr = atribArrDbContent:getObjects()[1]; -- só deveremos ter um objeto
    end;

    if atribArr == nil then
        atribArr = {}
    end;

    -- caso o novo valor seje o mesmo do salvo em base não faz nada
    if atribArr[atributo] ~= nil 
        and Util.toNumber(atribArr[atributo]) == Util.toNumber(newValue) then
            return;
    end

    local difValAtrib = Util.toNumber(newValue) - Util.toNumber(oldValue);
    local totalGasto = sheet.totalGastoAtrib;
    totalGasto = Util.toNumber(totalGasto) + Util.toNumber(difValAtrib);

    if Util.toNumber(totalGasto) > Util.toNumber(sheet.pontosAtribMax) then
        showMessage('Não é possível distribuir mais de '..sheet.pontosAtribMax..' pontos');
        sheet[field] = oldValue;
        return;
    end;

    -- atualizando total gasto e sobra
    sheet.totalGastoAtrib = totalGasto;
    sheet.pontosAtribSobra = Util.toNumber(sheet.pontosAtribMax) - Util.toNumber(sheet.totalGastoAtrib);

    local nomeCampoAtrib = Atributos:getNomeCampoAtrib(atributo);
    local nomeCampoMod = Atributos:getNomeCampoMod(atributo);
    local nomeCampoPercent = Atributos:getNomeCampoPercent(atributo);
    local nomeCampoBonus = Atributos:getNomeCampoBonus(atributo);

    -- atualizando outros campos de atributos
    sheet[nomeCampoPercent] = Atributos.getPercentualAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);
    sheet[nomeCampoBonus] = Atributos.getBonusAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);

    -- efetuando calculos impactados pelos atributos
    if atributo == atributos.FOR or atributo == atributos.CON then
        sheet = base.calcularPV(sheet);
    elseif atributo == atributos.WILL then
        sheet = base.calcularPM(sheet);
    end;

    Atributos:alternarVisibilidadePontosSobra(sheet, form);

    -- salvar o novo valor do atributo em base de dados
    atribArr[atributo] = newValue;
    sql.save(fileName, atribArr);

    Atributos:setSheet(sheet);
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
                if resultado >= base.erroCritico then
                    mesa.chat:enviarMensagem("Erro crítico! " .. resultado);
                else
                    mesa.chat:enviarMensagem("Errou: " .. resultado);
                end;
            end;
        end
    );
end;

function Atributos:alternarVisibilidadePontosSobra(sheet, form)
    if form.pontoAtribSobraText ~= nil then
        if Util.toNumber(sheet.pontosAtribSobra) > 0 then
            sheet.pontoAtribSobraText = Mensagens:criarMensagemPontosSobrando(sheet.pontosAtribSobra);
            form.pontoAtribSobraText.visible = true;
        else
            form.pontoAtribSobraText.visible = false;
        end;
    end;
end

function Atributos.export(sheet)
    local txt = Text:new();
    txt:appendLine('----- Atributos -----\n');

    for _,v in ipairs(arrayAtrib) do
        txt:appendLine(sheet[nomeCampos.prefixLabel..v]);
        txt:append('    ');
        txt:append(sheet[Atributos:getNomeCampoAtrib(v)]);
        txt:append(' / ');
        txt:append(sheet[Atributos:getNomeCampoMod(v)]);
        txt:append(' / ');
        txt:append(sheet[Atributos:getNomeCampoPercent(v)]);
    end;

    return txt:toString();
end;

return Atributos;