function list(...)
    return {...}
end

function is_list(t)
    return type(t) == "table" and iter_size(t) == #x
end

function list_concat_inplace(a, b)
    table.move(b, 1, #b, #a + 1, a)
    return a
end

function list_concat(a, b)
    local ab = {}
    table.move(a, 1, #a, 1, ab)
    table.move(b, 1, #b, #ab + 1, ab)
    return ab
end

function keys_to_list(t)
    local result = {}
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    return result
end

function values_to_list(t)
    local result = {}
    for _, v in pairs(t) do
        table.insert(result, v)
    end
    return result
end

function keys_to_sorted_list(t, sort_function)
    t = keys_to_list(t)
    table.sort(t, sort_function)
    return t
end

function values_to_sorted_list(t, sort_function)
    t = values_to_list(t)
    table.sort(t, sort_function)
    return t
end

function list_contains(l, x)
    if l == nil then
        return nil
    end
    for _, v in ipairs(l) do
        if v == x then
            return true
        end
    end
    return false
end
