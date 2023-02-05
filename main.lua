require "pixelcanvas"
require "level"
require "player"
require "time"
require "roots.roots"
require "roots.node"
require "roots.tree_spot"
require "roots.terminal"


function love.load()
    font = love.graphics.newFont(14)

    roots = Roots.new()
    local starting_tree_spot = TreeSpot.new(200, 200)
    roots:add_tree_spot(starting_tree_spot)
    roots:add_tree_spot(TreeSpot.new(300, 230))
    roots:add_tree_spot(TreeSpot.new(500, 200))
    starting_tree_spot:create_node()

    roots:add_terminal(Terminal.new(550, 100))
    roots:add_terminal(Terminal.new(150, 250))

    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    -- setup game state
    level = Level.new()
    player = Player.new()
    timers = {}
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

    player:update(dt)
end

function love.draw()
    canvas:set()

    level:draw()
    roots:draw()
    player:draw()

    canvas:draw()
end
