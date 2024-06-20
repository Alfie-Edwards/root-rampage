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

function draw_centred_text(text, x, y, color, bg_color, font)
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

function draw_text(text, x, y, color, font)
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
