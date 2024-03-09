local DEBUG = true

local TAMANHO_BURACO = 20
local RAIO_BOLA = 10
local DESACELERACAO_BOLA = 0.5
local ELASTICIDADE_BOLA = 0.8
local MOVIMENTO_MINIMO = 0    -- TODO: Remover
local FORCA_MAXIMA = 800

local world
local estadoAtual
local bolas = {}
local tela = {
    largura = 1366,
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
local buracos = {
    {x = mesa.x, y= mesa.y},
    {x = mesa.x + mesa.largura, y = mesa.y},
    {x = mesa.x + (mesa.largura / 2) - TAMANHO_BURACO / 2, y = mesa.y - TAMANHO_BURACO / 2},
    {x = mesa.x, y = mesa.y+mesa.altura},
    {x = mesa.x + mesa.largura, y =mesa.y+mesa.altura},
    {x = mesa.x + mesa.largura / 2 + TAMANHO_BURACO / 2, y =mesa.y+mesa.altura + TAMANHO_BURACO / 2}
} 

local x = require("bolas")

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
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("Aperte <ESC> se quiser reescolher a rotação", 0, tela.altura / 2, tela.largura, "center")
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
        local paradas = true

        for _, bola in pairs(bolas) do
            vx, vy = bola.body:getLinearVelocity( )
            if vx ~= 0 or vx ~= 0 then
                paradas = false
                break
            end
        end
        
        if paradas then
            estadoAtual = "rotação"
        end

    elseif estadoAtual == "reposição" then
        bolas[1].body:setLinearVelocity(0, 0)
        bolas[1].body:setPosition(300, 300)
        estadoAtual = "rotação"
    end

end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then -- Botão esquerdo do mouse
        if estadoAtual == "rotação" then
            estadoAtual = "distância"

        elseif estadoAtual == "distância" then
            efetuarTacada()
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
    world:setCallbacks( colidiu )
    estadoAtual = "rotação"

    adicionarTodasAsBolas()
    adicionarBuracos()
end

function colidiu(a, b, coll)
    if b:getUserData() == nil then
        local numBola = a:getUserData()
        if numBola == 1 then
            estadoAtual = "reposição"
        else
            for i, bola in pairs(bolas) do
                if bola.fixture:getUserData() == a:getUserData() then
                    bolas[i].body:destroy()
                    table.remove(bolas, i)
                end
            end
        end
    end
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

function adicionarBuracos()
    for _, buraco in pairs(buracos) do
        local body = love.physics.newBody(world, buraco.x, buraco.y, "static")
        local shape = love.physics.newCircleShape(TAMANHO_BURACO)
        local fixture = love.physics.newFixture(body, shape, 1)
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
    fixture:setUserData(#bolas)
end

function adicionarTodasAsBolas()
    -- Bola branca
    local x = tela.largura / 4
    local y = tela.altura / 2
    adicionarBola(x, y, {1, 1, 1})
    -- Demais bolas
    local baseX = x * 3
    local baseY = y

    for i=1,5 do
        x = baseX + ((i-1) * (RAIO_BOLA * 2))
        y = baseY - ((i-1) * RAIO_BOLA + 2)
        for j=1,i do
            y = (y + RAIO_BOLA * 2) + 2
            adicionarBola(x, y, {math.random(1, 255)/255, math.random(1, 127)/255, math.random(1, 255)/255})
        end
    end
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

function efetuarTacada()
    local forca = math.min(
        FORCA_MAXIMA, 
        (taco.distanciaDoCentro - (taco.comprimento / 2) - RAIO_BOLA) * 3
    )
    local bolaBranca = bolas[1]
    bolaBranca.body:setLinearVelocity(
        forca * -math.cos(taco.angulo),
        forca * -math.sin(taco.angulo)
    )
end

-- * COLISÕES

function checarColisaoBorda(bola)
    -- TODO: Converter as paredes para um objeto do love.physics
    local x, y = bola.body:getPosition()
    local raio = bola.shape:getRadius()
    local velocidadeX, velocidadeY = bola.body:getLinearVelocity()

   -- Colisão laterais
   if ((x - raio < mesa.x and velocidadeX < 0) or 
       (x + raio > tela.largura - mesa.x and velocidadeX > 0)) then
        bola.body:setLinearVelocity(-velocidadeX * 0.9, velocidadeY * 0.9)
    end

    -- Colisão superior/inferior
    if ((y - raio < mesa.y and velocidadeY < 0) or 
        (y + raio > tela.altura - mesa.y and velocidadeY > 0)) then
        bola.body:setLinearVelocity(velocidadeX * 0.9, -velocidadeY * 0.9)
    end
end