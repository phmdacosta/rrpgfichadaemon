local constants = require('constants.lua');

local nomeCamposCabecalho = constants.nomeCampos.cabecalho;
local nomeCampoLevel = nomeCamposCabecalho.level;

Cabecalho = {
    sheet = nil,
    nomeCampos = nomeCamposCabecalho,
};

Base = {
    dadoRolagem = '1d100',
    erroCritico = 95,
    cabecalho = Cabecalho,
    nomeCampos = nomeCamposCabecalho,
    dbContent = nil
};

function Cabecalho:init(sheet)
    self.sheet = sheet;

    sheet.pvExtra = nil;
    sheet.pmExtra = nil;
    sheet.phExtra = nil;
    sheet.ips = nil;
end

function Cabecalho:setSheet(sheet)
    self.sheet = sheet;
end

function Cabecalho:getSheet()
    return self.sheet;
end;

function Base:carregarTabelaLvlExp()

    local content = SQL.readFile('level_exp.csv');
    if content ~= nil then
        content.name = 'db_level_exp';
        self.dbContent = Util.copy(content);
    end;
end;

function Base:getDBContent()
    return self.dbContent;
end

--[[
    Atualiza a ficha com base na alteração do nível do personagem.
]]
function Base.aplicarLvl(sheet, form, oldValue, newValue)
    -- atualizar PV
    Base.atualizarPV(sheet, nomeCampoLevel, sheet[nomeCampoLevel]); -- adicionando level ao cálculo
    Base.calcularPV(sheet);

    -- atualizar PM
    Base.atualizarPM(sheet, nomeCampoLevel, sheet[nomeCampoLevel]); -- adicionando level ao cálculo
    Base.calcularPM(sheet);

    -- atualizar pontos heróicos
    Base.atualizarPH(sheet, nomeCampoLevel, sheet[nomeCampoLevel]);

    -- Mais um ponto de atributo
    if oldValue ~= nil and newValue ~= nil then
        local add = Util.toNumber(newValue) - Util.toNumber(oldValue);

        sheet.pontosAtribMax = Util.toNumber(sheet.pontosAtribMax) + add;
        sheet.pontosAtribSobra = Util.toNumber(sheet.pontosAtribMax) - Util.toNumber(sheet.totalGastoAtrib);

        Atributos:alternarVisibilidadePontosSobra(sheet, form);
    end;

end;

--[[
    Atualiza o nível com base na experiência ganha.
    Lê uma tabela de esperiência e verifica se o personagem alcançou a pontuação necessária para subir de nível.
    Caso tenha, atualiza o nível de forma automática
]]
function Base:verificarExp(sheet, oldValue, newValue)
    if sheet == nil or oldValue == nil or newValue == nil then
        return;
    end;

    local dbContent = Base:getDBContent();
    if dbContent == nil then
        return;
    end;

    local objects = dbContent:getObjects();
    
    for i = 1, #objects do
        local obj = objects[i];
        if tonumber(oldValue) < tonumber(obj.exp) 
            and tonumber(newValue) >= tonumber(obj.exp)
            and sheet[nomeCampoLevel] ~= obj.level then
                sheet[nomeCampoLevel] = obj.level;
        end;
    end;
end;

function Base.atualizarIP(sheet, key, ip)
    local updatedSheet = sheet;

    if updatedSheet.ips == nil then
        updatedSheet.ips = {};
    end;

    updatedSheet.ips[key] = ip
    updatedSheet.ip = 0;

    for k, v in pairs(updatedSheet.ips) do
        if v ~= nil then
            updatedSheet.ip = updatedSheet.ip + updatedSheet.ips[k];
        end;
    end;

    return updatedSheet;
end;

function Base.corrigirValor(sheet, campo)
    local campoMax = campo..'Max'
    if Util.toNumber(sheet[campo]) > Util.toNumber(sheet[campoMax]) then
        sheet[campo] = tonumber(sheet[campoMax])
    end;
end;

function Base.calcularPV(sheet)
    local updatedSheet = sheet;
    local atributos = constants.atributos;
    local level = sheet[nomeCampoLevel];

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

function Base.calcularPM(sheet)
    local updatedSheet = sheet;
    local atributos = constants.atributos;
    local level = sheet[nomeCampoLevel]

    if sheet == nil and level == nil then
        return updatedSheet;
    end;

    local pm = (tonumber(sheet[Atributos:getNomeCampoBonus(atributos.WILL)]) or 0);
    updatedSheet = Base.atualizarPM(sheet, 'atrib', pm);

    return updatedSheet;
