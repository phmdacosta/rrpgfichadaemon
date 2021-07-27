local constants = require('constants.lua');

local nomeCampos = constants.nomeCampos.cabecalho;

Cabecalho = {sheet = nil};

Base = {
    dadoRolagem = '1d100',
    erroCritico = 95,
    cabecalho = Cabecalho,
    nomeCampos = nomeCampos
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

function Base.aplicarLvl(sheet)
    -- atualizar PV
    Base.atualizarPV(sheet, nomeCampos.level, sheet[nomeCampos.level]); -- adicionando level ao cálculo
    Base.calcularPV(sheet);

    -- atualizar PM
    Base.atualizarPM(sheet, nomeCampos.level, sheet[nomeCampos.level]); -- adicionando level ao cálculo
    Base.calcularPM(sheet);

    -- atualizar pontos heróicos
    Base.atualizarPH(sheet, nomeCampos.level, sheet[nomeCampos.level]);
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
    if sheet[campo] > sheet[campoMax] then
        sheet[campo] = tonumber(sheet[campoMax])
    end;
end;

function Base.calcularPV(sheet)
    local updatedSheet = sheet;
    local atributos = constants.atributos;
    local level = sheet[nomeCampos.level];

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
    local level = sheet[nomeCampos.level]

    local numLevel = tonumber(level);
    if numLevel == 1 then
        local pm = (tonumber(sheet[Atributos:getNomeCampoBonus(atributos.WILL)]) or 0) + 1;
        updatedSheet = Base.atualizarPM(sheet, 'atrib', pm);
    end

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
        if v ~= nil and k ~= nomeCampos.level then
            updatedSheet.phMax = updatedSheet.phMax + v;
        end;
    end;

    if updatedSheet.phExtra[nomeCampos.level] ~= nil then
        updatedSheet.phMax = updatedSheet.phMax * updatedSheet.phExtra[nomeCampos.level];
    end;

    if (updatedSheet.firstUpdatePH == nil 
        and not updatedSheet.firstUpdatePH)
        or tonumber(updatedSheet.ph) >= tonumber(updatedSheet.phMax) then
            updatedSheet.ph = updatedSheet.phMax;
            updatedSheet.firstUpdatePH = true;
    end;

    return updatedSheet;
end;

function Base.export(sheet)
    local txt = Text:new();

    local personagem = Firecast.getPersonagemDe(sheet);
    txt:appendLine('Nome: ');
    txt:append(personagem.nome)

    txt:appendLine('Level: ');
    txt:append(sheet[nomeCampos.level]);
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