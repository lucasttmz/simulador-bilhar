local BRANCA = 1
local DESACELERACAO_BOLA = 0.4
local ELASTICIDADE_BOLA = 0.8
local RAIO = 15

local bolas = {}

local function desenharBola(bola)
    local x, y = bola.body:getPosition()
    local numBola = bola.fixture:getUserData()
    local raio = bola.shape:getRadius()

    -- Circulo Exterior
    love.graphics.setColor(bola.cor)
    love.graphics.circle("fill", x, y, raio)

    -- Contorno
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", x, y, raio)

    -- Circulo Interior
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", x, y, raio - 6)
    love.graphics.setColor(0, 0, 0)

    -- Listras
    if numBola >= 10 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.arc( "fill", x, y+3, RAIO-4, 0.5, math.pi-0.5)
        love.graphics.arc( "fill", x, y-3, RAIO-4, -0.5, -math.pi+0.5)
    end

    -- Número da bola
    x = x - 4
    y = y - 8
    if numBola - 1 >= 10 then
        x = x - 4 -- Espaçamento duplo para os dois dígitos
    end

    if numBola ~= BRANCA then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(numBola - 1, x, y)
    end
end

local function adicionarBola(x, y, rgb, num)
    -- Adiciona a bola e sua física
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(RAIO)
    local fixture = love.physics.newFixture(body, shape, 1)

    local bola = {
        body = body,
        fixture = fixture,
        shape = shape,
        cor = rgb
    }

    table.insert(bolas, bola)

    body:setLinearDamping(DESACELERACAO_BOLA)  -- Desacelaração Linear
    body:setAngularDamping(DESACELERACAO_BOLA) -- Desacelaração Angular
    fixture:setRestitution(ELASTICIDADE_BOLA)  -- Elasticidade
    fixture:setUserData(num)                   -- ID para checar encaçapamento
end

local function adicionarTodasAsBolas()
    -- Bola branca
    local x = tela.largura / 4
    local y = tela.altura / 2
    adicionarBola(x, y, {1, 1, 1}, 1)

    -- Demais bolas
    local baseX = x * 3
    local baseY = y
    local cores = {
        {0.9, 0.9, 0}, 
        {0.3, 0.2, 0},
        {0.6, 0, 0.6}, 
        {0.3, 0.2, 0},
        {0, 0, 0},
        {0.9, 0.9, 0}, 
        {0, 0.4, 0.2},
        {0, 0, 1}, 
        {1, 0, 0}, 
        {0, 0.4, 0.2},
        {1, 0, 0},
        {0, 0, 1}, 
        {1, 0.6, 0},
        {0.6, 0, 0.6}, 
        {1, 0.6, 0},
    }
    local numBolas = {9, 7, 12, 15, 8, 1, 6, 10, 3, 14, 11, 2, 13, 4, 5}

    for i=1,5 do
        x = baseX + ((i-1) * (RAIO * 2))
        y = baseY + ((i-1) * RAIO)
        for j=1,i do
            adicionarBola(x, y, cores[#bolas], numBolas[#bolas]+1)
            y = y - (RAIO * 2)
        end
    end
end

local function checarEncapamento(a, b)
    local bola = a:getUserData()
    local colidiuCom = b:getUserData()

    if colidiuCom == "buraco" then
        print(1)
        if bola == BRANCA then
            estadoAtual = "reposição"
        else
            -- Remove a bola da lista de bolas e a remove do mundo de colisões
            for i, bola_ in pairs(bolas) do
                if bola_.fixture:getUserData() == bola then
                    bolas[i].body:destroy()
                    table.remove(bolas, i)
                end
            end
        end
    end
end

local function realocarBolaBranca()
    local mesa = require("mesa").mesa
    -- Limites da mesa
    local LIMITE_ESQUERDA = mesa.x + RAIO
    local LIMITE_DIREITA = mesa.x + mesa.largura - RAIO
    local LIMITE_CIMA = mesa.y + RAIO
    local LIMITE_BAIXO = mesa.y + mesa.altura - RAIO
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Só deixa realocar a bola dentro da mesa
    if mouseX < LIMITE_ESQUERDA then
        mouseX = LIMITE_ESQUERDA
    elseif mouseX > LIMITE_DIREITA then
        mouseX = LIMITE_DIREITA
    end
    if mouseY < LIMITE_CIMA then
        mouseY = LIMITE_CIMA
    elseif mouseY > LIMITE_BAIXO then
        mouseY = LIMITE_BAIXO
    end
    bolas[BRANCA].body:setPosition(mouseX, mouseY)
end

local function bolasEmMovimento()
    for _, bola in pairs(bolas) do
        local velocidadeX, velocidadeY = bola.body:getLinearVelocity()
        -- Se uma das bolas estiver em movimento, não checa as demais
        if velocidadeX ~= 0 or velocidadeY ~= 0 then
            return true
        end
    end

    return false
end

return {
    BRANCA = BRANCA,
    RAIO = RAIO,
    bolas = bolas,
    desenharBola = desenharBola,
    adicionarTodasAsBolas = adicionarTodasAsBolas,
    checarEncapamento = checarEncapamento,
    bolasEmMovimento = bolasEmMovimento,
    realocarBolaBranca = realocarBolaBranca,
}