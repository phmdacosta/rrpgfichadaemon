require('sql.lua')
require('util.lua')

local CARTAS_DATA_PATH = "database/cartas.csv"
local PREFIX_NOME_ITEM = "carta";

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

function Cartas:initObservers(sheet)
    if self.cartasObservers == nil then
        self.cartasObservers = {length=0}
    end;
end;

function Cartas:initListaItens(sheet)
    if sheet ~= nil then
        if sheet.listaCartas == nil then
            sheet.listaCartas = {length=0, maxId=0}
        end;
    
        Cartas:initObservers(sheet);
    end;
end;

function Cartas.lerArquivoDeDados()
    return SQL.readFile(CARTAS_DATA_PATH);
end;

function Cartas:carregarTodos()
    self.dbItens = {}

    local content = Cartas.lerArquivoDeDados();
    if content ~= nil then
        content.name = 'db_cartas';
        self.dbContent = content;
        local objects = self.dbContent:getObjects();
        for i = 1, #objects do
            table.insert(self.dbItens, objects[i])
        end;
    end;
end;

function Cartas.getNomeItem(index)
    return PREFIX_NOME_ITEM .. index;
end;

function Cartas.getIdItem(nome)
    return string.gsub(nome, PREFIX_NOME_ITEM, "");
end

function Cartas:registrarObserver(sheet, lista, node)
    if lista ~= nil and node ~= nil then
        Cartas:initObservers(sheet);

        if self.cartasObservers[node.id] == nil then
            self.cartasObservers[node.id] = NDB.newObserver(node);
            self.cartasObservers[node.id].onChanged = 
                        function(nodo, attribute, oldValue)
                            local nomeNodo2 = Cartas.getNomeItem(nodo.id);
                            lista[nomeNodo2] = nodo;
                        end;
        end
    end;
end

function Cartas:adicionarCartas(sheet, form)
    Cartas:initListaItens(sheet);

    local node = form.listCartas:append();

    if node ~= nil then
        sheet.listaCartas.length = sheet.listaCartas.length + 1;
        self.cartasObservers.length = sheet.listaCartas.length;
        if sheet.listaCartas.maxId == 0 then
            sheet.listaCartas.maxId = sheet.listaCartas.length;
        else
            sheet.listaCartas.maxId = sheet.listaCartas.maxId +1;
        end
        

        node.id = sheet.listaCartas.maxId;
        local nomeNodo1 = self.getNomeItem(node.id);
        sheet.listaCartas[nomeNodo1] = node;

        Cartas:handleObserver(sheet, node);
    end;

    self:setSheet(sheet)
end;

function Cartas:removerCartas(sheet, node)
    if sheet ~= nil
        and sheet.listaCartas ~= nil 
        and node ~= nil then
            local nomeNodo = Cartas.getNomeItem(node.id);
            sheet.listaCartas[nomeNodo] = nil;

            sheet.listaCartas.length = sheet.listaCartas.length - 1;

            if self.cartasObservers ~= nil then
                self.cartasObservers[node.id].enabled = false;
                self.cartasObservers[node.id] = nil
                self.cartasObservers.length = sheet.listaCartas.length
            end;

            if sheet.listaCartas.length == 0 then
                sheet.listaCartas = nil
                self.cartasObservers = nil
            end;
            
            self:setSheet(sheet);
    end;
end;

function Cartas:handleObserver(sheet, node)
    if sheet ~= nil 
        and node ~= nil 
        and node.id ~= nil then
            Cartas:initListaItens(sheet);

            if self.cartasObservers[node.id] ~= nil then
                self.cartasObservers[node.id].enabled = false;
                self.cartasObservers[node.id] = nil;
            end;

            Cartas:registrarObserver(sheet, sheet.listaCartas, node);
    end;
end

function Cartas:alternarVisibilidadeDetalhes()
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
        and sheetItem.nomeCarta ~= nil 
        and sheetItem.nomeCarta ~= '' then

            local achou = false;
            local dbContent = Cartas:getDBContent();
            if dbContent ~= nil then
                local dbItens = dbContent:getObjects();

                -- No caso das cartas vamos ordernar pela ordem que o mestre definiu no documento
                table.sort(dbItens, function (left, right)
                    return left.id < right.id;
                end);

                for _,c in ipairs(dbItens) do
                    if c.nome == sheetItem.nomeCarta 
                        or string.find(c.nome, sheetItem.nomeCarta) then
                            achou = true;
                            sheetItem.idCarta = c.id;
                            sheetItem.nomeCarta = c.nome;
                            sheetItem.descricaoCarta = c.descricao;
                            sheetItem.raridadeCarta = c.raridade;
                            sheetItem.tipoCarta = c.tipo:sub(1,1); -- Apenas a primeira letra
                            break;
                    end;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar a carta \''..sheetItem.nomeCarta
                            ..'\'. Verifique se o nome está escrito corretamente com todas as pontuações e acentos');
            end
    end;
