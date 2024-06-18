NEVER = -1

function get_key(tab, value, pairs_fn)
    for k, v in nil_coalesce(pairs_fn, pairs)(tab) do
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

function lists_equal(l1, l2)
    if #l1 ~= #l2 then
        return false
    end

    for i=1,#l1 do
        if l1[i] ~= l2[i] then
            return false
        end
    end
    return true
end

function shallow_copy(x, result)
    if type(x) ~= "table" then
        return x
    end

    result = nil_coalesce(result, {})
    for k, v in pairs(x) do
        result[k] = v
    end
    return result
end

function deep_copy(x, result)
    if type(x) ~= "table" then
        return x
    end

    result = nil_coalesce(result, {})
    for k, v in pairs(x) do
        result[deep_copy(k)] = deep_copy(v)
    end
    return result
end

function shuffle_list(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
end

function choice(list)
    return list[math.random(#list)]
end

function union(a, b)
    local ab = shallow_copy(a)
    for k, v in pairs(b) do
        if ab[k] == nil then
            ab[k] = v
        end
    end
    return ab
end

function union_inplace(a, b)
    for k, v in pairs(b) do
        if a[k] == nil then
            a[k] = v
        end
    end
    return a
end

function index_of(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end
    return nil
end

function value_in(value, list)
    for _, item in ipairs(list) do
        if value == item then
            return true
        end
    end
    return false
end

function sq_dist(x1, y1, x2, y2)
    return Vector(x1, y1, x2, y2):sq_length()
end

function dist(x1, y1, x2, y2)
    return Vector(x1, y1, x2, y2):length()
end

function norm(x1, y1, x2, y2)
    return Vector(x1, y1, x2, y2):direction()
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

function is_non_negative_integer(x)
    if type(x) ~= "number" then
        return false
    end

    if x ~= math.floor(x) then
        return false
    end

    if x < 0 then
        return false
    end

    return true
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

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)),
            tonumber("0x"..hex:sub(3,4)),
            tonumber("0x"..hex:sub(5,6))}
end

function hex2col(hex, a)
    local rgb = hex2rgb(hex)
    if a == nil then
        a = 1
    end
    return {rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1}
end

function col2hex(col)
    return string.upper(string.format("#%02x%02x%02x", math.floor(col[1] * 255 + 0.5), math.floor(col[2] * 255 + 0.5), math.floor(col[3] * 255 + 0.5)))
end

function t_since(tstamp)
    return t_now() - tstamp
end

function t_now()
    return love.timer.getTime()
end

function iter_size(x)
    local n = 0
    for _, _ in pairs(x) do
        n = n + 1
    end
    return n
end

function normalize_angle(a)
    a = a + (2 * math.pi)
    a = a % (2 * math.pi)
    if a > math.pi then
        a = a - (math.pi * 2)
    end
    return a
end

function without_metatable(x, f, ...)
    local mt = getmetatable(x)
    setmetatable(x, nil)
    local result = f(...)
    setmetatable(x, mt)
    return result
end

function nil_coalesce(x, ...)
    if x == nil then
        return ...
    end
    return x
end

function get_if_not_nil(x, key)
    if x == nil then
        return nil
    end
    return x[key]
end

function call_if_not_nil(x, ...)
    if x == nil then
        return nil
    end
    return x(...)
end

function error_if_nil(x, msg)
    if x == nil then
        error(msg)
    end
    return x
end

function get_metatable_value(x, key)
    if x == nil or key == nil then
        return nil
    end
    return get_if_not_nil(getmetatable(x), key)
end

function bool(x)
    if x then
        return true
    end
    return false
end

function first_pair(x)
    for k, v in pairs(x) do
        return k, v
    end
end

function nth_pair(x, n)
    local i = 1
    for k, v in pairs(x) do
        if i == n then
            return k, v
        end
        i = i + 1
    end
    return nil, nil
end

function tern(cond, a, b)
    if cond then
        return a
    end
    return b
end

function hsva(h, s, v, a)
    h = clamp((h * 6) % 6, 0, 6)
    local x = h % 1
    local y = s * v
    local z = v * (1 - s)
    if h < 1 then     -- r -> y
        return {v, v - (1 - x) * y, z, a}
    elseif h < 2 then -- y -> g
        return {v - x * y, v, z, a}
    elseif h < 3 then -- g -> c
        return {z, v, v - (1 - x) * y, a}
    elseif h < 4 then -- c -> b
        return {z, v - x * y, v, a}
    elseif h < 5 then -- b -> m
        return {v - (1 - x) * y, z, v, a}
    elseif h < 6 then -- m -> r
        return {v, z, v - x * y, a}
    end
    error("Invalid hue ("..(h * 60)..").")
end

function weak_table(mode)
    local t = {}
    setmetatable(t, {__mode = nil_coalesce(mode, 'kv')})
    return t
end

function delete_unreferenced_keys(t)
     -- Clean up any children who's saved values are no longer referenced.
    local weak_children = weak_table('k')
    shallow_copy(self.children, weak_children)
    self.children = nil
    collectgarbage()
    self.children = shallow_copy(weak_children)
    for _, child in pairs(weak_children) do
        child:reinit_impl()
    end
end

-- Import other utils files.
require "utils.classes"
require "utils.stack"
require "utils.set"
require "utils.list"
require "utils.text"
require "utils.bounding_box"
require "utils.vector"
require "utils.event"
require "utils.property_table"
require "utils.fixed_property_table"
require "utils.getter_setter_property_table"
require "utils.hash"
require "utils.hash_map"
require "utils.hash_set"
require "utils.tokenizer"
require "utils.data_file"
require "utils.enum"
require "utils.direction"
require "utils.cell"
require "utils.intersections"
require "utils.schema"
require "utils.timer"
require "utils.priority_queue"
require "utils.rstar"