end;

function Base.atualizarPV(sheet, key, pv)
    local updatedSheet = sheet;

    if updatedSheet.pvExtra == nil then
        updatedSheet.pvExtra = {};
    end;

    updatedSheet.pvExtra[key] = pv
    updatedSheet.pvMax = 0;

    for k, v in pairs(updatedSheet.pvExtra) do
        if v ~= nil then
            updatedSheet.pvMax = updatedSheet.pvMax + v;
        end;
    end;

    if (updatedSheet.firstUpdatePV == nil 
        and not updatedSheet.firstUpdatePV) 
        or tonumber(updatedSheet.pv) >= tonumber(updatedSheet.pvMax) then
            updatedSheet.pv = updatedSheet.pvMax;
            updatedSheet.firstUpdatePV = true;
    end;

    return updatedSheet;
end;

function Base.atualizarPM(sheet, key, pm)
    local updatedSheet = sheet;

    if updatedSheet.pmExtra == nil then
        updatedSheet.pmExtra = {};
    end;

    updatedSheet.pmExtra[key] = pm
    updatedSheet.pmMax = 0;

    for k, v in pairs(updatedSheet.pmExtra) do
        if v ~= nil then
            updatedSheet.pmMax = updatedSheet.pmMax + v;
        end;
    end;

    if (updatedSheet.firstUpdatePM == nil 
        and not updatedSheet.firstUpdatePM)
        or tonumber(updatedSheet.pm) >= tonumber(updatedSheet.pmMax) then
            updatedSheet.pm = updatedSheet.pmMax;
            updatedSheet.firstUpdatePM = true;
    end;

    return updatedSheet;
end;

function Base.atualizarPH(sheet, key, ph)
    local updatedSheet = sheet;

    if updatedSheet.phExtra == nil then
        updatedSheet.phExtra = {};
    end;

    updatedSheet.phExtra[key] = ph
    updatedSheet.phMax = 0;

    for k, v in pairs(updatedSheet.phExtra) do
        if v ~= nil and k ~= nomeCampoLevel then
            updatedSheet.phMax = updatedSheet.phMax + v;
        end;
    end;

    if updatedSheet.phExtra[nomeCampoLevel] ~= nil then
        updatedSheet.phMax = updatedSheet.phMax * updatedSheet.phExtra[nomeCampoLevel];
    end;

    if (updatedSheet.firstUpdatePH == nil 
        and not updatedSheet.firstUpdatePH)
        or tonumber(updatedSheet.ph) >= tonumber(updatedSheet.phMax) then
            updatedSheet.ph = updatedSheet.phMax;
            updatedSheet.firstUpdatePH = true;
    end;

    return updatedSheet;
end;

function Base.calcularSobraPontos(pontosMax, totalGasto)
    if totalGasto == nil or totalGasto <= 0 then
        return pontosMax;
    elseif totalGasto < pontosMax then
        return Util.toNumber(pontosMax) - Util.toNumber(totalGasto);
    end;

    return 0;
end

function Base.export(sheet)
    local txt = Text:new();

    local personagem = Firecast.getPersonagemDe(sheet);
    txt:appendLine('Nome: ');
    txt:append(personagem.nome)

    txt:appendLine('Level: ');
    txt:append(sheet[nomeCampoLevel]);
    txt:append('    EXP: ');
    txt:append(sheet.exp);

    txt:appendLine('Idade: ');
    txt:append(sheet.idade);
    txt:appendLine('Sexo: ');
    txt:append(sheet.sexo);
    txt:appendLine('Altura: ');
    txt:append(sheet.altura);
    txt:append(' ');
    txt:append(sheet.medidaAltura);
    txt:appendLine('Peso: ');
    txt:append(sheet.peso);
    txt:append(' ');
    txt:append(sheet.medidaPeso);

    txt:breakLine();
    txt:appendLine('PV: ');
    txt:append(sheet.pv);
    txt:append(' / ');
    txt:append(sheet.pvMax);
    txt:appendLine('PM: ');
    txt:append(sheet.pm);
    txt:append(' / ');
    txt:append(sheet.pmMax);
    txt:appendLine('IP: ');
    txt:append(sheet.ip);
    txt:appendLine('PH: ');
    txt:append(sheet.ph);
    txt:append(' / ');
    txt:append(sheet.phMax);

    txt:breakLine();

    txt:appendLine('----- Armadura -----\n');
    txt:appendLine(sheet.descricaoArmadura);
    txt:append('    IP: ');
    txt:append(sheet.ipArmadura);

    return txt:toString();
end;

return Base;