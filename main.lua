require "pixelcanvas"
require "level"
require "player"
require "time"


function love.load()
    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    -- setup game state
    level = Level.new()
    player = Player.new()
end

function love.update(dt)
    t = t + dt

    player:input()
    player:move(dt)

    if level:solid(player.pos) then
        print(t.."  in")
    end
end

function love.draw()
    canvas:set()

    level:draw()
    player:draw()

    canvas:draw()
end
