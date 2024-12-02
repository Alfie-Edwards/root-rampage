function split_lines(text)
    local line_begin = 1
    local result = {}
    for i = 1, #text do
        if text:sub(i, i) == "\n" then
            table.insert(result, text:sub(line_begin, i - 1))
            line_begin = i + 1
        end
    end
    table.insert(result, text:sub(line_begin, #text))

    return result
end

function get_line(text, line_number)
    local line_begin = 1
    local line = 1
    for i = 1, #text do
        if text:sub(i, i) == "\n" then
            if line == line_number then
                return text:sub(line_begin, i - 1)
            end
            line = line + 1
            line_begin = i + 1
        end
    end
    if line == line_number then
        return text:sub(line_begin, #text)
    else
        return nil
    end
end

function get_line_number(lines, i)
    if not is_positive_integer(i) then
        error("Expected i to be a positive integer, got "..details_string(i))
    end
    if not is_type(lines, "table") then
        error("Expected lines to be a list, got "..details_string(lines))
    end
    for line_number, line in ipairs(lines) do
        local length = #line + 1
        if i <= length then
            return line_number, i
        end
        i = i - length
    end

    return nil, i
end

function wrap_text(text, font, width)
    local line_begin = 1
    local word_begin = 1
    local line_end = 1
    local result = {}
    while line_end <= #text do
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

function draw_centred_text(text, x, y, font, color, bg_color)
    local width = font:getWidth(text)
    local height = font:getHeight()
    x = x - font:getWidth(text) / 2
    if bg_color ~= nil then
        love.graphics.setColor(bg_color)
        love.graphics.rectangle("fill", x-2, y-1, width+4, height+4)
    end
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

function draw_text(text, x, y, font, color, bg_color)
    local width = font:getWidth(text)
    local height = font:getHeight()
    if bg_color ~= nil then
        love.graphics.setColor(bg_color)
        love.graphics.rectangle("fill", x-2, y-1, width+4, height+4)
    end
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

function prepend_lines(text, prefix)
    local lines = split_lines(text)
    for i = 1, #lines do
        lines[i] = prefix..lines[i]
    end
    return table.concat(lines, "\n")
end

function indent(text, indent_level, indent_string)
    return prepend_lines(text, string.rep(nil_coalesce(indent_string, " "), indent_level))
end

function split_iter(str, sep, max)
    local i_prev_sep = 1 - #sep
    local i_next_sep = nil
    local n = 1
    return function()
        if i_prev_sep == nil or (max ~= nil and n > max) then
            return nil
        end

        local i_start = i_prev_sep + #sep
        i_next_sep = str:find(sep, i_start)
        while nil_coalesce(i_next_sep, #str + 1) <= i_start do
            if i_next_sep == nil then
                return nil
            end
            i_prev_sep = i_next_sep
            i_start = nil_coalesce(i_prev_sep, #str + 1) + #sep
            i_next_sep = str:find(sep, i_start)
        end

        local i_end = -1
        if i_next_sep ~= nil then
            i_end = i_next_sep - 1
        end
        if n == max then
            i_end = nil
        end

        n = n + 1
        i_prev_sep = i_next_sep
        return str:sub(i_start, i_end)
    end
end

function split(str, sep, max)
    local result = {}
    for x in split_iter(str, sep, max) do
        table.insert(result, x)
    end
    return result
end