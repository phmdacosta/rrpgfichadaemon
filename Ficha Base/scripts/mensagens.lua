Mensagens = {
    critico = 'Crítico! ',
    dificil = 'Passou no difícil: ',
    passou = 'Passou: ',
    errou = 'Errou: ',
    erroCritico = 'Erro crítico! ',
    rolando = 'Rolando ',
};

function Mensagens:enviarParaMesa(sheet, str)
    local mesa = Firecast.getMesaDe(sheet);
    mesa.chat:enviarMensagem(str)
end

function Mensagens:criarMensagemPontosSobrando(pontos)
    if pontos == nil then
        pontos = '';
    end
    return '(' .. pontos .. ' pontos sobrando)';
end

return Mensagens;