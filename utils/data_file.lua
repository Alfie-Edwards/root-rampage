module ( "DataFile", package.seeall )

TOKEN_MAPPINGS = {
    { type = "boolean",     patterns = { "[tT][rR][uU][eE]", "([fF][aA][lL][sS][eE])" } },
    { type = "string",      patterns = { "(\"[^\"]*\")",     "'[^']*')" }               },
    { type = "number",      patterns = { "-?[0-9]+%.?[0-9]*"  } },
    { type = "table_begin", patterns = { "{"                  } },
    { type = "table_end",   patterns = { "}"                  } },
    { type = "list_begin",  patterns = { "%["                 } },
    { type = "list_end",    patterns = { "%]"                 } },
    { type = "deliminator", patterns = { ","                  } },
    { type = "separator",   patterns = { "="                  } },
    { type = "name",        patterns = { "[A-z_][A-z0-9_]*"   } },
    { type = "whitespace",  patterns = { "%s+"                } },
}

-- Serialize

function pattern(token_type)
    -- Get pattern for output.
    for _, token_mapping in ipairs(TOKEN_MAPPINGS) do
        if token_mapping.type == token_type then
            return string.gsub(token_mapping.patterns[1], "\\\\", "")
        end
    end
    return nil
end

INDENT = "   "

function save(filename, data)
    local text = serialize(data)
    love.filesystem.write(filename, text)
end

function serialize(data)
    return serialize_table(data)
end

function serialize_table(t, indent_level)
    indent_level = indent_level or 0
    local indent_string = string.rep(INDENT, indent_level + 1)
    local result = pattern("table_begin").."\n"

    for key, value in pairs(t) do
        -- Add indent.
        result = result..indent_string

        -- Add key.
        result = result..serialize_key(key, indent_level)

        -- Add : .
        result = result..": "

        -- Add value.
        result = result..serialize_value(value, indent_level)

        -- Add , .
        result = result..",\n"
    end

    result = result..string.rep(INDENT, indent_level)..pattern("table_end")
    return result
end

function serialize_list(l, indent_level)
    indent_level = indent_level or 0
    local indent_string = string.rep(INDENT, indent_level + 1)
    local result = pattern("list_begin").."\n"

    for _, value in ipairs(t) do
        -- Add indent.
        result = result..indent_string

        -- Add value.
        result = result..serialize_value(value, indent_level)

        -- Add , .
        result = result..",\n"
    end

    result = result..string.rep(INDENT, indent_level)..pattern("list_end")
    return result
end

