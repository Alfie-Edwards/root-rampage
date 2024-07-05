require "ui.layout_element"

Text = {
    text = nil,
    line_drawables = nil,
    text_align = nil,
    color = nil,
    font = nil,
    wrap_width = nil,
    line_spacing = nil,
}
setup_class(Text, LayoutElement)

function Text:__init(text, font, color)
    super().__init(self)

    self.line_drawables = {}
    self.text = text
    self.font = font
    self.color = color
end

function Text:set_text(value)
    if not is_type(value, "string", "table", "nil") then
        self:_value_error("Value must be a string, a list of strings, or nil.")
    end
    if self:_set_property("text", value) then
        self:update_layout()
    end
end

function Text:get_text()
    return nil_coalesce(self:_get_property("text"), "")
end

function Text:set_text_align(value)
    if value ~= nil and not value_in(value, {"left", "center", "right"}) then
        self:_value_error("Valid values are 'left', 'center', right', or nil.")
    end
    self:_set_property("text_align", value)
end

function Text:set_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("color", value)
end

function Text:set_font(value)
    if not is_type(value, "Font", "nil")  then
        self:_value_error("Value must be a love.graphics.Font, or nil.")
    end
    if self:_set_property("font", value) then
        self:update_layout()
    end
end

function Text:set_wrap_width(value)
    if not is_type(value, "number", "nil")  then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("wrap_width", value) then
        self:update_layout()
    end
end

function Text:set_line_spacing(value)
    if not is_type(value, "number", "nil")  then
        self:_value_error("Value must be a number, or nil.")
    end
    if self:_set_property("line_spacing", value) then
        self:update_layout()
    end
end

function Text:get_line_spacing()
    return nil_coalesce(self:_get_property("line_spacing"), 0)
end

function Text:update_layout()
    local text_type = type_string(self.text)
    local width = 0
    local height = 0
    local wrap_width = self:_total_wrap_width()
    self.line_drawables = {}

    -- Helper function
    local add_lines = function(lines)
        for _,line in pairs(lines) do
            local line_drawable = love.graphics.newText(self.font, line)
            table.insert(self.line_drawables, line_drawable)
            width = math.max(width, line_drawable:getWidth())
        end
    end

    if (text_type == "nil" or self.font == nil) then
        -- do nothing

    elseif (text_type == "string") then
        -- If text is a string:
        local lines
        if wrap_width ~= nil then
            lines = wrap_text(self.text, self.font, wrap_width)
        else
            lines = {self.text}
        end
        local total_lines = math.max(1, #lines)
        height = total_lines * (self.font:getHeight() + self.font:getLineHeight()) + (total_lines - 1) * self.line_spacing + self.font:getDescent()
        add_lines(lines)

    elseif (text_type == "table") then
        -- If text is a list of paragraphs:

        local total_lines = 0
        for _,paragraph in ipairs(self.text) do
            local lines
            if wrap_width ~= nil then
                lines = wrap_text(paragraph, self.font, wrap_width)
            else
                lines = {paragraph}
            end
            add_lines(lines)
            total_lines = total_lines + #lines
        end
        if total_lines == 0 then
            total_lines = 1
        end

        height = total_lines * (self.font:getHeight() + self.font:getLineHeight()) + (total_lines - 1) * self.line_spacing + self.font:getDescent()
    end

    -- Calculate bounding box.
    if self.width ~= nil then
        width = math.max(width, self.width)
    end
    if self.height ~= nil then
        height = math.max(height, self.height)
    end
    self.bb = calculate_bb(self.x, self.y, width, height, self.x_align, self.y_align)
end

function Text:_total_wrap_width()
    if self.wrap_width ~= nil then
        if self.width ~= nil then
            return math.min(wrap_width, self.width)
        else
            return self.wrap_width
        end
    else
        if self.width ~= nil then
            return self.width
        else
            return nil
        end
    end
end

function Text:draw()
    super().draw(self)

    local text_align = self.text_align or "left"

    love.graphics.setColor(self.color or {1, 1, 1, 1})
    if self.font ~= nil then
        love.graphics.setFont(self.font)
    end

    local y_offset = 0
    for _,line in ipairs(self.line_drawables) do
        local x_offset

        if text_align == "left" then
            x_offset = 1
        elseif text_align == "center" then
            x_offset = 1 + (self.bb:width() - line:getWidth()) / 2
        elseif text_align == "right" then
            x_offset = 1 + self.bb:width() - line:getWidth()
        end

        love.graphics.draw(line, x_offset, y_offset)
        y_offset = y_offset + line:getFont():getHeight() + (self.line_spacing or 0)
    end
end
