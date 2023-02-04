require "time"
require "utils"


Direction = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3 }

Player = {
    -- config
    img = love.graphics.newImage("assets/player.png"),
    size = 24,
    max_speed = 200,

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

    for direction, time in pairs(self.started_holding) do
        if time > most_recent.when then
            most_recent = { dir = Direction[direction], when = time }
        end
    end

    most_recent.speed = self.max_speed

    return most_recent
end

function Player:velocity()
    if self.dir == Direction.UP then
        return { x = 0, y = -self.speed }
    elseif self.dir == Direction.DOWN then
        return { x = 0, y = self.speed }
    elseif self.dir == Direction.LEFT then
        return { x = -self.speed, y = 0 }
    elseif self.dir == Direction.RIGHT then
        return { x = self.speed, y = 0 }
    end
end

function Player:collide()
    local vel = self:velocity()
    local next_pos = moved(self.pos, vel)

    if not level:solid(next_pos) then
        return vel
    end

    local old_cell_x, old_cell_y = level:cell(self.pos.x, self.pos.y)
    local new_cell_x, new_cell_y = level:cell(next_pos.x, next_pos.y)

    local intersection_x, intersection_y = level:position_in_cell(next_pos.x, next_pos.y)
    local cs = level:cell_size()

    local adjusted_vel = shallowcopy(vel)

    if old_cell_x ~= new_cell_x then
        if vel.x > 0 then
            -- left edge
            adjusted_vel.x = adjusted_vel.x - (intersection_x + 1)
        else
            -- right edge
            adjusted_vel.x = adjusted_vel.x + cs - intersection_x
        end
    else
        if vel.y > 0 then
            -- top edge
            adjusted_vel.y = adjusted_vel.y - (intersection_y + 1)
        else
            -- bottom edge
            adjusted_vel.y = adjusted_vel.y + cs - intersection_y
        end
    end

    return adjusted_vel
end

function Player:move(dt)
    local movement = self:get_movement()
    if movement.when == never then
        return
    end

    self.speed = movement.speed * dt
    self.dir = movement.dir

    local vel = self:collide(self.pos, self:velocity())

    self.pos = moved(self.pos, vel)
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

    local sx = self.size / self.img:getWidth()
    local sy = self.size / self.img:getHeight()

    love.graphics.draw(player.img, x, y, orientation, sx, sy, ox, oy)
    -- love.graphics.circle("fill", player.pos.x, player.pos.y, 10)
end
