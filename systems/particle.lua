require "systems.level"
require "systems.node"
require "states.particle"

PARTICLE = {
    BOMB_FUSE = 1,
    BOMB_RADIUS = 18,
    BOMB_WALL_OFFSET = 32,
    BOMB_FRAGS = 15,
    FRAG_RADIUS = 16,
    FRAG_SPEED = 500,
    FRAG_MAX_LIFETIME = 0.15,
    EXPLOSION_DURATION = 0.2,
    CLOUDLET_SPEED = 3,
    CLOUDLET_DURATION = 2,
    CLOUDLETS_PER_UPDATE = 2,
    BUZZ_DURATION = 0.2,
}

function PARTICLE.update(state, inputs)
    local particles = state.particles

    local to_kill = {}
    local to_spawn = {}
    for i, particle in pairs(particles) do
        if particle.kind == "bomb" then
            if particle.duration < (state.t - particle.t0) then
                table.insert(to_kill, i)

                for _ = 1, PARTICLE.BOMB_FRAGS do
                    local dir = love.math.random() * 2 * math.pi
                    table.insert(
                        to_spawn,
                        PARTICLE.create_frag(
                            state.t,
                            particle.x + math.cos(dir) * 0.1,
                            particle.y + math.sin(dir) * 0.1,
                            particle.vx * 1.8 + math.cos(dir) * PARTICLE.FRAG_SPEED,
                            particle.vy * 1.8 + math.sin(dir) * PARTICLE.FRAG_SPEED,
                            love.math.random() * PARTICLE.FRAG_MAX_LIFETIME
                        )
                    )
                end
                table.insert(
                    to_spawn,
                    PARTICLE.create_explosion(
                        state,
                        particle.x,
                        particle.y,
                        PARTICLE.BOMB_RADIUS
                    )
                )

            elseif PARTICLE.move(particle, state.dt) then
                table.insert(to_kill, i)

                local a = math.atan2(particle.vy, particle.vx) + math.pi
                for _ = 1, PARTICLE.BOMB_FRAGS do
                    local dir = a + (love.math.random() - 0.5) * math.pi
                    table.insert(
                        to_spawn,
                        PARTICLE.create_frag(
                            state.t,
                            particle.x + math.cos(dir) * 0.1,
                            particle.y + math.sin(dir) * 0.1,
                            math.cos(dir) * PARTICLE.FRAG_SPEED,
                            math.sin(dir) * PARTICLE.FRAG_SPEED,
                            love.math.random() * PARTICLE.FRAG_MAX_LIFETIME
                        )
                    )
                end
                table.insert(
                    to_spawn,
                    PARTICLE.create_explosion(
                        state,
                        particle.x,
                        particle.y,
                        PARTICLE.FRAG_RADIUS
                    )
                )
                table.insert(
                    to_spawn,
                    PARTICLE.create_explosion(
                        state,
                        particle.x + math.cos(a) * PARTICLE.BOMB_WALL_OFFSET,
                        particle.y + math.sin(a) * PARTICLE.BOMB_WALL_OFFSET,
                        PARTICLE.BOMB_RADIUS
                    )
                )
            end
        elseif particle.kind == "frag" then
            if particle.duration < (state.t - particle.t0) or PARTICLE.move(particle, state.dt) then
                table.insert(to_kill, i)
                table.insert(to_spawn, PARTICLE.create_explosion(state, particle.x, particle.y, PARTICLE.FRAG_RADIUS))
            end
        elseif particle.kind == "explosion" then
            if particle.duration < (state.t - particle.t0) then
                table.insert(to_kill, i)
            end
        elseif particle.kind == "cloud" then
            local life_remaining = particle.duration - (state.t - particle.t0)
            if life_remaining <= 0 then
                table.insert(to_kill, i)
            else
                if life_remaining > PARTICLE.CLOUDLET_DURATION / 3 then
                    for i = 1, PARTICLE.CLOUDLETS_PER_UPDATE do
                        local x, y = random_in_circle(particle.x, particle.y, particle.vx)
                        if not LEVEL.solid({x = x, y = y}) then
                            PARTICLE.add_cloudlet(state, x, y)
                        end
                    end
                end
                local effective_r = particle.vx + PLAYER.size / 2
                if sq_dist(state.player.pos.x, state.player.pos.y, particle.x, particle.y) < (effective_r * effective_r) then
                    PLAYER.kill(state.player, state.t)
                end
            end
        elseif particle.kind == "cloudlet" then
            if particle.duration < (state.t - particle.t0) then
                table.insert(to_kill, i)
            else
                PARTICLE.move(particle, state.dt, "bounce")
            end
        elseif particle.kind == "buzz" then
            if particle.duration < (state.t - particle.t0) then
                table.insert(to_kill, i)
            else
                PARTICLE.brownian(particle, 20)
                PARTICLE.move(particle, state.dt, "bounce")
            end
        end
    end

    for _, i in ipairs(to_kill) do
        state.particles[i] = nil
    end

    for _, particle in ipairs(to_spawn) do
        PropertyTable.append(particles, particle)
    end
end

