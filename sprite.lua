require "direction"


sprite = {}

function sprite.make(path)
    return love.graphics.newImage("assets/"..path)
end

function sprite.make_set(prefix, tab)
    local res = {}
    for k, v in pairs(tab) do
        if type(v) == "string" then
            res[k] = sprite.make(prefix..v)
        elseif type(v) == "table" then
            res[k] = sprite.make_set(prefix, v)
        else
            assert(false)
        end
    end
    return res
end

function sprite.directional(set, dir)
    if dir == Direction.UP then
        return set.up
    elseif dir == Direction.DOWN then
        return set.down
    elseif dir == Direction.LEFT then
        return set.left
    elseif dir == Direction.RIGHT then
        return set.right
    end

    return set.down
end

function sprite.sequence(set, duration, start_time)
    -- always return the final sprite after the duration is up
    local time_since = t - start_time
    local progress = time_since / duration
    local index = math.floor(progress * #set) + 1
    index = math.min(index, #set)
    return set[index]
end

function sprite.cycling(set, period, start_time)
    if start_time == nil then
        start_time = 0
    end

    local time_since = t - start_time
    local progress = (time_since % period) / period
    local index = math.floor(progress * #set) + 1
    return set[index]
end

