require "ui.layout_element"
require "ui.text"
require "ui.containers.scroll_frame"

TextBox = {
    CARET_PERIOD = 1,

    _selecting = nil,
    scroll_frame = nil,
    text_element = nil,

    select_pos = nil,
    caret_pos = nil,
}
setup_class(TextBox, LayoutElement)

function TextBox:__init(text)
    super().__init(self)

    self._selecting = false

    self.text_element = Text(text)

    self.scroll_frame = ScrollFrame()
    self.scroll_frame.show_h_scrollbar = false
    self.scroll_frame.show_v_scrollbar = false
    self.scroll_frame.bb = OneWayBinding(
        self, "bb",
        function(bb) 
            return BoundingBox(0, 0, bb:width(), bb:height())
        end
    )

    self.scroll_frame.content = self.text_element
    self:_add_visual_child(self.scroll_frame)

    self:forward_property(self.text_element, "text")
    self:forward_property(self.text_element, "font")
    self:forward_property(self.text_element, "line_spacing")
    self:forward_property(self.text_element, "color")

    self:forward_property(self.scroll_frame, "v_scroll")
    self:forward_property(self.scroll_frame, "h_scroll")
    self:forward_property(self.scroll_frame, "content_margin")
end

function TextBox:get_wrap()
    return self.text_element:has_binding("wrap_width")
end

