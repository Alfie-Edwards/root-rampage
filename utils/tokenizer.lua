Tokenizer = {
    i = nil,
    token_mappings = nil,
    text = nil,
}
setup_class(Tokenizer)

function Tokenizer:__init(text, token_mappings)
    if not is_type(text, "string") then
        error("Expected text to be a string, got "..details_string(text)..".")
    end
    if not is_type(token_mappings, "table") then
        error("Expected token mappings to be a table, got "..details_string(token_mappings)..".")
    end

    self.i = 1
    self.text = text
    self.token_mappings = shallow_copy(token_mappings)

    if self:pattern("whitespace") == nil then
        table.insert(self.token_mappings, { type = "whitespace", pattern = "%s+" })
    end

    self.token = nil
    self.token_type = nil
end

function Tokenizer:pattern(token_type)
    -- Get pattern for output.
    for _, token_mapping in ipairs(self.token_mappings) do
        if token_mapping.type == token_type then
            return string.gsub(token_mapping.patterns[1], "\\\\", "")
        end
    end
    return nil
end

function Tokenizer:_next_token()
    for _, token_mapping in ipairs(self.token_mappings) do
        for _, pattern in ipairs(token_mapping.patterns) do
            local _, i_end, token = string.find(self.text, "^("..pattern..")", self.i)
            if token ~= nil then
                self.i = i_end + 1
                self.token_type = token_mapping.type
                self.token = token
                return self.token_type, self.token
            end
        end
    end

    self:error("Failed to tokenize text at position "..tostring(self.i)..":")
end

function Tokenizer:next()
    local token_type, token
    repeat
        self:_next_token()
    until(self:done() or self.token_type ~= "whitespace")
    return self.token_type, self.token
end

function Tokenizer:is(...)
    for _, token_type_or_f in ipairs({...}) do
        if type(token_type_or_f) == "string" then
            if self.token_type == token_type_or_f then
                return true
            end
        elseif type(token_type_or_f) == "function" then
            if token_type_or_f(self.token_type, self.token) then
                return true
            end
        else
            error("Expected string or function, got "..details_string(token_type_or_f)..".")
        end
    end
    return false
end

function Tokenizer:done()
    return self.i > #self.text
end

function Tokenizer:error(msg, i)
    error(msg.."\n"..self:get_source_string(i))
end

function Tokenizer:get_source_string(i)
    local lines = split_lines(self.text)
    local line_no, line_i = get_line_number(lines, nil_coalesce(i, self.i))

    if line_no == nil then
        return "Tokenizer read past the end of the text (i > #text)."
    end

    local result = ""
    for n = math.max(1, line_no - 2), line_no do
        local line = lines[n]
        local i_begin = math.max(1, line_i - 39)
        local i_end = math.min(#line, line_i + 40)
        result = result..string.sub(line, i_begin, i_end).."\n"

        if n == line_no then
            result = result..string.rep(" ", line_i - i_begin).."^\n"
        end
    end
    if line_no < #lines then
        for n = math.min(#lines, line_no + 1), math.min(#lines, line_no + 2) do
            local line = lines[n]
            local i_begin = math.max(1, line_i - 39)
            local i_end = math.min(#line, line_i + 40)
            result = result..string.sub(line, i_begin, i_end).."\n"
        end
    end
    return result
end
