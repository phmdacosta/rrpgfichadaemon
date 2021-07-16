require("ndb.lua");
require('util.lua');
require('base.lua');
require('atributos.lua');

Armas = {sheet = nil, armasObservers = nil}

function Armas:setSheet(sheet)
    self.sheet = sheet;
end

function Armas:getSheet()
    return self.sheet;
end

function Armas.getNomeItem(index)
    return "arma" .. index;
end;

function Armas:adicionarArma(sheet, recordList)
    if sheet ~= nil then
        if sheet.listaArmas == nil then
            sheet.listaArmas = {length=0}
        end;
    
        if self.armasObservers == nil then
            self.armasObservers = {length=0}
        end;
    
        local node = recordList.listArmas:append();
    
        if node ~= nil then
            sheet.listaArmas.length = sheet.listaArmas.length + 1;
    
            node.id = sheet.listaArmas.length;
            local nomeNodo1 = Armas.getNomeItem(node.id);
            sheet.listaArmas[nomeNodo1] = node;
    
            self.armasObservers[node.id] = NDB.newObserver(node);
            self.armasObservers[node.id].onChanged = 
                        function(nodo, attribute, oldValue)
                            local nomeNodo2 = Armas.getNomeItem(nodo.id);
                            sheet.listaArmas[nomeNodo2] = nodo;
                        end;
        end;
    end;
end;

function Armas.atualizarArmaLista(sheet, arma)
    if sheet.listaArmas ~= nil then
        local nomeNodo = Armas.getNomeItem(arma.id);
        sheet.listaArmas[nomeNodo] = arma;
    end;
end;

function Armas.getListaArmas(sheet)
    return sheet.listaArmas;
end;

function Armas.removerArma(sheet, node)
    if sheet ~= nil 
        and sheet.listaArmas ~= nil 
        and node ~= nil then
            local nomeNodo = Armas.getNomeItem(node.id);
            sheet.listaArmas[nomeNodo] = nil;
            sheet.listaArmas.length = sheet.listaArmas.length - 1;
    end;
end;

function Armas.alternarVisibilidadeDefInimigo(sheet, armaItem)

    if sheet == nil or armaItem.defInimigoLayout == nil then
        return;
    end;

    if sheet.tipoArma == 'D' then
        armaItem.defInimigoLayout.enabled = false;
    else
        armaItem.defInimigoLayout.enabled = true;
    end;
end;

function Armas.verificarValorDano(danoArma)
    if danoArma ~= nil and not string.find(danoArma, "d") then
        showMessage('Dano da arma deve ser inserida com o formato: <quantidade_dados>d<tipo_dado>+<bonus>. Exemplos: 1d4, 2d10+2, 5d8+3')
    end;
end

function Armas.efetuarRolagem(sheet, dificuldade, bonusAtrib, critico)
    local mesa = Firecast.getMesaDe(sheet);

    -- Dado de teste
    local dadoDeAcerto = sheet.rolagemArma;
    
    -- Pegando informações do dano
    local arrayDano = Util.split(Util.trim(sheet.danoArma), "+");
    -- Dano fixo adicional da arma
    local danoAdicional = (tonumber(arrayDano[2]) or 0);
    
    arrayDano = Util.split(Util.trim(arrayDano[1]), "d");
    -- Quantidade de dados para o dano
    local qtdDadosDano = tonumber(arrayDano[1]);
    -- Dado base para o dano
    local dadoBaseDano = "d"..arrayDano[2];
    
    -- Quantidade de Ataques
    --local arrayRolagem = split(trim(dadoDeAcerto), "d");
    --local qtdAtaques = tonumber(arrayRolagem[1]);

    local function rolarDano(numDados, dado, bonus, isCritico)

        -- numDados = numDados * qtdAtaques;
        -- bonus = bonus * qtdAtaques;
        
        local danoBase = numDados .. dado .. " + " .. bonus;

        if isCritico then
            danoBase = (numDados * 2) .. dado .. " + " .. (bonus * 2);
        end;

        mesa.chat:rolarDados(danoBase, "Dano base: " .. danoBase,
            function(rolagem)
                local resultadoFinal = rolagem.resultado + bonusAtrib;
                mesa.chat:enviarMensagem("Dano: " .. rolagem.resultado .. " + " .. bonusAtrib 
                    .. "(bônus de atributo)" .. " = " .. resultadoFinal);
            end
        );
    end;

    mesa.chat:rolarDados(dadoDeAcerto, "Dificuldade: " .. dificuldade,
        function(rolagem)
            for i = 1, #rolagem.ops, 1 do
                local op = rolagem.ops[i];

                if op.tipo == "dado" then
                    for j = 1, #op.resultados, 1 do
                        mesa.chat:enviarMensagem("- Ataque " .. j .. " -");
                        local resultado = math.floor(op.resultados[j]);

                        if dificuldade >= resultado then
                            local dificil = dificuldade / 2;
                            local isCritico = false;
                            local _qtdDadosDano = qtdDadosDano;
                            local _danoAdicional = danoAdicional;

                            if critico >= resultado  then
                                mesa.chat:enviarMensagem("Crítico! " .. resultado);
                                isCritico = true;
                            elseif dificil >= resultado then
                                mesa.chat:enviarMensagem("Acertou no difícil: " .. resultado);
                            else
                                mesa.chat:enviarMensagem("Acertou: " .. resultado);
                            end;
                            
                            rolarDano(_qtdDadosDano, dadoBaseDano, _danoAdicional, isCritico);
                        else
                            if resultado >= Base.erroCritico then
                                mesa.chat:enviarMensagem("Erro crítico! " .. resultado);
                            else
                                mesa.chat:enviarMensagem("Errou: " .. resultado);
                            end;
                        end;
                    end;
                end;
            end;
        end
    );
end;

function Armas:rolarAtaque(sheet)

    local atribSheet = Atributos:getSheet();

    local mesa = Firecast.getMesaDe(sheet);
    local pericia = (tonumber(sheet.periciaArma) or 0);
    local critico = pericia / 4;

    if sheet.tipoArma == 'D' then
        mesa.chat:enviarMensagem("############## ATAQUE A DISTÂNCIA ##################");
        local bonus = Atributos.getBonusAtributo(sheet.atribPer, sheet.modAtribPer);
        self.efetuarRolagem(sheet, pericia, bonus, critico);
    else
        mesa.chat:enviarMensagem("############## ATAQUE CORPO A CORPO ##################");
        local dificuldade = (pericia - (tonumber(sheet.defInimigo) or 0)) + 50;
        local bonus = Atributos.getBonusAtributo(atribSheet.atribFor, atribSheet.modAtribFor);
        self.efetuarRolagem(sheet, dificuldade, bonus, critico);
    end;
end;