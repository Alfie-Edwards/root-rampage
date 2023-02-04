require "pixelcanvas"
require "level"
require "player"
require "time"
require "roots.roots"
require "roots.node"


function love.load()
    roots = Roots.new()
    Node.new(100, 100, nil, true, roots)
    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    -- setup game state
    level = Level.new()
    player = Player.new()
end

function love.mousepressed(x, y, button, istouch, presses)
    canvas_x, canvas_y = canvas:screen_to_canvas(x, y)
    roots:mousepressed(canvas_x, canvas_y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    roots:mousereleased(x, y, button)
end

function love.update(dt)
    roots:update(dt)
    t = t + dt

    player:input()
    player:move(dt)
end

function love.draw()
    canvas:set()

    level:draw()
    roots:draw()
    player:draw()

    canvas:draw()
end
