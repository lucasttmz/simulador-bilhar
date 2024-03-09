local DEBUG = false

local TAMANHO_BURACO = 30
local RAIO_BOLA = 10
local ESPACO_ENTRE_BOLAS = 2
local DESACELERACAO_BOLA = 0.4
local ELASTICIDADE_BOLA = 0.8
local DISTANCIA_MAXIMA = 600
local BOLA_BRANCA = 1

local world
local estadoAtual
local bolas = {}
local tela = {
    largura = 1280,
    altura = 720,
}
local taco = {
    comprimento = 400,
    largura = 10,
    distanciaDuranteRotacao = 30,
    distanciaDoCentro = 30,
    angulo = 0,
}
local mesa = {
    x = 120,
    y = 60,
    largura = tela.largura - 240,
    altura = tela.altura - 120,
}    
local buracos = {
    {x = mesa.x , y = mesa.y - (TAMANHO_BURACO / 3)},
    {x = mesa.largura / 2 + mesa.x, y = mesa.y - (TAMANHO_BURACO / 3)},
    {x = mesa.largura + mesa.x, y = mesa.y - (TAMANHO_BURACO / 3)},
    {x = mesa.x, y = mesa.y + mesa.altura + (TAMANHO_BURACO / 3)},
    {x = mesa.largura / 2 + mesa.x, y = mesa.y + mesa.altura + (TAMANHO_BURACO / 3)},
    {x = mesa.largura + mesa.x, y = mesa.y + mesa.altura + (TAMANHO_BURACO / 3)},
} 
local bordas = {
    {x1 = mesa.x, y1 = mesa.y, x2 = mesa.x + mesa.largura, y2 = mesa.y},
    {x1 = mesa.x + mesa.largura, y1 = mesa.y, x2=mesa.x + mesa.largura, y2 = mesa.y + mesa.altura},
    {x1 = mesa.x + mesa.largura, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y + mesa.altura},
    {x1 = mesa.x, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y}
}

function love.load()
    love.window.setTitle("Simulador Sinuca")
    love.window.setMode(tela.largura, tela.altura, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })
    love.graphics.setBackgroundColor(64/255, 29/255, 8/255)

    iniciarSimulacao()
end

function love.draw()
    desenharMesa()

    for _, bola in pairs(bolas) do
        desenharBola(bola)
    end

    if estadoAtual == "rotação" or estadoAtual == "distância" then
        desenharTaco()
        desenharTragetoria()

        if estadoAtual == "distância" then
            mostrarMensagem("Aperte <ESC> se quiser reescolher a rotação")
        end

    elseif estadoAtual == "reposição" then
        mostrarMensagem("Escolha a posição da bola branca")
    end

    if DEBUG then
        mostrarInformacoesDeDebug()
    end
end

function love.update(dt)
    if estadoAtual == "rotação" then
        rotacionarTaco()

    elseif estadoAtual == "distância" then
        distanciarTaco()

    elseif estadoAtual == "colisão" then
        -- Checa todas as colisões
        world:update(dt)

        if not bolasEmMovimento() then
            estadoAtual = "rotação"
        end

    elseif estadoAtual == "reposição" then
        realocarBolaBranca()
    end

end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then -- Botão esquerdo do mouse
        if estadoAtual == "rotação" then
            estadoAtual = "distância"

        elseif estadoAtual == "distância" then
            efetuarTacada()
            estadoAtual = "colisão"

        elseif estadoAtual == "reposição" then
            estadoAtual = "rotação"
        end
    end
end

function love.keypressed(key)
    if key == "escape" and estadoAtual == "distância" then
        estadoAtual = "rotação"
    end
end

-- * DESENHAR

function desenharBola(bola)
    local x, y = bola.body:getPosition()
    love.graphics.setColor(bola.cor)
    love.graphics.circle("fill", x, y, bola.shape:getRadius())
end

function desenharMesa()
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", mesa.x, mesa.y, mesa.largura, mesa.altura)

    love.graphics.setColor(0,0,0)
    for _, buraco in pairs(buracos) do
        love.graphics.circle("fill", buraco.x, buraco.y, TAMANHO_BURACO)
    end
end

function desenharTaco()
    love.graphics.push()
    love.graphics.translate(taco.x , taco.y)
    love.graphics.rotate(taco.angulo + math.pi / 2)  -- Para o taco apontar na bola
    love.graphics.setColor(140/255, 70/255, 20/255, 1)
    love.graphics.rectangle("fill", -taco.largura / 2, -taco.comprimento / 2, taco.largura, taco.comprimento)
    love.graphics.pop()
end

function desenharTragetoria()
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()
    local comprimentoLinha = tela.largura
    local linhaX = bolaX + comprimentoLinha * -math.cos(taco.angulo)
    local linhaY = bolaY + comprimentoLinha * -math.sin(taco.angulo)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(bolaX, bolaY, linhaX, linhaY)
end

-- * LÓGICA PRINCIPAL

function iniciarSimulacao()
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks( checarEncapamento )
    estadoAtual = "rotação"

    adicionarBordas()
    adicionarTodasAsBolas()
    adicionarBuracos()
