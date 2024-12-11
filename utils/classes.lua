_classes = {}
_method_owner_map = {}
_profile = {}
DO_PROFILE = true

function _profile_wrapper(name, f)
    return function(...)
        local t0 = t_now()
        local result = {f(...)}
        if _profile[name] then 
            _profile[name][1] = _profile[name][1] + (t_now() - t0)
            _profile[name][2] = _profile[name][2] + 1
        else
            _profile[name] = {(t_now() - t0), 1}
        end
        return unpack(result)
    end
end

function type_string(inst)
    -- Class instances and LOVE objects have their own type function.
    local t = type(inst)
    if ((t == "table" or t == "userdata") and inst.type ~= nil) then
        return inst:type()
    end
    return t
end

function details_string(t)
    -- Useful for telling classes apart in error messages.

    if get_metatable_value(t, "__tostring") then
        return tostring(t)
    end

    local typestring = type_string(t)
    if typestring == "table" or typestring == "function" or typestring == "nil" then
        return typestring
    end

    local valuestring = tostring(t)

    if typestring == "number" or typestring == "boolean" then
        return valuestring
    end
    if typestring == "string" then
        return '"'..valuestring..'"'
    end

    return valuestring.." ("..typestring..")"
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
    for _, t in ipairs({...}) do
        if type(t) ~= "string" then
            -- Handle passing in a raw type.
            t = type_string(t)
        end
        assert(type(t) == "string")
        if is_basic_type(inst) then
            if type(inst) == t then
                return true
            end
        else
            -- Class instances and LOVE objects have their own type function which accounts for inheritance.
            if inst:typeOf(t) then
                return true
            end
        end
    end
    return false
end

function setup_class(class, super)
    -- Setup inheritance and the type/typeof methods from LOVE.
    if (class ~= BaseObjectClass and super == nil) then
        super = BaseObjectClass
    end
    local name = get_key(getfenv(), class)

    -- Register existing methods.
    for k, v in pairs(class) do
        if type(v) == "function" then
            _method_owner_map[v] = class
            if DO_PROFILE then
                local old_v = v
                local v = _profile_wrapper(name.."."..k, v)
            end
            class[k] = v
        end
    end

    setmetatable(class,
        {
            __template = super, -- Custom field.
            __pairs = template_pairs, -- Custom field.
            __index = super,
            __name = name,
            __call = function(self, ...)
                local inst = {}
                setup_instance(inst, class)
                inst:__init(...)
                return inst
            end,

            -- Register methods created after setup_class is called.
            __newindex = function(self, k, v)
                if type(v) == "function" then
                    _method_owner_map[v] = class
                    if DO_PROFILE then
                        local old_v = v
                        v = _profile_wrapper(name.."."..k, v)
                    end
                end
                local mt = getmetatable(self)
                local ni = mt.__newindex
                mt.__newindex = nil
                class[k] = v
                mt.__newindex = ni
            end,
        }
    )
    _classes[class] = true
end

function setup_instance(inst, class)
    -- Setup the given table as an instance of the given class.
    assert(class ~= nil)
    assert(type(class) == "table")
    setmetatable(inst, generate_instance_metatable(class))
end

function super(class)
    -- Get the super class of the given class.
    -- If called from a class method, the class can be inferred.
    if class == nil then
        class = get_calling_class()
    end
    return get_metatable_value(class,  "__template")
end

function class(inst)
    -- Get the super class of the given class.
    -- If called from a class method, the class can be inferred.
    if inst == nil then
        return get_calling_class()
    end
    return get_metatable_value(inst,  "__template")
end

function get_calling_class()
    -- Must be called from a class method, returns the class.
    local info = debug.getinfo(3, 'f')
    if _method_owner_map[info.func] ~= nil then
        return _method_owner_map[info.func]
    end
    for class, _ in next, _classes, nil do
        for _, v in next, class, nil do
            if v == info.func then
                _method_owner_map[info.func] = class
                return class
            end
        end
    end
    error("Calling method must be owned by a class which has had `setup_class` called.")
end

function generate_instance_metatable(class)
    -- Create a metatable from the metatable values defined in the class and super classes.
    local mt = {}

    if class == nil then
        return mt
    end

    -- Custom value.
    mt.__template = class

    -- Special case for __index.
    mt.__index = function(self, name)
        if class[name] == nil and class.__index ~= nil then
            return class.__index(self, name)
        end
        return class[name]
    end

    for key, value in pairs(class) do
        if type(key) == "string" and #key >= 2 and string.sub(key, 1, 2) == "__" and key ~= "__index" then
            mt[key] = value
        end
    end

    return mt
end

-- Override pairs to iterate over our class hierarchy.
function pairs(target)
    return nil_coalesce(get_metatable_value(target, "__pairs"), native_pairs)(target)
 end

function native_pairs(target)
    return next, target, nil
end

function template_pairs(target)
    -- Iterate recursively over custom metatable field __template.
    local seen = {}
    return function(t, k)
        local v = nil

        while target do
            repeat
                -- Find next entry (new key) in target.
                k, v = next(target, k)
            until k == nil or not seen[k]

            if k ~= nil then
                -- If we found a key, return the pair.
                seen[k] = true
                return k, v
            end

            -- If we did not find a key we are done iterating this target, move onto the next.
            target = get_metatable_value(target, "__template")
        end

        -- No more targets, stop iteration.
        return nil, nil
    end, target, nil
end

BaseObjectClass = {}

function BaseObjectClass:__init()
end

function BaseObjectClass:type()
    assert(self ~= nil, "type is a method and must be called like `x:type()`, rather than `x.type()`.")
    return error_if_nil(
        nil_coalesce(
            get_metatable_value(self, "__name"),
            get_metatable_value(get_metatable_value(self, "__template"), "__name")
        ),
        "Could not identify type."
    )
end

function BaseObjectClass:typeOf(type_name)
    assert(self ~= nil, "typeOf is a method and must be called like `x:typeOf(type_name)`, rather than `x.typeOf(type_name)`.")
    while self do
        if self:type() == type_name then
            return true
        end
        self = get_metatable_value(self, "__template")
    end
    return false
end

BaseObjectClass.__pairs = template_pairs

setup_class(BaseObjectClass)
