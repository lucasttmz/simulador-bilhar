local DEBUG = true

local OFFSET_MESA = 50
local RAIO_BOLA = 10
local DESACELERACAO_BOLA = 0.3 -- TODO: Encontrar um bom número
local ELASTICIDADE_BOLA = 0.3  -- TODO: Encontrar um bom número
local MOVIMENTO_MINIMO = 15    -- TODO: Encontrar um bom número
local FORCA_MAXIMA = 300       -- TODO: Encontrar um bom número

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
    x = 50,
    y = 50,
    largura = tela.largura - 100,
    altura = tela.altura - 100,
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

    if estadoAtual ~= "colisão" then
        desenharTaco()
        desenharTragetoria()

        if estadoAtual == "distância" then
            -- TODO: Informar jogador que ele pode apertar <ESC> para reajustar ângulo
        end
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
        -- Calcula as colisões até as bolas atingirem o movimento minimo
        -- 1) Checa a colisão entre as bolas
        world:update(dt)

        -- 2) Checa as colisões entre 
        for _, bola in pairs(bolas) do
            checarMovimentoMinimo(bola)
            checarColisaoBorda(bola)
        end

        -- 3) Se todas as bolas pararam, mudar estadoAtual para "rotação"
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then -- Botão esquerdo do mouse
        if estadoAtual == "rotação" then
            estadoAtual = "distância"

        elseif estadoAtual == "distância" then
            local forca = math.min(
                FORCA_MAXIMA, 
                taco.distanciaDoCentro - (taco.comprimento / 2) - RAIO_BOLA
            )
            efetuarTacada(forca)
            estadoAtual = "colisão"
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
    local bolaX, bolaY = bolas[1].body:getPosition()

    -- TODO: Encontrar uma forma de  calcular a distancia da bola até o limite da mesa
    local comprimentoLinha = tela.largura -- ! Está saindo fora da mesa
    local linhaX = bolaX + comprimentoLinha * -math.cos(taco.angulo)
    local linhaY = bolaY + comprimentoLinha * -math.sin(taco.angulo)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(bolaX, bolaY, linhaX, linhaY)
end

-- * LÓGICA PRINCIPAL

function iniciarSimulacao()
    world = love.physics.newWorld(0, 0, true)
    estadoAtual = "rotação"

    adicionarTodasAsBolas()
end

function mostrarInformacoesDeDebug()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        "Estado Atual: " .. estadoAtual .. " - FPS: " .. tostring(love.timer.getFPS()), 
        5, 0
    )

    -- TODO: A distância mostrada é a distância central, corrigir!

    love.graphics.print(
        "Taco: Ângulo Atual: " .. string.format("%.2f", taco.angulo) .. " rad " ..
        "Distância Atual: " .. string.format("%.2f", taco.distanciaDoCentro),
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

-- * BOLAS

function adicionarBola(x, y, rgb)
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(RAIO_BOLA)
    local fixture = love.physics.newFixture(body, shape, 1)

    local bola = {
        body = body,
        shape = shape,
        cor = rgb
    }

    table.insert(bolas, bola)

    body:setLinearDamping(DESACELERACAO_BOLA)  -- Desacelaração Linear
    body:setAngularDamping(DESACELERACAO_BOLA) -- Desacelaração Angular
    fixture:setRestitution(ELASTICIDADE_BOLA)  -- Elasticidade
end

function adicionarTodasAsBolas()
    -- Bola branca
    local x = tela.largura / 4
    local y = tela.altura / 2
    adicionarBola(x, y, {1, 1, 1})
    -- Demais bolas
    adicionarBola(x * 3, y, {1, 0, 0})
end

function checarMovimentoMinimo(bola)
    -- Para as bolas que estão se lentas para agilizar a transição de estados
    local velocidadeX, velocidadeY = bola.body:getLinearVelocity()
    if (math.abs(velocidadeX) < MOVIMENTO_MINIMO and 
        math.abs(velocidadeY) < MOVIMENTO_MINIMO) then
        bola.body:setLinearVelocity(0, 0)
        bola.body:setAngularVelocity(0)
    end
end

-- * TACO

function rotacionarTaco()
    local bolaX, bolaY = bolas[1].body:getPosition()

    -- Angulo formado pelo lado oposto (y) e adjacente (x)
    taco.angulo = math.atan2(love.mouse.getY() - bolaY, love.mouse.getX() - bolaX)

    local distanciaCentralizada = taco.distanciaDuranteRotacao + (taco.comprimento / 2)
    taco.x = bolaX + distanciaCentralizada * math.cos(taco.angulo)
    taco.y = bolaY + distanciaCentralizada * math.sin(taco.angulo)
end

function distanciarTaco()
    local bolaX, bolaY = bolas[1].body:getPosition()
    local mouseX, mouseY = love.mouse.getPosition()
    local distancia = math.max(
        (taco.comprimento / 2) + RAIO_BOLA, 
        math.sqrt((mouseX - bolaX)^2 + (mouseY - bolaY)^2)
    )
    taco.x = bolaX + distancia * math.cos(taco.angulo)
    taco.y = bolaY + distancia * math.sin(taco.angulo)
    taco.distanciaDoCentro = distancia
end

function efetuarTacada(forca)
    -- TODO: aplicar o ângulo a força
    local bolaBranca = bolas[1]
    bolaBranca.body:setLinearVelocity(forca, 0)
end

-- * COLISÕES

function checarColisaoBorda(bola)
    -- TODO: Converter as paredes para um objeto do love.physics
    -- TODO: Reduzir um pouco a velocidade da bola depois da colisão
    local x, y = bola.body:getPosition()
    local raio = bola.shape:getRadius()
    local velocidadeX, velocidadeY = bola.body:getLinearVelocity()

   -- Colisão laterais
   if ((x - raio < mesa.x and velocidadeX < 0) or 
       (x + raio > tela.largura - mesa.x and velocidadeX > 0)) then
        bola.body:setLinearVelocity(-velocidadeX, velocidadeY)
    end

    -- Colisão superior/inferior
    if ((y - raio < mesa.y and velocidadeY < 0) or 
        (y + raio > tela.altura - mesa.y and velocidadeY > 0)) then
        bola.body:setLinearVelocity(velocidadeX, -velocidadeY)
    end
end