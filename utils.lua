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