end;

function Cartas:atualizarComRaridade(sheetItem)
    if sheetItem ~= nil 
        and sheetItem.raridadeCarta ~= nil 
        and sheetItem.raridadeCarta ~= '' then

            local achou = false;
            local dbContent = Cartas:getDBContent();
            local dbItens = dbContent:getObjects();

            for _,ca in ipairs(dbItens) do
                if ca.nome == sheetItem.nomeCarta 
                    and tonumber(ca.raridade) == tonumber(sheetItem.raridadeCarta) then
                        achou = true;
                        sheetItem.idCarta = ca.id;
                        sheetItem.nomeCarta = ca.nome;
                        local descricao = ca.descricao;
                        if ca.subTipo ~= nil and ca.subTipo ~= '' then
                            descricao = ca.subTipo..'\n\n'..descricao;
                        end;
                        if ca.tipo ~= nil and ca.tipo ~= '' then
                            descricao = Util.capitalize(ca.tipo)..' Card\n\n'..descricao;
                        end;
                        if ca.obs ~= nil and ca.obs ~= '' then
                            descricao = descricao..'\n\n('..ca.obs..')';
                        end;
                        sheetItem.descricaoCarta = descricao;
                end;
            end;

            if not achou then
                showMessage('Não foi possível encontrar a carta '..sheetItem.nomeCarta..
                            ' com raridade '..sheetItem.raridadeCarta);
            end
    end;
end;

function Cartas:puxarCarta(sheet)
    if sheet.listaCartas ~= nil and sheet.listaCartas.length > 0 then
        local max = sheet.listaCartas.maxId;
        math.randomseed(os.time());
        local initId = math.random(1, max);
        local nextId = initId;
        
        for _=1,max do
            local carta = sheet.listaCartas[self.getNomeItem(nextId)];
            showMessage(Utils.tableToStr(carta))
            if carta ~= nil 
                and not Util.isEmptyTable(carta) 
                and not carta.sideDeck 
                and not carta.usou then
                    local mesa = Firecast.getMesaDe(sheet);
                    mesa.chat:enviarMensagem('--- Puxou a carta '..Util.handleNil(carta.nomeCarta)
                                                ..' R'..Util.handleNil(carta.raridadeCarta)..' ---');
                    break;
            elseif nextId == max then
                nextId = 1;
            else
                nextId = nextId + 1;
            end;
        end;
    end;
end;

function Cartas.alternarUso(sheet, itemForm)
    if sheet == nil or itemForm == nil then
        return;
    end;

    if sheet.usou then
        Cartas.alternarAbilitarCampos(itemForm, false);
        local mesa = Firecast.getMesaDe(sheet);
        mesa.chat:enviarMensagem('--- Usou a carta '..sheet.nomeCarta..' R'..sheet.raridadeCarta..' ---');
    else
        Cartas.alternarAbilitarCampos(itemForm, true);
    end
end;

function Cartas.alternarAbilitarCampos(itemForm, bool)
    if itemForm ~= nil then
        itemForm.nomeCartaLayout.enabled = bool;
        itemForm.raridadeCartaLayout.enabled = bool;
        itemForm.sideDeckLayout.enabled = bool;
    end
end;

local function exportCarta(carta)
    local txt = Text:new();

    if carta ~= nil then
            txt:appendLine(carta.nomeCarta);
            txt:append(' ('..Util.handleNil(carta.tipoCarta)..')');
            txt:append('    R: ');
            txt:append(carta.raridadeCarta);
    end;

    return txt:toString();
end;

local function cartaNotEmpty(carta)
    return carta ~= nil and Util.isTable(carta) and carta.nomeCarta ~= nil;
end

function Cartas.export(sheet)
    local txt = Text:new();
    txt:appendLine('----- Cartas -----\n');

    if sheet.listaCartas ~= nil then
        -- Listar Side Deck
        txt:appendLine('Side Deck:');
        for k,_ in pairs(sheet.listaCartas) do
            local carta = sheet.listaCartas[k];
            if cartaNotEmpty(carta) and carta.sideDeck then
                txt:appendLine(exportCarta(carta));
            end;
        end;

        txt:breakLine();

        -- Listar Deck
        txt:appendLine('Deck:');
        for k,_ in pairs(sheet.listaCartas) do
            local carta = sheet.listaCartas[k];
            if cartaNotEmpty(carta) and not carta.sideDeck then
                txt:appendLine(exportCarta(carta));
            end;
        end;
    end;

    return txt:toString();
end;



return Cartas;