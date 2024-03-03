local world
local RAIO_BOLA = 10
local FRICCAO_BOLA = 0.0

local bolas = {}
local tela = {
    largura = 1280,
    altura = 720,
    angulo = 0,
    escala = 1.0
}

function love.load()
    love.window.setTitle("Simulador Sinuca")
    love.window.setMode(tela.largura, tela.altura, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })
    world = love.physics.newWorld(0, 0, true)

    adicionarBola(100, 100, {1, 0, 0}) -- ! Somente para teste
end

function love.draw()
    love.graphics.push()
    
    love.graphics.setBackgroundColor(64/255, 29/255, 8/255)
    
    -- Aplica o zoom e a rotação somente durante o desenho
    love.graphics.translate(tela.largura / 2, tela.altura / 2)
    love.graphics.rotate(tela.angulo)
    love.graphics.scale(tela.escala, tela.escala)

    desenharMesa()

    for _, bola in pairs(bolas) do
        desenharBola(bola)
    end

    love.graphics.pop()
end

function love.update(dt)
    -- Atualizar a física do mundo
    world:update(dt)

    -- TODO: Checar somente se tiver bolas em movimento
    for _, bola in pairs(bolas) do
        checarColisaoBorda(bola)
    end

    -- Controle do zoom
    if love.keyboard.isDown("up") then
        tela.escala = tela.escala + 0.2 * dt
    elseif love.keyboard.isDown("down") then
        tela.escala = math.max(0.1, tela.escala - 0.2 * dt)
    end
    -- Controle da rotação
    if love.keyboard.isDown("left") then
        tela.angulo = tela.angulo - 2 * dt 
    elseif love.keyboard.isDown("right") then
        tela.angulo = tela.angulo + 2 * dt
    end
end

-- * DESENHAR

function desenharBola(bola)
    local x, y = bola.body:getPosition()
    love.graphics.setColor(bola.cor)
    love.graphics.circle("fill", (-tela.largura/2) + x, (-tela.altura/2)+ y, bola.shape:getRadius())
end

function desenharMesa()
    local retanguloLargura = tela.largura - 100
    local retanguloAltura = tela.altura - 100
    local retanguloX = -retanguloLargura / 2
    local retanguloY = -retanguloAltura / 2

    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", retanguloX, retanguloY, retanguloLargura, retanguloAltura)
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

    local velocidadeInicialX = 100 -- ! Para testes apenas
    local velocidadeInicialY = 100 -- ! Para testes apenas
    body:setLinearVelocity(velocidadeInicialX, velocidadeInicialY)
    body:setLinearDamping(FRICCAO_BOLA)
end

function adicionarTodasAsBolas()
    -- Bola branca

    -- Demais bolas
end

-- * COLISÕES
function checarColisaoBorda(bola)
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