Base = {
    dadoRolagem = '1d100',
    erroCritico = 95
};
Cabecalho = {sheet = nil};

function Cabecalho:setSheet(sheet)
    self.sheet = sheet;
end

function Cabecalho:getSheet()
    return self.sheet;
end

function Base.atualizarIP(sheet, id, ip)
    local updatedSheet = sheet;

    if updatedSheet.ips == nil then
        updatedSheet.ips = {};
    end;

    updatedSheet.ips[id] = ip
    updatedSheet.ip = 0;

    for i, v in pairs(updatedSheet.ips) do
        if v ~= nil then
            updatedSheet.ip = updatedSheet.ip + updatedSheet.ips[i];
        end;
    end;

    return updatedSheet;
end;

function Base.atualizarPV(sheet, id, pv)
    local updatedSheet = sheet;

    if updatedSheet.pvExtra == nil then
        updatedSheet.pvExtra = {};
    end;

    updatedSheet.pvExtra[id] = pv
    updatedSheet.pv = 0;

    for i, v in pairs(updatedSheet.pvExtra) do
        if v ~= nil then
            updatedSheet.pv = updatedSheet.pv + updatedSheet.pvExtra[i];
        end;
    end;

    return updatedSheet;
end;

function Base.atualizarPM(sheet, id, pm)
    local updatedSheet = sheet;

    if updatedSheet.pmExtra == nil then
        updatedSheet.pmExtra = {};
    end;

    updatedSheet.pmExtra[id] = pm
    updatedSheet.pm = 0;

    for i, v in pairs(updatedSheet.pmExtra) do
        if v ~= nil then
            updatedSheet.pm = updatedSheet.pm + updatedSheet.pmExtra[i];
        end;
    end;

    return updatedSheet;
end;

function Base.atualizarPH(sheet, id, ph)
    local updatedSheet = sheet;

    if updatedSheet.phExtra == nil then
        updatedSheet.phExtra = {};
    end;

    updatedSheet.phExtra[id] = ph
    updatedSheet.ph = 0;

    for i, v in pairs(updatedSheet.phExtra) do
        if v ~= nil then
            updatedSheet.ph = updatedSheet.ph + updatedSheet.phExtra[i];
        end;
    end;

    return updatedSheet;
end;

function Base.export(sheet)
    local txt = Text:new();

    local personagem = Firecast.getPersonagemDe(sheet);
    txt:appendLine('Nome: ');
    txt:append(personagem.nome)

    txt:appendLine('Level: ');
    txt:append(sheet.level);
    txt:append('    EXP: ');
    txt:append(sheet.exp);

    txt:appendLine('Idade: ');
    txt:append(sheet.idade);
    txt:appendLine('Sexo: ');
    txt:append(sheet.sexo);
    txt:appendLine('Altura: ');
    txt:append(sheet.altura);
    txt:appendLine('Peso: ');
    txt:append(sheet.peso);

    txt:breakLine();
    txt:appendLine('PV: ');
    txt:append(sheet.pv);
    txt:appendLine('PM: ');
    txt:append(sheet.pm);
    txt:appendLine('IP: ');
    txt:append(sheet.ip);
    txt:appendLine('PH: ');
    txt:append(sheet.ph);

    txt:breakLine();

    txt:appendLine('----- Armadura -----\n');
    txt:appendLine(sheet.descricaoArmadura);
    txt:append('    IP: ');
    txt:append(sheet.ipArmadura);

    return txt:toString();
end;

return Base;