function setup_instance(inst, class)
    assert(class ~= nil)
    setmetatable(inst, {__index = class})
end

function setup_class(name, super)
    if (super == nil) then
        super = Object
    end
    local template = _G[name]
    setmetatable(template, {__index = super})
    template.type = function(obj) return name end
end

function moved(pos, vel)
    res = {}
    for axis, speed in pairs(vel) do
        res[axis] = pos[axis] + speed
    end
    return res
end

function shallowcopy(tab)
    res = {}
    for k, v in pairs(tab) do
        res[k] = v
    end
    return res
end

function remove_value(list, value_to_remove)
    local i = get_key(list, value_to_remove)
    if i ~= nil then
        table.remove(list, i)
    end
end

function get_key(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

function round(num)
    return math.floor(num + 0.5)
end

function draw_centred_text(text, x, y, color, bg_color)
    local width = font:getWidth(text)
    local height = font:getHeight()
    x = x - font:getWidth(text) / 2
    if bg_color ~= nil then 
        love.graphics.setColor(bg_color)
        love.graphics.rectangle("fill", x-2, y-1, width+4, height+4)
    end
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.print(text, x, y)
end

function draw_text(text, x, y, color, bg_color)
    local width = font:getWidth(text)
    local height = font:getHeight()
    if bg_color ~= nil then 
        love.graphics.setColor(bg_color)
        love.graphics.rectangle("fill", x-2, y-1, width+4, height+4)
    end
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.print(text, x, y)
end

function reverse(x)
    local rev = {}
    for i=#x, 1, -1 do
        rev[#rev+1] = x[i]
    end
    return rev
end

function list_to_set(t)
    local result = {}
    for _, v in ipairs(t) do
        result[v] = true
    end
    return result
end