end

function checarEncapamento(a, b)
    local numBola = a:getUserData()
    local colidiuCom = b:getUserData()

    if colidiuCom == "buraco" then
        if numBola == BOLA_BRANCA then
            estadoAtual = "reposição"
        else
            for i, bola in pairs(bolas) do
                if bola.fixture:getUserData() == numBola then
                    bolas[i].body:destroy()
                    table.remove(bolas, i)
                end
            end
        end
    end
end

function mostrarMensagem(mensagem)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(mensagem, 0, tela.altura / 2, tela.largura, "center")
end

function mostrarInformacoesDeDebug()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        "Estado Atual: " .. estadoAtual .. " - FPS: " .. tostring(love.timer.getFPS()), 
        5, 0
    )

    love.graphics.print(
        "Taco: Ângulo Atual: " .. string.format("%.2f", taco.angulo) .. " rad " ..
        "Distância Atual: " .. string.format("%.2f", taco.distanciaDoCentro - (taco.comprimento / 2) - RAIO_BOLA),
        5, 18
    )

    for i, bola in pairs(bolas) do
        local va = string.format("%.2f", bola.body:getAngularVelocity())
        local vx, vy = bola.body:getLinearVelocity()
        vx = string.format("%.2f", vx)
        vy = string.format("%.2f", vy)
        love.graphics.setColor(bola.cor)
        love.graphics.print(
            "Bola " .. i ..
            ": Velocidade X: ".. vx .. 
            " Velocidade Y: ".. vy ..
            " Velocidade Angular: " .. va, 
            5, (i+1) * 18
        )
    end
end

-- * MESA

function adicionarBordas()
    for _, borda in pairs(bordas) do
        local body = love.physics.newBody(world, borda.x, borda.y, "static")
        local shape = love.physics.newEdgeShape(borda.x1, borda.y1, borda.x2, borda.y2)
        love.physics.newFixture(body, shape, 1)
    end
end

function adicionarBuracos()
    for _, buraco in pairs(buracos) do
        local body = love.physics.newBody(world, buraco.x, buraco.y, "static")
        local shape = love.physics.newCircleShape(TAMANHO_BURACO)
        local fixture = love.physics.newFixture(body, shape, 1)

        fixture:setUserData("buraco") 
    end
end

-- * BOLAS

function adicionarBola(x, y, rgb)
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(RAIO_BOLA)
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
    fixture:setUserData(#bolas)                -- ID para checar encaçapamento
end

function adicionarTodasAsBolas()
    -- Bola branca
    local x = tela.largura / 4
    local y = tela.altura / 2
    adicionarBola(x, y, {1, 1, 1})

    -- Demais bolas
    local baseX = x * 3
    local baseY = y
    local cores = {{1, 1, 0}, {1, 0, 0}}

    for i=1,5 do
        x = baseX + ((i-1) * (RAIO_BOLA * 2) + ESPACO_ENTRE_BOLAS)
        y = baseY + ((i-1) * RAIO_BOLA + ESPACO_ENTRE_BOLAS)
        for j=1,i do
            adicionarBola(x, y, cores[(#bolas % 2) + 1])
            y = y - (RAIO_BOLA * 2) - ESPACO_ENTRE_BOLAS
        end
    end
end

function bolasEmMovimento()
    for _, bola in pairs(bolas) do
        local velocidadeX, velocidadeY = bola.body:getLinearVelocity()
        if velocidadeX ~= 0 or velocidadeY ~= 0 then
            return true
        end
    end

    return false
end

function realocarBolaBranca()
    local mouseX, mouseY = love.mouse.getPosition()
    bolas[BOLA_BRANCA].body:setPosition(mouseX, mouseY)
end

-- * TACO

function rotacionarTaco()
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()

    -- Angulo formado pelo lado oposto (y) e adjacente (x)
    taco.angulo = math.atan2(love.mouse.getY() - bolaY, love.mouse.getX() - bolaX)

    local distanciaCentralizada = taco.distanciaDuranteRotacao + (taco.comprimento / 2)
    taco.x = bolaX + distanciaCentralizada * math.cos(taco.angulo)
    taco.y = bolaY + distanciaCentralizada * math.sin(taco.angulo)
end

function distanciarTaco()
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()
    local mouseX, mouseY = love.mouse.getPosition()
    local distancia = math.max(
        (taco.comprimento / 2) + RAIO_BOLA, 
        math.sqrt((mouseX - bolaX)^2 + (mouseY - bolaY)^2)
    )
    taco.x = bolaX + distancia * math.cos(taco.angulo)
    taco.y = bolaY + distancia * math.sin(taco.angulo)
    taco.distanciaDoCentro = distancia
end

function efetuarTacada()
    local forca = math.min(
        DISTANCIA_MAXIMA, 
        (taco.distanciaDoCentro - (taco.comprimento / 2) - RAIO_BOLA) * 3
    )
    bolas[BOLA_BRANCA].body:setLinearVelocity(
        forca * -math.cos(taco.angulo),
        forca * -math.sin(taco.angulo)
    )
end
