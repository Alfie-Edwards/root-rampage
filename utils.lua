function get_key(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

function type_string(inst)
    -- Class instances and LOVE objects have their own type function.
    local type = type(inst)
    if ((type == "table" or type == "userdata") and inst.type ~= nil) then
        return inst:type()
    end
    return type
end

function is_basic_type(inst)
    return value_in(
        type_string(inst),
        {
            "nil",
            "boolean",
            "number",
            "string",
            "userdata",
            "function",
            "thread",
            "table"
        }
    )
end

function is_type(inst, ...)
    for _, type_name in ipairs({...}) do
        assert(type(type_name) == "string") 
        if is_basic_type(inst) then
            if type(inst) == type_name then
                return true
            end
        else
            -- Class instances and LOVE objects have their own type function which accounts for inheritance.
            if inst:typeOf(type_name) then
                return true
            end
        end
    end
    return false
end


classes = {}

function setup_class(class, super)
    -- Setup inheritance and the type/typeof methods from LOVE.
    if (super == nil) then
        super = Object
    end
    local name = get_key(_G, class)
    setmetatable(class,
        { 
            __index = super,
            __name = name,
        }
    )

    class.type = function(self)
        return name
    end
    class.typeOf = function(self, type_name)
        local c = class
        while class ~= nil do
            if class:type() == type_name then
                return true
            end
            local mt = getmetatable(class)
            if mt == nil then
                return false
            end
            class = mt.__index
        end
        return false
    end
    classes[class] = true
end

function magic_new(...)
    -- Create an instance of the class this method was called from.class
    -- Args are passed to the super class constructor.
    local class = get_calling_class()
    local inst = nil
    local super = super(class)
    if (super == nil) or (super.new == nil) then
        inst = {}
    else
        inst = super.new(...)
    end

    setup_instance(inst, class)
    return inst
end

function setup_instance(inst, class)
    -- Setup the given table as an instance of the given class.
    assert(class ~= nil)
    assert(type(class) == "table")
    setmetatable(inst, generate_inheritance_metatable(class))
end

function super(class)
    -- Get the super class of the given class.
    -- If called from a class method, the class can be inferred.
    if class == nil then
        class = get_calling_class()
    end
    local mt = getmetatable(class)
    if mt == nil then
        return nil
    end
    if type(mt.__index) == "function" then
        return nil
    end
    return mt.__index
end

function get_calling_class()
    -- Must be called from a class method, returns the class.
    local info = debug.getinfo(3, 'f')
    for x, _ in pairs(classes) do
        if get_key(x, info.func) ~= nil then
            return x
        end
    end
    error("Calling method must be owned by a class which has had `setup_class` called.")
end

function generate_inheritance_metatable(class)
    -- Create a metatable from the metatable values defined in the class and super classes.
    local mt = {}

    if class == nil then
        return mt
    end

    -- Special case for __index.
    mt.__index = function(self, name)
        if class[name] == nil and class.__index ~= nil then
            return class.__index(self, name)
        end
        return class[name]
    end

    local seen = {}
    local c = class
    while c ~= nil do
        for key, value in pairs(c) do
            if not seen[key] and type(key) == "string" and #key >= 2 and string.sub(key, 1, 2) == "__" and key ~= "__index" then
                mt[key] = value
                seen[key] = true
            end
        end
        c = super(c)
    end

    return mt
end

Vector = {
    x1 = nil,
    y1 = nil,
    x2 = nil,
    y2 = nil,
}
setup_class(Vector)

function Vector.new(x1, y1, x2, y2)
    local obj = magic_new()
    assert(x1 ~= nil)
    assert(y1 ~= nil)
    assert(x2 ~= nil)
    assert(y2 ~= nil)

    obj.x1 = x1
    obj.y1 = y1
    obj.x2 = x2
    obj.y2 = y2

    return obj
end

function Vector:dx()
    return self.x2 - self.x1
end

function Vector:dy()
    return self.y2 - self.y1
end

function Vector:sq_length()
    return self:dx() ^ 2 + self:dy() ^ 2
end

function Vector:length()
    return self:sq_length() ^ (1 / 2)
end

function Vector:direction_x()
    local length = self:length()
    return self:dx() / self:length()
end

function Vector:direction_y()
    return self:dy() / self:length()
end

function Vector:direction()
    local length = self:length()
    return { x = self:dx() / length, y = self:dy() / length }
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

function keys_to_set(t)
    local result = {}
    for k, _ in pairs(t) do
        result[k] = true
    end
    return result
end

function values_to_set(t)
    local result = {}
    for _, v in pairs(t) do
        result[v] = true
    end
    return result
end

function is_valid_set(t)
    if t == nil then
        return false
    end
    for _, v in pairs(t) do
        if v ~= true then
            return false
        end
    end
    return true
end

NEVER = -1

BoundingBox = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
}
setup_class(BoundingBox)

function BoundingBox.new(x1, y1, x2, y2)
    local obj = magic_new()
    obj.x1 = x1
    obj.y1 = y1
    obj.x2 = x2
    obj.y2 = y2

    return obj
end

function BoundingBox:contains(x, y)
    return (x >= self.x1 and x < self.x2 and y >= self.y1 and y < self.y2)
end

function BoundingBox:width()
    return self.x2 - self.x1
end

function BoundingBox:height()
    return self.y2 - self.y1
end

function BoundingBox:center_x()
    return (self.x2 + self.x1) / 2
end

function BoundingBox:center_y()
    return (self.y2 + self.y1) / 2
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

function canvas_position()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local x_scale = screen_width / canvas_size[1]
    local y_scale = screen_height / canvas_size[2]
    local min_scale = math.min(x_scale, y_scale)
    local x_offset = (screen_width - (canvas_size[1] * min_scale)) / 2
    local y_offset = ((screen_height - (canvas_size[2] * min_scale)) / 2) + 50
    return x_offset, y_offset, min_scale
end

function screen_to_canvas(screen_x, screen_y)
    local x_offset, y_offset, scale = canvas_position()
    local canvas_x = (screen_x - x_offset) / scale
    local canvas_y = (screen_y - y_offset) / scale
    local canvas_x, canvas_y = effects:get_transform():transformPoint(canvas_x, canvas_y)
    return canvas_x, canvas_y
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

function randfloat(low, high)
    return (math.random() * (high - low)) + low
end

function draw_bb(bb, color)
    if (color == nil) or (bb == nil) or (color[4] == 0) then
        return
    end
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", bb.x1, bb.y1, bb:width(), bb:height())
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
