local atributos = {
    CON = 'CON',
    FOR = 'FOR',
    DEX = 'DEX',
    AGI = 'AGI',
    INT = 'INT',
    WILL = 'WILL',
    PER = 'PER',
    CAR = 'CAR'
};

local nomeCamposCabecalho = {
    level = 'level',
    experiencia = 'exp',
    idade = 'idade',
    sexo = 'sexo',
    altura = 'altura',
    medidaAltura = 'medidaAltura',
    peso = 'peso',
    medidaPeso = 'medidaPeso',
    pv = 'pv',
    pvMax = 'pvMax',
    pm = 'pm',
    pmMax = 'pmMax',
    ip = 'ip',
    ph = 'ph',
    phMax = 'phMax'
};

local nomeCamposAtributos = {
    prefixLabel = 'labelAtrib',
    prefixAtrib = 'atrib',
    prefixMod = 'modAtrib',
    prefixPercent = 'percentAtrib',
    prefixBonus = 'bonus',
    pontosMax = 'pontosAtribMax'
};

local nomeCamposArmadura = {
    descricao = 'descricaoArmadura',
    ip = 'ipArmadura'
};

Constants = {
    atributos = atributos,
    nomeCampos = {
        cabecalho = nomeCamposCabecalho,
        atributos = nomeCamposAtributos,
        armadura = nomeCamposArmadura
    }
}

return Constants;