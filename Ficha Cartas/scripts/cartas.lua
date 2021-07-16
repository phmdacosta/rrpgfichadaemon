require('sql.lua')
require('util.lua')

local CARTAS_DATA_PATH = "database/cartas.csv"

Cartas = {
    sheet = nil,
    form = nil,
    cartasObservers = nil,
    dbItens = {},
    dbContent = nil
}

function Cartas:setSheet(sheet)
    self.sheet = sheet;
end

function Cartas:getSheet()
    return self.sheet;
end

function Cartas:setForm(form)
    self.form = form;
end

function Cartas:getForm()
    return self.form;
end

function Cartas:getDBItens()
    return self.dbItens;
end

function Cartas:getDBContent()
    return self.dbContent;
end

function Cartas.lerArquivoDeDados()
    return  SQL.readFile(CARTAS_DATA_PATH);
end;

function Cartas:carregarTodos()
    self.dbItens = {}

    local content = Cartas.lerArquivoDeDados();
    if content ~= nil then
        self.dbContent = content;
        local objects = content:getObjects();
        for i = 1, #objects do
            table.insert(self.dbItens, objects[i])
        end;
    end;
end;

function Cartas.getNomeItem(index)
    return "carta" .. index;
end;

function Cartas:adicionarCartas(sheet, recordList)
    if sheet.listaCartas == nil then
        sheet.listaCartas = {length=0}
    end;

    if self.cartasObservers == nil then
        self.cartasObservers = {length=0}
    end;

    local node = recordList.listCartas:append();

    if node ~= nil then
        sheet.listaCartas.length = sheet.listaCartas.length + 1;

        node.id = sheet.listaCartas.length;
        local nomeNodo1 = self.getNomeItem(node.id);
        sheet.listaCartas[nomeNodo1] = node;

        self.cartasObservers[node.id] = NDB.newObserver(node);
        self.cartasObservers[node.id].onChanged = 
                    function(nodo, attribute, oldValue)
                        local nomeNodo2 = self.getNomeItem(nodo.id);
                        sheet.listaCartas[nomeNodo2] = nodo;
                    end;
    end;
end;

function Cartas.removerCartas(sheet, node)
    if sheet ~= nil 
        and sheet.listaCartas ~= nil 
        and node ~= nil then
            local nomeNodo = Cartas.getNomeItem(node.id);
            sheet.listaCartas[nomeNodo] = nil;
            sheet.listaCartas.length = sheet.listaCartas.length - 1;
    end;
end;

function Cartas:alternarVisibilidadeDetalhes(sheetItem)
    local parentForm = Cartas:getForm();

    if parentForm.boxDetalhesCartas.node == parentForm.listCartas.selectedNode then
        parentForm.boxDetalhesCartas.visible = not parentForm.boxDetalhesCartas.visible;
    else
        parentForm.boxDetalhesCartas.node = parentForm.listCartas.selectedNode;
        parentForm.boxDetalhesCartas.visible = true;
    end
end;

function Cartas:procurarCarta(sheetItem)
    if sheetItem ~= nil 
        and sheetItem.nomeCartas ~= nil 
        and sheetItem.nomeCartas ~= '' then

            local achou = false;
            local dbItens = Cartas:getDBItens();

            -- Ordenamos a lista por ordem alfabetica para facilitar a busca do nome
            table.sort(dbItens, function (left, right)
                return left.nome < right.nome;
            end);

            for _,a in ipairs(dbItens) do
                if a.nome == sheetItem.nomeCartas 
                    or string.find(a.nome, sheetItem.nomeCartas) then
                        achou = true;
                        sheetItem.idCartas = a.id;
                        sheetItem.nomeCartas = a.nome;
                        sheetItem.descricaoCartas = a.descricao;
                        break;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar a carta \''..sheetItem.nomeCartas
                            ..'\'. Verifique se o nome está escrito corretamente com todas as pontuações e acentos');
            end
    end;
end;

function Cartas:atualizarComRaridade(sheetItem)
    if sheetItem ~= nil 
        and sheetItem.raridadeCartas ~= nil 
        and sheetItem.raridadeCartas ~= '' then

            local achou = false;
            local dbContent = Cartas:getDBContent();
            local dbItens = dbContent:getObjects();

            for _,ca in ipairs(dbItens) do
                if ca.nome == sheetItem.nomeCartas 
                    and tonumber(ca.raridade) == tonumber(sheetItem.raridadeCartas) then
                        achou = true;
                        sheetItem.idCartas = ca.id;
                        sheetItem.nomeCartas = ca.nome;
                        local descricao = ca.descricao;
                        if ca.tipo ~= nil and ca.tipo ~= '' then
                            descricao = ca.tipo..' card\n\n'..descricao;
                        end;
                        if ca.subTipo ~= nil and ca.subTipo ~= '' then
                            descricao = ca.subTipo..'\n\n'..descricao;
                        end;
                        if ca.obs ~= nil and ca.obs ~= '' then
                            descricao = descricao..'\n\n('..ca.obs..')';
                        end;
                        sheetItem.descricaoCartas = descricao;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar o Cartasoramento '..sheetItem.nomeCartas..' custando '..sheetItem.pontosCartas..' pontos');
            end
    end;
end;