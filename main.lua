require "utils.utils"
require "asset_cache"
assets = AssetCache()
require "ui.view"
require "screens.game"
require "screens.main_menu"
require "pixelcanvas"

function love.load()

    -- setup rendering
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    font = assets:get_font("font")
    font16 = assets:get_font("font", "ttf", 16)
    font24 = assets:get_font("font", "ttf", 24)
    font32 = assets:get_font("font", "ttf", 32)
    love.graphics.setFont(font)
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineStyle("rough")
    canvas = PixelCanvas({ 768, 432 })

    love.keyboard.setKeyRepeat(true)

    view = View()
    view:set_content(MainMenu())
end

function love.mousemoved(x, y, dx, dy, istouch)
    local pos = canvas:screen_to_canvas(x, y)
    local disp = canvas:screen_to_canvas(dx, dy)
    view:mousemoved(pos.x, pos.y, disp.x, disp.y)
end

function love.mousepressed(x, y, button)
    local pos = canvas:screen_to_canvas(x, y)
    view:mousepressed(pos.x, pos.y, button)
end

function love.mousereleased(x, y, button)
    local pos = canvas:screen_to_canvas(x, y)
    view:mousereleased(pos.x, pos.y, button)
end

function love.textinput(t)
    view:textinput(t)
end

function love.wheelmoved(x, y)
    view:wheelmoved(-x, -y)
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
