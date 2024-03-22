local bolas = require("bolas")

local DISTANCIA_MAXIMA = 400
local MODIFICADOR_VELOCIDADE = 4
local taco = {
    comprimento = 400,
    largura = 10,
    distanciaDuranteRotacao = 30,
    distanciaDoCentro = 30,
    angulo = 0,
}

local desenharTaco = function()
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

local rotacionarTaco = function()
    local bolaX, bolaY = bolas.bolas[bolas.BRANCA].body:getPosition()

    -- Angulo formado pelo lado oposto (y) e adjacente (x)
    taco.angulo = math.atan2(love.mouse.getY() - bolaY, love.mouse.getX() - bolaX)

    -- Centraliza o taco na metade do comprimento
    local distanciaCentralizada = taco.distanciaDuranteRotacao + (taco.comprimento / 2)
    taco.x = bolaX + distanciaCentralizada * math.cos(taco.angulo)
    taco.y = bolaY + distanciaCentralizada * math.sin(taco.angulo)
end

local distanciarTaco = function()
    local bolaX, bolaY = bolas.bolas[bolas.BRANCA].body:getPosition()
    local mouseX, mouseY = love.mouse.getPosition()

    -- Limita a distância entre o contato com a bola e a distância máxima
    local distancia = math.min(
        math.max(
            (taco.comprimento / 2) + bolas.RAIO, 
            math.sqrt((mouseX - bolaX)^2 + (mouseY - bolaY)^2)
        ),
        DISTANCIA_MAXIMA
    )
    taco.x = bolaX + distancia * math.cos(taco.angulo)
    taco.y = bolaY + distancia * math.sin(taco.angulo)
    taco.distanciaDoCentro = distancia
end

local efetuarTacada = function()
    -- Utiliza a distância calculada subtraida do centro do taco (mouse sempre fica 
    -- centralizado no taco).
    local forca = (taco.distanciaDoCentro - (taco.comprimento / 2) - bolas.RAIO) * MODIFICADOR_VELOCIDADE

    bolas.bolas[bolas.BRANCA].body:setLinearVelocity(
        forca * -math.cos(taco.angulo), -- Velocidade eixo x
        forca * -math.sin(taco.angulo)  -- Velocidade eixo y
    )
end

local desenharTragetoria = function()
    local mesa = require("mesa").mesa

    -- Utiliza o ângulo contrário ao taco para desenhar a tragetória da bola
    local bolaX, bolaY = bolas.bolas[bolas.BRANCA].body:getPosition()
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

return {
    taco = taco,
    desenharTaco = desenharTaco,
    rotacionarTaco = rotacionarTaco,
    distanciarTaco = distanciarTaco,
    efetuarTacada = efetuarTacada,
    desenharTragetoria = desenharTragetoria,
}