require "time"
require "utils"


Direction = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3 }

Player = {
    -- config
    img = love.graphics.newImage("assets/player.png"),
    max_speed = 350,

    -- main state
    pos = { x = 0, y = 0 },
    speed = 0,
    dir = Direction.UP,

    -- other bits of state
    started_holding = {
        LEFT = 0,
        RIGHT = 0,
        UP = 0,
        DOWN = 0,
    },
}
setup_class("Player")

function Player.new()
    local obj = {}
    setup_instance(obj, Player)

    obj.pos = { x = 50, y = 50 }

    return obj
end

function Player:input()
    if love.keyboard.isDown("up", "w") then
        if self.started_holding.UP == never then
            self.started_holding.UP = t
        end
    else
        self.started_holding.UP = never
    end
    if love.keyboard.isDown("down", "s") then
        if self.started_holding.DOWN == never then
            self.started_holding.DOWN = t
        end
    else
        self.started_holding.DOWN = never
    end
    if love.keyboard.isDown("left", "a") then
        if self.started_holding.LEFT == never then
            self.started_holding.LEFT = t
        end
    else
        self.started_holding.LEFT = never
    end
    if love.keyboard.isDown("right", "d") then
        if self.started_holding.RIGHT == never then
            self.started_holding.RIGHT = t
        end
    else
        self.started_holding.RIGHT = never
    end
end

function Player:get_movement()
    local most_recent = { dir = Direction.UP, when = never }

    if self.started_holding.LEFT > most_recent.when then
        most_recent = { dir = Direction.LEFT, when = self.started_holding.LEFT }
    end

    if self.started_holding.RIGHT > most_recent.when then
        most_recent = { dir = Direction.RIGHT, when = self.started_holding.RIGHT }
    end

    if self.started_holding.UP > most_recent.when then
        most_recent = { dir = Direction.UP, when = self.started_holding.UP }
    end

    if self.started_holding.DOWN > most_recent.when then
        most_recent = { dir = Direction.DOWN, when = self.started_holding.DOWN }
    end

    most_recent.speed = self.max_speed

    return most_recent
end

function Player:move(dt)
    local movement = self:get_movement()
    if movement.when == never then
        return
    end

    self.speed = movement.speed
    self.dir = movement.dir

    local real_speed = self.speed * dt

    if self.dir == Direction.UP then
        self.pos.y = self.pos.y - real_speed
    elseif self.dir == Direction.DOWN then
        self.pos.y = self.pos.y + real_speed
    elseif self.dir == Direction.LEFT then
        self.pos.x = self.pos.x - real_speed
    elseif self.dir == Direction.RIGHT then
        self.pos.x = self.pos.x + real_speed
    end
end

function Player:orientation()
    if self.dir == Direction.UP then
        return 0
    elseif self.dir == Direction.DOWN then
        return math.pi
    elseif self.dir == Direction.LEFT then
        return math.pi * 1.5
    elseif self.dir == Direction.RIGHT then
        return math.pi * 0.5
    end

end

function Player:draw()
    local orientation = self:orientation()

    local x = player.pos.x
    local y = player.pos.y

    local ox = player.img:getWidth() / 2
    local oy = player.img:getHeight() / 2

    love.graphics.draw(player.img, x, y, orientation, 1, 1, ox, oy)
    -- love.graphics.circle("fill", player.pos.x, player.pos.y, 10)
end
