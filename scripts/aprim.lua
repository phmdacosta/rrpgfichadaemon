require('sql.lua')
require('util.lua')

local APRIM_DATA_PATH = "database/aprim.csv"

Aprim = {
    sheet = nil,
    form = nil,
    aprimObservers = nil,
    itens = {}
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

function Aprim.lerArquivoDeDados()
    return  SQL.readFile(APRIM_DATA_PATH);
end;

function Aprim:carregarTodos()
    local content = Aprim.lerArquivoDeDados();
    if content ~= nil then
        local objects = content:getObjects();
        for i = 1, #objects do
            table.insert(Aprim.itens, objects[i])
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

function Aprim:alternarVisibilidadeDetalhes(form)
    
    --local parentSheet = Aprim:getSheet();


    local parentForm = Aprim:getForm();
    local selectedNode = parentForm.listAprim.selectedNode;
    local nomeNode = self.getNomeItem(selectedNode.id);
    --showMessage('nome selected node'..nomeNode)
    --showMessage('selected node'..Utils.tableToStr(parentForm.listAprim.selectedNode))

    if parentForm.boxDetalhesAprim.node == parentForm.listAprim.selectedNode then
        parentForm.boxDetalhesAprim.visible = not parentForm.boxDetalhesAprim.visible;
    else
        parentForm.boxDetalhesAprim.node = parentForm.listAprim.selectedNode;
        parentForm.boxDetalhesAprim.visible = true;
    end
end;