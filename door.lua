require "utils"
require "time"

Door = {
    SPRITE = sprite.make("VaultDoor.png"),
    ANIM_TIME = 2,

    x = nil,
    y = nil,
    open = nil,
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
    obj.open = true
    obj.t_anim = never

    return obj
end

function Door:open()
    if not self.open then
        self.t_anim = t
        self.open = true
    end
end

function Door:close()
    if self.open then 
        self.t_anim = t
        self.open = false
    end
end

function Door:draw(dt)
    local anim = 1
    if self.t_anim ~= never then
        anim = math.min(1, (t - self.t_anim) / Door.ANIM_TIME)
    end
    if not self.open then
        anim = 1 - anim
    end
    local angle = math.pi + math.pi / 2 * anim
    print(anim)

    love.graphics.draw(Door.SPRITE, self.x, self.y, angle, 1, 1, 3, 2)
end