local DEBUG = false
local tela = require("mesa").tela
local taco = require("tacada").taco

local mostrarMensagem = function(mensagem)
    -- Centraliza mensagem com sombra
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(mensagem, 2, (tela.altura / 2)+2, tela.largura, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(mensagem, 0, tela.altura / 2, tela.largura, "center")
end

local mostrarInformacoesDeDebug = function()
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

return {
    DEBUG = DEBUG,
    mostrarMensagem = mostrarMensagem,
    mostrarInformacoesDeDebug = mostrarInformacoesDeDebug
}