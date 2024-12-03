
INPUT_UNDEFINED = {}
function INPUT_UNDEFINED.type() return "undefined" end
setmetatable(INPUT_UNDEFINED, {__tostring=INPUT_UNDEFINED.type})

Inputs = {
    ALL_UNDEFINED = {
        player_up = INPUT_UNDEFINED,
        player_down = INPUT_UNDEFINED,
        player_left = INPUT_UNDEFINED,
        player_right = INPUT_UNDEFINED,
        player_chop = INPUT_UNDEFINED,
        player_dash = INPUT_UNDEFINED,
        roots_grow = INPUT_UNDEFINED,
        roots_attack = INPUT_UNDEFINED,
        roots_pos_x = INPUT_UNDEFINED,
        roots_pos_y = INPUT_UNDEFINED,
    },
    DEFAULTS = {
        player_up = false,
        player_down = false,
        player_left = false,
        player_right = false,
        player_chop = false,
        player_dash = false,
        roots_grow = false,
        roots_attack = false,
        roots_pos_x = 0,
        roots_pos_y = 0,
    },
}
setup_class(Inputs, FixedPropertyTable)

function Inputs.new_undefined()
    return Inputs(Inputs.ALL_UNDEFINED)
end

function Inputs.new_defaults()
    return Inputs(Inputs.DEFAULTS)
end

function Inputs.parse_bool(x)
    if x == "0" then
        return false
    elseif x == "1" then
        return true
    elseif x == "u" then
        return INPUT_UNDEFINED
    end
end

function Inputs.parse_f(x)
    if x == "u" then
        return INPUT_UNDEFINED
    else
        return tonumber(x)
    end
end

function Inputs.bool_to_string(x)
    if x == false then
        return "0"
    elseif x == true then
        return "1"
    elseif x == INPUT_UNDEFINED then
        return "u"
    end
    error("unreachable")
end

function Inputs.f_to_string(x)
    if x == INPUT_UNDEFINED then
        return "u"
    else
        return tostring(x)
    end
end

function Inputs:serialize_player()
    return Inputs.bool_to_string(self.player_up)..
        Inputs.bool_to_string(self.player_down)..
        Inputs.bool_to_string(self.player_left)..
        Inputs.bool_to_string(self.player_right)..
        Inputs.bool_to_string(self.player_chop)..
        Inputs.bool_to_string(self.player_dash)
end

function Inputs:serialize_roots()
    return Inputs.bool_to_string(self.roots_grow)..
        Inputs.bool_to_string(self.roots_attack)..
        Inputs.f_to_string(self.roots_pos_x).."|"..
        Inputs.f_to_string(self.roots_pos_y)
end

function Inputs.deserialize_player(x)
    return Inputs({
        player_up = Inputs.parse_bool(x:sub(1, 1)),
        player_down = Inputs.parse_bool(x:sub(2, 2)),
        player_left = Inputs.parse_bool(x:sub(3, 3)),
        player_right = Inputs.parse_bool(x:sub(4, 4)),
        player_chop = Inputs.parse_bool(x:sub(5, 5)),
        player_dash = Inputs.parse_bool(x:sub(6, 6)),
        roots_grow = INPUT_UNDEFINED,
        roots_attack = INPUT_UNDEFINED,
        roots_pos_x = INPUT_UNDEFINED,
        roots_pos_y = INPUT_UNDEFINED,
    })
end

function Inputs.deserialize_roots(x)
    local sep = x:find("|", 4)
    return Inputs({
        player_up = INPUT_UNDEFINED,
        player_down = INPUT_UNDEFINED,
        player_left = INPUT_UNDEFINED,
        player_right = INPUT_UNDEFINED,
        player_chop = INPUT_UNDEFINED,
        player_dash = INPUT_UNDEFINED,
        roots_grow = Inputs.parse_bool(x:sub(1, 1)),
        roots_attack = Inputs.parse_bool(x:sub(2, 2)),
        roots_pos_x = Inputs.parse_f(x:sub(3, sep-1)),
        roots_pos_y = Inputs.parse_f(x:sub(sep+1, -1)),
    })
end
