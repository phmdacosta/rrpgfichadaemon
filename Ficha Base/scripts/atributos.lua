---@diagnostic disable: trailing-space
local base = require('base.lua');
local constants = require('constants.lua');
local config = require('config.lua');

-- Constantes dos atributos
local atributos = constants.atributos;
local nomeCampos = constants.nomeCampos.atributos;
local pontosIniciais = config.pontosIniciais.atributos;

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
    pontosIniciais = 0,
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

-- Função para inicializar o conteúdo de atributos
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

-- OnChange do campo totalGastoAtrib
function Atributos.onChangeGastoPontos(sheet, form, oldValue, newValue)
    if newValue == nil or newValue <= 0 then
        -- iniciando pontos max de atributos
        sheet.pontosAtribMax = pontosIniciais;
        if sheet.level ~= nil then
            sheet.pontosAtribMax = sheet.pontosAtribMax + (sheet.level);
        end;
    end;

    -- calculando sobra
    sheet.pontosAtribSobra = Base.calcularSobraPontos(sheet.pontosAtribMax, sheet.totalGastoAtrib)

    Atributos:alternarVisibilidadePontosSobra(sheet, form);
end;

-- Inicializando código de base de dados
local sql = require('scripts/sql.lua');

local function getDbFileName(nomeMesa)
    return 'array_atributos_'..nomeMesa..'.csv';
end

--[[
    Carrega o backup dos atributos distribuidos salvos no arquivo CSV no virtual HD.
    Os arquivos CSV do VHD ficam salvos no plugin, assim não possuem ligação direta com a ficha.
    Para evitar algum problema de conflito entre fichas, o arquivo é criado com o nome da ficha.

    @return Objeto table dos atributos salvos.
            Se o objeto da ficha passado como argumento for nil, retorna nil.
]]
local function carregarBackupDB(sheet)
    if sheet == nil then
        return nil;
    end;
    local personagem = Firecast.getPersonagemDe(sheet);
    local mesa = Firecast.getMesaDe(sheet);

    local atribArr = nil;
    if personagem ~= nil and mesa ~= nil then
        --Mensagens:enviarParaMesa(sheet, 'load:')
        --Mensagens:enviarParaMesa(sheet, personagem.nome)
        local fileName = getDbFileName(mesa.nome);
        local atribArrDbContent = sql.readFile(fileName);

        if atribArrDbContent ~= nil then
            atribArr = atribArrDbContent:getObject('personagem', personagem.nome);
            --Mensagens:enviarParaMesa(sheet, Utils.tableToStr(atribArr))
        end;
    end;

    if atribArr == nil then
        atribArr = {}
        if personagem ~= nil then
            atribArr.personagem = personagem.nome;
        end;
        --Mensagens:enviarParaMesa(sheet, Utils.tableToStr(atribArr))
    end;

    return atribArr;
end;

-- Faz o save do array de atributos no arquivo CSV
local function saveBackupDB(sheet, atribArr)
    if sheet == nil then
        return;
    end;

    local mesa = Firecast.getMesaDe(sheet);
    local personagem = Firecast.getPersonagemDe(sheet);
    if mesa ~= nil and personagem ~= nil then
        Mensagens:enviarParaMesa(sheet, 'to save:')
        local fileName = getDbFileName(mesa.nome);
        local dbContent = sql.readFile(fileName);
        local dbItens = {}
        if dbContent ~= nil then
            dbItens = dbContent:getObjects();
            Mensagens:enviarParaMesa(sheet, Utils.tableToStr(atribArr))
            if Util.arrayContains(dbItens, atribArr) then
                Mensagens:enviarParaMesa(sheet, 'contains')
                for i,o in ipairs(dbItens) do
                    if o.personagem == personagem.nome then
                        Mensagens:enviarParaMesa(sheet, 'atualizando objeto')
                        dbItens[i] = atribArr;
                    end;
                end;
            else
                table.insert(dbItens, atribArr);
            end;
        else
            table.insert(dbItens, atribArr);
        end;
        Mensagens:enviarParaMesa(sheet, 'atribArr = '..Utils.tableToStr(atribArr))
        Mensagens:enviarParaMesa(sheet, 'dbItens = '..Utils.tableToStr(dbItens))

        sql.save(getDbFileName(mesa.nome), dbItens);
    end;
end;

-- Remove o arquivo CSV de atributos do VHD
local function deleteBackupFile(sheet)
    if sheet == nil then
        return;
    end;

    local mesa = Firecast.getMesaDe(sheet);
    if mesa ~= nil then
        sql.deleteFile(getDbFileName(mesa.nome));
    end;
end

