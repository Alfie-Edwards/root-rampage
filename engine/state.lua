require "utils"
require "engine.event"

NONE = {}

State = {
    properties_set = nil,
    property_changed = nil,
}
setup_class(State)

function State.new(properties)
    local obj = {}
    assert(properties ~= nil)

    obj.property_changed = Event.new() -- (state, name, old_value, new_value)
    obj.properties_set = keys_to_set(properties)

    -- The properties aren't directly accessable outside of this function.
    -- This means we must create the get and set methods within this function.
    local properties_closure = {}

    obj.set = function(self, name, value)
        if value == nil then
            value = NONE
        end
        if properties_closure[name] == value then
            return
        end
        local old_value = properties_closure[name]
        properties_closure[name] = value
        self:property_changed(name, old_value, value)
    end

    obj.get = function(self, name)
        local value = properties_closure[name]
        if value == NONE then
            value = nil
        end
        return value
    end

    setup_instance(obj, State)
    obj:set_many(properties)

    return obj
end

function State:set_many(values)
    for name, value in pairs(values) do
        self:set(name, value)
    end
end

function State:__tostring()
    if debug.getinfo(3).name == "tostring" then
        return "..."
    end

    local result = self.type().." {"
    for key, _ in pairs(self.properties_set) do
        local value = tostring(self:get(key))
        value = string.gsub(value, "\n", "\n    ")
        result = result.."\n    "..key..": "..value
    end
    if #self.properties_set > 0 then
        result = result.."\n"
    end
    result = result.."\n}"
    return result
end

-- Getting properties as state.prop will call through to state:get(prop).
function State:__index(name)
    return self:get(name)
end

-- Setting properties as state.prop = val will call through to state:set(prop, val).
function State:__newindex(name, value)
    self:set(name, value)
end

