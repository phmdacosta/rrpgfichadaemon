require('sql.lua')
require('util.lua')

local APRIM_DATA_PATH = "aprim.csv"

Aprim = {
    sheet = nil,
    form = nil,
    aprimObservers = nil,
    dbItens = {},
    dbContent = nil
}

function Aprim:setSheet(sheet)
    self.sheet = sheet;
end

function Aprim:getSheet()
    return self.sheet;
end

function Aprim:setForm(form)
    self.form = form;
end

function Aprim:getForm()
    return self.form;
end

function Aprim:getDBItens()
    return self.dbItens;
end

function Aprim:getDBContent()
    return self.dbContent;
end

function Aprim.lerArquivoDeDados()
    return  SQL.readFile(APRIM_DATA_PATH);
end;

function Aprim:carregarTodos()
    self.dbItens = {}

    local content = Aprim.lerArquivoDeDados();
    if content ~= nil then
        content.name = 'db_aprim';
        self.dbContent = Util.copy(content);
        local objects = content:getObjects();
        for i = 1, #objects do
            table.insert(self.dbItens, objects[i])
        end;
    end;
end;

function Aprim.getNomeItem(index)
    return "aprim" .. index;
end;

function Aprim:adicionarAprim(sheet, form)
    if sheet.listaAprim == nil then
        sheet.listaAprim = {length=0}
    end;

    if self.aprimObservers == nil then
        self.aprimObservers = {length=0}
    end;

    local node = form.listAprim:append();

    if node ~= nil then
        sheet.listaAprim.length = sheet.listaAprim.length + 1;

        node.id = sheet.listaAprim.length;
        local nomeNodo1 = self.getNomeItem(node.id);
        sheet.listaAprim[nomeNodo1] = node;

        self.aprimObservers[node.id] = NDB.newObserver(node);
        self.aprimObservers[node.id].onChanged = 
                    function(nodo, attribute, oldValue)
                        local nomeNodo2 = self.getNomeItem(nodo.id);
                        sheet.listaAprim[nomeNodo2] = nodo;
                    end;
    end;
end;

function Aprim.removerAprim(sheet, node)
    if sheet ~= nil 
        and sheet.listaAprim ~= nil 
        and node ~= nil then
            local nomeNodo = Aprim.getNomeItem(node.id);
            sheet.listaAprim[nomeNodo] = nil;
            sheet.listaAprim.length = sheet.listaAprim.length - 1;
    end;
end;

function Aprim:alternarVisibilidadeDetalhes()
    local parentForm = Aprim:getForm();

    if parentForm.boxDetalhesAprim.node == parentForm.listAprim.selectedNode then
        parentForm.boxDetalhesAprim.visible = not parentForm.boxDetalhesAprim.visible;
    else
        parentForm.boxDetalhesAprim.node = parentForm.listAprim.selectedNode;
        parentForm.boxDetalhesAprim.visible = true;
    end
end;

function Aprim:procurar(aprim)
    local dbItens = Aprim:getDBItens();

    for _,a in ipairs(dbItens) do
        if a.nome == aprim then
            return a;
        end;
    end;

    return nil;
end

function Aprim:procurarAprim(sheetItem)
    if sheetItem ~= nil 
        and sheetItem.nomeAprim ~= nil 
        and sheetItem.nomeAprim ~= '' then

            local achou = false;
            local dbItens = Aprim:getDBItens();

            -- Ordenamos a lista por ordem alfabetica e pontos para facilitar a busca do nome
            Util.orderTableAsc(dbItens, 'nome');

            for _,a in ipairs(dbItens) do
                if (a.nome == sheetItem.nomeAprim 
                    or string.find(a.nome, sheetItem.nomeAprim))
                    and a.pontos ~= nil and tonumber(a.pontos) > 0 then
                        achou = true;
                        sheetItem.idAprim = a.id;
                        sheetItem.nomeAprim = a.nome;
                        sheetItem.descricaoAprim = a.descricao;
                        break;
                end;
            end;

            if not achou then
                showMessage('N??o foi poss??vel encontrar o aprimoramento \''..sheetItem.nomeAprim
                            ..'\'. Verifique se o nome est?? escrito corretamente com todas as pontua????es e acentos');
            end
    end;
end;

