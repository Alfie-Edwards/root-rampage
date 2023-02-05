require "time"
require "utils"


Direction = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3 }

function sprite_set(tab)
    local res = {}
    for k, v in pairs(tab) do
        if type(v) == "string" then
            res[k] = love.graphics.newImage("assets/player/"..v)
        elseif type(v) == "table" then
            res[k] = sprite_set(v)
        else
            assert(false)
        end
    end
    return res
end

Player = {
    -- config
    size = 24,
    max_speed = 200,
    attack_radius = 12,
    attack_cooldown = 1,
    attack_centre_offset = 8,

    attack_duration = 0.25,

    -- sprites
    sprite_sets = {
        idle = sprite_set({
            left = "PlayerleftIdle.png",
            right = "PlayerrightIdle.png",
            up = "PlayerbackIdle.png",
            down = "PlayerfrontIdle.png",
        }),
        walk = sprite_set({
            left = { "Player walk/Leftwalk1.png", "Player walk/Leftwalk2.png" },
            right = { "Player walk/Rightwalk1.png", "Player walk/Rightwalk2.png" },
            up = { "Player walk/Backwalk1.png", "Player walk/Backwalk2.png" },
            down = { "Player walk/Frontwalk1.png", "Player walk/Frontwalk2.png" },
        }),
        swing = sprite_set({
            left = { "Playerleftswing1.png", "Playerleftswing2.png" },
            right = { "Playerrightswing1.png", "Playerrightswing2.png" },
            up = { "Playerbackswing1.png", "Playerbackswing2.png" },
            down = { "Playerfrontswing1.png", "Playerfrontswing2.png" },
        }),
    },

    -- main state
    pos = { x = 0, y = 0 },
    speed = 0,
    dir = Direction.DOWN,
    attack_centre = nil,

    -- other bits of state
    started_holding = {
        LEFT = 0,
        RIGHT = 0,
        UP = 0,
        DOWN = 0,
    },

    time_of_prev_attack = never,
}
setup_class("Player")

function Player.new()
    local obj = {}
    setup_instance(obj, Player)

    obj.pos = { x = 50, y = 50 }
    obj.time_of_prev_attack = -obj.attack_cooldown

    return obj
end

function Player:directional_sprite(set)
    if self.dir == Direction.UP then
        return set.up
    elseif self.dir == Direction.DOWN then
        return set.down
    elseif self.dir == Direction.LEFT then
        return set.left
    elseif self.dir == Direction.RIGHT then
        return set.right
    end

    return set.down
end

function Player:is_swinging()
    return t - self.time_of_prev_attack < self.attack_duration
end

function Player:sequence_sprite(set, duration, start_time)
    local time_since = t - start_time
    local progress = (time_since % duration) / duration
    local index = math.floor(progress * #set) + 1
    return set[index]
end

function Player:cycling_sprite(set, period)
    return self:sequence_sprite(set, period, 0)
end

function Player:sprite()
    if self:is_swinging() then
        return self:sequence_sprite(
            self:directional_sprite(self.sprite_sets.swing),
            self.attack_duration,
            self.time_of_prev_attack)
    end

    if self.speed ~= 0 then
        return self:cycling_sprite(self:directional_sprite(self.sprite_sets.walk), 0.5)
    end

    return self:directional_sprite(self.sprite_sets.idle)
end

function Player:attack_centre()
    local adj = {}
    if self.dir == Direction.UP then
        adj = { x = 0, y = -self.attack_centre_offset }
    elseif self.dir == Direction.DOWN then
        adj = { x = 0, y = self.attack_centre_offset }
    elseif self.dir == Direction.LEFT then
        adj = { x = -self.attack_centre_offset, y = 0 }
    elseif self.dir == Direction.RIGHT then
        adj = { x = self.attack_centre_offset, y = 0 }
    end

    return moved(self.pos, adj)
end

function Player:attack()
    if t - self.time_of_prev_attack > self.attack_cooldown then
        self.time_of_prev_attack = t
    end

    local atk_centre = self:attack_centre()
    local nodes_to_cut = roots:get_within_radius(atk_centre.x, atk_centre.y,
                                                 self.attack_radius)

    for _,node in ipairs(nodes_to_cut) do
        node:cut()
    end
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

    if love.keyboard.isDown("space") then
        self:attack()
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
    if movement.when == never or self:is_swinging() then
        self.speed = 0
        return
    end

    self.speed = movement.speed * dt
    self.dir = movement.dir

    local vel = self:collide(self.pos, self:velocity())

    self.pos = moved(self.pos, vel)
end

function Player:draw()
    local sprite = self:sprite()

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    local sx = self.size / sprite:getWidth()
    local sy = self.size / sprite:getHeight()

    -- draw attack
    if self:is_swinging() then
        local atk = self:attack_centre()

        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.circle("fill", atk.x, atk.y, self.attack_radius)
    end

    -- draw player
    local x = round(player.pos.x)
    local y = round(player.pos.y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, x, y, 0, sx, sy, ox, oy)
end
