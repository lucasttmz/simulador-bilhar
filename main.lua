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
end

function love.draw()
    love.graphics.setBackgroundColor(64/255, 29/255, 8/255)
    -- Aplica o zoom e a rotação
    love.graphics.push()

    love.graphics.translate(tela.largura / 2, tela.altura / 2)
    love.graphics.rotate(tela.angulo)
    love.graphics.scale(tela.escala, tela.escala)

    desenharMesa()

    love.graphics.pop()
end

function love.update(dt)
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

-- ! DESENHAR

function desenharMesa()
    local retanguloLargura = tela.largura - 100
    local retanguloAltura = tela.altura - 100
    local retanguloX = -retanguloLargura / 2
    local retanguloY = -retanguloAltura / 2

    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", retanguloX, retanguloY, retanguloLargura, retanguloAltura)
end
