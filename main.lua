require "utils"
require "game"
require "pixelcanvas"

function love.load()

    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    font = love.graphics.newFont("assets/font.ttf", 8, "none")
    love.graphics.setFont(font)
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    game = Game.new(Game.MODE_ALL)
    tick_offset = 0
end

function love.update(dt)
    tick_offset = tick_offset + dt
    while tick_offset / game.state.dt > 1 do
        tick_offset = tick_offset - game.state.dt
        game:tick()
    end
end

function love.draw()
    game:draw()
end