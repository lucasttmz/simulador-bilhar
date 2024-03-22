estadoAtual = "rotação" -- Estado da partida
world = nil             -- Mundo que contém os objetos da colisão
tela = {
    largura = 1280,
    altura = 720,
}

local utils = require("utils")
local mesa = require("mesa")
local tacada = require("tacada")
local bolas = require("bolas")

function love.load()
    love.window.setTitle("Simulador Bilhar")
    love.window.setMode(tela.largura, tela.altura, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    -- Cria o mundo de colisões
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(bolas.checarEncapamento)

    -- Adiciona os objetos para responderem as colisões
    mesa.adicionarBordas()
    bolas.adicionarTodasAsBolas()
    mesa.adicionarBuracos()
end

function love.draw()
    mesa.desenharMesa()

    for _, bola in pairs(bolas.bolas) do
        bolas.desenharBola(bola)
    end

    if estadoAtual == "rotação" or estadoAtual == "distância" then
        tacada.desenharTaco()
        tacada.desenharTragetoria()

        if estadoAtual == "distância" then
            utils.mostrarMensagem("Aperte <ESC> se quiser escolher a rotação novamente")
        end

    elseif estadoAtual == "reposição" then
        utils.mostrarMensagem("Escolha a posição da bola branca")
    end

    if utils.DEBUG then
        utils.mostrarInformacoesDeDebug()
    end
end

function love.update(dt)
    if estadoAtual == "rotação" then
        tacada.rotacionarTaco()

    elseif estadoAtual == "distância" then
        tacada.distanciarTaco()

    elseif estadoAtual == "colisão" then
        world:update(dt) -- Checa todas as colisões

        if not bolas.bolasEmMovimento() then
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
            tacada.efetuarTacada()
            estadoAtual = "colisão"

        elseif estadoAtual == "reposição" then
            estadoAtual = "rotação"
        end
    end
end

function love.keypressed(key)
    if key == "escape" and estadoAtual == "distância" then
        estadoAtual = "rotação"
    elseif key == "f1" then
        utils.DEBUG = not utils.DEBUG
    end
end
