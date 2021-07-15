require('sql.lua')
require('util.lua')

local APRIM_DATA_PATH = "database/aprim.csv"

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
        self.dbContent = content;
        local objects = content:getObjects();
        for i = 1, #objects do
            table.insert(self.dbItens, objects[i])
        end;
    end;
end;

function Aprim.getNomeItem(index)
    return "aprim" .. index;
end;

function Aprim:adicionarAprim(sheet, recordList)
    if sheet.listaAprim == nil then
        sheet.listaAprim = {length=0}
    end;

    if self.aprimObservers == nil then
        self.aprimObservers = {length=0}
    end;

    local node = recordList.listAprim:append();

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

function Aprim:alternarVisibilidadeDetalhes(sheetItem)
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

            -- Ordenamos a lista por ordem alfabetica para facilitar a busca do nome
            table.sort(dbItens, function (left, right)
                return left.nome < right.nome;
            end);

            for _,a in ipairs(dbItens) do
                if a.nome == sheetItem.nomeAprim 
                    or string.find(a.nome, sheetItem.nomeAprim) then
                        achou = true;
                        sheetItem.idAprim = a.id;
                        sheetItem.nomeAprim = a.nome;
                        sheetItem.descricaoAprim = a.descricao;
                        break;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar o aprimoramento \''..sheetItem.nomeAprim
                            ..'\'. Verifique se o nome está escrito corretamente com todas as pontuações e acentos');
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
                    and tonumber(a.pontos) == tonumber(sheetItem.pontosAprim) then
                        achou = true;
                        sheetItem.idAprim = a.id;
                        sheetItem.nomeAprim = a.nome;
                        sheetItem.descricaoAprim = a.pontos.." ponto(s): "..a.descricao;

                        --[[
                            Cada aprimoramento é dividido pelos pontos na base de dados (cada ponto diferente é um registro diferente).
                            Desta forma precisamos procurar os outros registros deste aprimoramento para exibir uma descrição completa.
                            Cada aprimoramento tem um campo chamado id_ref_aprim que contém o id dos pontos anteriores.
                        ]]
                        if a.id_ref_aprim ~= nil and tonumber(a.id_ref_aprim) > 0 then
                            local parents =  Aprim:getAllParents(dbContent, a.id);
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
                                        O textEdit por algum motivo está escondendo o final do texto.
                                        Incluindo algumas quebras de linha geramos espaço para que o 
                                        componente possa cortar sem cortar informações do texto.
                                    ]]
                                    if not Util.endsWith(sheetItem.descricaoAprim, '\n\n\n') then
                                        sheetItem.descricaoAprim = sheetItem.descricaoAprim..'\n\n\n'
                                    end;
                                end
                            end;
                        end;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar o aprimoramento '..sheetItem.nomeAprim..' custando '..sheetItem.pontosAprim..' pontos');
            end
    end;
end;

function Aprim:getAllParents(dbContent, childId)
    local parents = nil;

    if childId ~= nil then
        local c = dbContent:getObjectById(childId);

        if c ~= nil then
            if c.id_ref_aprim ~= nil then
                parents = {}
            end
    
            repeat
                local parent = dbContent:getObjectById(c.id_ref_aprim);
                if parent ~= nil then
                    table.insert(parents, parent);
                    c = Util.copy(parent);
                end;
            until c == nil or c.id_ref_aprim == nil or c.id_ref_aprim == '' or c.id_ref_aprim == '0'
        end;
    end;

    return parents;
end;