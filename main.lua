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
    love.graphics.setBackgroundColor(64/255, 29/255, 8/255)

    iniciarSimulacao()
end

function love.draw()
    love.graphics.push() -- TODO: Checar se realmente precisa salvar o estado

    -- Aplica o zoom e a rotação somente durante o desenho
    love.graphics.translate(tela.largura / 2, tela.altura / 2)
    love.graphics.rotate(tela.angulo)
    love.graphics.scale(tela.escala, tela.escala)

    desenharMesa()

    for _, bola in pairs(bolas) do
        desenharBola(bola)
    end

    love.graphics.pop() -- TODO: Checar se realmente precise salvar o estado

    if DEBUG then
        mostrarInformacoesDeDebug()
    end
end

function love.update(dt)
    if estadoAtual == "rotação" then
        -- Rotaciona o taco em relação a bola branca
        -- 1) Atualizar o ãngulo do taco em relação ao mouse
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
    local mesaLargura = tela.largura - OFFSET_MESA * 2
    local mesaAltura = tela.altura - OFFSET_MESA * 2

    -- Largura e altura invertida por causa do translate que centraliza o sistema de coordenadas
    local mesaX = -mesaLargura / 2 
    local mesaY = -mesaAltura / 2

    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", mesaX, mesaY, mesaLargura, mesaAltura)
end

-- * LÓGICA PRINCIPAL

function iniciarSimulacao()
    world = love.physics.newWorld(0, 0, true)
    -- estadoAtual = "rotação"
    estadoAtual = "colisão" -- ! Para testes apenas

    adicionarTodasAsBolas()
end

function mostrarInformacoesDeDebug()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        "Estado Atual: " .. estadoAtual .. " - FPS: " .. tostring(love.timer.getFPS()), 
        5, 5
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

    local velocidadeInicialX = 100 -- ! Para testes apenas
    local velocidadeInicialY = 50 -- ! Para testes apenas
    body:setLinearVelocity(velocidadeInicialX, velocidadeInicialY)
    body:setLinearDamping(FRICCAO_BOLA)
end

function adicionarTodasAsBolas()
    -- Bola branca
    local x = (tela.largura / 4)
    local y = (tela.altura / 2)
    adicionarBola(x, y, {1, 1, 1})
    -- Demais bolas
end

function checarMovimentoMinimo(bola)
    -- Para as bolas que estão se lentas para agilizar a transição de estados
    local vx, vy = bola.body:getLinearVelocity()
    if (math.abs(vx) < MOVIMENTO_MINIMO and math.abs(vy) < MOVIMENTO_MINIMO) then
        bola.body:setLinearVelocity(0, 0)
    end
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