function TextBox:set_wrap(value)
    if not is_value("boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    if self.wrap ~= bool(value) then
        if value then
            self.text_element.wrap_width = OneWayBinding(
                self, "bb",
                function(bb) return bb:width() end
            )
        else
            self.text_element:unbind("wrap_width")
        end
    end
end

function TextBox:set_allow_input(value)
    if not is_value("boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("allow_input", value)
end

function TextBox:get_allow_input()
    return nil_coalesce(self:_get_property("allow_input"), true)
end

function TextBox:get_caret_index()
    return clamp(nil_coalesce(self:_get_property("caret_index"), 1), 1, #self.text + 1)
end

function TextBox:set_caret_index(value)
    if not (value == nil or is_positive_integer(value)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    self:_set_property("caret_index", value)
end

function TextBox:get_select_index()
    local result = self:_get_property("select_index")
    if result ~= nil then
        result = clamp(result, 1, #self.text + 1)
    end
    return result
end

function TextBox:set_select_index(value)
    if not (value == nil or is_positive_integer(value)) then
        self:_value_error("Value must be a positive integer, or nil.")
    end
    self:_set_property("select_index", value)
end

function TextBox:set_focussed(value)
    if not is_type(value, "boolean", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("focussed", value)
end

function TextBox:set_caret_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("caret_color", value)
end

function TextBox:get_caret_color()
    return nil_coalesce(self:_get_property("caret_color"), {0, 0, 0, 1})
end

function TextBox:set_select_color(value)
    if value ~= nil and #value ~= 4 then
        self:_value_error("Value must be in the form {r, g, b, a}, or nil.")
    end
    self:_set_property("select_color", value)
end

function TextBox:get_select_color()
    return nil_coalesce(self:_get_property("select_color"), {0, 0.3, 1, 0.6})
end

function TextBox:set_allow_newlines(value)
    if not is_type(value, "bool", "nil") then
        self:_value_error("Value must be a boolean, or nil.")
    end
    self:_set_property("allow_newlines", value)
end

function TextBox:get_allow_newlines()
    return nil_coalesce(self:_get_property("allow_newlines"), false)
end

function TextBox:character_pos(character_index)
    if self.font == nil then
        return {0, 0}
    end

    local line, char = get_line_number(split_lines(self.text), character_index)

    local x = self.font:getWidth(string.sub(self.text, 1, char - 1)) + 1
    local y = (line - 1) * (self.font:getHeight() + self.line_spacing + self.font:getLineHeight()) + 1 - self.font:getLineHeight()
    return {x + self.content_margin, y + self.content_margin}
end

function TextBox:has_selection()
    return self.select_index ~= nil and self.select_index ~= self.caret_index
end

function TextBox:delete_selection()
    if not self:has_selection() then
        return
    end
    local min = math.min(self.select_index, self.caret_index)
    local max = math.max(self.select_index, self.caret_index)
    self.text = string.sub(self.text, 1, min - 1)..string.sub(self.text, max, -1)
    self.caret_index = min
    self.select_index = nil
    self._selecting = false
end

function TextBox:clear_selection()
    self.select_index = nil
end

function TextBox:select_all()
    self.select_index = 1
    self:jump_to_end()
end

function TextBox:jump_to_start()
    self.caret_index = 1
end

function TextBox:jump_to_end()
    self.caret_index = #self.text + 1
end

function TextBox:move_caret(direction)
    if direction == Direction.RIGHT then
        self.caret_index = math.min(#self.text + 1, self.caret_index + 1)
        return
    elseif direction == Direction.UP then
        local lines = split_lines(self.text)
        local line, char = get_line_number(lines, self.caret_index)
        if line > 1 then
            self.caret_index = self.caret_index - math.max(#(lines[line - 1]), char)
        else
            self:jump_to_start()
        end
        return
    elseif direction == Direction.LEFT then
        self.caret_index = math.max(1, self.caret_index - 1)
        return
    elseif direction == Direction.DOWN then
        local lines = split_lines(self.text)
        local line, char = get_line_number(lines, self.caret_index)
        if line < #lines then
            self.caret_index = self.caret_index + #(lines[line]) + math.min(#(lines[line + 1]) - char, 0)
        else
            self:jump_to_end()
        end
        return
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function TextBox:character_index(x, y)
    if self.font == nil then
        return 1
    end

    x = x - self.content_margin 
    y = y - self.content_margin 

    local lines = split_lines(self.text)
    local line = math.floor((y - 1) / (self.font:getHeight() + self.line_spacing + self.font:getLineHeight())) + 1
    line = clamp(line, 1, #lines)

    local line_text = lines[line]
    local char = 1
    for i = 1, line - 1 do
        char = char + #(lines[i])
    end

    local lower_w = 0
    local upper_w = self.font:getWidth(line_text)
    if x < 0 then
        return char
    elseif x > self.font:getWidth(line_text) then
        return char + #line_text
    end

    local lower = 1
    local upper = #line_text + 1
    local line_char = 1
    while upper - lower > 1 do
        local middle = math.floor((upper + lower) / 2)
        local w = self.font:getWidth(string.sub(line_text, 1, middle - 1))
        if w > x then
            upper = middle
            upper_w = w
        else
            lower = middle
            lower_w = w
        end
    end
    local line_char = lower
    if math.abs(x - lower_w) > math.abs(x - upper_w) then
        line_char = upper
    end

    char = char + line_char - 1
    return char
end

function TextBox:textinput(t)
    if self.allow_input and self.focussed then
        if not self.allow_newlines then
            t = t.gsub(t, "\n", "")
        end
        if #t > 0 then
            self:delete_selection()
            self:clear_selection()

            self.text = string.sub(self.text, 1, self.caret_index - 1)..t..string.sub(self.text, self.caret_index, -1)
            self.caret_index = self.caret_index + 1
        end
        return true
    end

    return false
end

function TextBox:keypressed(key)
    local ctrl = {"rctrl", "lctrl"}
    local shift = {"rshift", "lshift"}
    if love.system.getOS() == "OS X" then
        ctrl = {"rgui", "lgui"}
    end

    if self.focussed then
        if key == "a" then
            if love.keyboard.isDown(unpack(ctrl)) then
                self:select_all()
            end
        elseif key == "escape" then
            self.focussed = false
            return true
        elseif key == "backspace" then
            if self:has_selection() then
                self:delete_selection()
            elseif self.caret_index > 1 then
                self.text = string.sub(self.text, 1, self.caret_index - 2)..string.sub(self.text, self.caret_index, -1)
                self.caret_index = self:_get_property("caret_index") - 1
            end
            return true
        elseif key == "right" then
            if love.keyboard.isDown(unpack(shift)) and self.select_index == nil then
                self.select_index = self.caret_index
            end
            if love.keyboard.isDown(unpack(ctrl)) then
                self:jump_to_end()
            else
                if love.keyboard.isDown(unpack(shift)) or self.select_index == nil then
                    self:move_caret(Direction.RIGHT)
                elseif self.select_index ~= nil then
                    self.caret_index = math.max(self.caret_index, self.select_index)
                end
            end
            if not love.keyboard.isDown(unpack(shift)) then
                self.select_index = nil
            end
        elseif key == "left" then
            if love.keyboard.isDown(unpack(shift)) and self.select_index == nil then
                self.select_index = self.caret_index
            end
            if love.keyboard.isDown(unpack(ctrl)) then
                self:jump_to_start()
            else
                if love.keyboard.isDown(unpack(shift)) or self.select_index == nil then
                    self:move_caret(Direction.LEFT)
                elseif self.select_index ~= nil then
                    self.caret_index = math.min(self.caret_index, self.select_index)
                end
            end
            if not love.keyboard.isDown(unpack(shift)) then
                self.select_index = nil
            end
        end
    end
    return false
end

function TextBox:mousepressed(x, y, button)
    if button == 1 then
        self.focussed = true
        self.caret_index = self:character_index(x, y)
        self.select_index = self:character_index(x, y)
        self._selecting = true
        return true
    end

    return false
end

function TextBox:update(dt)
    if love.mouse.isDown(1) and not self:contains(unpack(self.mouse_pos)) then
        self.focussed = false
    end

    if self.font == nil then
        return
    end

    if self._selecting then
        if love.mouse.isDown(1) then
            self.caret_index = self:character_index(unpack(self.mouse_pos))
        else
            self._selecting = false
            if self.select_index == self.caret_index then
                self.select_index = nil
            end
        end
    end


    local caret_pos = self:character_pos(self.caret_index)
    self.h_scroll = clamp(self.h_scroll, caret_pos[1] - self.scroll_frame.bb:width(), caret_pos[1])  
    self.v_scroll = clamp(self.v_scroll, caret_pos[2] - self.scroll_frame.bb:height(), caret_pos[2])
end

function TextBox:draw()
    super().draw(self)
    if self.font == nil then
        return
    end
    if self.focussed then
        local caret_pos = self:character_pos(self.caret_index)

        if self.select_index ~= nil and self.select_index ~= self.caret_index then
            local select_pos = self:character_pos(self.select_index)
            local x1, y1, x2, y2 = select_pos[1], select_pos[2], caret_pos[1], caret_pos[2]

            love.graphics.setColor(self.select_color)
            love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1 + self.font:getHeight() + self.font:getLineHeight())
        end

        if (t_now() % (2 * TextBox.CARET_PERIOD) < TextBox.CARET_PERIOD) then
            love.graphics.setColor(self.caret_color)
            love.graphics.line(caret_pos[1], caret_pos[2], caret_pos[1], caret_pos[2] + self.font:getHeight() + self.font:getLineHeight())
        end
    end
end
