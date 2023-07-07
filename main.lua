require "utils.utils"
require "asset_cache"
assets = AssetCache.new()
require "ui.view"
require "screens.game"
require "screens.main_menu"
require "pixelcanvas"

function love.load()

    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    font = assets:get_font("font")
    love.graphics.setFont(font)
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas.new({ 768, 432 })

    view = View.new()
    view:set_content(MainMenu.new())
end

function love.mousemoved(x, y, dx, dy, istouch)
    local pos = canvas:screen_to_canvas(x, y)
    view:mousemoved(pos.x, pos.y, dx, dy)
end

function love.mousepressed(x, y, button)
    local pos = canvas:screen_to_canvas(x, y)
    view:click(pos.x, pos.y, button)
end

function love.keypressed(key, scancode, isrepeat)
   view:keypressed(key)
end

function love.update(dt)
    view:update(dt)
end

function love.draw()
    canvas:set()

    view:draw()

    canvas:draw()
end
