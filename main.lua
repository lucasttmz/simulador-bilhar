local DEBUG = true

local RAIO_BOLA = 10
local FRICCAO_BOLA = 0.1
local OFFSET_MESA = 50
local MOVIMENTO_MINIMO = 15 -- TODO: Verificar um número bom

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
    distanciaBola = 10,
    distanciaFixa = 175,
    angulo = 0,
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
    end

    if DEBUG then
        mostrarInformacoesDeDebug()
    end
end

function love.update(dt)
    if estadoAtual == "rotação" then
        -- Rotaciona o taco em relação a bola branca
        -- 1) Atualizar o ãngulo do taco em relação ao mouse
        rotacionarTaco()
        -- 2) Se clicar, mudar estadoAtual para "distância"

    elseif estadoAtual == "distância" then
        -- Distancia o taco da bola branca
        -- 1) Atualizar a distância do taco em relação ao mouse
        -- 2) Se clicar, calcular o poder da tacada utilizando a distância e aplicar na bola branca.
        -- 3) Por fim, mudar estadoAtual para "colisão"

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

-- * DESENHAR

function desenharBola(bola)
    local x, y = bola.body:getPosition()
    love.graphics.setColor(bola.cor)
    love.graphics.circle("fill", x, y, bola.shape:getRadius())
end

function desenharMesa()
    local mesaLargura = tela.largura - (OFFSET_MESA * 2)
    local mesaAltura = tela.altura - (OFFSET_MESA * 2)
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", OFFSET_MESA, OFFSET_MESA, mesaLargura, mesaAltura)
end

function desenharTaco()
    love.graphics.push()
    love.graphics.translate(taco.x , taco.y)
    love.graphics.rotate(taco.angulo + math.pi / 2)  -- para alinhar o taco corretamente
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", -taco.largura / 2, -taco.comprimento / 2, taco.largura, taco.comprimento)
    love.graphics.pop()
end

-- * LÓGICA PRINCIPAL

function iniciarSimulacao()
    world = love.physics.newWorld(0, 0, true)
    -- estadoAtual = "rotação"
    estadoAtual = "colisão"

    adicionarTodasAsBolas()
end

function mostrarInformacoesDeDebug()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        "Estado Atual: " .. estadoAtual .. " - FPS: " .. tostring(love.timer.getFPS()), 
        5, 0
    )

    for i, bola in pairs(bolas) do
        local va = string.format("%.2f", bola.body:getAngularVelocity())
        local vx, vy = bola.body:getLinearVelocity()
        vx = string.format("%.2f", vx)
        vy = string.format("%.2f", vy)
        love.graphics.setColor(bola.cor)
        love.graphics.print(
            "Bola " .. i ..
            " Velocidade X: ".. vx .. 
            " Velocidade Y: ".. vy ..
            " Velocidade Angular: " .. va, 
            5, i * 18
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

    local velocidadeInicialX = math.random(100, 150)
    local velocidadeInicialY = math.random(100, 150)
    body:setLinearVelocity(velocidadeInicialX, velocidadeInicialY)
    body:setLinearDamping(FRICCAO_BOLA)
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

    local distanciaCentralizada = taco.distanciaBola + (taco.comprimento / 2)
    taco.x = bolaX + distanciaCentralizada * math.cos(taco.angulo)
    taco.y = bolaY + distanciaCentralizada * math.sin(taco.angulo)

end

-- * COLISÕES

function checarColisaoBorda(bola)
    -- TODO: Converter as paredes para um objeto do love.physics
    -- TODO: Melhorar o if else, remover redundância
    local x, y = bola.body:getPosition()
    local velocidadeX, velocidadeY = bola.body:getLinearVelocity()

    -- Colisão com bordas laterais
    if x - bola.shape:getRadius() < 50 and velocidadeX < 0 then -- Esquerda
        bola.body:setLinearVelocity(-velocidadeX, velocidadeY)
    elseif x + bola.shape:getRadius() > tela.largura - 50 and velocidadeX > 0 then -- Direita
        bola.body:setLinearVelocity(-velocidadeX, velocidadeY)
    end

    -- Colisão com bordas superiores e inferiores
    if y - bola.shape:getRadius() < 50 and velocidadeY < 0 then -- Cima
        bola.body:setLinearVelocity(velocidadeX, -velocidadeY)
    elseif y + bola.shape:getRadius() > tela.altura - 50 and velocidadeY > 0 then -- Baixo
        bola.body:setLinearVelocity(velocidadeX, -velocidadeY)
    end
end