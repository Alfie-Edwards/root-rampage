require "utils"


Level = {
    img = love.graphics.newImage("assets/level-img.png"),
    geom = love.graphics.newImage("assets/level-geom.bmp"),
}
setup_class("Level")

function Level.new()
    local obj = {}
    setup_instance(obj, Level)

    obj.geom:setFilter("nearest")

    return obj
end

function Level:draw_geom(opacity)
    if opacity == nil then
        opacity = 1
    end

    local scale_x = canvas:width() / self.geom:getWidth()
    local scale_y = canvas:height() / self.geom:getHeight()

    love.graphics.draw(self.geom, 0, 0, 0, scale_x, scale_y)
end

function Level:draw()
    self:draw_geom()
end
