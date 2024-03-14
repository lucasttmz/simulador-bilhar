local DEBUG = false

local RAIO_BURACO = 30
local RAIO_BOLA = 15
local ESPACO_ENTRE_BOLAS = 2
local DESACELERACAO_BOLA = 0.4
local ELASTICIDADE_BOLA = 0.8
local DISTANCIA_MAXIMA = 400
local MODIFICADOR_VELOCIDADE = 4
local BOLA_BRANCA = 1

local world
local estadoAtual
local reposicionarBolaBranca = false
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
    {x = mesa.x , y = mesa.y - (RAIO_BURACO / 3)},
    {x = mesa.largura / 2 + mesa.x, y = mesa.y - (RAIO_BURACO / 3)},
    {x = mesa.largura + mesa.x, y = mesa.y - (RAIO_BURACO / 3)},
    {x = mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3)},
    {x = mesa.largura / 2 + mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3)},
    {x = mesa.largura + mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3)},
} 
local bordas = {
    {x1 = mesa.x, y1 = mesa.y, x2 = mesa.x + mesa.largura, y2 = mesa.y},
    {x1 = mesa.x + mesa.largura, y1 = mesa.y, x2=mesa.x + mesa.largura, y2 = mesa.y + mesa.altura},
    {x1 = mesa.x + mesa.largura, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y + mesa.altura},
    {x1 = mesa.x, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y}
}

function love.load()
    love.window.setTitle("Simulador Bilhar")
    love.window.setMode(tela.largura, tela.altura, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

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
            mostrarMensagem("Aperte <ESC> se quiser escolher a rotação novamente")
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
        world:update(dt) -- Checa todas as colisões

        if not bolasEmMovimento() then
            estadoAtual = "rotação"
        end

    elseif estadoAtual == "reposição" then
        realocarBolaBranca()
    end
end

function love.mousepressed(x, y, button)
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
        love.graphics.arc( "fill", x, y+3, RAIO_BOLA-4, 0.5, math.pi-0.5)
        love.graphics.arc( "fill", x, y-3, RAIO_BOLA-4, -0.5, -math.pi+0.5)
    end

    -- Número da bola
    x = x - 4
    y = y - 8
    if numBola - 1 >= 10 then
        x = x - 4 -- Espaçamento duplo para os dois dígitos
    end

    if numBola ~= BOLA_BRANCA then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(numBola - 1, x, y)
    end
end

function desenharMesa()
    -- Madeira da borda
    love.graphics.setColor(64/255, 29/255, 8/255)
    love.graphics.rectangle(
        "fill", 
        mesa.x - (RAIO_BURACO * 2), 
        mesa.y - (RAIO_BURACO * 2), 
        mesa.largura + (RAIO_BURACO * 4), 
        mesa.altura + (RAIO_BURACO * 4)
    )

    -- Camadas de madeira
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", 80, 15, mesa.largura + 80, mesa.altura + 90)
    love.graphics.setColor(64/255, 29/255, 8/255)
    love.graphics.rectangle("fill", 100, 40, mesa.largura + 40, mesa.altura + 40)
   
    -- Protetor da borda
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setLineWidth(3)
    for _, linha in pairs(bordas) do
        love.graphics.line(linha.x1, linha.y1, linha.x2, linha.y2)
    end

    -- Tecido
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.rectangle("fill", mesa.x, mesa.y, mesa.largura, mesa.altura)

    -- Buracos
    for _, buraco in pairs(buracos) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO)

        -- Textura
        love.graphics.setColor(0 ,0, 0, 0.5)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO * 0.90)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO * 0.75)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO * 0.50)
        love.graphics.circle("fill", buraco.x, buraco.y, RAIO_BURACO * 0.25)
    end
end

function desenharTaco()
    -- Utiliza o ângulo do taco para rotacionar em volta de taco.x e taco.y, coordenadas
    -- atualizadas em rotacionarTaco(). 
    love.graphics.push()
    love.graphics.translate(taco.x , taco.y)
    love.graphics.rotate(taco.angulo + math.pi / 2)  -- Para o taco apontar na bola

    -- Taco
    love.graphics.setColor(140/255, 70/255, 20/255, 1)
    love.graphics.rectangle("fill", -taco.largura / 2, -taco.comprimento / 2, taco.largura, taco.comprimento)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", -taco.largura / 2, -taco.comprimento / 2, taco.largura, taco.comprimento)

    -- Ponta
    love.graphics.setColor(100/255, 60/255, 20/255, 1)
    love.graphics.rectangle("fill", -taco.largura / 2, (taco.comprimento / 2) - 30, taco.largura, 30)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", -taco.largura / 2, (taco.comprimento / 2) - 30, taco.largura, 30)
    love.graphics.pop()
end