function Aprim:atualizarComPontos(sheetItem)
    if sheetItem ~= nil 
        and sheetItem.pontosAprim ~= nil 
        and sheetItem.pontosAprim ~= '' then

            local achou = false;
            local dbContent = Aprim:getDBContent();
            local dbItens = dbContent:getObjects();

            for _,a in ipairs(dbItens) do
                if a.nome == sheetItem.nomeAprim 
                    and tonumber(a.pontos) == tonumber(sheetItem.pontosAprim) 
                    and tonumber(a.pontos) > 0 then
                        achou = true;
                        sheetItem.idAprim = a.id;
                        sheetItem.nomeAprim = a.nome;
                        sheetItem.descricaoAprim = a.pontos.." ponto(s): "..a.descricao;

                        --[[
                            Cada aprimoramento ?? dividido pelos pontos na base de dados (cada ponto diferente ?? um registro diferente).
                            Desta forma precisamos procurar os outros registros deste aprimoramento para exibir uma descri????o completa.
                            Cada aprimoramento tem um campo chamado id_ref_aprim que cont??m o id dos pontos anteriores.
                        ]]
                        local refFieldName = 'id_ref_aprim';
                        if a[refFieldName] ~= nil and tonumber(a[refFieldName]) > 0 then
                            local parents =  Aprim:getAllParents(dbContent, a.id, refFieldName);

                            for _,p in ipairs(parents) do
                                if p.descricao == '' then
                                    sheetItem.descricaoAprim = p.descricao..sheetItem.descricaoAprim;
                                else
                                    if p.pontos ~= nil and p.pontos ~= '0' and p.pontos ~= '' then
                                        sheetItem.descricaoAprim = p.pontos.." ponto(s): "..p.descricao..'\n'..sheetItem.descricaoAprim;
                                    else
                                        sheetItem.descricaoAprim = p.descricao..'\n'..sheetItem.descricaoAprim;
                                    end;

                                    --[[
                                        O textEdit por algum motivo est?? escondendo o final do texto.
                                        Incluindo algumas quebras de linha geramos espa??o para que o 
                                        componente possa cortar sem cortar informa????es do texto.
                                    ]]
                                    if not Util.endsWith(sheetItem.descricaoAprim, '\n\n\n') then
                                        sheetItem.descricaoAprim = sheetItem.descricaoAprim..'\n\n\n'
                                    end;
                                end
                            end;
                        end;

                        -- Alguns aprimoramentos podem influenciar em campos na ficha
                        local max = 10
                        for i = 1, max do
                            local colCampo = 'campo'..i
                            local colValor = 'valor'..i
                            if a[colCampo] ~= nil and a[colCampo] ~= '' then
                                Aprim:atualizarCampo(a[colValor], a[colCampo]);
                            end;
                        end;
                end;
            end;

            if not achou then
                showMessage('N??o foi poss??vel encontrar o aprimoramento '..sheetItem.nomeAprim..' custando '..sheetItem.pontosAprim..' pontos');
            end
    end;
end;

function Aprim:getAllParents(dbContent, childId, refFieldName)
    local parents = {};

    if childId ~= nil then
        local c = dbContent:getObjectById(childId);
        if c ~= nil and c[refFieldName] ~= nil then
            repeat
                local parent = dbContent:getObjectById(c[refFieldName]);
                if parent ~= nil then
                    table.insert(parents, parent);
                    c = Util.copy(parent);
                end;
            until c == nil or c[refFieldName] == nil 
                    or c[refFieldName] == '' or c[refFieldName] == '0';
        end;
    end;

    return parents;
end;

function Aprim:atualizarCampo(valor, campo)
    local sheet = Aprim:getSheet();

    local scriptName = 'base';
    local separadorCampo = '::';
    
    if string.find(campo, separadorCampo) then
        local strArr = Util.split(campo, separadorCampo);
        scriptName = strArr[1];
        campo = strArr[2];
    end;

    local script = require('scripts/'..scriptName..'.lua');

    if script ~= nil then
        local funcUpper = 'atualizar'..string.upper(campo);
        local funcCapt = 'atualizar'..Util.capitalize(campo);

        if script[funcCapt] ~= nil then
            script[funcCapt](sheet, 'aprim', tonumber(valor))
        elseif script[funcUpper] ~= nil then
            script[funcUpper](sheet, 'aprim', tonumber(valor))
        end;
    end;
 end;

function Aprim.export(sheet)
    local txt = Text:new();
    txt:appendLine('----- Aprimoramentos -----\n');

    if sheet.listaAprim ~= nil then
        for k,_ in pairs(sheet.listaAprim) do
            local aprim = sheet.listaAprim[k];
            if aprim ~= nil 
                and Util.isTable(aprim) 
                and aprim.nomeAprim ~= nil then
                    txt:appendLine(aprim.nomeAprim)
                    txt:append(' ')
                    txt:append(aprim.pontosAprim)
            end;
        end;
    end;

    return txt:toString();
end;

return Aprim;