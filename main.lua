require "hacking"
require "wincon"
require "pixelcanvas"
require "level"
require "player"
require "time"
require "door"
require "roots.roots"
require "roots.node"
require "roots.tree_spot"
require "roots.terminal"


function love.load()
    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    font = love.graphics.newFont("assets/font.ttf", 8, "none")
    love.graphics.setFont(font)
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    level = Level.new()

    -- setup roots
    roots = Roots.new()
    local cs = level:cell_size()
    local starting_tree_spot = TreeSpot.new(45.5 * cs, 13.5 * cs)
    roots:add_tree_spot(starting_tree_spot)
    roots:add_tree_spot(TreeSpot.new(35.5 * cs,  8.5 * cs))
    roots:add_tree_spot(TreeSpot.new(35.5 * cs, 18.5 * cs))
    roots:add_tree_spot(TreeSpot.new(15.5 * cs,  8.5 * cs))
    roots:add_tree_spot(TreeSpot.new(15.5 * cs, 18.5 * cs))
    starting_tree_spot:create_node()

    roots:add_terminal(Terminal.new( 2.5 * cs,  2 * cs))
    roots:add_terminal(Terminal.new( 2.5 * cs, 24 * cs))
    roots:add_terminal(Terminal.new(45.5 * cs,  2 * cs))
    roots:add_terminal(Terminal.new(45.5 * cs, 24 * cs))
    roots:add_terminal(Terminal.new(26.5 * cs,  8 * cs))
    roots:add_terminal(Terminal.new(26.5 * cs, 17 * cs))

    -- setup hacking
    door = Door.new(16 * 2 - 3, 16 * 15 - 2)
    door:close()
    hacking = Hacking.new(roots, door)

    -- setup win conditions
    wincon = Wincon.new(roots, hacking)

    -- setup game state
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
    hacking:update(dt)
    wincon:update(dt)
end

function love.draw()
    canvas:set()

    level:draw()
    roots:draw()
    player:draw()
    door:draw()
    hacking:draw()
    wincon:draw()
    love.graphics.setColor({1, 1, 1, 0.05})
    love.graphics.setBlendMode("add")
    love.graphics.rectangle("fill", 0, 0, canvas:width(), canvas:height())
    love.graphics.setBlendMode("alpha")

    canvas:draw()
end