function PARTICLE.draw(state, inputs, dt)
    local particles = state.particles

    for _, particle in pairs(particles) do
        local x = particle.x + particle.vx * dt
        local y = particle.y + particle.vy * dt

        if particle.kind == "bomb" then
            local t = (state.t + dt) - particle.t0
            local image = assets:get_image("bomb")
            love.graphics.draw(
                image,
                x - (x - image:getWidth() / 2) % 1,
                y - (y - image:getHeight() / 2) % 1,
                t * 6,
                1,
                1,
                image:getWidth() / 2,
                image:getHeight() / 2
            )
        elseif particle.kind == "frag" then
            love.graphics.setColor({1, 0, 0, 1})
            love.graphics.points(x, y)
        elseif particle.kind == "explosion" then
            local progress = clamp(((state.t + dt) - particle.t0) / particle.duration, 0, 1)
            love.graphics.setColor({1, 1, 1, 1 - progress})
            love.graphics.circle("fill", particle.x, particle.y, particle.vx)
        elseif particle.kind == "cloudlet" then
            local progress = clamp(((state.t + dt) - particle.t0) / particle.duration, 0, 1)
            love.graphics.setColor({0.5, 0.8, 0.2, 1 - progress})
            love.graphics.circle("fill", x, y, 1)
        elseif particle.kind == "buzz" then
            love.graphics.setColor({0.6, 0.0, 0.0, 1})
            love.graphics.points(x, y)
        end
    end
end

function PARTICLE.brownian(particle, scale)
    local vx, vy = random_in_circle(particle.vx, particle.vy, 2 * scale)
    if (vx * vy) == 0 then 
        vx = scale
    end
    local s = scale / math.sqrt(vx * vx + vy * vy)
    particle.vx = vx * s
    particle.vy = vy * s
end

function PARTICLE.move(particle, dt, mode)
    local x0 = particle.x / LEVEL.cell_size()
    local y0 = particle.y / LEVEL.cell_size()
    local vx = particle.vx / LEVEL.cell_size()
    local vy = particle.vy / LEVEL.cell_size()
    local t = 0
    local x = x0
    local y = y0

    local dtx, dty, t_remaining, x_offset, y_offset
    while true do

        -- Figure out how far in t we are from hitting the next cell boundaries in x and y.
        -- Only works for positive x and y positions.
        if vx == 0 then
            dtx = math.huge
        elseif vx < 0 then
            dtx = (-x % 1 - 1) / vx
        else
            dtx = (1 - x % 1) / vx
        end
        if vy == 0 then
            dty = math.huge
        elseif vy < 0 then
            dty = (-y % 1 - 1) / vy
        else
            dty = (1 - y % 1) / vy
        end

        -- If we won't hit either boundary before dt, apply full move and return false for no collision.
        t_remaining = (dt - t)
        if dtx > t_remaining and dty > t_remaining then
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            return false
        end

        -- Advance t.
        if dtx < dty then
            t = t + dtx
        else
            t = t + dty
        end

        -- Move.
        x = x0 + vx * t
        y = y0 + vy * t

        -- Calculate which cell we're at the boundary of.
        x_offset = 0
        y_offset = 0
        if dtx <= dty then
            if vx > 0 then
                x_offset = 0.5
            else
                x_offset = -0.5
            end
        end
        if dty <= dtx then
            if vy > 0 then
                y_offset = 0.5
            else
                y_offset = -0.5
            end
        end

        -- Check if cell is solid, if so, apply move and return true for a collision.
        if LEVEL.cell_solid(x + x_offset, y + y_offset) then
            particle.x = x * LEVEL.cell_size()
            particle.y = y * LEVEL.cell_size()
            if mode == "bounce" then
                if x_offset ~= 0 then
                    particle.vx = -particle.vx
                end
                if y_offset ~= 0 then
                    particle.vy = -particle.vy
                end
            end
            if mode == "stop" then
                if x_offset ~= 0 then
                    particle.vx = 0
                end
                if y_offset ~= 0 then
                    particle.vy = 0
                end
            end
            return true
        end
    end
end

function PARTICLE.create_bomb(t, x, y, vx, vy)
    return ParticleState("bomb", t, x, y, vx, vy, PARTICLE.BOMB_FUSE)
end

function PARTICLE.add_bomb(state, x, y, vx, vy)
    PropertyTable.append(state.particles, PARTICLE.create_bomb(state.t, x, y, vx, vy))
end

function PARTICLE.create_frag(t, x, y, vx, vy, fuse)
    return ParticleState("frag", t, x, y, vx, vy, fuse)
end

function PARTICLE.add_frag(state, x, y, vx, vy, fuse)
    PropertyTable.append(state.particles, PARTICLE.create_frag(state.t, x, y, vx, vy, fuse))
end

function PARTICLE.create_explosion(state, x, y, r)
    local nodes_to_cut = state.nodes:in_radius(x, y, r)
    for _, node in ipairs(nodes_to_cut) do
        NODE.cut(state, node)
    end
    return ParticleState("explosion", state.t, x, y, r, 0, PARTICLE.EXPLOSION_DURATION)
end

function PARTICLE.add_explosion(state, x, y, r)
    PropertyTable.append(state.particles, PARTICLE.create_explosion(state, x, y, r))
end

function PARTICLE.create_cloud(state, x, y, r, duration)
    return ParticleState("cloud", state.t, x, y, r, 0, duration)
end

function PARTICLE.add_cloud(state, x, y, r, duration)
    PropertyTable.append(state.particles, PARTICLE.create_cloud(state, x, y, r, duration))
end

function PARTICLE.create_cloudlet(state, x, y)
    local a = love.math.random() * math.pi * 2
    return ParticleState("cloudlet", state.t, x, y, math.cos(a) * PARTICLE.CLOUDLET_SPEED, math.sin(a) * PARTICLE.CLOUDLET_SPEED, PARTICLE.CLOUDLET_DURATION)
end

function PARTICLE.add_cloudlet(state, x, y)
    PropertyTable.append(state.particles, PARTICLE.create_cloudlet(state, x, y))
end

function PARTICLE.create_buzz(state, x, y)
    local a = love.math.random() * math.pi * 2
    return ParticleState("buzz", state.t, x, y, 0, 0, PARTICLE.BUZZ_DURATION)
end

function PARTICLE.add_buzz(state, x, y)
    PropertyTable.append(state.particles, PARTICLE.create_buzz(state, x, y))
end