function serialize_key(key, indent_level)
    if is_list(key) then
        return serialize_list(key, indent_level + 1)
    elseif type(key) == "table" then
        return serialize_table(key, indent_level + 1)
    elseif type(key) == "string" then
        -- Handle string differently for keys (don't serialize with quotes).
        return key
    elseif is_primitive(key) then
        return serialize_primitive(key)
    end
    error("Unexpected type for key \""..type(key).."\".")
end

function serialize_value(value, indent_level)
    if is_list(value) then
        return serialize_list(value, indent_level + 1)
    elseif type(value) == "table" then
        return serialize_table(value, indent_level + 1)
    elseif is_primitive(value) then
        return serialize_primitive(value)
    end
    error("Unexpected type for value \""..type(value).."\".")
end

function is_primitive(p)
    return type(p) == "string" or
           type(p) == "number" or
           type(p) == "boolean"
end

function serialize_primitive(p)
    if type(p) == "string" then
        return serialize_string(p)
    elseif type(p) == "number" then
        return serialize_number(p)
    elseif type(p) == "boolean" then
        return serialize_boolean(p)
    end

    error("Unrecognised primitive type \""..type(p).."\".")
end

function serialize_string(s)
    assert(type(s) == "string")
    return "\""..s.."\""
end

function serialize_number(n)
    assert(type(n) == "number")
    return string.format("%f", n)
end

function serialize_boolean(b)
    assert(type(b) == "boolean")
    if b then
        return "true"
    else
        return "false"
    end
end

-- Deserialize

function load(filename)
    local text, _ = love.filesystem.read(filename)

    if not text then
        error("Couldn't open file \""..filename.."\"!")
    end

    return deserialize(text)
end

function deserialize(text)
    local tokenizer = Tokenizer(text, TOKEN_MAPPINGS)
    -- Parse to beginning of root table.
    tokenizer:next()
    if tokenizer.token_type ~= "table_begin" then
        tokenizer:error("Expected a table at the root, found a "..tokenizer.token_type.." token:")
    end

    -- Parse root table.
    local data = deserialize_table(tokenizer)

    -- Check only whitespace after root table.
    while not tokenizer:done() do
        tokenizer:next()
        if tokenizer.token_type ~= "whitespace" then
            tokenizer:error("Found "..tokenizer.token_type.." token after the end of the root table:")
        end
    end

    return data
end

function deserialize_table(tokenizer)
    local result = {}
    local start_i = tokenizer.i - 1
    local key, value

    repeat
        -- Parse key or end.
        if tokenizer:done() then
            tokenizer:error("Table at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if tokenizer:is("table_end") then
            break
        end
        if tokenizer:is(is_key_token) then
            key = deserialize_key(tokenizer)
        else
            tokenizer:error("Expected key or '"..tokenizer:pattern("table_end").."', got "..tokenizer.token_type.." token:")
        end

        -- Parse separator.
        if tokenizer:done() then
            error("Table at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if not tokenizer:is("separator") then
            tokenizer:error("Expected '"..tokenizer:pattern("separator").."', got "..tokenizer.token_type.." token:")
        end

        -- Parse value.
        if tokenizer:done() then
            tokenizer:error("Table at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if tokenizer:is(is_value_token) then
            value = deserialize_value(tokenizer)
        else
            tokenizer:error("Expected value, got "..tokenizer.token_type.." token:")
        end

        -- Parse deliminator or end.
        if tokenizer:done() then
            tokenizer:error("Table at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if not tokenizer:is("deliminator", "table_end") then
            tokenizer:error("Expected '"..tokenizer:pattern("deliminator").."' or '"..tokenizer:pattern("table_end").."', got "..tokenizer.token_type.." token:")
        end

        result[key] = value
    until(tokenizer:is("table_end"))

    return result
end

function deserialize_list(tokenizer)
    local result = {}
    local start_i = tokenizer.i - 1
    local value

    repeat
        -- Parse value or end.
        if tokenizer:done() then
            tokenizer:error("List at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if tokenizer:is("list_end") then
            break
        end
        if tokenizer:is(is_value_token) then
            value = deserialize_value(tokenizer)
        else
            tokenizer:error("Expected value, got "..tokenizer.token_type.." token:")
        end

        -- Parse deliminator or end.
        if tokenizer:done() then
            tokenizer:error("List at "..tostring(start_i).." never closed:", start_i)
        end
        tokenizer:next()
        if not tokenizer:is("deliminator", "list_end") then
            tokenizer:error("Expected '"..tokenizer:pattern("deliminator").."' or '"..tokenizer:pattern("list_end").."', got "..tokenizer.token_type.." token:")
        end

        table.insert(result, value)
    until(tokenizer:is("list_end"))

    return result
end

function deserialize_key(tokenizer)
    if tokenizer:is("table_begin") then
        return deserialize_table(tokenizer)
    elseif tokenizer:is("list_begin") then
        return deserialize_list(tokenizer)
    end
    if tokenizer:is("name") then
        return tokenizer.token
    elseif tokenizer:is(is_primitive_token) then
        return deserialize_primitive(tokenizer)
    end
    tokenizer:error("Unrecognised key token type \""..tokenizer.token_type.."\":")
end

function deserialize_value(tokenizer)
    if tokenizer:is("table_begin") then
        return deserialize_table(tokenizer)
    elseif tokenizer:is("list_begin") then
        return deserialize_list(tokenizer)
    elseif tokenizer:is(is_primitive_token) then
        return deserialize_primitive(tokenizer)
    end
    tokenizer:error("Unrecognised value token type \""..tokenizer.token_type.."\":")
end

function deserialize_primitive(tokenizer)
    if tokenizer:is("boolean") then
        return deserialize_boolean(tokenizer)
    elseif tokenizer:is("string") then
        return deserialize_string(tokenizer)
    elseif tokenizer:is("number") then
        return deserialize_number(tokenizer)
    end

    tokenizer:error("Unrecognised primitive token type \""..tokenizer.token_type.."\":")
end

function deserialize_boolean(tokenizer)
    if tokenizer.token == "true" then
        return true
    elseif tokenizer.token == "false" then
        return false
    end
    tokenizer:error("Failed to deserialize boolean \""..tokenizer.token.."\":")
end

function deserialize_string(tokenizer)
    if not (#tokenizer.token > 1) and
        ((string.sub(tokenizer.token, 1, 1) == "\"" and string.sub(tokenizer.token, -1, -1) == "\"") or
        (string.sub(tokenizer.token, 1, 1) == "'"  and string.sub(tokenizer.token, -1, -1) == "'")) then

        tokenizer:error("Failed to deserialize string \""..tokenizer.token.."\":")
    end
    return string.sub(tokenizer.token, 2, -2)
end

function deserialize_number(tokenizer)
    local number = tonumber(tokenizer.token)
    if number == nil then
        tokenizer:error("Failed to deserialize number \""..tokenizer.token.."\":")
    end
    return number
end

function is_key_token(token_type)
    return token_type == "table_begin" or token_type == "list_begin" or
           token_type == "name" or is_primitive_token(token_type)
end

function is_value_token(token_type)
    return token_type == "table_begin" or token_type == "list_begin"
           or is_primitive_token(token_type)
end

function is_primitive_token(token_type)
    return token_type == "boolean" or
           token_type == "string" or
           token_type == "number"
end
