require "utils"
require "time"

Door = {
    SPRITE = sprite.make("VaultDoor.png"),
    ANIM_TIME = 2,
    ORIGIN_X = 17.5,
    ORIGIN_Y = 45.5,
    WIDTH = 24,
    HEIGHT = 48,
    TOOLTIP_OPEN = "< Escape",
    TOOLTIP_CLOSED = "Locked",

    x = nil,
    y = nil,
    is_open = nil,
    t_anim = nil,
}
setup_class("Door")

function Door.new(x, y)
    local obj = {}
    setup_instance(obj, Door)
    assert(x ~= nil)
    assert(y ~= nil)

    obj.x = x
    obj.y = y
    obj.is_open = true
    obj.t_anim = never

    return obj
end

function Door:get_center()
    return {x = self.x - Door.WIDTH / 2,
            y = self.y + Door.HEIGHT / 2}
end

function Door:open()
    if not self.is_open then
        self.t_anim = t
        self.is_open = true
    end
end

function Door:close()
    if self.is_open then
        self.t_anim = t
        self.is_open = false
    end
end

function Door:draw(dt)
    local anim = 1
    if self.t_anim ~= never then
        anim = math.min(1, (t - self.t_anim) / Door.ANIM_TIME)
    end
    if not self.is_open then
        anim = 1 - anim
    end
    local angle = math.pi / 2 * anim

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Door.SPRITE, self.x - Door.ORIGIN_X, self.y + Door.ORIGIN_Y, angle, 1, 1, Door.ORIGIN_X, Door.ORIGIN_Y)
end