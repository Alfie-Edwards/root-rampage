NEVER = -1

function get_key(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

function remove_value(list, value_to_remove)
    local i = get_key(list, value_to_remove)
    if i ~= nil then
        table.remove(list, i)
    end
end

function reverse(x)
    local rev = {}
    for i=#x, 1, -1 do
        rev[#rev+1] = x[i]
    end
    return rev
end

function shallowcopy(tab)
    res = {}
    for k, v in pairs(tab) do
        res[k] = v
    end
    return res
end

function shuffle_list(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
end

function concat(a, b)
    local ab = {}
    table.move(a, 1, #a, 1, ab)
    table.move(b, 1, #b, #ab + 1, ab)
    return ab
end

function index_of(list, value)
    for i,v in ipairs(list) do
        if v == value then
            return i
        end
    end
    return nil
end

function value_in(value, list)
    for _,item in ipairs(list) do
        if value == item then
            return true
        end
    end
    return false
end

function sq_dist(x1, y1, x2, y2)
    return Vector.new(x1, y1, x2, y2):sq_length()
end

function dist(x1, y1, x2, y2)
    return Vector.new(x1, y1, x2, y2):length()
end

function norm(x1, y1, x2, y2)
    return Vector.new(x1, y1, x2, y2):direction()
end

function moved(pos, vel)
    res = {}
    for axis, speed in pairs(vel) do
        res[axis] = pos[axis] + speed
    end
    return res
end

function round(num)
    return math.floor(num + 0.5)
end

function rotate_about(angle, x, y)
    local transform = love.math.newTransform()
    transform:translate(x, y)
    transform:rotate(angle)
    transform:translate(-x, -y)
    return transform
end

function scale_about(scale_x, scale_y, x, y)
    local transform = love.math.newTransform()
    transform:translate(x, y)
    transform:scale(scale_x, scale_y)
    transform:translate(-x, -y)
    return transform
end

function randfloat(low, high)
    return (math.random() * (high - low)) + low
end

function clamp(x, min, max)
    x = math.min(x, max)
    x = math.max(x, min)
    return x
end

function lerp(a, b, ratio)
    ratio = clamp(ratio, 0, 1)
    return a * (1 - ratio) + b * ratio
end

function lerp_list(a, b, ratio)
    if (#a ~= #b) then
        error("lerp_list requires lists of equal length ("..tostring(#a).." != "..tostring(#b)..")")
    end
    local result = {}
    for i, a_item in ipairs(a) do
        b_item = b[i]
        result[i] = lerp(a_item, b_item, ratio)
    end
    return result
end

function is_positive_integer(x)
    if type(x) ~= "number" then
        return false
    end

    if x ~= math.floor(x) then
        return false
    end

    if x < 1 then
        return false
    end

    return true
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

function wrap_text(text, font, width)
    local line_begin = 1
    local word_begin = 1
    local line_end = 1
    local result = {}
    while line_end < #text do
        if text:sub(line_end,line_end) == "\n" then
            table.insert(result, text:sub(line_begin,line_end-1))
            line_begin = line_end + 1
        elseif not text:sub(line_end,line_end):match("^[A-z0-9_]$") then
            word_begin = line_end + 1
        elseif line_begin ~= word_begin and font:getWidth(text:sub(line_begin,line_end)) > width then
            table.insert(result, text:sub(line_begin,word_begin-1))
            line_begin = word_begin
        end
        line_end = line_end + 1
    end
    table.insert(result, text:sub(line_begin,#text))
    return result
end

function draw_bb(bb, color)
    if (color == nil) or (bb == nil) or (color[4] == 0) then
        return
    end
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", bb.x1, bb.y1, bb:width(), bb:height())
end

function get_local(name, default, stack_level)
    if stack_level == nil then
        stack_level = 1
    end

    local var_index = 1
    while true do
        local var_name, value = debug.getlocal(stack_level, var_index)
        if var_name == name then
            return value
        elseif var_name == nil then
            return default
        end
        var_index = var_index + 1
    end
end

-- Import other utils files.
require "utils.classes"
require "utils.set"
require "utils.bounding_box"
require "utils.vector"
require "utils.event"
require "utils.state"