function desenharTragetoria()
    -- Utiliza o ângulo contrário ao taco para desenhar a tragetória da bola
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()
    local intervaloPontos = 5
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(3)
    for i=5, mesa.largura, 5 do
        local pontoX = bolaX + (intervaloPontos * i) * -math.cos(taco.angulo)
        local pontoY = bolaY + (intervaloPontos * i) * -math.sin(taco.angulo)

        -- Para de desenhar os pontos se eles sairem da mesa
        if (pontoX > mesa.x + mesa.largura) or (pontoX < mesa.x) or
           (pontoY > mesa.y + mesa.altura) or (pontoY < mesa.y) then
            break
        end

        love.graphics.points(pontoX, pontoY)
        love.graphics.setPointSize(love.graphics.getPointSize() * 0.95)
    end
end

-- * LÓGICA PRINCIPAL

function iniciarSimulacao()
    -- Inicia o sistema de colisões do LOVE2D
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks( checarEncapamento )
    estadoAtual = "rotação"

    -- Adiciona os objetos para responderem as colisões
    adicionarBordas()
    adicionarTodasAsBolas()
    adicionarBuracos()
end

function checarEncapamento(a, b)
    local bola = a:getUserData()
    local colidiuCom = b:getUserData()

    if colidiuCom == "buraco" then
        if bola == BOLA_BRANCA then
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

function mostrarMensagem(mensagem)
    -- Centraliza mensagem com sombra
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(mensagem, 2, (tela.altura / 2)+2, tela.largura, "center")
    love.graphics.setColor(1, 1, 1)
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
    -- Adiciona a física das bordas
    for _, borda in pairs(bordas) do
        local body = love.physics.newBody(world, borda.x, borda.y, "static")
        local shape = love.physics.newEdgeShape(borda.x1, borda.y1, borda.x2, borda.y2)
        love.physics.newFixture(body, shape, 1)
    end
end

function adicionarBuracos()
    -- Adiciona a física dos buracos
    for _, buraco in pairs(buracos) do
        local body = love.physics.newBody(world, buraco.x, buraco.y, "static")
        local shape = love.physics.newCircleShape(RAIO_BURACO)
        local fixture = love.physics.newFixture(body, shape, 1)

        fixture:setUserData("buraco") 
    end
end

-- * BOLAS

function adicionarBola(x, y, rgb, num)
    -- Adiciona a bola e sua física
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
    fixture:setUserData(num)                   -- ID para checar encaçapamento
end

function adicionarTodasAsBolas()
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
        x = baseX + ((i-1) * (RAIO_BOLA * 2))
        y = baseY + ((i-1) * RAIO_BOLA)
        for j=1,i do
            adicionarBola(x, y, cores[#bolas], numBolas[#bolas]+1)
            y = y - (RAIO_BOLA * 2)
        end
    end
end

function bolasEmMovimento()
    for _, bola in pairs(bolas) do
        local velocidadeX, velocidadeY = bola.body:getLinearVelocity()
        -- Se uma das bolas estiver em movimento, não checa as demais
        if velocidadeX ~= 0 or velocidadeY ~= 0 then
            return true
        end
    end

    return false
end

function realocarBolaBranca()
    -- Limites da mesa
    local LIMITE_ESQUERDA = mesa.x + RAIO_BOLA
    local LIMITE_DIREITA = mesa.x + mesa.largura - RAIO_BOLA
    local LIMITE_CIMA = mesa.y + RAIO_BOLA
    local LIMITE_BAIXO = mesa.y + mesa.altura - RAIO_BOLA
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
    bolas[BOLA_BRANCA].body:setPosition(mouseX, mouseY)
end

-- * TACO

function rotacionarTaco()
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()

    -- Angulo formado pelo lado oposto (y) e adjacente (x)
    taco.angulo = math.atan2(love.mouse.getY() - bolaY, love.mouse.getX() - bolaX)

    -- Centraliza o taco na metade do comprimento
    local distanciaCentralizada = taco.distanciaDuranteRotacao + (taco.comprimento / 2)
    taco.x = bolaX + distanciaCentralizada * math.cos(taco.angulo)
    taco.y = bolaY + distanciaCentralizada * math.sin(taco.angulo)
end

function distanciarTaco()
    local bolaX, bolaY = bolas[BOLA_BRANCA].body:getPosition()
    local mouseX, mouseY = love.mouse.getPosition()

    -- Limita a distância entre o contato com a bola e a distância máxima
    local distancia = math.min(
        math.max(
            (taco.comprimento / 2) + RAIO_BOLA, 
            math.sqrt((mouseX - bolaX)^2 + (mouseY - bolaY)^2)
        ),
        DISTANCIA_MAXIMA
    )
    taco.x = bolaX + distancia * math.cos(taco.angulo)
    taco.y = bolaY + distancia * math.sin(taco.angulo)
    taco.distanciaDoCentro = distancia
end

function efetuarTacada()
    -- Utiliza a distância calculada subtraida do centro do taco (mouse sempre fica 
    -- centralizado no taco).
    local forca = (taco.distanciaDoCentro - (taco.comprimento / 2) - RAIO_BOLA) * MODIFICADOR_VELOCIDADE

    bolas[BOLA_BRANCA].body:setLinearVelocity(
        forca * -math.cos(taco.angulo), -- Velocidade eixo x
        forca * -math.sin(taco.angulo)  -- Velocidade eixo y
    )
end
