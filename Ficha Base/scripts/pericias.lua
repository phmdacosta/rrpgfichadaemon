require('base.lua');
require('mensagens.lua');
require('atributos.lua');

Pericias = {
    sheet = nil,
    periciasObservers = nil
}

function Pericias:setSheet(sheet)
    self.sheet = sheet;
end

function Pericias:getSheet()
    return self.sheet;
end

function Pericias.getAtributosArray()
    return Atributos.array;
end

function Pericias.getDefaultAtributo()
    return Atributos.default;
end

function Pericias.aplicarAtributo(sheet)
    if sheet.atribBasePericia ~= nil and sheet.valorPericia ~= nil then
        local nodoAtributos = Atributos:getSheet();
        local nomeCampoValor = Atributos.prefixCampoAtrib .. sheet.atribBasePericia;
        local nomeCampoMod = Atributos.prefixCampoMod .. sheet.atribBasePericia;
        local valorTotal = Atributos.getTotalAtributo(nodoAtributos[nomeCampoValor], nodoAtributos[nomeCampoMod]);
        sheet.totalPericia = sheet.valorPericia + valorTotal;
    end;
end;

function Pericias.efetuarTeste(sheet)
    local pericia = sheet.totalPericia;
    
    local mesa = Firecast.getMesaDe(sheet);
    mesa.chat:rolarDados(Base.dadoRolagem, Mensagens.rolando .. sheet.nomePericia,
        function(rolagem)
            local resultado = rolagem.resultado;
            if pericia >= resultado then
                local dificil = pericia / 2;
                local critico = pericia / 4;

                if critico >= resultado  then
                    mesa.chat:enviarMensagem(Mensagens.critico .. resultado);
                elseif dificil >= resultado then
                    mesa.chat:enviarMensagem(Mensagens.dificil .. resultado);
                else
                    mesa.chat:enviarMensagem(Mensagens.passou .. resultado);
                end;
            else
                if resultado >= Base.erroCritico then
                    mesa.chat:enviarMensagem(Mensagens.erroCritico .. resultado);
                else
                    mesa.chat:enviarMensagem(Mensagens.errou .. resultado);
                end;
            end;
        end
    );
end;

function Pericias.getNomeItem(index)
    return "pericia" .. index;
end;

function Pericias:adicionarPericia(sheet, recordList)
    if sheet.listaPericias == nil then
        sheet.listaPericias = {length=0}
    end;

    if self.periciasObservers == nil then
        self.periciasObservers = {length=0}
    end;

    local node = recordList.listPericias:append();

    if node ~= nil then
        sheet.listaPericias.length = sheet.listaPericias.length + 1;

        node.id = sheet.listaPericias.length;
        local nomeNodo1 = self.getNomeItem(node.id);
        sheet.listaPericias[nomeNodo1] = node;

        self.periciasObservers[node.id] = NDB.newObserver(node);
        self.periciasObservers[node.id].onChanged = 
                    function(nodo, attribute, oldValue)
                        local nomeNodo2 = self.getNomeItem(nodo.id);
                        sheet.listaPericias[nomeNodo2] = nodo;
                    end;
    end;
end;

function Pericias.removerPericia(sheet, node)
    if sheet ~= nil 
        and sheet.listaPericias ~= nil 
        and node ~= nil then
            local nomeNodo = Pericias.getNomeItem(node.id);
            sheet.listaPericias[nomeNodo] = nil;
            sheet.listaPericias.length = sheet.listaPericias.length - 1;
    end;
end;

function Pericias:atualizarPericiaLista(sheet, pericia)
    if sheet ~= nil 
        and pericia ~= nil 
        and pericia.id ~= nil 
        and sheet.listaPericias ~= nil then
            local nomeNodo4 = self.getNomeItem(pericia.id);
            sheet.listaPericias[nomeNodo4] = pericia;
    end;
end;

function Pericias.getListaPericias(sheet)
    return sheet.listaPericias;
end;

function Pericias.export(sheet)
    local txt = Text:new();
    txt:appendLine('----- Perícias -----\n');

    if sheet.listaPericias ~= nil then
        for k,_ in pairs(sheet.listaPericias) do
            local pericia = sheet.listaPericias[k];
            if pericia ~= nil 
                and Util.isTable(pericia)
                and pericia.nomePericia ~= nil then
                    txt:appendLine(pericia.nomePericia);
                    txt:append(' ('..Util.handleNil(pericia.atribBasePericia)..')   ');
                    txt:append(Util.handleNil(pericia.valorPericia)..'/');
                    txt:append(Util.handleNil(pericia.totalPericia));
            end;
        end;
    end;

    return txt:toString();
end;

return Pericias;