--[[
    Mesmo que a ficha seja apagada, o arquivo CSV fica salvo no plugin.
    Desta forma, o arquivo só será limpo ou removido se o plugin for desinstalado.
    Essa função serve para limpar o arquivo caso precise.
]]
local function limparBackupDB(sheet, atributo)
    if sheet == nil then
        return;
    end;

    local atribArr = carregarBackupDB(sheet);

    if atribArr == nil then
        return;
    end;

    Mensagens:enviarParaMesa(sheet, 'atribArr = '..Utils.tableToStr(atribArr))
    Mensagens:enviarParaMesa(sheet, 'to clean:')
    if atributo == nil then
        deleteBackupFile(sheet);
    else
        atribArr[atributo] = nil;
    end;
    Mensagens:enviarParaMesa(sheet, 'atribArr = '..Utils.tableToStr(atribArr))

    Mensagens:enviarParaMesa(sheet, 'salvando após limpeza')
    saveBackupDB(sheet, atribArr);
end;

-- Verifica se o array de atributos possui o valor indicado
local function arrayTemAtrib(atribArr, atributo, valor)
    return atribArr[atributo] ~= nil 
        and Util.toNumber(atribArr[atributo]) == Util.toNumber(valor);
end;

-- OnChange dos campos de atributo
function Atributos:onChange(sheet, atributo, form, field, oldValue, newValue)
    --showMessage(atributo)
    --showMessage(field)
    --showMessage(oldValue)
    --showMessage(newValue)

    if sheet == nil then
        return;
    end;

    if newValue == nil then
        newValue = 0;
    end;

    local nomeCampoAtrib = Atributos:getNomeCampoAtrib(atributo);
    local nomeCampoMod = Atributos:getNomeCampoMod(atributo);
    local nomeCampoPercent = Atributos:getNomeCampoPercent(atributo);
    local nomeCampoBonus = Atributos:getNomeCampoBonus(atributo);

    
    if oldValue == nil and field == nomeCampoAtrib then
        local atribArr = carregarBackupDB(sheet);
        if not arrayTemAtrib(atribArr, atributo, newValue) then
            if newValue > 0 then
                -- no caso de um reset do plugin (pode acontecer após atualização ou reinstalação)
                -- verificamos se o atributo continua salvo no VHD.
                -- se não tiver, salvamos.
                atribArr[atributo] = newValue;
                saveBackupDB(sheet, atribArr);
            end;
        end;
    end;

    -- caso o campo alterado seja o campo básico do atributo, iremos gerenciar o gasto
    -- (MOD são bônus)
    if field == nomeCampoAtrib then
        -- para evitar calculos desencessários ou aplicar gastos já feitos antes,
        -- salvamos um backup dos pontos usados em cada atributo em um arquivo CSV no VHD
        local atribArr = carregarBackupDB(sheet);

        -- caso o novo valor seje o mesmo do salvo em base não faz nada
        if arrayTemAtrib(atribArr, atributo, newValue) then
            return;
        end;

        local difValAtrib = Util.toNumber(newValue) - Util.toNumber(oldValue);
        Mensagens:enviarParaMesa(sheet, 'dif: ')
        Mensagens:enviarParaMesa(sheet, difValAtrib)
        local totalGasto = sheet.totalGastoAtrib;
        totalGasto = Util.toNumber(totalGasto) + Util.toNumber(difValAtrib);
        Mensagens:enviarParaMesa(sheet, 'total gasto: ')
        Mensagens:enviarParaMesa(sheet, totalGasto)

        if Util.toNumber(totalGasto) > Util.toNumber(sheet.pontosAtribMax) then
            showMessage('Não é possível distribuir mais de '..sheet.pontosAtribMax..' pontos');
            sheet[field] = atribArr[atributo];            
            return;
        end;

        -- atualizando total gasto e sobra
        sheet.totalGastoAtrib = totalGasto;
        sheet.pontosAtribSobra = Util.toNumber(sheet.pontosAtribMax) - Util.toNumber(sheet.totalGastoAtrib);

        Atributos:alternarVisibilidadePontosSobra(sheet, form);

        -- salvar o novo valor do atributo em base de dados
        atribArr[atributo] = newValue;
        saveBackupDB(sheet, atribArr);
    end;    

    -- atualizando outros campos de atributos
    sheet[nomeCampoPercent] = Atributos.getPercentualAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);
    sheet[nomeCampoBonus] = Atributos.getBonusAtributo(sheet[nomeCampoAtrib], sheet[nomeCampoMod]);

    -- efetuando calculos impactados pelos atributos
    if atributo == atributos.FOR or atributo == atributos.CON then
        sheet = base.calcularPV(sheet);
    elseif atributo == atributos.WILL then
        sheet = base.calcularPM(sheet);
    end;

    Atributos:setSheet(sheet);
end;

-- Efetua teste de rolagem dos atributos
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

-- Alterna a visibilidade da label informativa de pontos de atributos em sobra para serem usados.
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

-- Função que exporta o conteúdo de atributos para texto.
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