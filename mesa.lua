local RAIO_BURACO = 30

local mesa = {
    x = 120,
    y = 60,
    largura = tela.largura - 240,
    altura = tela.altura - 120,
}    
local buracos = {
    { x = mesa.x , y = mesa.y - (RAIO_BURACO / 3) },
    { x = mesa.largura / 2 + mesa.x, y = mesa.y - (RAIO_BURACO / 3) },
    { x = mesa.largura + mesa.x, y = mesa.y - (RAIO_BURACO / 3) },
    { x = mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3) },
    { x = mesa.largura / 2 + mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3) },
    { x = mesa.largura + mesa.x, y = mesa.y + mesa.altura + (RAIO_BURACO / 3) },
} 
local bordas = {
    { x1 = mesa.x, y1 = mesa.y, x2 = mesa.x + mesa.largura, y2 = mesa.y },
    { x1 = mesa.x + mesa.largura, y1 = mesa.y, x2=mesa.x + mesa.largura, y2 = mesa.y + mesa.altura },
    { x1 = mesa.x + mesa.largura, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y + mesa.altura },
    { x1 = mesa.x, y1 = mesa.y + mesa.altura, x2 = mesa.x, y2 = mesa.y }
}

local function desenharMesa()
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

local function adicionarBordas()
    -- Adiciona a física das bordas
    for _, borda in pairs(bordas) do
        local body = love.physics.newBody(world, borda.x, borda.y, "static")
        local shape = love.physics.newEdgeShape(borda.x1, borda.y1, borda.x2, borda.y2)
        local fixture = love.physics.newFixture(body, shape, 1)
    end
end

local function adicionarBuracos()
    -- Adiciona a física dos buracos
    for _, buraco in pairs(buracos) do
        local body = love.physics.newBody(world, buraco.x, buraco.y, "static")
        local shape = love.physics.newCircleShape(RAIO_BURACO)
        local fixture = love.physics.newFixture(body, shape, 1)

        fixture:setUserData("buraco") 
    end
end


return {
    mesa = mesa,
    buracos = buracos,
    bordas = bordas,
    desenharMesa = desenharMesa,
    adicionarBuracos = adicionarBuracos,
    adicionarBordas = adicionarBordas,
}