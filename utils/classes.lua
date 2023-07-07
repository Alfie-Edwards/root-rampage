classes = {}

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