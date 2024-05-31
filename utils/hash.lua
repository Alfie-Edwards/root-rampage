function hash(x)
    -- Use custom metatable method __hash().
    return call_if_not_nil(
        get_metatable_value(x, "__hash"),
        x
    )
end

function hashable(x)
    -- Use custom metatable method __hash().
    return get_metatable_value(x, "__hash") ~= nil
end

