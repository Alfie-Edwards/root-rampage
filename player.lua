require "direction"
require "sprite"
require "time"
require "utils"


Player = {
    -- config
    sprite_size = 24,
    size = 18,
    max_speed = 100,
    acceleration_time = 0.2,
    root_speed = 50,
    attack_radius = 12,
    attack_cooldown = 1,
    attack_centre_offset = 8,
    respawn_time = 3,
    spawn_pos = {x = 50, y = 50},

    attack_duration = 0.25,

    -- sprites
    sprite_sets = {
        idle = sprite.make_set("player/", {
            left = "PlayerleftIdle.png",
            right = "PlayerrightIdle.png",
            up = "PlayerbackIdle.png",
            down = "PlayerfrontIdle.png",
        }),
        walk = sprite.make_set("player/", {
            left = { "Player walk/Leftwalk1.png", "Player walk/Leftwalk2.png" },
            right = { "Player walk/Rightwalk1.png", "Player walk/Rightwalk2.png" },
            up = { "Player walk/Backwalk1.png", "Player walk/Backwalk2.png" },
            down = { "Player walk/Frontwalk1.png", "Player walk/Frontwalk2.png" },
        }),
        swing = sprite.make_set("player/", {
            left = { "Playerleftswing1.png", "Playerleftswing2.png" },
            right = { "Playerrightswing1.png", "Playerrightswing2.png" },
            up = { "Playerbackswing1.png", "Playerbackswing2.png" },
            down = { "Playerfrontswing1.png", "Playerfrontswing2.png" },
        }),
        dead = sprite.make_set("player/", {
            left = "PlayerleftIdle.png",
            right = "PlayerrightIdle.png",
            up = "PlayerbackIdle.png",
            down = "PlayerfrontIdle.png",
        }),
    },

    sounds = {
        swing = love.audio.newSource("assets/woosh.mp3", "static"),
        hit = love.audio.newSource("assets/wooshsmack.mp3", "static"),
        death = love.audio.newSource("assets/deathsouth.mp3", "static"),
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
    time_of_death = never,
}
setup_class("Player")

function Player.new()
    local obj = {}
    setup_instance(obj, Player)

    obj:spawn()

    return obj
end

function Player:is_swinging()
    return t - self.time_of_prev_attack < self.attack_duration
end

function Player:sprite()
    if self:is_swinging() then
        return sprite.sequence(
            sprite.directional(self.sprite_sets.swing, self.dir),
            self.attack_duration,
            self.time_of_prev_attack)
    end

    if self.speed ~= 0 then
        return sprite.cycling(sprite.directional(self.sprite_sets.walk, self.dir), 0.5)
    end

    return sprite.directional(self.sprite_sets.idle, self.dir)
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
    if self:is_swinging() then
        return
    end

    self.sounds.swing:play()

    self.time_of_prev_attack = t

    local atk_centre = self:attack_centre()
    local nodes_to_cut = roots:get_within_radius(atk_centre.x, atk_centre.y,
                                                 self.attack_radius)

    if #nodes_to_cut > 0 then
        self.sounds.hit:play()
    end

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
    if #(roots:get_within_radius(self.pos.x, self.pos.y, self.size / 2)) > 0 then
        most_recent.speed = self.root_speed
    end
    most_recent.speed = most_recent.speed * (0.5 + 0.5 * math.min(1, (t - most_recent.when) / self.acceleration_time))


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

function Player:bounds(pos)
    if pos == nil then
        pos = self.pos
    end

    local off = self.size / 2

    return { left   = pos.x - off,
             right  = pos.x + off,
             top    = pos.y - off,
             bottom = pos.y + off }
end

function Player:collision_x()
    local vel = { x = self:velocity().x, y = 0 }
    local next_pos = moved(self.pos, vel)

    local curr_bounds = self:bounds()
    local next_bounds = self:bounds(next_pos)

    local vel_x_adjustment = vel.x

    -- check player's left edge (right edge of obstacle)
    local curr_left_cell_x, top_cell_y    = level:cell(curr_bounds.left, next_bounds.top)
    local next_left_cell_x, bottom_cell_y = level:cell(next_bounds.left, next_bounds.bottom)

    for vert_cell=top_cell_y, bottom_cell_y do
        local vert_y = vert_cell * level:cell_size()

        if level:solid({x = next_bounds.left, y = vert_y}) then
            local intersection_x,_ = level:position_in_cell(next_bounds.left, vert_y)
            vel_x_adjustment = level:cell_size() - intersection_x
            break
        end
    end

    -- check player's right edge (left edge of obstacle)
    local curr_right_cell_x = level:cell_x(curr_bounds.right)
    local next_right_cell_x = level:cell_x(next_bounds.right)

    for vert_cell=top_cell_y, bottom_cell_y do
        local vert_y = vert_cell * level:cell_size()

        if level:solid({x = next_bounds.right, y = vert_y}) then
            local intersection_x,_ = level:position_in_cell(next_bounds.right, vert_y)
            vel_x_adjustment = - (intersection_x + 1)
            break
        end
    end

    -- return x velocity adjustment
    return vel_x_adjustment
end

function Player:collision_y()
    local vel = { x = 0, y = self:velocity().y }
    local next_pos = moved(self.pos, vel)

    local curr_bounds = self:bounds()
    local next_bounds = self:bounds(next_pos)

    local vel_y_adjustment = vel.y

    -- check player's top edge (bottom edge of obstacle)
    local left_cell_x, curr_top_cell_y  = level:cell(next_bounds.left, curr_bounds.top)
    local right_cell_x, next_top_cell_y = level:cell(next_bounds.right, next_bounds.top)

    for horiz_cell=left_cell_x, right_cell_x do
        local horiz_x = horiz_cell * level:cell_size()

        if level:solid({x = horiz_x, y = next_bounds.top}) then
            local _,intersection_y = level:position_in_cell(horiz_x, next_bounds.top)
            vel_y_adjustment = level:cell_size() - intersection_y
            break
        end
    end

    -- check player's bottom edge (top edge of obstacle)
    local curr_bottom_cell_y = level:cell_y(curr_bounds.bottom)
    local next_bottom_cell_y = level:cell_y(next_bounds.bottom)

    for horiz_cell=left_cell_x, right_cell_x do
        local horiz_x = horiz_cell * level:cell_size()

        if level:solid({x = horiz_x, y = next_bounds.bottom}) then
            local _,intersection_y = level:position_in_cell(horiz_x, next_bounds.bottom)
            vel_y_adjustment = - (intersection_y + 1)
            break
        end
    end

    -- return y velocity adjustment
    return vel_y_adjustment
end

function Player:move(dt)
    local movement = self:get_movement()
    if movement.when == never or self:is_swinging() then
        self.speed = 0
        return
    end

    self.speed = movement.speed * dt
    self.dir = movement.dir

    local vel = self:velocity()
    if vel.x ~= 0 then
        vel.x = vel.x + self:collision_x()
    end
    self.pos = moved(self.pos, {x = vel.x, y = 0})
    if vel.y ~= 0 then
        vel.y = vel.y + self:collision_y()
    end
    self.pos = moved(self.pos, {x = 0, y = vel.y})
end

function Player:update(dt)
    if self.time_of_death == never then
        self:input()
        self:move(dt)
    elseif (t - self.time_of_death) >= self.respawn_time then
        self:spawn()
    end
end

function Player:kill()
    self.time_of_death = t
    self.sounds.death:play()
end

function Player:spawn()
    self.time_of_death = never
    self.pos = shallowcopy(Player.spawn_pos)
    self.time_of_prev_attack = -self.attack_cooldown
end

function Player:draw()
    local sprite = self:sprite()

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    local sx = self.sprite_size / sprite:getWidth()
    local sy = self.sprite_size / sprite:getHeight()

    -- draw player
    local x = round(player.pos.x)
    local y = round(player.pos.y)

    if self.time_of_death == never then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, x, y, 0, sx, sy, ox, oy)
    else
        local opacity = 1 - math.min(1, (t - self.time_of_death) / self.respawn_time)
        love.graphics.setColor(1, 0.2, 0.2, opacity)
        love.graphics.draw(sprite, x, y, 0, sx, -sy, ox, oy)
    end
end
